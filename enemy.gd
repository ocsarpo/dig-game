extends Node2D

var hit_points := 1
var player: Node2D
var ground: TileMapLayer
var manager
var step_timer := 0.0
var move_interval := 0.38
var rng := RandomNumberGenerator.new()
var siege_timer := 3.0
var touching_player := false

func setup(hp: int, target: Node2D, map: TileMapLayer, game_manager: Node2D, seed_value: int) -> void:
	hit_points = hp * 2
	player = target
	ground = map
	manager = game_manager
	rng.seed = seed_value
	add_to_group("enemies")

func _process(delta: float) -> void:
	if manager == null or manager.game_over or manager.game_won:
		return
	# Treat a vertically adjacent tile as contact; the pixel-art silhouettes nearly touch at this spacing.
	var is_touching_player := global_position.distance_to(player.global_position) <= 32.0
	if is_touching_player and not touching_player:
		touching_player = true
		manager.damage_excavator(1)
		take_hit(1)
		if manager.game_over or hit_points <= 0:
			return
	elif not is_touching_player:
		touching_player = false

	var current := ground.local_to_map(ground.to_local(global_position))
	var top_row: int = manager.map_bounds.position.y
	var defense_row := top_row + 1
	if current.y <= defense_row:
		siege_timer -= delta
		if siege_timer <= 0.0:
			manager.damage_house(1)
			siege_timer = 3.0
		return
	step_timer -= delta
	if step_timer > 0.0:
		return
	step_timer = move_interval
	var target := Vector2i(current.x, top_row)
	var choices: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	choices.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (current + a).distance_to(target) < (current + b).distance_to(target)
	)
	var step: Vector2i = choices[0] if rng.randf() > 0.28 else choices[rng.randi_range(0, choices.size() - 1)]
	var next_cell := current + step
	if next_cell.y < defense_row:
		next_cell = Vector2i(next_cell.x, defense_row)
	if manager.map_bounds.has_point(next_cell):
		global_position = ground.to_global(ground.map_to_local(next_cell))
		manager.damage_dirt(next_cell)
		if next_cell.y <= defense_row:
			siege_timer = 3.0
	queue_redraw()

func take_hit(damage: int = 1) -> void:
	hit_points -= maxi(1, damage)
	if hit_points <= 0:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var body_color := Color("f3f1e8") if hit_points <= 2 else Color("d92732")
	var ink := Color("271727")
	var highlight := Color("fff0aa")
	# Bright cream rim separates the monster from the brown dirt tiles.
	draw_rect(Rect2(-11, -9, 22, 19), ink)
	draw_rect(Rect2(-10, -11, 20, 19), highlight)
	# Horns and feet give the enemy a distinct silhouette at small sizes.
	draw_rect(Rect2(-10, -14, 5, 5), ink)
	draw_rect(Rect2(-9, -13, 3, 4), body_color)
	draw_rect(Rect2(5, -14, 5, 5), ink)
	draw_rect(Rect2(6, -13, 3, 4), body_color)
	draw_rect(Rect2(-10, 7, 6, 5), ink)
	draw_rect(Rect2(4, 7, 6, 5), ink)
	draw_rect(Rect2(-8, -9, 16, 14), body_color)
	if hit_points > 4:
		var rainbow := [Color("ef3b45"), Color("ff8d32"), Color("ffe24a"), Color("4fc96b"), Color("38bfe3"), Color("5968e8"), Color("bd55db")]
		for i in range(rainbow.size()):
			draw_rect(Rect2(-7 + i * 2, -8, 2, 12), rainbow[i])
	# Chunky highlight makes the body readable over textured ground.
	draw_rect(Rect2(-7, -8, 3, 2), Color("ffffff") if hit_points <= 2 else Color("ff6870"))
	# Large pale eyes and dark pupils remain visible when the game is zoomed out.
	draw_rect(Rect2(-5, -3, 4, 5), highlight)
	draw_rect(Rect2(2, -3, 4, 5), highlight)
	draw_rect(Rect2(-4, -2, 2, 3), ink)
	draw_rect(Rect2(3, -2, 2, 3), ink)
	# Health pips sit above the head: one pip per remaining hit.
	for i in range(hit_points):
		draw_rect(Rect2(-hit_points * 2 + i * 4, -19, 3, 4), highlight)
