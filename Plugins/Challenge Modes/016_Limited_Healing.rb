class PokemonGlobalMetadata
  attr_accessor :challenge_healing_counts
end

module ChallengeModes
  class << self
    attr_accessor :healing_interpreter

    def limited_healing?
      return on?(:LIMITED_HEALING)
    end

    def healing_counts
      return {} if !$PokemonGlobal
      return $PokemonGlobal.challenge_healing_counts ||= {}
    end

    def get_healing_count(map_id = nil)
      return healing_counts[map_id || $game_map.map_id] || 0
    end

    def increment_healing_count(map_id = nil)
      map_id ||= $game_map.map_id
      healing_counts[map_id] = get_healing_count(map_id) + 1
    end

    def can_heal_on_map?(map_id = nil)
      return !limited_healing? || get_healing_count(map_id) < LIMITED_HEALING_COUNT
    end

    def remaining_heals(map_id = nil)
      return -1 if !limited_healing?
      return [LIMITED_HEALING_COUNT - get_healing_count(map_id), 0].max
    end

    def reset_healing_counter
      $PokemonGlobal.challenge_healing_counts = {} if $PokemonGlobal
    end

    def center_healing_allowed?(map_id)
      if no_pokemon_center?
        pbMessage(_INTL("Pokémon Center healing is blocked by Challenge Mode rules!"))
        return false
      end
      if !can_heal_on_map?(map_id)
        pbMessage(_INTL("You've already used your {1} healing visits in {2}.",
                        LIMITED_HEALING_COUNT, pbGetMapNameFromId(map_id)))
        return false
      end
      return true
    end

    alias __limitheal__reset reset unless method_defined?(:__limitheal__reset)
    def reset
      __limitheal__reset
      reset_healing_counter
    end
  end

  module CenterHealingEvent
    attr_writer :challenge_healing_map

    def clear
      @challenge_healing_map = nil
      super
    end

    def command_end
      @challenge_healing_map = nil
      super
    end

    def command_355
      previous = ChallengeModes.healing_interpreter
      ChallengeModes.healing_interpreter = self
      result = catch(:challenge_center_denied) { super }
      return command_115 if result == :denied
      return result
    ensure
      ChallengeModes.healing_interpreter = previous
    end

    def command_314
      return super if @parameters[0] != 0
      map_id = @challenge_healing_map
      if !map_id && @event_id > 0 && @map_id == $game_map.map_id
        event = $game_map.events[@event_id]
        map_id = @map_id if event && event.name == "Nurse"
      end
      return super if !map_id
      @challenge_healing_map = nil
      return command_115 if !ChallengeModes.center_healing_allowed?(map_id)
      result = super
      if result && ChallengeModes.limited_healing?
        ChallengeModes.increment_healing_count(map_id)
        pbMessage(_INTL("Healing visits remaining in {1}: {2}.",
                        pbGetMapNameFromId(map_id), ChallengeModes.remaining_heals(map_id)))
      end
      return result
    end
  end
end

Interpreter.prepend(ChallengeModes::CenterHealingEvent)

alias __challenge_healing__pbSetPokemonCenter pbSetPokemonCenter
def pbSetPokemonCenter
  interpreter = ChallengeModes.healing_interpreter
  if interpreter
    if !ChallengeModes.center_healing_allowed?($game_map.map_id)
      $game_temp.pokecenter_following_pkmn = 0 if $game_temp.respond_to?(:pokecenter_following_pkmn=)
      throw :challenge_center_denied, :denied
    end
    interpreter.challenge_healing_map = $game_map.map_id
  end
  return __challenge_healing__pbSetPokemonCenter
end

def pbCheckHealingStatus
  if !ChallengeModes.limited_healing?
    pbMessage(_INTL("Limited Healing is not active."))
    return
  end

  map_id = $game_map.map_id
  map_name = pbGetMapNameFromId(map_id)
  count = ChallengeModes.get_healing_count(map_id)
  remaining = ChallengeModes.remaining_heals(map_id)

  if remaining > 0
    pbMessage(_INTL("Healing visits in {1}:\n{2} used, {3} remaining",
                    map_name, count, remaining))
  else
    pbMessage(_INTL("You've used all {1} healing visits in {2}!",
                    ChallengeModes::LIMITED_HEALING_COUNT, map_name))
  end
end
