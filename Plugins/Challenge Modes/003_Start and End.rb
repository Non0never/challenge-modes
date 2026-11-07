if defined?(UI::Load)
class UI::Load
  alias __challenge__pbStartLoadScreen main unless method_defined?(:__challenge__pbStartLoadScreen)
  def main(*args)
    ret = __challenge__pbStartLoadScreen(*args)
    ChallengeModes.toggle(true) if ChallengeModes.running?
    return ret
  end
end
elsif defined?(PokemonLoadScreen)
class PokemonLoadScreen
  alias __challenge__pbStartLoadScreen pbStartLoadScreen unless method_defined?(:__challenge__pbStartLoadScreen)
  def pbStartLoadScreen(*args)
    ret = __challenge__pbStartLoadScreen(*args)
    ChallengeModes.toggle(true) if ChallengeModes.running?
    return ret
  end
end
end

alias __challenge__pbTrainerName pbTrainerName unless defined?(__challenge__pbTrainerName)
def pbTrainerName(*args)
  ret = __challenge__pbTrainerName(*args)
  ChallengeModes.reset
  $PokemonGlobal.challenge_state = {}
  return ret
end

class PokemonBag
  alias __challenge__add add unless method_defined?(:__challenge__add)
  def add(*args)
    item_data = GameData::Item.try_get(args[0])
    watched_ball = $PokemonGlobal && $PokemonGlobal.challenge_qued && item_data&.is_poke_ball?
    previous_quantity = quantity(item_data.id) if watched_ball
    ret = __challenge__add(*args)
    return ret if !watched_ball || !$PokemonGlobal.challenge_qued
    return ret if quantity(item_data.id) <= previous_quantity
    pbMessage(_INTL("Your Challenge has begun! Good Luck!")) if ChallengeModes.begin_challenge
    return ret
  end
end

alias __challenge__pbStartOver pbStartOver unless defined?(__challenge__pbStartOver)
def pbStartOver(*args)
  return __challenge__pbStartOver(*args) if !ChallengeModes.on?
  resume = false
  pbEachPokemon do |pkmn, _|
    next if pkmn.fainted? || pkmn.egg?
    resume = true
    break
  end
  if resume && !ChallengeModes.on?(:GAME_OVER_WHITEOUT)
    loop do
      pbMessage("\\w[]\\wm\\c[8]\\l[3]" +
        _INTL("All your Pokémon have fainted. But you still have Pokémon in your PC which you can continue the challenge with."))
      pbFadeOutIn(99999) do
        if defined?(UI::PokemonStorage)
          UI::PokemonStorage.new($PokemonStorage, mode: :organize).main
        else
          PokemonStorageScreen.new(PokemonStorageScene.new, $PokemonStorage).pbStartScreen(0)
        end
      end
      break if $player.able_pokemon_count != 0
    end
  else
    pbMessage("\\w[]\\wm\\c[8]\\l[3]" +
      _INTL("All your Pokémon have fainted. You have lost the challenge! All challenge modifiers will now be turned off."))
    ChallengeModes.set_loss
  end
  return __challenge__pbStartOver(*args)
end
