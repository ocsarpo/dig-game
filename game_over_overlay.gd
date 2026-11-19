extends Control

signal choice_selected(choice: String)

var active := false
var mode := "hidden"
var elapsed := 0.0
var blast_center := Vector2.ZERO
var cycle_duration := 2.0
var message := ""
var blast_offsets := [Vector2(-18, -7), Vector2(14, -10), Vector2(-5, 8), Vector2(19, 9), Vector2(0, -20), Vector2(4, 2)]

func begin_at_world_position(world_position: Vector2) -> void:
	blast_center = get_viewport().get_canvas_transform() * world_position
	elapsed = 0.0
	active = true
	mode = "failure"
	show()
	queue_redraw()

func begin_player_fire_at_world_position(world_position: Vector2) -> void:
	blast_center = get_viewport().get_canvas_transform() * world_position
	elapsed = 0.0
	active = true
	mode = "player_fire"
	show()
	queue_redraw()

func show_round_clear() -> void:
	active = true
	mode = "clear"
	show()
	queue_redraw()

func show_pending(message_text: String) -> void:
	message = message_text
	mode = "pending"
	queue_redraw()

func _process(delta: float) -> void:
	if active and (mode == "failure" or mode == "player_fire"):
		elapsed += delta
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if mode != "clear" or not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var center := size * 0.5
	if Rect2(center + Vector2(-180, 4), Vector2(160, 42)).has_point(event.position):
		choice_selected.emit("upgrade")
		accept_event()
	elif Rect2(center + Vector2(20, 4), Vector2(160, 42)).has_point(event.position):
		choice_selected.emit("next_round")
		accept_event()

func _draw() -> void:
	if not active:
		return
	if mode == "failure":
		for i in range(blast_offsets.size()):
			var age := fposmod(elapsed - i * 0.22, cycle_duration)
			if age < 0.38:
				_draw_burst(blast_center + blast_offsets[i], age)
		if elapsed >= 1.8:
			var center := size * 0.5
			_draw_panel(center)
			draw_string(ThemeDB.fallback_font, center + Vector2(-99, -2), "ROUND FAILED", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
			draw_string(ThemeDB.fallback_font, center + Vector2(-144, 34), "PRESS R TO RETRY THIS ROUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	elif mode == "player_fire":
		_draw_player_fire(blast_center)
		if elapsed >= 1.8:
			var center := size * 0.5
			_draw_panel(center)
			draw_string(ThemeDB.fallback_font, center + Vector2(-99, -2), "ROUND FAILED", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
			draw_string(ThemeDB.fallback_font, center + Vector2(-144, 34), "PRESS R TO RETRY THIS ROUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	elif mode == "clear":
		var center := size * 0.5
		_draw_panel(center)
		draw_string(ThemeDB.fallback_font, center + Vector2(-106, -24), "ROUND CLEARED", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		draw_rect(Rect2(center + Vector2(-180, 4), Vector2(160, 42)), Color("70412e"))
		draw_rect(Rect2(center + Vector2(20, 4), Vector2(160, 42)), Color("70412e"))
		draw_string(ThemeDB.fallback_font, center + Vector2(-141, 32), "강화", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		draw_string(ThemeDB.fallback_font, center + Vector2(45, 32), "다음 라운드", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		draw_string(ThemeDB.fallback_font, center + Vector2(-106, 68), "CLICK AN OPTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f3d9ad"))
	elif mode == "pending":
		var center := size * 0.5
		_draw_panel(center)
		draw_string(ThemeDB.fallback_font, center + Vector2(-140, 2), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
		draw_string(ThemeDB.fallback_font, center + Vector2(-92, 35), "PRESS ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f3d9ad"))

func _draw_panel(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-200, -58), Vector2(400, 132)), Color("38251d"))
	draw_rect(Rect2(center + Vector2(-197, -55), Vector2(394, 126)), Color("9d4430"))

func _draw_burst(center: Vector2, age: float) -> void:
	var step := int(age / 0.08)
	var extent := 5 + step * 4
	draw_rect(Rect2(center.x - extent, center.y - 3, extent * 2, 6), Color("71351f"))
	draw_rect(Rect2(center.x - 3, center.y - extent, 6, extent * 2), Color("71351f"))
	draw_rect(Rect2(center.x - extent + 2, center.y - 2, (extent - 2) * 2, 4), Color("ef542f"))
	draw_rect(Rect2(center.x - 2, center.y - extent + 2, 4, (extent - 2) * 2), Color("ef542f"))
	draw_rect(Rect2(center.x - 3, center.y - 3, 6, 6), Color("ffc34a"))
	draw_rect(Rect2(center.x - 1, center.y - 1, 2, 2), Color("fff0aa"))

func _draw_player_fire(center: Vector2) -> void:
	var flicker := int(elapsed * 10.0) % 3
	draw_rect(Rect2(center + Vector2(-12, 4), Vector2(24, 12)), Color("71351f"))
	draw_rect(Rect2(center + Vector2(-11, -5 - flicker), Vector2(7, 14 + flicker)), Color("ef542f"))
	draw_rect(Rect2(center + Vector2(-3, -12 + flicker), Vector2(7, 21 - flicker)), Color("ff8d32"))
	draw_rect(Rect2(center + Vector2(5, -7 - flicker), Vector2(7, 16 + flicker)), Color("ef542f"))
	draw_rect(Rect2(center + Vector2(-7, -5), Vector2(4, 10)), Color("ffc34a"))
	draw_rect(Rect2(center + Vector2(-1, -8), Vector2(4, 13)), Color("fff0aa"))
	draw_rect(Rect2(center + Vector2(7, -4), Vector2(3, 9)), Color("ffc34a"))
