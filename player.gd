extends Node2D

@onready var ground: TileMapLayer = $"../Ground"
@onready var game_manager: Variant = $"../GameManager"
@onready var sprite: Sprite2D = $Sprite2D
const TILE_SIZE: int = 32
const MOVE_INTERVAL: float = 0.15
const MISSILE_SCENE = preload("res://missile.tscn")

var move_timer: float = 0.0
var facing_direction := Vector2.RIGHT

func _ready() -> void:
	sprite.hide()
	queue_redraw()

# Called every frame. 'delta' is the elapsed time since the previous frame.
# 60 FPS  → delta ≈ 1 / 60 ≈ 0.0167초
# 120 FPS → delta ≈ 1 / 120 ≈ 0.0083초
func _process(delta: float) -> void:
	if game_manager.game_over or game_manager.game_won:
		return
	if Input.is_action_just_pressed("radial_shot"):
		# missile.tscn을 실제 게임 안에 하나 생성
		var missile = MISSILE_SCENE.instantiate()
		# 생성된 Missile을 Player 위치에 놓음
		missile.global_position = global_position
		missile.direction = Vector2.DOWN
		missile.level = game_manager.missile_level
		# Player와 같은 부모인 Main 아래에 Missile을 실제로 추가
		get_parent().add_child(missile)
		game_manager.play_missile_launch_sound()

	move_timer -= delta
	if move_timer > 0:
		return
		
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction = Vector2.LEFT
		
	# 입력이 아무것도 없을 때
	if direction == Vector2.ZERO:
		return
	if direction.x != 0.0:
		facing_direction = direction

	var next_position = position + direction * TILE_SIZE
	
	if can_move_to(next_position):
		position = next_position
		
	move_timer = MOVE_INTERVAL

func can_move_to(next_position: Vector2) -> bool:
	var map_position = ground.local_to_map(next_position)
	return game_manager.map_bounds.has_point(map_position) and ground.get_cell_source_id(map_position) == -1

func _draw() -> void:
	var rotation_angle := facing_direction.angle()
	draw_set_transform(Vector2.ZERO, rotation_angle, Vector2.ONE)
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
	draw_line(Vector2(5, -3), Vector2(10, -9), ink, 6.0)
	draw_line(Vector2(5, -3), Vector2(10, -9), bright, 3.0)
	draw_line(Vector2(10, -9), Vector2(13, -4), ink, 5.0)
	draw_line(Vector2(10, -9), Vector2(13, -4), yellow, 2.0)
	draw_rect(Rect2(10, -3, 7, 8), ink)
	draw_rect(Rect2(11, -2, 5, 4), yellow)
	draw_rect(Rect2(13, 2, 3, 2), bright)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
