extends Node2D

func _draw() -> void:
	var ink := Color("38251d")
	var wall := Color("d99243")
	var roof := Color("9d4430")
	var light := Color("f5c565")
	var glass := Color("72c9d4")
	# Two-row surface house with a clear roof, walls, windows, and entrance.
	draw_rect(Rect2(-31, -7, 62, 30), ink)
	draw_rect(Rect2(-29, -5, 58, 26), wall)
	draw_rect(Rect2(-36, -19, 72, 12), ink)
	draw_rect(Rect2(-33, -17, 66, 8), roof)
	draw_rect(Rect2(-25, -27, 8, 10), ink)
	draw_rect(Rect2(-23, -25, 4, 8), roof)
	draw_rect(Rect2(-24, 0, 12, 11), ink)
	draw_rect(Rect2(-22, 2, 8, 7), glass)
	draw_rect(Rect2(12, 0, 12, 11), ink)
	draw_rect(Rect2(14, 2, 8, 7), glass)
	draw_rect(Rect2(-6, 4, 12, 19), ink)
	draw_rect(Rect2(-4, 6, 8, 15), Color("67412b"))
	draw_rect(Rect2(1, 13, 2, 2), light)
	draw_rect(Rect2(-32, 19, 64, 4), ink)
	# The roof launcher stays visible above the enlarged silhouette.
	draw_rect(Rect2(-8, -31, 16, 11), ink)
	draw_rect(Rect2(-6, -29, 12, 7), Color("657d84"))
	draw_rect(Rect2(-2, -21, 4, 5), Color("b8d4d1"))
