extends Node2D

var kind := "missile"
var age := 0.0
var lifetime := 0.0

func setup(pickup_kind: String) -> void:
	kind = pickup_kind
	if kind == "bomb": add_to_group("bombs")
	elif kind != "flash": add_to_group("pickups")
	else: lifetime = 0.16

func _process(delta: float) -> void:
	if kind == "flash":
		lifetime -= delta
		if lifetime <= 0.0: queue_free()
		queue_redraw()
	else:
		age += delta
		queue_redraw()

func _draw() -> void:
	if kind == "missile":
		draw_rect(Rect2(-8, -8, 16, 16), Color("71351f"))
		draw_rect(Rect2(-5, -5, 10, 10), Color("ffc34a"))
		draw_rect(Rect2(-2, -2, 5, 5), Color("fff0aa"))
	elif kind == "defense":
		draw_rect(Rect2(-8, -8, 16, 16), Color("273d70"))
		draw_rect(Rect2(-5, -5, 10, 10), Color("70b8e8"))
		draw_rect(Rect2(-2, -2, 4, 4), Color("e8f8ff"))
	elif kind == "bomb":
		draw_rect(Rect2(-10, -10, 20, 20), Color("71351f"))
		draw_rect(Rect2(-7, -7, 14, 14), Color("b83d28"))
		draw_rect(Rect2(3, -11, 5, 5), Color("ffc34a"))
	elif kind == "heart":
		draw_rect(Rect2(-7, -6, 6, 6), Color("661e2b"))
		draw_rect(Rect2(1, -6, 6, 6), Color("661e2b"))
		draw_rect(Rect2(-6, -5, 12, 7), Color("ef4053"))
		draw_rect(Rect2(-4, 2, 8, 4), Color("ef4053"))
		draw_rect(Rect2(-2, 6, 4, 3), Color("ef4053"))
		draw_rect(Rect2(-4, -4, 3, 2), Color("ffd6d8"))
	else:
		var radius := maxf(1.0, 12.0 * lifetime / 0.16)
		draw_rect(Rect2(-radius, -radius, radius * 2, radius * 2), Color("ffc34a"))
