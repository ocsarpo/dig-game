extends Node2D

const ENEMY_SCRIPT = preload("res://enemy.gd")
const BALANCE = preload("res://game_balance.gd")
const MISSILE_LAUNCH_SFX = preload("res://assets/audio/missile_launch.wav")
const MISSILE_IMPACT_SFX = preload("res://assets/audio/missile_impact.wav")
const ENEMY_HIT_SFX = preload("res://assets/audio/enemy_hit.wav")
const HOUSE_ATTACK_SFX = preload("res://assets/audio/house_attack.wav")
const HOUSE_EXPLOSION_SFX = preload("res://assets/audio/house_explosion.wav")
const WORK_HIT_EFFECT_DURATION := 0.16
const DURABILITY_BLOCKED_DURATION := 0.65
var ground: TileMapLayer
var player: Node2D

var half_damaged: Dictionary = {}
var enemy_warning_cells: Dictionary = {}
var player_dig_progress: Dictionary = {}
var ore_cells: Dictionary = {}
var ore_dig_progress: Dictionary = {}
var work_hit_timer := 0.0
var work_hit_cell := Vector2i.ZERO
var work_hit_color := Color("b87442")
var durability_blocked_timer := 0.0
var durability_blocked_cell := Vector2i.ZERO
var durability_blocked_required := 0
var excavator_dig_durability := BALANCE.EXCAVATOR_STARTING_DIG_DURABILITY
var excavator_dig_power := BALANCE.EXCAVATOR_STARTING_DIG_POWER
var missile_level := 1
var game_over := false
var game_won := false
var house_lives := BALANCE.HOUSE_MAX_HEALTH
const EXCAVATOR_MAX_HEALTH := BALANCE.EXCAVATOR_MAX_HEALTH
var excavator_health := EXCAVATOR_MAX_HEALTH
var carried_weight := 0
var carry_capacity := BALANCE.STARTING_CARRY_CAPACITY
var rng := RandomNumberGenerator.new()
var map_bounds := Rect2i()
var house: Node2D
var shop: Node2D
var shop_menu: Variant
var shop_open := false
var game_over_overlay: Control
var damage_feedback: Control

func _ready() -> void:
	rng.randomize()
	var main_scene := get_tree().current_scene
	ground = main_scene.find_child("Ground", true, false) as TileMapLayer
	player = main_scene.find_child("Player", true, false) as Node2D
	house = main_scene.find_child("House", true, false) as Node2D
	shop = main_scene.find_child("Shop", true, false) as Node2D
	shop_menu = main_scene.find_child("ShopMenu", true, false)
	game_over_overlay = main_scene.find_child("Overlay", true, false) as Control
	damage_feedback = main_scene.find_child("DamageFeedback", true, false) as Control
	if ground == null or player == null or house == null or shop == null or shop_menu == null or game_over_overlay == null or damage_feedback == null:
		push_error("GameManager needs Ground, Player, House, Shop, ShopMenu, Overlay, and DamageFeedback nodes in the current scene.")
		set_process(false)
		return
	game_over_overlay.choice_selected.connect(_on_round_choice)
	shop_menu.sell_requested.connect(_on_shop_sell_requested)
	shop_menu.sell_all_requested.connect(_on_shop_sell_all_requested)
	map_bounds = ground.get_used_rect()
	_recalculate_carried_weight()
	RunState.excavation_power_level = clampi(RunState.excavation_power_level, 0, BALANCE.EXCAVATION_POWER_MAX_LEVEL)
	excavator_dig_power = BALANCE.EXCAVATOR_STARTING_DIG_POWER + RunState.excavation_power_level * BALANCE.EXCAVATION_POWER_PER_UPGRADE
	excavator_dig_durability = BALANCE.EXCAVATOR_STARTING_DIG_DURABILITY
	var top_row := map_bounds.position.y
	var center_x := map_bounds.position.x + int(map_bounds.size.x / 2)
	for y in range(top_row, mini(top_row + BALANCE.SURFACE_CLEAR_ROWS, map_bounds.end.y)):
		for x in range(map_bounds.position.x, map_bounds.end.x):
			ground.erase_cell(Vector2i(x, y))
	var home_cell := Vector2i(center_x, top_row)
	player.global_position = ground.to_global(ground.map_to_local(home_cell))
	var building_y := BALANCE.SURFACE_BUILDING_Y_OFFSET
	house.global_position = player.global_position + Vector2(BALANCE.HOUSE_OFFSET_TILES * ground.tile_set.tile_size.x, building_y)
	shop.global_position = player.global_position + Vector2(BALANCE.SHOP_OFFSET_TILES * ground.tile_set.tile_size.x, building_y)
	# Keep the spawn tile open so the player never starts trapped in dirt.
	ground.erase_cell(ground.local_to_map(ground.to_local(player.global_position)))
	_populate_stage_one_ores()

func damage_dirt(cell: Vector2i, damage: int = BALANCE.ENEMY_DIRT_DAMAGE) -> bool:
	if ground.get_cell_source_id(cell) == -1:
		if ore_cells.has(cell):
			return false
		if half_damaged.has(cell) or enemy_warning_cells.has(cell):
			half_damaged.erase(cell)
			enemy_warning_cells.erase(cell)
			player_dig_progress.erase(cell)
			queue_redraw()
		return false
	if damage >= BALANCE.DIRT_DURABILITY or half_damaged.has(cell):
		ground.erase_cell(cell)
		half_damaged.erase(cell)
		enemy_warning_cells.erase(cell)
		player_dig_progress.erase(cell)
		queue_redraw()
		_check_win()
		return true
	half_damaged[cell] = true
	queue_redraw()
	return false

func dig_dirt(cell: Vector2i) -> bool:
	if game_over or game_won:
		return false
	if not map_bounds.has_point(cell):
		return false
	if ground.get_cell_source_id(cell) == -1:
		if ore_cells.has(cell):
			return _mine_ore(cell)
		return false
	if excavator_dig_durability < BALANCE.DIRT_DIG_DURABILITY_COST:
		_show_durability_blocked(cell, BALANCE.DIRT_DIG_DURABILITY_COST)
		return false
	if carried_weight + BALANCE.DIRT_WEIGHT > carry_capacity:
		return false
	excavator_dig_durability = maxi(0, excavator_dig_durability - BALANCE.DIRT_DIG_DURABILITY_COST)
	var contains_enemy := enemy_warning_cells.has(cell)
	_trigger_work_feedback(cell, "dirt")
	if not contains_enemy:
		if not player_dig_progress.has(cell) and _should_mark_enemy_dirt(cell):
			enemy_warning_cells[cell] = true
			queue_redraw()
			return true
		var damage_so_far := float(player_dig_progress.get(cell, 0.0))
		damage_so_far += excavator_dig_power
		if damage_so_far + 0.001 < BALANCE.DIRT_DURABILITY:
			player_dig_progress[cell] = damage_so_far
			half_damaged[cell] = true
			queue_redraw()
			return true
	var world_position := ground.to_global(ground.map_to_local(cell))
	ground.erase_cell(cell)
	half_damaged.erase(cell)
	enemy_warning_cells.erase(cell)
	player_dig_progress.erase(cell)
	RunState.carried_dirt += 1
	_recalculate_carried_weight()
	queue_redraw()
	if contains_enemy:
		_spawn_enemies(world_position)
	_check_win()
	return true

func _mine_ore(cell: Vector2i) -> bool:
	var ore_type: String = ore_cells[cell]
	var durability_cost: int = BALANCE.ORE_DURABILITY_COST[ore_type]
	var ore_weight: int = BALANCE.ORE_WEIGHT[ore_type]
	if excavator_dig_durability < durability_cost:
		_show_durability_blocked(cell, durability_cost)
		return false
	if carried_weight + ore_weight > carry_capacity:
		return false
	excavator_dig_durability -= durability_cost
	_trigger_work_feedback(cell, ore_type)
	var damage_so_far := float(ore_dig_progress.get(cell, 0.0)) + excavator_dig_power
	if damage_so_far + 0.001 < float(BALANCE.ORE_HARDNESS[ore_type]):
		ore_dig_progress[cell] = damage_so_far
		half_damaged[cell] = true
		queue_redraw()
		return true
	ore_cells.erase(cell)
	ore_dig_progress.erase(cell)
	half_damaged.erase(cell)
	RunState.carried_ores[ore_type] = int(RunState.carried_ores.get(ore_type, 0)) + 1
	_recalculate_carried_weight()
	queue_redraw()
	_check_win()
	return true

func _recalculate_carried_weight() -> void:
	carried_weight = RunState.carried_dirt * BALANCE.DIRT_WEIGHT
	for ore_type in RunState.carried_ores:
		carried_weight += int(RunState.carried_ores[ore_type]) * int(BALANCE.ORE_WEIGHT.get(ore_type, 0))

func _trigger_work_feedback(cell: Vector2i, material: String) -> void:
	durability_blocked_timer = 0.0
	work_hit_cell = cell
	work_hit_timer = WORK_HIT_EFFECT_DURATION
	match material:
		"coal":
			work_hit_color = Color("c1c6c9")
		"copper":
			work_hit_color = Color("f5ad56")
		"iron":
			work_hit_color = Color("d4e0e6")
		_:
			work_hit_color = Color("d89760")
	queue_redraw()

func _show_durability_blocked(cell: Vector2i, required: int) -> void:
	durability_blocked_cell = cell
	durability_blocked_required = required
	durability_blocked_timer = DURABILITY_BLOCKED_DURATION
	queue_redraw()

func _populate_stage_one_ores() -> void:
	var available_cells := ground.get_used_cells()
	for i in range(available_cells.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, i)
		var cell := available_cells[i]
		available_cells[i] = available_cells[swap_index]
		available_cells[swap_index] = cell
	var coal_count := floori(available_cells.size() * float(BALANCE.STAGE_ONE_RESOURCE_RATIOS["coal"]) / 100.0)
	var copper_count := floori(available_cells.size() * float(BALANCE.STAGE_ONE_RESOURCE_RATIOS["copper"]) / 100.0)
	var iron_count := floori(available_cells.size() * float(BALANCE.STAGE_ONE_RESOURCE_RATIOS["iron"]) / 100.0)
	var ore_counts := {"coal": coal_count, "copper": copper_count, "iron": iron_count}
	var cell_index := 0
	for ore_type in BALANCE.STAGE_ONE_ORE_TYPES:
		for _count in range(int(ore_counts[ore_type])):
			ore_cells[available_cells[cell_index]] = ore_type
			cell_index += 1

func upgrade_excavation_power() -> bool:
	if RunState.excavation_power_level >= BALANCE.EXCAVATION_POWER_MAX_LEVEL:
		return false
	RunState.excavation_power_level += 1
	excavator_dig_power = BALANCE.EXCAVATOR_STARTING_DIG_POWER + RunState.excavation_power_level * BALANCE.EXCAVATION_POWER_PER_UPGRADE
	queue_redraw()
	return true

func fire_hit(cell: Vector2i, level: int) -> void:
	if ground.get_cell_source_id(cell) == -1:
		return
	if level == 1:
		damage_dirt(cell, BALANCE.DIRT_DURABILITY)
	elif level == 2:
		damage_dirt(cell, BALANCE.DIRT_DURABILITY)
		for offset in _neighbors():
			damage_dirt(cell + offset)
	else:
		for y in range(-1, 2):
			for x in range(-1, 2):
				damage_dirt(cell + Vector2i(x, y), BALANCE.DIRT_DURABILITY)

func _process(delta: float) -> void:
	if work_hit_timer > 0.0:
		work_hit_timer = maxf(0.0, work_hit_timer - delta)
		queue_redraw()
	if durability_blocked_timer > 0.0:
		durability_blocked_timer = maxf(0.0, durability_blocked_timer - delta)
		queue_redraw()
	if game_over:
		return
	if game_won:
		return
	_check_win()

func damage_house(amount: int) -> void:
	if game_over or game_won:
		return
	house_lives = maxi(0, house_lives - amount)
	play_sfx(HOUSE_ATTACK_SFX)
	queue_redraw()
	if house_lives <= 0:
		start_game_over()

func damage_excavator(amount: int) -> void:
	if game_over or game_won or amount <= 0:
		return
	excavator_health = maxi(0, excavator_health - amount)
	damage_feedback.call("play", get_tree().current_scene)
	queue_redraw()
	if excavator_health <= 0:
		_close_shop()
		game_over = true
		game_over_overlay.begin_player_fire_at_world_position(player.global_position)
		_freeze_round_entities()

func start_game_over() -> void:
	_close_shop()
	game_over = true
	play_sfx(HOUSE_EXPLOSION_SFX, 0.0)
	game_over_overlay.begin_at_world_position(house.global_position)
	_freeze_round_entities()

func _freeze_round_entities() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_process(false)
	for missile in get_tree().get_nodes_in_group("missiles"):
		missile.set_process(false)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if shop_open:
		if event.keycode == KEY_ESCAPE:
			_close_shop()
		else:
			shop_menu.handle_key(event)
		get_viewport().set_input_as_handled()
		return
	if game_over and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	elif game_won:
		if event.keycode == KEY_1 or event.keycode == KEY_U:
			_on_round_choice("upgrade")
		elif event.keycode == KEY_2 or event.keycode == KEY_N:
			_on_round_choice("next_round")
		elif event.keycode == KEY_ENTER and game_over_overlay.mode == "pending":
			game_over_overlay.show_round_clear()
	elif event.is_action_pressed("interact") and player.global_position.distance_to(shop.global_position) <= BALANCE.SHOP_INTERACTION_DISTANCE:
		_open_shop()
		get_viewport().set_input_as_handled()

func _open_shop() -> void:
	shop_open = true
	shop_menu.reset_selection()
	if game_won:
		game_over_overlay.hide()
	shop_menu.show()
	shop_menu.queue_redraw()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_process(false)
	for missile in get_tree().get_nodes_in_group("missiles"):
		missile.set_process(false)
	queue_redraw()

func _on_shop_sell_requested(resource_type: String, amount: int) -> void:
	if not shop_open or RunState.sell_resource(resource_type, amount) <= 0:
		return
	_recalculate_carried_weight()
	shop_menu.refresh_after_sale()
	queue_redraw()

func _on_shop_sell_all_requested() -> void:
	if not shop_open or RunState.sell_all_cargo() <= 0:
		return
	_recalculate_carried_weight()
	shop_menu.reset_selection()
	queue_redraw()

func _close_shop() -> void:
	if not shop_open:
		return
	shop_open = false
	shop_menu.hide()
	if game_won:
		game_over_overlay.show()
	if not game_over and not game_won:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.set_process(true)
		for missile in get_tree().get_nodes_in_group("missiles"):
			missile.set_process(true)
	queue_redraw()

func _on_round_choice(choice: String) -> void:
	if choice == "upgrade":
		_open_shop()
	else:
		game_over_overlay.show_pending("다음 라운드는 준비 중")

func _should_mark_enemy_dirt(cell: Vector2i) -> bool:
	if ore_cells.has(cell):
		return false
	var surface_row: int = map_bounds.position.y
	if cell.y - surface_row <= BALANCE.ENEMY_SAFE_DEPTH:
		return false
	return rng.randf() < BALANCE.ENEMY_SPAWN_CHANCE

func _spawn_enemies(world_position: Vector2) -> void:
	var hp_roll := rng.randf()
	var hp := 1 if hp_roll < BALANCE.ENEMY_TIER_ONE_ROLL_MAX else (2 if hp_roll < BALANCE.ENEMY_TIER_TWO_ROLL_MAX else 3)
	for i in range(BALANCE.ENEMIES_PER_WARNING_BLOCK):
		var enemy := Node2D.new()
		enemy.set_script(ENEMY_SCRIPT)
		add_child(enemy)
		enemy.global_position = world_position + Vector2(rng.randi_range(-12, 12), rng.randi_range(-12, 12))
		enemy.setup(hp, player, ground, self, rng.randi())

func play_missile_launch_sound() -> void:
	play_sfx(MISSILE_LAUNCH_SFX)

func play_enemy_hit_sound() -> void:
	play_sfx(ENEMY_HIT_SFX)

func play_missile_impact_sound() -> void:
	play_sfx(MISSILE_IMPACT_SFX)

func play_sfx(sound: AudioStream, volume_db: float = -4.0) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = sound
	audio.volume_db = volume_db
	audio.finished.connect(audio.queue_free)
	add_child(audio)
	audio.play()

func _check_win() -> void:
	if not game_over and ground.get_used_cells().is_empty() and ore_cells.is_empty():
		game_won = true
		game_over_overlay.show_round_clear()
		_freeze_round_entities()

func _neighbors() -> Array[Vector2i]:
	return [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]

func _draw() -> void:
	for cell in ore_cells:
		if ground.get_cell_source_id(cell) == -1:
			var center := to_local(ground.to_global(ground.map_to_local(cell)))
			var ore_type := String(ore_cells[cell])
			if work_hit_timer > 0.0 and cell == work_hit_cell:
				var hit_phase := 1.0 - work_hit_timer / WORK_HIT_EFFECT_DURATION
				center.x += roundf(sin(hit_phase * PI * 5.0) * 2.0 * (1.0 - hit_phase))
			_draw_ore_icon(center, ore_type)
	for cell in half_damaged:
		var center := to_local(ground.to_global(ground.map_to_local(cell)))
		# Pixel-like cracks distinguish a half-damaged dirt block.
		draw_line(center + Vector2(-5, -5), center + Vector2(0, 0), Color("21150f"), 2.0)
		draw_line(center + Vector2(0, 0), center + Vector2(5, -3), Color("21150f"), 2.0)
		draw_line(center + Vector2(0, 0), center + Vector2(2, 6), Color("21150f"), 2.0)
	for cell in enemy_warning_cells:
		var center := to_local(ground.to_global(ground.map_to_local(cell)))
		draw_rect(Rect2(center + Vector2(-7, -8), Vector2(14, 16)), Color("38251d"))
		draw_rect(Rect2(center + Vector2(-5, -6), Vector2(10, 12)), Color("d92732"))
		draw_rect(Rect2(center + Vector2(-1, -4), Vector2(2, 6)), Color("fff0aa"))
		draw_rect(Rect2(center + Vector2(-1, 3), Vector2(2, 2)), Color("fff0aa"))
	if work_hit_timer > 0.0:
		var hit_center := to_local(ground.to_global(ground.map_to_local(work_hit_cell)))
		var hit_phase := 1.0 - work_hit_timer / WORK_HIT_EFFECT_DURATION
		var flash_alpha := (1.0 - hit_phase) * 0.28
		draw_rect(Rect2(hit_center + Vector2(-11, -11), Vector2(22, 22)), Color(1.0, 0.91, 0.68, flash_alpha))
		for chip_index in range(4):
			var side := -1.0 if chip_index % 2 == 0 else 1.0
			var chip_x := side * (3.0 + hit_phase * (5.0 + float(chip_index % 3)))
			var chip_y := -3.0 + hit_phase * (5.0 + float(chip_index / 2) * 3.0)
			var chip_position := hit_center + Vector2(roundf(chip_x), roundf(chip_y))
			draw_rect(Rect2(chip_position, Vector2(2, 2)), work_hit_color)
	if durability_blocked_timer > 0.0:
		var blocked_center := to_local(ground.to_global(ground.map_to_local(durability_blocked_cell)))
		var blocked_color := Color("ff5548")
		draw_rect(Rect2(blocked_center + Vector2(-13, -13), Vector2(26, 26)), blocked_color, false, 2.0)
		draw_rect(Rect2(blocked_center + Vector2(-2, -15), Vector2(4, 3)), blocked_color)
	if not game_over and not game_won:
		draw_string(ThemeDB.fallback_font, Vector2(12, 24), "집 체력 %d / %d" % [house_lives, BALANCE.HOUSE_MAX_HEALTH], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff0aa"))
		draw_string(ThemeDB.fallback_font, Vector2(12, 46), "굴삭기 체력 %d / %d" % [excavator_health, EXCAVATOR_MAX_HEALTH], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe0a0"))
		var cargo_color := Color("ff7057") if carried_weight >= carry_capacity else Color("e6d3ad")
		draw_string(ThemeDB.fallback_font, Vector2(12, 66), "적재 무게 %d / %d" % [carried_weight, carry_capacity], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cargo_color)
		var dig_color := Color("ff5548") if durability_blocked_timer > 0.0 or excavator_dig_durability <= 20 else Color("e6d3ad")
		draw_string(ThemeDB.fallback_font, Vector2(12, 86), "굴착 내구도 %d / %d" % [excavator_dig_durability, BALANCE.EXCAVATOR_STARTING_DIG_DURABILITY], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, dig_color)
		draw_string(ThemeDB.fallback_font, Vector2(12, 106), "굴착력 %.1f" % excavator_dig_power, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe0a0"))
		draw_string(ThemeDB.fallback_font, Vector2(12, 126), "광물  석탄 %d  구리 %d  철 %d" % [RunState.carried_ores["coal"], RunState.carried_ores["copper"], RunState.carried_ores["iron"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e6d3ad"))
		draw_string(ThemeDB.fallback_font, Vector2(12, 146), "돈 %d원" % RunState.money, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff0aa"))
		if durability_blocked_timer > 0.0:
			draw_string(ThemeDB.fallback_font, Vector2(12, 166), "내구도 부족 (필요: %d)" % durability_blocked_required, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ff5548"))
		if not shop_open and player.global_position.distance_to(shop.global_position) <= BALANCE.SHOP_INTERACTION_DISTANCE:
			var shop_position := to_local(shop.global_position)
			draw_string(ThemeDB.fallback_font, shop_position + Vector2(37, -4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff0aa"))

func _draw_ore_icon(center: Vector2, ore_type: String) -> void:
	var colors: Dictionary = {
		"coal": [Color("282b30"), Color("777b80"), Color("b2b4b2")],
		"copper": [Color("4a261c"), Color("bf642f"), Color("edaa57")],
		"iron": [Color("343941"), Color("8795a2"), Color("c7d1d8")]
	}
	var palette: Array = colors[ore_type]
	var outline: Color = palette[0]
	var body: Color = palette[1]
	var highlight: Color = palette[2]
	draw_rect(Rect2(center + Vector2(-9, -5), Vector2(18, 12)), outline)
	draw_rect(Rect2(center + Vector2(-6, -9), Vector2(12, 16)), outline)
	draw_rect(Rect2(center + Vector2(-6, -5), Vector2(12, 8)), body)
	draw_rect(Rect2(center + Vector2(-2, -9), Vector2(4, 4)), highlight)
	draw_rect(Rect2(center + Vector2(2, -1), Vector2(4, 4)), highlight)
