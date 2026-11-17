extends Node2D

var speed: float = 300.0
var direction: Vector2 = Vector2.DOWN
var level := 1
var house_shot := false
var target: Node2D
var turn_speed := 3.0

var life_time: float = 5.0
var exploded: bool = false
var explosion_time: float = 0.0

@onready var ground: TileMapLayer = get_tree().current_scene.get_node_or_null("Ground")
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	rotation = direction.angle()
	sprite.hide()
	queue_redraw()

func _process(delta: float) -> void:
	if exploded:
		explosion_time -= delta
		if explosion_time <= 0.0:
			queue_free()
		return

	if house_shot and is_instance_valid(target):
		var desired := (target.global_position - global_position).normalized()
		var turn := direction.angle_to(desired)
		direction = direction.rotated(clampf(turn, -turn_speed * delta, turn_speed * delta)).normalized()
		rotation = direction.angle()
	position += direction * speed * delta

	if ground != null:
		var cell := ground.local_to_map(ground.to_local(global_position))
		var manager: Variant = get_tree().current_scene.get_node_or_null("GameManager")
		if not house_shot and manager != null and manager.is_bomb(cell):
			manager.detonate_bomb(cell)
			_explode(false)
			return
		if not house_shot and manager != null and ground.get_cell_source_id(cell) != -1:
			manager.fire_hit(cell, level)
			_explode()
			return
		if not house_shot and manager != null:
			for pickup in get_tree().get_nodes_in_group("pickups"):
				if pickup.global_position.distance_to(global_position) < 14.0:
					manager.hit_pickup(pickup)
					_explode()
					return
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position) < 14.0:
				if manager != null:
					manager.play_enemy_hit_sound()
				enemy.take_hit(level)
				_explode()
				return

	life_time -= delta

	if life_time <= 0:
		queue_free()

func _explode(play_sound: bool = true) -> void:
	exploded = true
	explosion_time = 0.12
	sprite.hide()
	if play_sound:
		var manager = get_tree().current_scene.get_node_or_null("GameManager")
		if manager != null:
			manager.play_missile_impact_sound()
	queue_redraw()

func _draw() -> void:
	if not exploded:
		_draw_missile()
		return

	# Simple blocky flash, drawn directly in the 32 px tile scale.
	var flash_color := Color("fff0aa") if level == 1 else (Color("ffc34a") if level == 2 else Color("ef872c"))
	draw_rect(Rect2(-4, -12, 8, 8), flash_color)
	draw_rect(Rect2(-12, -4, 8, 8), Color("ffc34a"))
	draw_rect(Rect2(-4, -4, 8, 8), flash_color)
	draw_rect(Rect2(4, -4, 8, 8), Color("ef872c"))
	draw_rect(Rect2(-4, 4, 8, 8), Color("ffc34a"))

func _draw_missile() -> void:
	var ink := Color("39251f")
	draw_rect(Rect2(-8, -4, 14, 8), ink)
	draw_rect(Rect2(-6, -6, 5, 2), ink)
	draw_rect(Rect2(-6, 4, 5, 2), ink)
	draw_rect(Rect2(-11, -2, 4, 4), Color("ef542f"))
	draw_rect(Rect2(6, -2, 3, 4), ink)
	draw_rect(Rect2(8, -1, 2, 2), ink)
	if level == 1:
		draw_rect(Rect2(-7, -3, 12, 6), Color("f3f1e8"))
		draw_rect(Rect2(-5, -5, 4, 2), Color("c9c9c4"))
		draw_rect(Rect2(-5, 3, 4, 2), Color("c9c9c4"))
		draw_rect(Rect2(5, -1, 3, 2), Color("ffffff"))
	elif level == 2:
		draw_rect(Rect2(-7, -3, 12, 6), Color("d92732"))
		draw_rect(Rect2(-5, -5, 4, 2), Color("9e1d2a"))
		draw_rect(Rect2(-5, 3, 4, 2), Color("9e1d2a"))
		draw_rect(Rect2(-7, -2, 8, 2), Color("ff6870"))
		draw_rect(Rect2(5, -1, 3, 2), Color("fff0aa"))
	else:
		var rainbow := [Color("ef3b45"), Color("ff8d32"), Color("ffe24a"), Color("4fc96b"), Color("38bfe3"), Color("5968e8"), Color("bd55db")]
		for i in range(6):
			draw_rect(Rect2(-7 + i * 2, -3, 2, 6), rainbow[i])
		draw_rect(Rect2(-5, -5, 4, 2), Color("38bfe3"))
		draw_rect(Rect2(-5, 3, 4, 2), Color("bd55db"))
		draw_rect(Rect2(5, -1, 3, 2), Color("fff0aa"))
