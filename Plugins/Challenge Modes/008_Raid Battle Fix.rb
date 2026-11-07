
class Battle
  alias raid_fix_pbStorePokemon pbStorePokemon if method_defined?(:pbStorePokemon)
  def pbStorePokemon(pkmn)
    if @raid

      if $player.party.length < Settings::MAX_PARTY_SIZE
        return true
      else
        return false
      end
    end

    if respond_to?(:raid_fix_pbStorePokemon)
      return raid_fix_pbStorePokemon(pkmn)
    else
      return $player.party.length < Settings::MAX_PARTY_SIZE
    end
  end
end
