extends Node2D

func _draw() -> void:
	var ink := Color("38251d")
	var wall := Color("d99243")
	var roof := Color("9d4430")
	var light := Color("f5c565")
	var glass := Color("72c9d4")
	# Small house silhouette with a roof-mounted launcher.
	draw_rect(Rect2(-23, -5, 46, 23), ink)
	draw_rect(Rect2(-21, -4, 42, 20), wall)
	draw_rect(Rect2(-26, -12, 52, 10), ink)
	draw_rect(Rect2(-23, -11, 46, 7), roof)
	draw_rect(Rect2(-17, -8, 5, 3), light)
	draw_rect(Rect2(12, -8, 5, 3), light)
	draw_rect(Rect2(-5, 5, 10, 11), ink)
	draw_rect(Rect2(-3, 7, 6, 9), Color("67412b"))
	# Launcher sits above the roof and points down toward approaching enemies.
	draw_rect(Rect2(-7, -17, 14, 7), ink)
	draw_rect(Rect2(-5, -16, 10, 4), Color("657d84"))
	draw_rect(Rect2(-2, -12, 4, 8), Color("b8d4d1"))
