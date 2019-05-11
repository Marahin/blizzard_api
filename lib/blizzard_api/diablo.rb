# frozen_string_literal: true

module BlizzardApi
  # Diablo III related classes
  module Diablo
    require_relative 'diablo/request'
    require_relative 'diablo/game_data/generic_data_endpoint'

    # Diablo data api
    require_relative 'diablo/game_data/season'
    require_relative 'diablo/game_data/era'

    ##
    # @return {Season}
    def season
      BlizzardApi::Diablo::Season.new
    end

    ##
    # @return {Era}
    def era
      BlizzardApi::Diablo::Era.new
    end

    # Diablo community api
    require_relative 'diablo/community/act'
    require_relative 'diablo/community/artisan'
    require_relative 'diablo/community/follower'
    require_relative 'diablo/community/character'
    require_relative 'diablo/community/item_type'
    require_relative 'diablo/community/item'
    require_relative 'diablo/community/profile'

    ##
    # @return {Act}
    def act
      BlizzardApi::Diablo::Act.new
    end

    ##
    # @return {Artisan}
    def artisan
      BlizzardApi::Diablo::Artisan.new
    end

    ##
    # @return {Follower}
    def follower
      BlizzardApi::Diablo::Follower.new
    end

    ##
    # @return {Character}
    def character
      BlizzardApi::Diablo::Character.new
    end

    ##
    # @return {ItemType}
    def item_type
      BlizzardApi::Diablo::ItemType.new
    end

    ##
    # @return {Type}
    def item
      BlizzardApi::Diablo::Item.new
    end

    ##
    # @return {Profile}
    def profile
      BlizzardApi::Diablo::Profile.new
    end
  end
end