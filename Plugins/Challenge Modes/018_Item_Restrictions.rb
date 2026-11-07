
module ChallengeModes
  x_items = [:XATTACK, :XATTACK2, :XATTACK3, :XATTACK6,
             :XDEFENSE, :XDEFENSE2, :XDEFENSE3, :XDEFENSE6,
             :XSPATK, :XSPATK2, :XSPATK3, :XSPATK6,
             :XSPDEF, :XSPDEF2, :XSPDEF3, :XSPDEF6,
             :XSPEED, :XSPEED2, :XSPEED3, :XSPEED6,
             :XACCURACY, :XACCURACY2, :XACCURACY3, :XACCURACY6,
             :DIREHIT, :DIREHIT2, :DIREHIT3, :GUARDSPEC]
  ITEM_RESTRICTIONS_CONFIG[:banned_items] = ITEM_RESTRICTIONS_CONFIG[:banned_x_items] ? x_items : []
  ITEM_RESTRICTIONS_CONFIG[:limited_items] = [:REVIVE, :MAXREVIVE, :FULLRESTORE]
  ITEM_RESTRICTIONS_CONFIG[:item_limits] = {
    :REVIVE => ITEM_RESTRICTIONS_CONFIG[:max_revives_per_battle],
    :MAXREVIVE => ITEM_RESTRICTIONS_CONFIG[:max_revives_per_battle],
    :FULLRESTORE => ITEM_RESTRICTIONS_CONFIG[:max_full_restores_per_battle]
  }

  @battle_item_usage ||= {}

  def self.item_restrictions?
    return on?(:ITEM_RESTRICTIONS)
  end

  def self.reset_battle_items
    @battle_item_usage = {}
  end

  def self.get_item_usage(item_id)
    @battle_item_usage ||= {}
    return @battle_item_usage[item_id] || 0
  end

  def self.increment_item_usage(item_id)
    @battle_item_usage ||= {}
    @battle_item_usage[item_id] ||= 0
    @battle_item_usage[item_id] += 1
  end

  def self.get_limited_item_usage(item_id)
    return get_item_usage(:REVIVE) + get_item_usage(:MAXREVIVE) if [:REVIVE, :MAXREVIVE].include?(item_id)
    get_item_usage(item_id)
  end

  def self.can_use_item?(item_id)
    return true if !item_restrictions?

    item_data = GameData::Item.get(item_id)
    item_symbol = item_data.id

    if ITEM_RESTRICTIONS_CONFIG[:banned_items].include?(item_symbol)
      return false
    end

    if ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item_symbol)
      limit = ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
      usage = get_limited_item_usage(item_symbol)
      return usage < limit
    end

    return true
  end

  def self.remaining_uses(item_id)
    return -1 if !item_restrictions?

    item_data = GameData::Item.get(item_id)
    item_symbol = item_data.id

    return -1 if !ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item_symbol)

    limit = ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
    usage = get_limited_item_usage(item_symbol)
    return [limit - usage, 0].max
  end
end

class Battle
  alias __challengemodes_itemrestrict__pbUseItemOnPokemon pbUseItemOnPokemon unless method_defined?(:__challengemodes_itemrestrict__pbUseItemOnPokemon)

  def pbUseItemOnPokemon(item, idx_party, user_battler)
    result = __challengemodes_itemrestrict__pbUseItemOnPokemon(item, idx_party, user_battler)
    if ChallengeModes.item_restrictions? &&
       ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item) &&
       @choices[user_battler.index][1].nil?
      ChallengeModes.increment_item_usage(item)
    end
    result
  end

  alias __challengemodes_itemrestrict__pbStartBattle pbStartBattle unless method_defined?(:__challengemodes_itemrestrict__pbStartBattle)

  def pbStartBattle
    ChallengeModes.reset_battle_items if ChallengeModes.item_restrictions?
    return __challengemodes_itemrestrict__pbStartBattle
  end
end

(ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:banned_items] +
 ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items]).each do |restricted_item|
  original_handler = ItemHandlers::CanUseInBattle[restricted_item]
  ItemHandlers::CanUseInBattle.add(restricted_item,
    proc { |item, pokemon, battler, move, first_action, battle, scene, show_messages|
      if !ChallengeModes.can_use_item?(item)
        scene.pbDisplay(_INTL("{1} is restricted by Challenge Mode.", GameData::Item.get(item).name)) if show_messages
        next false
      end
      next original_handler.call(item, pokemon, battler, move, first_action,
                                 battle, scene, show_messages) if original_handler
      next true
    })
end

def pbCheckItemUsage
  if !ChallengeModes.item_restrictions?
    pbMessage(_INTL("Item Restrictions is not active."))
    return
  end

  text = "Battle Item Usage:\n"
  used_any = false
  revives_used = ChallengeModes.get_limited_item_usage(:REVIVE)
  if revives_used > 0
    limit = ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:max_revives_per_battle]
    text += "Revives: #{revives_used}/#{limit}\n"
    used_any = true
  end

  ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].each do |item_symbol|
    next if [:REVIVE, :MAXREVIVE].include?(item_symbol)
    usage = ChallengeModes.get_item_usage(item_symbol)
    if usage > 0
      item_name = GameData::Item.get(item_symbol).name
      limit = ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
      text += "#{item_name}: #{usage}/#{limit}\n"
      used_any = true
    end
  end

  if !used_any
    text += "No limited items used yet."
  end

  pbMessage(_INTL(text))
end

if ChallengeModes.running?
  puts "Challenge Modes: Item Restrictions rule loaded"
  puts "  - Banned items: #{ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:banned_items].join(', ')}"
  puts "  - Limited items: #{ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].join(', ')}"
  puts "  - Tracks usage per battle"
end
