extends Control

var active := false
var elapsed := 0.0
var blast_center := Vector2.ZERO
var cycle_duration := 2.0
var blast_offsets := [Vector2(-18, -7), Vector2(14, -10), Vector2(-5, 8), Vector2(19, 9), Vector2(0, -20), Vector2(4, 2)]

func begin_at_world_position(world_position: Vector2) -> void:
	blast_center = get_viewport().get_canvas_transform() * world_position
	elapsed = 0.0
	active = true
	show()
	queue_redraw()

func _process(delta: float) -> void:
	if active:
		elapsed += delta
		queue_redraw()

func _draw() -> void:
	if not active:
		return
	for i in range(blast_offsets.size()):
		var age := fposmod(elapsed - i * 0.22, cycle_duration)
		if age < 0.38:
			_draw_burst(blast_center + blast_offsets[i], age)
	if elapsed >= 1.8:
		var center := size * 0.5
		draw_rect(Rect2(center + Vector2(-145, -36), Vector2(290, 78)), Color("38251d"))
		draw_rect(Rect2(center + Vector2(-142, -33), Vector2(284, 72)), Color("9d4430"))
		draw_string(ThemeDB.fallback_font, center + Vector2(-90, -2), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		draw_string(ThemeDB.fallback_font, center + Vector2(-128, 34), "PRESS R TO RESTART", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _draw_burst(center: Vector2, age: float) -> void:
	var step := int(age / 0.08)
	var extent := 5 + step * 4
	draw_rect(Rect2(center.x - extent, center.y - 3, extent * 2, 6), Color("71351f"))
	draw_rect(Rect2(center.x - 3, center.y - extent, 6, extent * 2), Color("71351f"))
	draw_rect(Rect2(center.x - extent + 2, center.y - 2, (extent - 2) * 2, 4), Color("ef542f"))
	draw_rect(Rect2(center.x - 2, center.y - extent + 2, 4, (extent - 2) * 2), Color("ef542f"))
	draw_rect(Rect2(center.x - 3, center.y - 3, 6, 6), Color("ffc34a"))
	draw_rect(Rect2(center.x - 1, center.y - 1, 2, 2), Color("fff0aa"))
