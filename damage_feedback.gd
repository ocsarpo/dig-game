extends Control

const DURATION := 0.28
const SHAKE_OFFSETS := [
	Vector2(4, -2), Vector2(-3, 2), Vector2(2, 3),
	Vector2(-2, -2), Vector2(1, 1), Vector2(-1, 0),
]

var target: Node2D
var base_position := Vector2.ZERO
var elapsed := DURATION

func play(scene_root: Node2D) -> void:
	if target != null and is_instance_valid(target):
		target.position = base_position
	target = scene_root
	base_position = target.position
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if elapsed >= DURATION:
		return
	elapsed = minf(elapsed + delta, DURATION)
	if target == null or not is_instance_valid(target):
		elapsed = DURATION
		return
	if elapsed >= DURATION:
		target.position = base_position
	else:
		var step := mini(int(elapsed / 0.045), SHAKE_OFFSETS.size() - 1)
		var strength := 1.0 - elapsed / DURATION
		target.position = base_position + (SHAKE_OFFSETS[step] * strength).round()
	queue_redraw()

func _draw() -> void:
	if elapsed < DURATION:
		var strength := 1.0 - elapsed / DURATION
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.08, 0.06, 0.30 * strength))
