
class PokemonGlobalMetadata
  attr_accessor :challenge_randomizer_active
end

module ChallengeModes

  class << self
    alias early_randomizer_on? on?
    alias early_randomizer_start start
    alias early_randomizer_begin_challenge begin_challenge
    alias early_randomizer_reset reset
  end

  def self.start
    early_randomizer_start

    if $PokemonGlobal&.challenge_rules&.include?(:RANDOMIZER_MODE)
      if !$PokemonGlobal.challenge_randomizer_seed
        initialize_randomizer
        echoln ">>> Randomizer mode activated immediately (will work on starters)"
      end
      $PokemonGlobal.challenge_randomizer_active = true
      echoln "  challenge_randomizer_active set to TRUE"
      echoln "  ChallengeModes.on?(:RANDOMIZER_MODE) = #{on?(:RANDOMIZER_MODE)}"
    end
  end

  def self.on?(rule = nil)

    if rule == :RANDOMIZER_MODE && $PokemonGlobal&.challenge_randomizer_active
      return true
    end

    return early_randomizer_on?(rule)
  end

  def self.begin_challenge

    randomizer_already_active = $PokemonGlobal&.challenge_randomizer_active

    return false if !early_randomizer_begin_challenge

    if randomizer_already_active
      echoln ">>> Full challenge started (Randomizer was already active)"
    end
    return true
  end

  def self.reset
    $PokemonGlobal.challenge_randomizer_active = nil if $PokemonGlobal
    early_randomizer_reset
  end
end

