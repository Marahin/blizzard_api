# frozen_string_literal: true

module BlizzardApi
  module Diablo
    ##
    # This class allows access to Diablo III profile data
    #
    # @see https://develop.battle.net/documentation/api-reference/diablo-3-community-api
    #
    # You can get an instance of this class using the default region as follows:
    #   api_instance = BlizzardApi::Diablo.profile
    class Profile < BlizzardApi::Diablo::Request
      ##
      # Return an user's profile data with a list of heroes
      #
      # @param battletag [String] User's battletag
      # @param oauth_token [String] A token generated by the OAuth authorization flow. See the link below for more info.
      # @!macro request_options
      #
      # @!macro response
      #
      # @see https://develop.battle.net/documentation/guides/using-oauth/authorization-code-flow
      def index(battletag, oauth_token, **options)
        opts = { access_token: oauth_token, ttl: CACHE_TRIMESTER }.merge(options)
        api_request "#{base_url(:community)}/profile/#{parse_battle_tag(battletag)}/", opts
      end

      ##
      # Return more data about a hero
      #
      # @param battletag [String] User's battletag
      # @param oauth_token [String] A token generated by the OAuth authorization flow. See the link below for more info.
      # @param hero_id [Integer] Hero id
      # @!macro request_options
      #
      # @!macro response
      #
      # @see https://develop.battle.net/documentation/guides/using-oauth/authorization-code-flow
      def hero(battletag, oauth_token, hero_id, **options)
        opts = { access_token: oauth_token, ttl: CACHE_TRIMESTER }.merge(options)
        api_request "#{base_url(:community)}/profile/#{parse_battle_tag(battletag)}/hero/#{hero_id}", opts
      end

      ##
      # Return more data about a hero's items
      #
      # @param battletag [String] User's battletag
      # @param oauth_token [String] A token generated by the OAuth authorization flow. See the link below for more info.
      # @param hero_id [Integer] Hero id
      # @!macro request_options
      #
      # @!macro response
      #
      # @see https://develop.battle.net/documentation/guides/using-oauth/authorization-code-flow
      def hero_items(battletag, oauth_token, hero_id, **options)
        opts = { access_token: oauth_token, ttl: CACHE_TRIMESTER }.merge(options)
        api_request "#{base_url(:community)}/profile/#{parse_battle_tag(battletag)}/hero/#{hero_id}/items", opts
      end

      ##
      # Return more data about a hero's followers
      #
      # @param battletag [String] User's battletag
      # @param oauth_token [String] A token generated by the OAuth authorization flow. See the link below for more info.
      # @param hero_id [Integer] Hero id
      # @!macro request_options
      #
      # @!macro response
      #
      # @see https://develop.battle.net/documentation/guides/using-oauth/authorization-code-flow
      def hero_follower_items(battletag, oauth_token, hero_id, **options)
        opts = { access_token: oauth_token, ttl: CACHE_TRIMESTER }.merge(options)
        api_request "#{base_url(:community)}/profile/#{parse_battle_tag(battletag)}/hero/#{hero_id}/follower-items", opts
      end

      private

      def parse_battle_tag(battletag)
        battletag.sub('#', '-')
      end
    end
  end
end
