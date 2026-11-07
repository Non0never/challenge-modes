module ChallengeModes
  TRAINER_SCALING = {
    :level_boost => 2,
    :extra_pokemon_chance => 40,
    :evolution_upgrade_chance => 30,
    :better_items => true,
    :improved_ivs => true,
    :held_items => true
  }

  def self.scaling_active?
    on?(:TRAINER_SCALING)
  end

  def self.scaling_held_item(pokemon)
    items = {
      :FIRE => :CHARCOAL, :WATER => :MYSTICWATER, :GRASS => :MIRACLESEED,
      :ELECTRIC => :MAGNET, :PSYCHIC => :TWISTEDSPOON, :FIGHTING => :BLACKBELT,
      :DARK => :BLACKGLASSES, :DRAGON => :DRAGONFANG, :GHOST => :SPELLTAG,
      :POISON => :POISONBARB, :ICE => :NEVERMELTICE, :BUG => :SILVERPOWDER,
      :ROCK => :HARDSTONE, :GROUND => :SOFTSAND, :STEEL => :METALCOAT,
      :FLYING => :SHARPBEAK, :FAIRY => :PIXIEPLATE
    }
    item = items[pokemon.types.first] || :SITRUSBERRY
    GameData::Item.exists?(item) ? item : nil
  end

  def self.scale_trainer_party(trainer)
    return unless trainer && trainer.party && !trainer.party.empty?
    settings = TRAINER_SCALING
    trainer.party.compact.each do |pokemon|
      pokemon.level = (pokemon.level + settings[:level_boost]).clamp(1, Settings::MAXIMUM_LEVEL)
      if rand(100) < settings[:evolution_upgrade_chance]
        evolution = pokemon.species_data.get_evolutions.find do |entry|
          method, level = entry[1], entry[2]
          next false unless [:Level, :LevelMale, :LevelFemale].include?(method)
          next false if method == :LevelMale && !pokemon.male?
          next false if method == :LevelFemale && !pokemon.female?
          level.is_a?(Numeric) && pokemon.level >= level
        end
        if evolution
          pokemon.species = evolution[0]
          pokemon.form_simple = 0
          pokemon.reset_moves
        end
      end
      if settings[:improved_ivs]
        GameData::Stat.each_main { |stat| pokemon.iv[stat.id] = [pokemon.iv[stat.id], 25].max }
      end
      pokemon.item = scaling_held_item(pokemon) if settings[:held_items] && !pokemon.item
      pokemon.calc_stats
    end
    if trainer.party.length < 6 && rand(100) < settings[:extra_pokemon_chance]
      strongest = trainer.party.compact.max_by(&:level)
      if strongest
        pool = []
        GameData::Species.each_species do |species|
          next if species.species == strongest.species
          next if species.has_flag?("Legendary") || species.has_flag?("Mythical")
          pool << species.species if (species.types & strongest.types).any?
        end
        species = pool.sample || strongest.species
        level = (strongest.level - rand(1..3)).clamp(1, Settings::MAXIMUM_LEVEL)
        pokemon = Pokemon.new(species, level, trainer)
        pokemon.item = scaling_held_item(pokemon) if settings[:held_items]
        GameData::Stat.each_main { |stat| pokemon.iv[stat.id] = 20 } if settings[:improved_ivs]
        pokemon.calc_stats
        trainer.party << pokemon
      end
    end
    if settings[:better_items]
      upgrades = { :POTION => :SUPERPOTION, :SUPERPOTION => :HYPERPOTION,
                   :HYPERPOTION => :FULLRESTORE, :REVIVE => :MAXREVIVE }
      trainer.items = Array(trainer.items).map do |item|
        replacement = upgrades[item]
        replacement && GameData::Item.exists?(replacement) ? replacement : item
      end
      trainer.items << :FULLRESTORE if trainer.items.length < 2 && GameData::Item.exists?(:FULLRESTORE)
    end
  end
end

module ChallengeModesTrainerScaling
  def initialize(scene, party1, party2, player, opponent)
    if opponent && ChallengeModes.scaling_active?
      trainers = Array(opponent)
      trainers.each { |trainer| ChallengeModes.scale_trainer_party(trainer) }
      party2 = trainers.flat_map(&:party)
    end
    super(scene, party1, party2, player, opponent)
  end
end

Battle.prepend(ChallengeModesTrainerScaling)
