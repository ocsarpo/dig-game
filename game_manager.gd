extends Node2D

const ENEMY_SCRIPT = preload("res://enemy.gd")
const MISSILE_LAUNCH_SFX = preload("res://assets/audio/missile_launch.wav")
const MISSILE_IMPACT_SFX = preload("res://assets/audio/missile_impact.wav")
const ENEMY_HIT_SFX = preload("res://assets/audio/enemy_hit.wav")
const HOUSE_ATTACK_SFX = preload("res://assets/audio/house_attack.wav")
const HOUSE_EXPLOSION_SFX = preload("res://assets/audio/house_explosion.wav")
var ground: TileMapLayer
var player: Node2D

var half_damaged: Dictionary = {}
var missile_level := 1
var game_over := false
var game_won := false
var house_lives := 10
const EXCAVATOR_MAX_HEALTH := 3
var excavator_health := EXCAVATOR_MAX_HEALTH
var rng := RandomNumberGenerator.new()
var map_bounds := Rect2i()
var house: Node2D
var game_over_overlay: Control

func _ready() -> void:
	rng.randomize()
	var main_scene := get_tree().current_scene
	ground = main_scene.find_child("Ground", true, false) as TileMapLayer
	player = main_scene.find_child("Player", true, false) as Node2D
	house = main_scene.find_child("House", true, false) as Node2D
	game_over_overlay = main_scene.find_child("Overlay", true, false) as Control
	if ground == null or player == null or house == null or game_over_overlay == null:
		push_error("GameManager needs Ground, Player, House, and Overlay nodes in the current scene.")
		set_process(false)
		return
	game_over_overlay.choice_selected.connect(_on_round_choice)
	map_bounds = ground.get_used_rect()
	var top_row := map_bounds.position.y
	var center_x := map_bounds.position.x + int(map_bounds.size.x / 2)
	for x in range(map_bounds.position.x, map_bounds.end.x):
		ground.erase_cell(Vector2i(x, top_row))
	var home_cell := Vector2i(center_x, top_row)
	player.global_position = ground.to_global(ground.map_to_local(home_cell))
	house.global_position = player.global_position
	# Keep the spawn tile open so the player never starts trapped in dirt.
	ground.erase_cell(ground.local_to_map(ground.to_local(player.global_position)))

func damage_dirt(cell: Vector2i, damage: int = 1) -> bool:
	if ground.get_cell_source_id(cell) == -1:
		if half_damaged.has(cell):
			half_damaged.erase(cell)
			queue_redraw()
		return false
	if damage >= 2 or half_damaged.has(cell):
		ground.erase_cell(cell)
		half_damaged.erase(cell)
		queue_redraw()
		_spawn_dirt_result(ground.to_global(ground.map_to_local(cell)))
		_check_win()
		return true
	half_damaged[cell] = true
	queue_redraw()
	return false

func fire_hit(cell: Vector2i, level: int) -> void:
	if ground.get_cell_source_id(cell) == -1:
		return
	if level == 1:
		damage_dirt(cell, 2)
	elif level == 2:
		damage_dirt(cell, 2)
		for offset in _neighbors():
			damage_dirt(cell + offset)
	else:
		for y in range(-1, 2):
			for x in range(-1, 2):
				damage_dirt(cell + Vector2i(x, y), 2)

func _process(_delta: float) -> void:
	if game_over:
		return
	if game_won:
		return
	_check_win()

func damage_house(amount: int = 1) -> void:
	if game_over or game_won:
		return
	house_lives = maxi(0, house_lives - amount)
	play_sfx(HOUSE_ATTACK_SFX)
	queue_redraw()
	if house_lives <= 0:
		start_game_over()

func damage_excavator(amount: int = 1) -> void:
	if game_over or game_won:
		return
	excavator_health = maxi(0, excavator_health - amount)
	queue_redraw()
	if excavator_health <= 0:
		game_over = true
		game_over_overlay.begin_player_fire_at_world_position(player.global_position)
		_freeze_round_entities()

func start_game_over() -> void:
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
	if game_over and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	elif game_won and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 or event.keycode == KEY_U:
			_on_round_choice("upgrade")
		elif event.keycode == KEY_2 or event.keycode == KEY_N:
			_on_round_choice("next_round")
		elif event.keycode == KEY_ENTER and game_over_overlay.mode == "pending":
			game_over_overlay.show_round_clear()

func _on_round_choice(choice: String) -> void:
	if choice == "upgrade":
		game_over_overlay.show_pending("SHOP IS THE NEXT TASK")
	else:
		game_over_overlay.show_pending("NEXT ROUND IS THE NEXT TASK")

func _spawn_dirt_result(world_position: Vector2) -> void:
	if rng.randf() >= 0.60:
		return
	var cell := ground.local_to_map(ground.to_local(world_position))
	var player_cell := ground.local_to_map(ground.to_local(player.global_position))
	if cell.y - player_cell.y <= 4:
		return
	var hp_roll := rng.randf()
	var hp := 1 if hp_roll < 0.50 else (2 if hp_roll < 0.80 else 3)
	var count := rng.randi_range(1, 3)
	for i in range(count):
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
	if not game_over and ground.get_used_cells().is_empty():
		game_won = true
		game_over_overlay.show_round_clear()
		_freeze_round_entities()

func _neighbors() -> Array[Vector2i]:
	return [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]

func _draw() -> void:
	for cell in half_damaged:
		var center := to_local(ground.to_global(ground.map_to_local(cell)))
		# Pixel-like cracks distinguish a half-damaged dirt block.
		draw_line(center + Vector2(-5, -5), center + Vector2(0, 0), Color("21150f"), 2.0)
		draw_line(center + Vector2(0, 0), center + Vector2(5, -3), Color("21150f"), 2.0)
		draw_line(center + Vector2(0, 0), center + Vector2(2, 6), Color("21150f"), 2.0)
	if not game_over and not game_won:
		draw_string(ThemeDB.fallback_font, Vector2(12, 24), "HOUSE %d / 10" % house_lives, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff0aa"))
		draw_string(ThemeDB.fallback_font, Vector2(12, 46), "EXCAVATOR %d / %d" % [excavator_health, EXCAVATOR_MAX_HEALTH], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe0a0"))
		var mining_mode: bool = player.get("mining_mode")
		var mode_label := "MINERAL MODE" if mining_mode else "DIG MODE"
		var mode_color := Color("7de3e8") if mining_mode else Color("ffd36b")
		draw_string(ThemeDB.fallback_font, Vector2(12, 66), mode_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, mode_color)
