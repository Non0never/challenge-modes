module ChallengeModes
  ONE_CAPTURE_WHITELIST = [
    :DIALGA, :PALKIA, :GIRATINA, :ARCEUS
  ]

  SPLIT_MAPS_FOR_ENCOUNTERS = [
    [44, 45],
    [49, 50, 51]
  ]

  MONOTYPE_TYPES = [
    :NORMAL, :FIRE, :WATER, :ELECTRIC, :GRASS, :ICE, :FIGHTING, :POISON,
    :GROUND, :FLYING, :PSYCHIC, :BUG, :ROCK, :GHOST, :DRAGON, :DARK, :STEEL, :FAIRY
  ]

  RANDOMIZER_SETTINGS = {
    :wild_pokemon => true,
    :trainer_pokemon => true,
    :starter_pokemon => true,
    :gift_pokemon => true,
    :legendary_separate => true,
    :similar_strength => true
  }

  RULES = {
    :PERMAFAINT => {
      :name  => _INTL("Permafaint"),
      :desc  => _INTL("Once a Pokémon faints, it cannot be revived until the challenge ends."),
      :order => 1
    },
    :ONE_CAPTURE => {
      :name  => _INTL("One Capture per Map"),
      :desc  => _INTL("Only the first Pokémon encountered on a map can be caught and added to your party."),
      :order => 2
    },
    :SHINY_CLAUSE => {
      :name  => _INTL("Shiny Clause"),
      :desc  => _INTL("Shiny Pokemon are exempt from the \"One Capture per Map\" rule."),
      :order => 3
    },
    :DUPS_CLAUSE => {
      :name  => _INTL("Dupes Clause"),
      :desc  => _INTL("Evolution lines of owned species don't count as \"first encounters\" for the \"One Capture per Map\" rule."),
      :order => 4
    },
    :GIFT_CLAUSE => {
      :name  => _INTL("Gift Clause"),
      :desc  => _INTL("Gifted Pokémon or eggs don't count as \"first encounters\" for the \"One Capture per Map\" rule."),
      :order => 5
    },
    :MONOTYPE_MODE => {
      :name  => _INTL("Monotype Challenge"),
      :desc  => _INTL("You can only use Pokémon of a single type. Mixed-type Pokémon must have your chosen type as primary or secondary type."),
      :order => 6
    },
    :RANDOMIZER_MODE => {
      :name  => _INTL("Randomizer Mode"),
      :desc  => _INTL("Wild Pokémon, trainer Pokémon, and gifts are randomized while maintaining game balance."),
      :order => 7
    },
    :FORCE_NICKNAME => {
      :name  => _INTL("Forced Nicknames"),
      :desc  => _INTL("Any Pokémon that is caught/obtained must be nicknamed."),
      :order => 8
    },
    :FORCE_SET_BATTLES => {
      :name  => _INTL("Forced Set Battle Style"),
      :desc  => _INTL("The option to switch your Pokémon after fainting an opponent's Pokémon will not be shown."),
      :order => 9
    },
    :NO_TRAINER_BATTLE_ITEMS => {
      :name  => _INTL("No Items in Trainer Battles"),
      :desc  => _INTL("Item usage will be disabled in Trainer Battles."),
      :order => 10
    },
    :GAME_OVER_WHITEOUT => {
      :name  => _INTL("No White-out"),
      :desc  => _INTL("If all your party Pokémon faint in battle, you lose the challenge immediately."),
      :order => 11
    },

    :LEVEL_CAP => {
      :name  => _INTL("Level Cap"),
      :desc  => _INTL("Your Pokémon cannot exceed the level of the next Gym Leader's strongest Pokémon."),
      :order => 12
    },
    :TRAINER_SCALING => {
      :name  => _INTL("Trainer Scaling"),
      :desc  => _INTL("All trainers receive boosted levels (+2), better items, improved IVs, and a chance for extra Pokémon."),
      :order => 13
    },
    :NO_POKEMON_CENTER => {
      :name  => _INTL("No Pokémon Centers"),
      :desc  => _INTL("Pokémon Centers cannot be used for healing. Only items can restore your team."),
      :order => 14
    },
    :NO_LEGENDARIES => {
      :name  => _INTL("No Legendaries"),
      :desc  => _INTL("Legendary and Mythical Pokémon cannot be caught or used in battle."),
      :order => 15
    },
    :LIMITED_HEALING => {
      :name  => _INTL("Limited Pokémon Center Usage"),
      :desc  => _INTL("You can only heal at Pokémon Centers a limited number of times per area."),
      :order => 16
    },
    :SPECIES_CLAUSE => {
      :name  => _INTL("Species Clause"),
      :desc  => _INTL("Cannot have duplicate Pokémon species in your party. Forces team diversity."),
      :order => 17
    },
    :ITEM_RESTRICTIONS => {
      :name  => _INTL("Item Restrictions"),
      :desc  => _INTL("X-Items are banned in battle. Limited Revives and Full Restores per battle."),
      :order => 18
    }
  }

  LIMITED_HEALING_COUNT = 3

  ITEM_RESTRICTIONS_CONFIG = {
    :banned_x_items => true,
    :max_revives_per_battle => 2,
    :max_full_restores_per_battle => 1
  }
end
