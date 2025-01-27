# frozen_string_literal: true

##
# @!macro [new] request_options
#   @param {Hash} options You can specify some options
#   @option options [String] :locale Overrides the default locale for a single call
#   @option options [String] :namespace Overrides the default namespace for a single call
#   @option options [String] :access_token Overrides the access_token for a single call
#   @option options [Boolean] :ignore_cache If set to true the request will not use the cache
#   @option options [Integer] :ttl Override the default time (in seconds) a request should be cached
#   @option options [DateTime] :since Adds the If-modified-since headers. Will always ignore cache when set.

##
# @!macro [new] regions
#   @param {Symbol} region One of the valid API regions *:us*, *:eu*, *:ko*, and *:tw*
#   @note This gem do not support nor will support China endpoints

##
# @!macro [new] response
#   @return [Hash] API Response. The actual type of the returned object depends on the *format* option
#   in the configuration module

##
# @!macro [new] complete
#   Iterates through the {index} response data and fetch additional information using {get}, it results in a more
#   complete set of data
#   @note IT MAY PERFORM MANY REQUESTS TO FETCH ALL DATA
#   @!macro request_options
#   @!macro response

module BlizzardApi
  ##
  # Simplifies the requests to Blizzard APIS
  class Request
    # One hour cache
    CACHE_HOUR = 3600
    # One day cache
    CACHE_DAY = 24 * CACHE_HOUR
    # Three (commercial) months cache
    CACHE_TRIMESTER = CACHE_DAY * 90

    # Common endpoints
    BASE_URLS = {
      game_data: 'https://%s.api.blizzard.com/data/%s',
      community: 'https://%s.api.blizzard.com/%s',
      profile: 'https://%s.api.blizzard.com/profile/%s',
      media: 'https://%s.api.blizzard.com/data/%s/media',
      user_profile: 'https://%s.api.blizzard.com/profile/user/%s',
      search: 'https://%s.api.blizzard.com/data/%s/search'
    }.freeze

    ##
    # @!attribute region
    #   @return [String] Api region
    attr_accessor :region

    ##
    # @!attribute mode
    #   @return [:regular, :extended]
    attr_accessor :mode

    ##
    # @!macro regions
    def initialize(region = nil, mode = :regular)
      self.region = region || BlizzardApi.region
      @redis = Redis.new(host: BlizzardApi.redis_host, port: BlizzardApi.redis_port) if BlizzardApi.use_cache
      # Use the shared access_token, or create one if it doesn't exists. This avoids unnecessary calls to create tokens.
      @access_token = get_access_token
      # Mode
      @mode = mode
    end

    require 'net/http'
    require 'uri'
    require 'json'
    require 'redis'

    protected

    def base_url(scope)
      raise ArgumentError, 'Invalid scope' unless BASE_URLS.include? scope

      format BASE_URLS[scope], region, @game
    end

    ##
    # Returns a valid namespace string for consuming the api endpoints
    #
    # @param [Hash] options A hash containing the namespace key
    def endpoint_namespace(options)
      case options[:namespace]
      when :dynamic
        options.include?(:classic) ? "dynamic-classic-#{region}" : "dynamic-#{region}"
      when :static
        options.include?(:classic) ? "static-classic-#{region}" : "static-#{region}"
      when :profile
        "profile-#{region}"
      else
        raise ArgumentError, 'Invalid namespace scope'
      end
    end

    def get_access_token
      unless BlizzardApi.access_token
        return create_access_token
      end

      if BlizzardApi.access_token_expires_at <= Time.now + 1.minute
        return create_access_token
      end

      puts "Token exists and has not expired yet, using it (#{Time.now} vs #{BlizzardApi.access_token_expires_at})"
      BlizzardApi.access_token
    end

    def create_access_token
      puts "Token was inexistent or expiring soon; refreshing"

      uri = URI.parse("https://#{BlizzardApi.region}.battle.net/oauth/token")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request.basic_auth(BlizzardApi.app_id, BlizzardApi.app_secret)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.set_form_data grant_type: 'client_credentials'

      response = http.request(request)
    
      BlizzardApi.access_token = JSON.parse(response.body)['access_token']
      BlizzardApi.access_token_expires_at = Time.now + 1.hour

      BlizzardApi.access_token
    end

    def request(url, **options)
      # Creates the whole url for request
      parsed_url = URI.parse(url)

      data = using_cache?(options) ? find_in_cache(parsed_url.to_s) : nil

      # If data was found that means cache is enabled and valid
      return JSON.parse(data, symbolize_names: true) if data

      response = consume_api parsed_url, options

      save_in_cache parsed_url.to_s, response.body, options[:ttl] || CACHE_DAY if using_cache? options

      response_data = response.code.to_i.eql?(304) ? nil : JSON.parse(response.body, symbolize_names: true)
      return [response, response_data] if mode.eql? :extended

      response_data
    end

    def api_request(uri, query_string = {})
      # List of request options
      options_key = %i[ignore_cache ttl format access_token namespace classic headers since]

      # Separates request options from api fields and options. Any user-defined option will be treated as api field.
      options = query_string.select { |k, _v| query_string.delete(k) || true if options_key.include? k }

      # Namespace
      query_string[:namespace] = endpoint_namespace(options) if options.include? :namespace

      # In case uri already have query string parameters joins them with &
      if query_string.size.positive?
        query_string = URI.encode_www_form(query_string, false)
        uri = uri.include?('?') ? "#{uri}&#{query_string}" : "#{uri}?#{query_string}"
      end

      request uri, options
    end

    private

    ##
    # @param options [Hash] Request options
    def using_cache?(options)
      return false if mode.eql?(:extended) || options.key?(:since)

      !options.fetch(:ignore_cache, false)
    end

    def consume_api(url, **options)
      # Creates a HTTP connection and request to ensure thread safety
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(url)

      add_headers request, options

      # Executes the request
      http.request(request).tap do |response|
        if mode.eql?(:regular) && ![200, 304].include?(response.code.to_i)
        puts "Request made; url: #{url}, options: #{options.inspect}, code: #{response.code}"
          raise BlizzardApi::ApiException.new "Request failed (Blizzard responded with status: #{response.code})", response.code.to_i
        end
      end
    end

    def add_headers(request, options)
      # Blizzard API documentation states the preferred way to send the access_token is using Bearer token on header
      request['Authorization'] = "Bearer #{options.fetch(:access_token, @access_token)}"
      # Format If-modified-since option
      request['If-Modified-Since'] = options[:since].httpdate if options.key? :since
      options[:headers]&.each { |header, content| request[header] = content }
    end

    def save_in_cache(resource_url, data, ttl)
      @redis.setex resource_url, ttl, data if BlizzardApi.use_cache
    end

    def find_in_cache(resource_url)
      return false unless BlizzardApi.use_cache

      @redis.get resource_url if @redis.exists? resource_url
    end
  end
end
