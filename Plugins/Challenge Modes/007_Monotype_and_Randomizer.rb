
EventHandlers.add(:on_pokemon_received, :monotype_check,
  proc { |pokemon|
    next if !pokemon
    next if !ChallengeModes.on?(:MONOTYPE_MODE)
    next if ChallengeModes.valid_monotype_catch?(pokemon)

    type_name = GameData::Type.get($PokemonGlobal.challenge_monotype_type).name
    species_name = pokemon.species_data.name
    pbMessage(_INTL("The Monotype challenge prevents you from using {1}! You can only use {2}-type Pokémon.", species_name, type_name))

  }
)

class Battle
  alias __monotype__initialize initialize unless method_defined?(:__monotype__initialize)
  def initialize(scene, party1, party2, player, opponent)
    no_legendaries = ChallengeModes.no_legendaries?
    if (ChallengeModes.on?(:MONOTYPE_MODE) || no_legendaries) &&
       (player == $player || (player.is_a?(Array) && player[0] == $player))
      partner_length = player.is_a?(Array) ? player.drop(1).sum { |trainer| trainer.party.length } : 0
      player_party_length = [party1.length - partner_length, 0].max
      usable = party1.first(player_party_length).any? do |pokemon|
        pokemon && pokemon.able? && ChallengeModes.valid_monotype_battle?(pokemon) &&
          (!no_legendaries || !ChallengeModes.is_legendary?(pokemon))
      end
      if usable
        party1 = party1.each_with_index.map do |pokemon, index|
          invalid = pokemon && (!ChallengeModes.valid_monotype_battle?(pokemon) ||
                                (no_legendaries && ChallengeModes.is_legendary?(pokemon)))
          index < player_party_length && invalid ? nil : pokemon
        end
      end
    end
    __monotype__initialize(scene, party1, party2, player, opponent)
  end

  alias __monotype__pbCanSwitchIn? pbCanSwitchIn? unless method_defined?(:__monotype__pbCanSwitchIn?)
  def pbCanSwitchIn?(idxBattler, idxParty, partyScene = nil)
    return false if !__monotype__pbCanSwitchIn?(idxBattler, idxParty, partyScene)

    if idxParty >= 0 && pbOwnedByPlayer?(idxBattler) && @player[0] == $player
      pokemon = pbParty(idxBattler)[idxParty]
      if pokemon && (!ChallengeModes.valid_monotype_battle?(pokemon) ||
                     (ChallengeModes.no_legendaries? && ChallengeModes.is_legendary?(pokemon)))
        return false
      end
    end

    return true
  end
end

EventHandlers.add(:on_wild_species_chosen, :randomizer_wild,
  proc { |encounter|
    next if !ChallengeModes.on?(:RANDOMIZER_MODE)
    next if !ChallengeModes::RANDOMIZER_SETTINGS[:wild_pokemon]
    next if !encounter

    original_species = encounter[0]
    level = encounter[1] || 1

    begin
      species_data = GameData::Species.get(original_species)
    rescue

      Console.echo_warn("Randomizer: Received unexpected species format: #{original_species.class} - #{original_species}")
      next
    end

    is_legendary = species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")

    randomized_species = ChallengeModes.get_randomized_species(original_species, is_legendary, level)
    encounter[0] = randomized_species
  }
)

module ChallengeModes
  def self.replace_randomized_species(pokemon, species)
    return if pokemon.species == species
    level = pokemon.level
    fraction = pokemon.exp_fraction
    growth = GameData::GrowthRate.get(GameData::Species.get(species).growth_rate)
    start_exp = growth.minimum_exp_for_level(level)
    new_exp = start_exp
    if level < GameData::GrowthRate.max_level
      next_exp = growth.minimum_exp_for_level(level + 1)
      new_exp += ((next_exp - start_exp) * fraction).floor
      new_exp = [new_exp, next_exp - 1].min
    end
    pokemon.exp = new_exp
    pokemon.species = species
    pokemon.form_simple = 0
    pokemon.reset_moves
  end

  def self.randomize_gifts?
    return false if !on?(:RANDOMIZER_MODE)
    setting = running? ? :gift_pokemon : :starter_pokemon
    return RANDOMIZER_SETTINGS[setting]
  end

  def self.randomize_gift_args(args, egg = false)
    if randomize_gifts? && args[0]
      pkmn = args[0]
      if pkmn.is_a?(Symbol) || pkmn.is_a?(String)
        species_data = GameData::Species.get(pkmn)
        is_legendary = species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")
        level = egg ? Settings::EGG_LEVEL : (args[1] || 1)
        args[0] = get_randomized_species(pkmn, is_legendary, level)
      elsif pkmn.is_a?(Pokemon)
        species_data = pkmn.species_data
        is_legendary = species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")
        randomized_species = get_randomized_species(pkmn.species, is_legendary, pkmn.level)
        if randomized_species != pkmn.species
          new_pokemon = pkmn.clone
          new_pokemon.iv = pkmn.iv.clone
          new_pokemon.ev = pkmn.ev.clone
          new_pokemon.moves = []
          replace_randomized_species(new_pokemon, randomized_species)
          args[0] = new_pokemon
        end
      end
    end
    return args
  end

  def self.process_randomizer_gift(args, egg = false)
    args = randomize_gift_args(args, egg)
    return false if on?(:NO_LEGENDARIES) && block_legendary_gift?(args[0])
    return yield(*args)
  end
end

alias __randomizer__pbAddPokemon pbAddPokemon unless defined?(__randomizer__pbAddPokemon)
def pbAddPokemon(*args)
  return ChallengeModes.process_randomizer_gift(args) { |*gift_args| __randomizer__pbAddPokemon(*gift_args) }
end

alias __randomizer__pbAddPokemonSilent pbAddPokemonSilent unless defined?(__randomizer__pbAddPokemonSilent)
def pbAddPokemonSilent(*args)
  return ChallengeModes.process_randomizer_gift(args) { |*gift_args| __randomizer__pbAddPokemonSilent(*gift_args) }
end

alias __randomizer__pbAddToParty pbAddToParty unless defined?(__randomizer__pbAddToParty)
def pbAddToParty(*args)
  return ChallengeModes.process_randomizer_gift(args) { |*gift_args| __randomizer__pbAddToParty(*gift_args) }
end

alias __randomizer__pbAddToPartySilent pbAddToPartySilent unless defined?(__randomizer__pbAddToPartySilent)
def pbAddToPartySilent(*args)
  return ChallengeModes.process_randomizer_gift(args) { |*gift_args| __randomizer__pbAddToPartySilent(*gift_args) }
end

alias __randomizer__pbAddForeignPokemon pbAddForeignPokemon unless defined?(__randomizer__pbAddForeignPokemon)
def pbAddForeignPokemon(*args)
  return ChallengeModes.process_randomizer_gift(args) { |*gift_args| __randomizer__pbAddForeignPokemon(*gift_args) }
end

alias __randomizer__pbGenerateEgg pbGenerateEgg unless defined?(__randomizer__pbGenerateEgg)
def pbGenerateEgg(*args)
  return ChallengeModes.process_randomizer_gift(args, true) { |*gift_args| __randomizer__pbGenerateEgg(*gift_args) }
end

alias __randomizer__pbAddEgg pbAddEgg unless defined?(__randomizer__pbAddEgg)
def pbAddEgg(*args)
  return ChallengeModes.process_randomizer_gift(args, true) { |*gift_args| __randomizer__pbAddEgg(*gift_args) }
end

alias __randomizer__pbGenEgg pbGenEgg unless defined?(__randomizer__pbGenEgg)
def pbGenEgg(*args)
  return ChallengeModes.process_randomizer_gift(args, true) { |*gift_args| __randomizer__pbGenEgg(*gift_args) }
end

alias __randomizer__pbLoadTrainer pbLoadTrainer unless defined?(__randomizer__pbLoadTrainer)
def pbLoadTrainer(tr_type, tr_name, tr_version = 0)
  trainer = __randomizer__pbLoadTrainer(tr_type, tr_name, tr_version)
  return nil if !trainer

  if ChallengeModes.on?(:RANDOMIZER_MODE) && ChallengeModes::RANDOMIZER_SETTINGS[:trainer_pokemon]
    trainer.party.each do |pokemon|
      original_species = pokemon.species
      species_data = pokemon.species_data
      is_legendary = species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")
      randomized_species = ChallengeModes.get_randomized_species(original_species, is_legendary, pokemon.level)

      if randomized_species != original_species
        ChallengeModes.replace_randomized_species(pokemon, randomized_species)
      end
    end
  end
  return trainer
end

module ChallengeModes
  alias __new_modes__reset reset unless method_defined?(:__new_modes__reset)
  def reset
    __new_modes__reset
    return if !$PokemonGlobal
    $PokemonGlobal.challenge_monotype_type = nil
    $PokemonGlobal.challenge_randomizer_seed = nil
    $PokemonGlobal.challenge_randomizer_map = nil
  end
end
