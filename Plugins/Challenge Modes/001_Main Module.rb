
class PokemonGlobalMetadata
  attr_accessor :challenge_monotype_type
  attr_accessor :challenge_randomizer_seed
  attr_accessor :challenge_randomizer_map
  attr_accessor :challenge_previous_battlestyle
  attr_accessor :challenge_previous_givenicknames
  attr_accessor :challenge_previous_level_cap
  attr_accessor :challenge_previous_level_cap_mode
end

module ChallengeModes
  @@started = false

  module_function

  def level_caps_available?
    return defined?(LevelCapsEX)
  end

  def level_cap_active?
    return false unless level_caps_available?
    return on?(:LEVEL_CAP)
  end

  def running?; return $PokemonGlobal && $PokemonGlobal.challenge_started; end

  def on?(rule = nil)
    return false if !(running? && @@started)
    return rule.nil? ? true : rules.include?(rule)
  end

  def toggle(force = nil); @@started = force.nil? ? !@@started : force; end

  def rules
    selected = ($PokemonGlobal && $PokemonGlobal.challenge_rules) || []
    return selected
  end

  def start
    $PokemonGlobal.challenge_rules = select_mode
    return if $PokemonGlobal.challenge_rules.empty?
    $PokemonGlobal.challenge_qued  = true
    $PokemonGlobal.challenge_encs  = {}
    return if !$bag
    GameData::Item.each do |item|
      next if !item.is_poke_ball? || !$bag.has?(item)
      pbMessage(_INTL("Your Challenge has begun! Good Luck!")) if begin_challenge
      return
    end
  end

  def begin_challenge
    if $PokemonGlobal.challenge_rules.include?(:MONOTYPE_MODE) &&
       !$PokemonGlobal.challenge_monotype_type && !select_monotype_type
      reset
      $PokemonGlobal.challenge_rules = []
      return false
    end

    @@started                        = true
    $PokemonGlobal.challenge_started = true
    $PokemonGlobal.challenge_qued    = false
    if $PokemonGlobal.challenge_rules.include?(:FORCE_SET_BATTLES)
      if $PokemonGlobal.challenge_previous_battlestyle.nil?
        $PokemonGlobal.challenge_previous_battlestyle = $PokemonSystem.battlestyle
      end
      $PokemonSystem.battlestyle = 1
    end
    if $PokemonGlobal.challenge_rules.include?(:FORCE_NICKNAME)
      if $PokemonGlobal.challenge_previous_givenicknames.nil?
        $PokemonGlobal.challenge_previous_givenicknames = $PokemonSystem.givenicknames
      end
      $PokemonSystem.givenicknames = 0
    end

    $PokemonGlobal.challenge_randomizer_map ||= {}

    if $PokemonGlobal.challenge_rules.include?(:RANDOMIZER_MODE)
      initialize_randomizer if !$PokemonGlobal.challenge_randomizer_seed
    end

    if $PokemonGlobal.challenge_rules.include?(:LEVEL_CAP) && defined?(LevelCapsEX)
      if $PokemonGlobal.challenge_previous_level_cap.nil?
        $PokemonGlobal.challenge_previous_level_cap = $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE]
        $PokemonGlobal.challenge_previous_level_cap_mode = $game_variables[LevelCapsEX::LEVEL_CAP_MODE_VARIABLE]
      end
      initialize_level_cap
    end
    return true
  end

  def begin_randomizer_early
    return if !$PokemonGlobal&.challenge_rules&.include?(:RANDOMIZER_MODE)
    return if $PokemonGlobal.challenge_randomizer_active

    initialize_randomizer if !$PokemonGlobal.challenge_randomizer_seed
    $PokemonGlobal.challenge_randomizer_active = true
    echoln ">>> Randomizer mode activated early (will work on starters)"
  end

  def reset
    was_running = running?
    @@started                             = false
    return if !$PokemonGlobal
    if $PokemonSystem && !$PokemonGlobal.challenge_previous_battlestyle.nil?
      $PokemonSystem.battlestyle = $PokemonGlobal.challenge_previous_battlestyle
    end
    if $PokemonSystem && !$PokemonGlobal.challenge_previous_givenicknames.nil?
      $PokemonSystem.givenicknames = $PokemonGlobal.challenge_previous_givenicknames
    end
    $PokemonGlobal.challenge_previous_battlestyle = nil
    $PokemonGlobal.challenge_previous_givenicknames = nil
    $PokemonGlobal.challenge_qued         = nil
    $PokemonGlobal.challenge_encs         = nil
    $PokemonGlobal.challenge_started      = nil
    pbEachPokemon do |pkmn, _|
      next if !pkmn.respond_to?(:perma_faint)
      pkmn.perma_faint = false
    end

    if was_running && defined?(LevelCapsEX) && $PokemonGlobal.challenge_rules&.include?(:LEVEL_CAP)
      $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE] = $PokemonGlobal.challenge_previous_level_cap || 0
      $game_variables[LevelCapsEX::LEVEL_CAP_MODE_VARIABLE] = $PokemonGlobal.challenge_previous_level_cap_mode || 0
      echoln ">>> Challenge Mode: Level Cap reset"
    end
    $PokemonGlobal.challenge_previous_level_cap = nil
    $PokemonGlobal.challenge_previous_level_cap_mode = nil

  end

  def set_victory(should_reset = false)
    return if !ChallengeModes.on?
    num = $PokemonGlobal.hallOfFameLastNumber
    num = 0 if num < 0
    $PokemonGlobal.challenge_state[num] = [:VICTORY, ChallengeModes.rules.clone]
    reset if should_reset
  end

  def won?(hall_no = -1)
    if hall_no == -1
      return $PokemonGlobal.challenge_state.values.any? { |v| v.is_a?(Array) && v[0] == :VICTORY }
    else
      return false if !$PokemonGlobal.challenge_state[hall_no].is_a?(Array)
      return $PokemonGlobal.challenge_state[hall_no][0] == :VICTORY
    end
  end

  def set_loss(should_reset = true)
    num = $PokemonGlobal.hallOfFameLastNumber
    num = 0 if num < 0
    return if !ChallengeModes.on? || ChallengeModes.won?(num)
    $PokemonGlobal.challenge_state[num] = [:LOSS, ChallengeModes.rules.clone]
    reset if should_reset
  end

  def lost?(hall_no = -1)
    if hall_no == -1
      return $PokemonGlobal.challenge_state.values.any? { |v| v.is_a?(Array) && v[0] == :LOSS }
    else
      return false if !$PokemonGlobal.challenge_state[hall_no].is_a?(Array)
      return $PokemonGlobal.challenge_state[hall_no][0] == :LOSS
    end
  end

  def set_first_encounter(pkmn, owned_flag = nil)
    return if !ChallengeModes.on?(:ONE_CAPTURE)
    return if $mystery_gift
    sp_data  = GameData::Species.get_species_form(pkmn.species, pkmn.form)
    captured = true
    captured = false if ChallengeModes::ONE_CAPTURE_WHITELIST.any? { |s| pkmn.isSpecies?(s) }
    captured = false if sp_data.has_flag?("OneCaptureWhitelist")
    if ChallengeModes.on?(:DUPS_CLAUSE)
      sp_data.get_family_species.each do |pk|
        captured = false if owned_flag.nil? ? $player.owned?(pk) : owned_flag
      end
    end
    captured = false if ChallengeModes.on?(:SHINY_CLAUSE) && pkmn.shiny?
    return if !captured
    map_id = $game_map.map_id
    $PokemonGlobal.challenge_encs[map_id] = true
    ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS.each do |map_grp|
      next if !map_grp.include?(map_id)
      map_grp.each { |m| $PokemonGlobal.challenge_encs[m] = true }
    end
  end

  def had_first_encounter?(pkmn = nil)
    return false if !ChallengeModes.on?(:ONE_CAPTURE)
    return false if pkmn && pkmn.shiny? && ChallengeModes.on?(:SHINY_CLAUSE)
    if pkmn
      return false if ONE_CAPTURE_WHITELIST.any? { |species| pkmn.isSpecies?(species) }
      species_data = GameData::Species.get_species_form(pkmn.species, pkmn.form)
      return false if species_data.has_flag?("OneCaptureWhitelist")
    end
    return false if $mystery_gift
    map_id = $game_map.map_id
    return true if $PokemonGlobal.challenge_encs[map_id]
    ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS.each do |map_grp|
      next if !map_grp.include?(map_id)
      map_grp.each { |m| return true if $PokemonGlobal.challenge_encs[m] }
    end
    return false
  end

  def select_monotype_type
    type_names = []
    MONOTYPE_TYPES.each { |type| type_names.push(GameData::Type.get(type).name) }
    type_names.push(_INTL("Cancel"))

    selected = pbMessage(_INTL("Choose your Monotype:"), type_names)
    if selected >= 0 && selected < MONOTYPE_TYPES.length
      $PokemonGlobal.challenge_monotype_type = MONOTYPE_TYPES[selected]
      type_name = GameData::Type.get($PokemonGlobal.challenge_monotype_type).name
      pbMessage(_INTL("You have chosen {1}-type Pokémon for your Monotype challenge!", type_name))
    else
      return false
    end
    return true
  end

  def valid_monotype_battle?(pokemon)
    return true if !on?(:MONOTYPE_MODE)
    return false if !$PokemonGlobal.challenge_monotype_type

    chosen_type = $PokemonGlobal.challenge_monotype_type
    species_data = pokemon.is_a?(Pokemon) ? pokemon.species_data : GameData::Species.get(pokemon)

    return species_data.types.include?(chosen_type)
  end

  def valid_monotype_catch?(pokemon)
    return true if !on?(:MONOTYPE_MODE)
    return false if !$PokemonGlobal.challenge_monotype_type

    chosen_type = $PokemonGlobal.challenge_monotype_type
    species_id = pokemon.is_a?(Pokemon) ? pokemon.species : (pokemon.is_a?(Symbol) ? pokemon : GameData::Species.get(pokemon).species)

    return check_monotype_recursive(species_id, chosen_type, [])
  end

  def check_monotype_recursive(species_id, type, checked)
    return false if checked.include?(species_id)
    checked.push(species_id)

    species_data = GameData::Species.get(species_id)
    return true if species_data.types.include?(type)

    species_data.evolutions.each do |evo|

      next_species = evo[0]
      return true if check_monotype_recursive(next_species, type, checked)
    end

    return false
  end

  def initialize_randomizer

    seed = Time.now.to_i + $player.id
    $PokemonGlobal.challenge_randomizer_seed = seed
    $PokemonGlobal.challenge_randomizer_map = {}

  end

  def get_randomized_species(original_species, is_legendary = false, level = 1)
    return original_species if !on?(:RANDOMIZER_MODE)

    key = original_species.to_s + (is_legendary ? "_legendary" : "_normal")

    if $PokemonGlobal.challenge_randomizer_map[key]
      return $PokemonGlobal.challenge_randomizer_map[key]
    end

    possible_species = []
    original_bst = GameData::Species.get(original_species).base_stats.values.sum if RANDOMIZER_SETTINGS[:similar_strength]
    GameData::Species.each do |species|
      next if species.form != 0
      next if species.mega_stone || species.mega_move

      species_is_legendary = species.has_flag?("Legendary") || species.has_flag?("Mythical")
      if RANDOMIZER_SETTINGS[:legendary_separate]
        next if is_legendary != species_is_legendary
      end

      if RANDOMIZER_SETTINGS[:similar_strength]
        species_bst = species.base_stats.values.sum
        next if (species_bst - original_bst).abs > 100
      end

      possible_species.push(species.species)
    end

    seed = $PokemonGlobal.challenge_randomizer_seed + Zlib.crc32(key)
    randomized_species = possible_species.sample(random: Random.new(seed))

    $PokemonGlobal.challenge_randomizer_map[key] = randomized_species

    return randomized_species
  end

  def initialize_level_cap
    return if !defined?(LevelCapsEX)

    mode = select_level_cap_mode
    $game_variables[LevelCapsEX::LEVEL_CAP_MODE_VARIABLE] = mode

    if $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE] <= 0
      $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE] = 15
    end

    mode_name = case mode
      when 1 then "Hard Cap"
      when 2 then "EXP Cap"
      when 3 then "Obedience Cap"
      else "Unknown"
    end

    echoln ">>> Challenge Mode: Level Cap activated (Cap: #{$game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE]}, Mode: #{mode_name})"
  end

  def select_level_cap_mode
    commands = []
    commands.push(_INTL("Hard Cap"))
    commands.push(_INTL("EXP Cap"))
    commands.push(_INTL("Obedience Cap"))

    vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
    infowindow = Window_AdvancedTextPokemon.newWithSize("", 0, Graphics.height - 128, Graphics.width, 128, vp)
    infowindow.setSkin(MessageConfig.pbGetSystemFrame)

    cmdwindow = Window_CommandPokemon.new(commands)
    cmdwindow.viewport = vp
    cmdwindow.y = 64

    titlewindow = Window_UnformattedTextPokemon.newWithSize(
      _INTL("Select Level Cap Mode"), 0, 0, Graphics.width, 64, vp)

    descriptions = [
      _INTL("Your Pokémon cannot level up or gain experience past the level cap. Most restrictive mode."),
      _INTL("Your Pokémon gain reduced EXP (1/10th) when above the level cap. They can still level slowly."),
      _INTL("Your Pokémon will disobey you in battle when above the level cap, similar to traded Pokémon.")
    ]

    pbSetNarrowFont(infowindow.contents)
    infowindow.text = descriptions[0]

    selected_mode = 1
    loop do
      Graphics.update
      Input.update
      old_index = cmdwindow.index
      cmdwindow.update
      infowindow.update
      pbUpdateSceneMap

      if old_index != cmdwindow.index
        infowindow.text = descriptions[cmdwindow.index]
      end

      if Input.trigger?(Input::BACK)

        selected_mode = 1
        break
      elsif Input.trigger?(Input::USE)
        selected_mode = cmdwindow.index + 1
        break
      end
    end

    cmdwindow.dispose
    titlewindow.dispose
    infowindow.dispose
    vp.dispose

    return selected_mode
  end

  def update_level_cap(new_cap)
    return if !ChallengeModes.on?(:LEVEL_CAP)
    return if !defined?(LevelCapsEX)

    $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE] = new_cap
    echoln ">>> Challenge Mode: Level Cap updated to #{new_cap}"

    if LevelCapsEX::LOG_LEVEL_CAP_CHANGES
      pbMessage(_INTL("The level cap has been raised to {1}!", new_cap))
    end
  end
end
