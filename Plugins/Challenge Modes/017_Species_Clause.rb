
module ChallengeModes
  def self.species_clause?
    return on?(:SPECIES_CLAUSE)
  end

  def self.species_in_party?(species)
    species_data = GameData::Species.get(species).species

    $player.party.each do |pokemon|
      next if !pokemon

      party_species = pokemon.species_data.species
      return true if party_species == species_data
    end

    return false
  end

  def self.get_party_species
    species_list = []
    $player.party.each do |pokemon|
      next if !pokemon
      species_list.push(pokemon.species_data.species)
    end
    return species_list
  end

  def self.store_duplicate_gift(result, party_size)
    return result if !result || !species_clause? || $player.party.length <= party_size
    received = $player.party.last
    duplicate = $player.party.first(party_size).any? do |pokemon|
      pokemon && pokemon.species_data.species == received.species_data.species
    end
    return result if !duplicate
    if $PokemonStorage.full?
      $player.party.pop
      pbMessage(_INTL("There is no room in the PC for {1}.", received.name))
      return false
    end
    received.record_first_moves
    box = $PokemonStorage.pbStoreCaught(received)
    if box.nil? || box < 0
      $player.party.pop
      pbMessage(_INTL("There is no room in the PC for {1}.", received.name))
      return false
    end
    $player.party.pop
    pbMessage(_INTL("{1} was sent to Box \"{2}\".", received.name, $PokemonStorage[box].name))
    return true
  end

  def self.process_species_clause_gift
    party_size = $player.party.length
    encounters_before = $PokemonGlobal.challenge_encs&.dup
    result = yield
    processed = store_duplicate_gift(result, party_size)
    $PokemonGlobal.challenge_encs = encounters_before if result && !processed && encounters_before
    return processed
  end
end

EventHandlers.add(:on_player_step_taken, :species_clause_party_check,
  proc {
    next if !ChallengeModes.species_clause?
    seen = {}
    index = 0
    while index < $player.party.length
      pokemon = $player.party[index]
      species = pokemon.species_data.species
      if seen[species]
        if $PokemonStorage.full?
          if !pokemon.instance_variable_defined?(:@challenge_species_clause_full_warning)
            pbMessage(_INTL("{1} cannot be moved to the PC because the Pokémon Boxes are full!", pokemon.name))
            pokemon.instance_variable_set(:@challenge_species_clause_full_warning, true)
          end
        else
          box = $PokemonStorage.pbStoreCaught(pokemon)
          if box && box >= 0
            $player.party.delete_at(index)
            pbMessage(_INTL("{1} was sent to Box \"{2}\" by Species Clause.", pokemon.name, $PokemonStorage[box].name))
            next
          end
        end
      else
        seen[species] = true
      end
      index += 1
    end
  }
)

alias __challengemodes_speciesclause__pbAddPokemon pbAddPokemon unless defined?(__challengemodes_speciesclause__pbAddPokemon)

def pbAddPokemon(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbAddPokemon(*args) }
end

alias __challengemodes_speciesclause__pbAddPokemonSilent pbAddPokemonSilent unless defined?(__challengemodes_speciesclause__pbAddPokemonSilent)
def pbAddPokemonSilent(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbAddPokemonSilent(*args) }
end

alias __challengemodes_speciesclause__pbAddToParty pbAddToParty unless defined?(__challengemodes_speciesclause__pbAddToParty)
def pbAddToParty(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbAddToParty(*args) }
end

alias __challengemodes_speciesclause__pbAddToPartySilent pbAddToPartySilent unless defined?(__challengemodes_speciesclause__pbAddToPartySilent)
def pbAddToPartySilent(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbAddToPartySilent(*args) }
end

alias __challengemodes_speciesclause__pbAddForeignPokemon pbAddForeignPokemon unless defined?(__challengemodes_speciesclause__pbAddForeignPokemon)
def pbAddForeignPokemon(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbAddForeignPokemon(*args) }
end

alias __challengemodes_speciesclause__pbGenerateEgg pbGenerateEgg unless defined?(__challengemodes_speciesclause__pbGenerateEgg)
def pbGenerateEgg(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbGenerateEgg(*args) }
end

alias __challengemodes_speciesclause__pbAddEgg pbAddEgg unless defined?(__challengemodes_speciesclause__pbAddEgg)
def pbAddEgg(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbAddEgg(*args) }
end

alias __challengemodes_speciesclause__pbGenEgg pbGenEgg unless defined?(__challengemodes_speciesclause__pbGenEgg)
def pbGenEgg(*args)
  return ChallengeModes.process_species_clause_gift { __challengemodes_speciesclause__pbGenEgg(*args) }
end

class Battle
  alias __challengemodes_speciesclause__pbThrowPokeBall pbThrowPokeBall unless method_defined?(:__challengemodes_speciesclause__pbThrowPokeBall)

  def pbThrowPokeBall(*args)

    if ChallengeModes.species_clause?
      battler = nil
      if opposes?(args[0])
        battler = @battlers[args[0]]
      else
        battler = @battlers[args[0]].pbDirectOpposing(true)
      end
      battler = battler.allAllies.first if battler.fainted?

      if battler && ChallengeModes.species_in_party?(battler.pokemon.species_data.species)
        species_name = battler.pokemon.species_data.name
        pbDisplay(_INTL("Wait! You already have a {1}!", species_name))
        pbDisplay(_INTL("Species Clause: Only one of each species allowed!"))
        pbDisplay(_INTL("The Poké Ball cannot be used."))
        return
      end
    end

    return __challengemodes_speciesclause__pbThrowPokeBall(*args)
  end
end

def pbCheckPartySpecies
  if !ChallengeModes.species_clause?
    pbMessage(_INTL("Species Clause is not active."))
    return
  end

  species_list = ChallengeModes.get_party_species

  if species_list.empty?
    pbMessage(_INTL("Your party is empty."))
    return
  end

  text = "Party Species:\n"
  species_list.each_with_index do |species, i|
    species_name = GameData::Species.get(species).name
    text += "#{i + 1}. #{species_name}\n"
  end

  pbMessage(_INTL(text))
end
