extends Node2D

@onready var ground: TileMapLayer = $"../Ground"
@onready var game_manager: Variant = $"../GameManager"
@onready var sprite: Sprite2D = $Sprite2D
const BALANCE = preload("res://game_balance.gd")
const TILE_SIZE: int = 32
const WORK_ANIMATION_DURATION := 0.16

var move_timer: float = 0.0
var work_animation_timer := 0.0
var facing_direction := Vector2.RIGHT

func _ready() -> void:
	sprite.hide()
	queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
# 60 FPS  → delta ≈ 1 / 60 ≈ 0.0167초
# 120 FPS → delta ≈ 1 / 120 ≈ 0.0083초
func _process(delta: float) -> void:
	if game_manager.game_over or game_manager.game_won or game_manager.shop_open:
		return
	if work_animation_timer > 0.0:
		work_animation_timer = maxf(0.0, work_animation_timer - delta)
		queue_redraw()
	if Input.is_action_just_pressed("work"):
		_perform_work()

	move_timer -= delta
	if move_timer > 0:
		return
		
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction = Vector2.UP
	elif Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction = Vector2.DOWN
		
	# 입력이 아무것도 없을 때
	if direction == Vector2.ZERO:
		return
	facing_direction = direction
	queue_redraw()

	var next_position = position + direction * TILE_SIZE
	
	if can_move_to(next_position):
		position = next_position
		game_manager.queue_redraw()
		
	move_timer = BALANCE.PLAYER_MOVE_INTERVAL

func _perform_work() -> void:
	var target_world_position := global_position + facing_direction * TILE_SIZE
	var target_cell := ground.local_to_map(ground.to_local(target_world_position))
	if game_manager.dig_dirt(target_cell):
		work_animation_timer = WORK_ANIMATION_DURATION
		queue_redraw()

func can_move_to(next_position: Vector2) -> bool:
	var map_position = ground.local_to_map(next_position)
	return game_manager.map_bounds.has_point(map_position) and ground.get_cell_source_id(map_position) == -1 and not game_manager.ore_cells.has(map_position)

func _draw() -> void:
	var visual_scale := 0.88
	var rotation_angle := facing_direction.angle()
	var facing_scale := Vector2(visual_scale, visual_scale)
	var arm_push := 0.0
	if work_animation_timer > 0.0:
		var work_phase := 1.0 - work_animation_timer / WORK_ANIMATION_DURATION
		arm_push = float(roundi(sin(work_phase * PI) * 4.0))
	if facing_direction == Vector2.LEFT:
		# Mirror horizontally so the crawler tracks stay beneath the excavator.
		rotation_angle = 0.0
		facing_scale.x = -visual_scale
	# Center the asymmetric silhouette in its grid cell after rotation or mirroring.
	var transformed_center := (Vector2(1.5, 1.5) * facing_scale).rotated(rotation_angle)
	draw_set_transform(-transformed_center, rotation_angle, facing_scale)
	var ink := Color("38251d")
	var yellow := Color("f2b632")
	var bright := Color("ffe06a")
	var glass := Color("55c6d4")

	# Continuous tracks and their chunky tread marks.
	draw_rect(Rect2(-14, 5, 28, 10), ink)
	draw_rect(Rect2(-12, 6, 24, 8), Color("56504a"))
	for x in range(-10, 11, 5):
		draw_rect(Rect2(x, 7, 2, 6), Color("b4a18a"))

	# Engine housing and driver's cab.
	draw_rect(Rect2(-9, -1, 19, 9), ink)
	draw_rect(Rect2(-8, 0, 17, 7), yellow)
	draw_rect(Rect2(-9, -10, 13, 12), ink)
	draw_rect(Rect2(-8, -9, 11, 10), bright)
	draw_rect(Rect2(-6, -7, 7, 5), Color("22526a"))
	draw_rect(Rect2(-5, -6, 4, 3), glass)
	draw_rect(Rect2(-1, -2, 2, 3), ink)

	# Boom, stick, and bucket form a readable excavator profile.
	draw_line(Vector2(5, -3), Vector2(10 + arm_push, -9), ink, 6.0)
	draw_line(Vector2(5, -3), Vector2(10 + arm_push, -9), bright, 3.0)
	draw_line(Vector2(10 + arm_push, -9), Vector2(13 + arm_push, -4), ink, 5.0)
	draw_line(Vector2(10 + arm_push, -9), Vector2(13 + arm_push, -4), yellow, 2.0)
	draw_rect(Rect2(10 + arm_push, -3, 7, 8), ink)
	draw_rect(Rect2(11 + arm_push, -2, 5, 4), yellow)
	draw_rect(Rect2(13 + arm_push, 2, 3, 2), bright)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
