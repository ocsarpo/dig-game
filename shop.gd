extends Node2D

func _draw() -> void:
	var ink := Color("38251d")
	var wall := Color("67a994")
	var roof := Color("267d79")
	var light := Color("fff0aa")
	draw_rect(Rect2(-30, -7, 60, 30), ink)
	draw_rect(Rect2(-28, -5, 56, 26), wall)
	draw_rect(Rect2(-34, -19, 68, 13), ink)
	draw_rect(Rect2(-31, -17, 62, 9), roof)
	for stripe_x in range(-27, 28, 12):
		draw_rect(Rect2(stripe_x, -15, 6, 7), light)
	draw_rect(Rect2(-23, 0, 25, 15), ink)
	draw_rect(Rect2(-21, 2, 21, 11), Color("bfe8ce"))
	draw_rect(Rect2(-21, 9, 21, 2), roof)
	draw_rect(Rect2(9, 1, 15, 22), ink)
	draw_rect(Rect2(11, 3, 11, 18), Color("8c5c39"))
	draw_rect(Rect2(18, 12, 2, 2), light)
	draw_rect(Rect2(-31, 19, 62, 4), ink)
	draw_rect(Rect2(-20, -31, 40, 11), ink)
	draw_rect(Rect2(-18, -29, 36, 7), roof)
	draw_string(ThemeDB.fallback_font, Vector2(-12, -22), "상점", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, light)
