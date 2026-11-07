
module ChallengeModes
  RULES[:HARDCORE_MODE] = {
    :name  => _INTL("Hardcore Mode"),
    :desc  => _INTL("All Pokémon have perfect IVs (31) and EVs are disabled entirely. Creates a balanced competitive experience."),
    :order => 19
  }
end

EventHandlers.add(:on_wild_pokemon_created, :hardcore_ivs,
  proc { |pkmn|
    next if !ChallengeModes.on?(:HARDCORE_MODE)

    GameData::Stat.each_main do |s|
      pkmn.iv[s.id] = 31
    end

    GameData::Stat.each_main do |s|
      pkmn.ev[s.id] = 0
    end

    pkmn.calc_stats
  }
)

EventHandlers.add(:on_pokemon_received, :hardcore_ivs,
  proc { |pkmn|

    next if !pkmn
    next if !ChallengeModes.on?(:HARDCORE_MODE)

    GameData::Stat.each_main do |s|
      pkmn.iv[s.id] = 31
    end

    GameData::Stat.each_main do |s|
      pkmn.ev[s.id] = 0
    end

    pkmn.calc_stats
  }
)

class Battle
  alias hardcore_pbGainEVsOne pbGainEVsOne
  def pbGainEVsOne(idxParty, defeatedBattler)
    return if ChallengeModes.on?(:HARDCORE_MODE)
    hardcore_pbGainEVsOne(idxParty, defeatedBattler)
  end
end

[:HPUP, :PROTEIN, :IRON, :CALCIUM, :ZINC, :CARBOS,
 :HEALTHFEATHER, :MUSCLEFEATHER, :RESISTFEATHER,
 :GENIUSFEATHER, :CLEVERFEATHER, :SWIFTFEATHER,
 :HEALTHWING, :MUSCLEWING, :RESISTWING,
 :GENIUSWING, :CLEVERWING, :SWIFTWING,
 :POMEGBERRY, :KELPSYBERRY, :QUALOTBERRY,
 :HONDEWBERRY, :GREPABERRY, :TAMATOBERRY].each do |item_id|
  original_handler = ItemHandlers::UseOnPokemon[item_id]
  next if !original_handler
  ItemHandlers::UseOnPokemon.add(item_id, proc { |item, qty, pkmn, scene|
    if ChallengeModes.on?(:HARDCORE_MODE)
      scene.pbDisplay(_INTL("Hardcore Mode prevents changing EVs!"))
      next false
    end
    next original_handler.call(item, qty, pkmn, scene)
  })
end

class Pokemon
  alias hardcore_calc_stats calc_stats unless method_defined?(:hardcore_calc_stats)

  def calc_stats(*args)
    if ChallengeModes.on?(:HARDCORE_MODE)
      GameData::Stat.each_main do |s|
        @iv[s.id] = 31
        @ev[s.id] = 0
      end
    end
    hardcore_calc_stats(*args)
  end
end

alias __hardcore__pbLoadTrainer pbLoadTrainer unless defined?(__hardcore__pbLoadTrainer)
def pbLoadTrainer(tr_type, tr_name, tr_version = 0)
  trainer = __hardcore__pbLoadTrainer(tr_type, tr_name, tr_version)
  return nil if !trainer

  if ChallengeModes.on?(:HARDCORE_MODE)
    trainer.party.each do |pkmn|

      GameData::Stat.each_main do |s|
        pkmn.iv[s.id] = 31
      end

      GameData::Stat.each_main do |s|
        pkmn.ev[s.id] = 0
      end

      pkmn.calc_stats
    end
  end

  return trainer
end

module ChallengeModes
  class << self
    alias hardcore_begin_challenge begin_challenge
  end

  def self.begin_challenge
    return false if !hardcore_begin_challenge

    if on?(:HARDCORE_MODE)
      pbEachPokemon { |pkmn, _| pkmn.calc_stats }
      pbMessage(_INTL("Hardcore Mode activated!"))
      pbMessage(_INTL("All Pokémon will have perfect IVs (31) and EVs are completely disabled."))
      pbMessage(_INTL("This creates a fair and balanced competitive environment!"))
    end
    return true
  end
end
