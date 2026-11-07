module ChallengeModes
  def self.is_legendary?(pokemon)
    species_data = pokemon.is_a?(Pokemon) ? pokemon.species_data : GameData::Species.get(pokemon)
    return species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")
  end

  def self.no_legendaries?
    return on?(:NO_LEGENDARIES)
  end

  def self.block_legendary_gift?(pokemon)
    return false if !pokemon || !no_legendaries? || !is_legendary?(pokemon)
    pbMessage(_INTL("Legendary and Mythical Pokémon cannot be obtained in Challenge Mode!"))
    return true
  end
end

class Battle
  alias __challengemodes_nolegend__pbThrowPokeBall pbThrowPokeBall unless method_defined?(:__challengemodes_nolegend__pbThrowPokeBall)

  def pbThrowPokeBall(*args)
    if ChallengeModes.no_legendaries?
      battler = @battlers[args[0]]
      battler = battler.pbDirectOpposing(true) if battler && !opposes?(args[0])
      battler = battler.allAllies.first if battler && battler.fainted?
      if battler && ChallengeModes.is_legendary?(battler.pokemon)
        pbDisplay(_INTL("The Poké Ball won't work!"))
        pbDisplay(_INTL("Legendary and Mythical Pokémon cannot be caught in Challenge Mode!"))
        return
      end
    end
    return __challengemodes_nolegend__pbThrowPokeBall(*args)
  end
end

EventHandlers.add(:on_player_step_taken, :no_legendaries_check,
  proc {
    next if !ChallengeModes.no_legendaries?
    ($player.party.length - 1).downto(0) do |i|
      pokemon = $player.party[i]
      next if !ChallengeModes.is_legendary?(pokemon)
      if $player.party.none? { |candidate| !candidate.equal?(pokemon) && candidate.able? && !ChallengeModes.is_legendary?(candidate) }
        if !pokemon.instance_variable_defined?(:@challenge_nolegend_only_warning)
          pbMessage(_INTL("{1} cannot be removed until you have another usable Pokémon!", pokemon.name))
          pokemon.instance_variable_set(:@challenge_nolegend_only_warning, true)
        end
        next
      end
      if $PokemonStorage.full?
        if !pokemon.instance_variable_defined?(:@challenge_nolegend_full_warning)
          pbMessage(_INTL("{1} cannot be used in Challenge Mode, but the Pokémon Boxes are full!", pokemon.name))
          pokemon.instance_variable_set(:@challenge_nolegend_full_warning, true)
        end
        next
      end
      stored_box = $PokemonStorage.pbStoreCaught(pokemon)
      next if stored_box.nil? || stored_box < 0
      $player.party.delete_at(i)
      pbMessage(_INTL("{1} was sent to the Pokémon Boxes because of the No Legendaries rule.", pokemon.name))
    end
  }
)

alias __challengemodes_nolegend__pbAddPokemon pbAddPokemon unless defined?(__challengemodes_nolegend__pbAddPokemon)
def pbAddPokemon(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbAddPokemon(*args)
end

alias __challengemodes_nolegend__pbAddPokemonSilent pbAddPokemonSilent unless defined?(__challengemodes_nolegend__pbAddPokemonSilent)
def pbAddPokemonSilent(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbAddPokemonSilent(*args)
end

alias __challengemodes_nolegend__pbAddToParty pbAddToParty unless defined?(__challengemodes_nolegend__pbAddToParty)
def pbAddToParty(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbAddToParty(*args)
end

alias __challengemodes_nolegend__pbAddToPartySilent pbAddToPartySilent unless defined?(__challengemodes_nolegend__pbAddToPartySilent)
def pbAddToPartySilent(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbAddToPartySilent(*args)
end

alias __challengemodes_nolegend__pbAddForeignPokemon pbAddForeignPokemon unless defined?(__challengemodes_nolegend__pbAddForeignPokemon)
def pbAddForeignPokemon(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbAddForeignPokemon(*args)
end

alias __challengemodes_nolegend__pbGenerateEgg pbGenerateEgg unless defined?(__challengemodes_nolegend__pbGenerateEgg)
def pbGenerateEgg(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbGenerateEgg(*args)
end

alias __challengemodes_nolegend__pbAddEgg pbAddEgg unless defined?(__challengemodes_nolegend__pbAddEgg)
def pbAddEgg(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbAddEgg(*args)
end

alias __challengemodes_nolegend__pbGenEgg pbGenEgg unless defined?(__challengemodes_nolegend__pbGenEgg)
def pbGenEgg(*args)
  return false if ChallengeModes.block_legendary_gift?(args[0])
  return __challengemodes_nolegend__pbGenEgg(*args)
end
