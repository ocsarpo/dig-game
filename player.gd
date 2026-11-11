extends Node2D

@onready var ground: TileMapLayer = $"../Ground"
const TILE_SIZE: int = 32
const MOVE_INTERVAL: float = 0.15

var move_timer: float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
# 60 FPS  → delta ≈ 1 / 60 ≈ 0.0167초
# 120 FPS → delta ≈ 1 / 120 ≈ 0.0083초
func _process(delta: float) -> void:
	move_timer -= delta
	if move_timer > 0:
		return
		
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_up"):
		direction = Vector2.UP
		
	# 입력이 아무것도 없을 때
	if direction == Vector2.ZERO:
		return
	
	var next_position = position + direction * TILE_SIZE
	
	if can_move_to(next_position):
		position = next_position
		
	move_timer = MOVE_INTERVAL


func can_move_to(next_position: Vector2) -> bool:
	var map_position = ground.local_to_map(next_position)
	# 현재 사용 중인 타일 영역을 Rect2i로 돌려주는 get_used_rect()
	var used_rect = ground.get_used_rect()
	
	return used_rect.has_point(map_position)
