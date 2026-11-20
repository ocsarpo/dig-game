extends Control

signal sell_requested(resource_type: String, amount: int)
signal sell_all_requested

const RESOURCE_TYPES := ["dirt", "coal", "copper", "iron"]
const RESOURCE_NAMES := ["흙", "석탄", "구리", "철"]

var selected_index := 0
var sale_quantity := 1
var previous_column := 0
var mode := "browse"

func reset_selection() -> void:
	mode = "browse"
	selected_index = 0
	previous_column = 0
	refresh_after_sale()

func handle_key(event: InputEventKey) -> void:
	if mode == "browse":
		match event.keycode:
			KEY_UP:
				if selected_index == 4:
					_select(2 + previous_column)
				elif selected_index >= 2:
					_select(selected_index - 2)
			KEY_DOWN:
				if selected_index < 2:
					_select(selected_index + 2)
				elif selected_index < 4:
					previous_column = selected_index % 2
					_select(4)
			KEY_LEFT:
				if selected_index == 1 or selected_index == 3:
					_select(selected_index - 1)
			KEY_RIGHT:
				if selected_index == 0 or selected_index == 2:
					_select(selected_index + 1)
			KEY_ENTER:
				mode = "confirm_all" if selected_index == 4 else "quantity"
				queue_redraw()
	elif mode == "quantity":
		match event.keycode:
			KEY_LEFT:
				_change_quantity(-1)
			KEY_RIGHT:
				_change_quantity(1)
			KEY_ENTER:
				_request_sale()
				mode = "browse"
				queue_redraw()
			KEY_BACKSPACE:
				mode = "browse"
				queue_redraw()
	elif mode == "confirm_all":
		if event.keycode == KEY_ENTER:
			sell_all_requested.emit()
			mode = "browse"
			queue_redraw()
		elif event.keycode == KEY_BACKSPACE:
			mode = "browse"
			queue_redraw()

func refresh_after_sale() -> void:
	if selected_index < RESOURCE_TYPES.size():
		var available := RunState.get_resource_count(RESOURCE_TYPES[selected_index])
		sale_quantity = mini(sale_quantity, available) if available > 0 else 0
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var center := size * 0.5
	for index in range(RESOURCE_TYPES.size()):
		if _resource_rect(center, index).has_point(event.position):
			_select(index)
			accept_event()
			return
	if mode == "quantity" and Rect2(center + Vector2(8, 22), Vector2(28, 27)).has_point(event.position):
		_change_quantity(-1)
	elif mode == "quantity" and Rect2(center + Vector2(43, 22), Vector2(28, 27)).has_point(event.position):
		_change_quantity(1)
	elif Rect2(center + Vector2(-196, 79), Vector2(392, 27)).has_point(event.position):
		_select(4)
	accept_event()

func _resource_rect(center: Vector2, index: int) -> Rect2:
	var column := index % 2
	var row := int(index / 2)
	return Rect2(center + Vector2(-200 + column * 204, -74 + row * 48), Vector2(194, 43))

func _select(index: int) -> void:
	selected_index = index
	mode = "browse"
	if selected_index < RESOURCE_TYPES.size():
		var available := RunState.get_resource_count(RESOURCE_TYPES[selected_index])
		sale_quantity = 1 if available > 0 else 0
	else:
		sale_quantity = 0
	queue_redraw()

func _change_quantity(amount: int) -> void:
	if mode != "quantity" or selected_index >= RESOURCE_TYPES.size():
		return
	var available := RunState.get_resource_count(RESOURCE_TYPES[selected_index])
	if available <= 0:
		sale_quantity = 0
	else:
		sale_quantity = clampi(sale_quantity + amount, 1, available)
	queue_redraw()

func _request_sale() -> void:
	if selected_index >= RESOURCE_TYPES.size() or sale_quantity <= 0:
		return
	sell_requested.emit(RESOURCE_TYPES[selected_index], sale_quantity)

func _draw() -> void:
	var center := size * 0.5
	var ink := Color("38251d")
	var panel := Color("426f61")
	var light := Color("fff0aa")
	draw_rect(Rect2(center + Vector2(-220, -128), Vector2(440, 256)), ink)
	draw_rect(Rect2(center + Vector2(-216, -124), Vector2(432, 248)), panel)
	draw_string(ThemeDB.fallback_font, center + Vector2(-196, -91), "상점 · 자원 판매", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, light)
	for index in range(RESOURCE_TYPES.size()):
		var item_rect := _resource_rect(center, index)
		var selected := index == selected_index
		draw_rect(item_rect, Color("527869") if selected else Color("35594f"))
		draw_rect(item_rect, light if selected else ink, false, 2.0)
		_draw_resource_icon(item_rect.position + Vector2(8, 12), RESOURCE_TYPES[index])
		draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(34, 22), "%s %d개" % [RESOURCE_NAMES[index], RunState.get_resource_count(RESOURCE_TYPES[index])], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		draw_string(ThemeDB.fallback_font, item_rect.position + Vector2(34, 37), "개당 %d원" % RunState.get_resource_price(RESOURCE_TYPES[index]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, light)
	var selected_count := RunState.get_resource_count(RESOURCE_TYPES[selected_index]) if selected_index < RESOURCE_TYPES.size() else 0
	var selected_price := RunState.get_resource_price(RESOURCE_TYPES[selected_index]) if selected_index < RESOURCE_TYPES.size() else 0
	var sale_value := sale_quantity * selected_price
	if mode == "confirm_all":
		sale_value = RunState.get_cargo_sale_value()
		draw_string(ThemeDB.fallback_font, center + Vector2(-196, 43), "보유 자원을 전부 팔까요?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	elif mode == "quantity":
		draw_string(ThemeDB.fallback_font, center + Vector2(-196, 43), "%s 판매 수량 %d / %d" % [RESOURCE_NAMES[selected_index], sale_quantity, selected_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		draw_rect(Rect2(center + Vector2(8, 22), Vector2(28, 27)), ink)
		draw_rect(Rect2(center + Vector2(43, 22), Vector2(28, 27)), ink)
		draw_string(ThemeDB.fallback_font, center + Vector2(17, 42), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, light)
		draw_string(ThemeDB.fallback_font, center + Vector2(50, 42), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, light)
	else:
		draw_string(ThemeDB.fallback_font, center + Vector2(-196, 43), "방향키로 항목을 고르고 Enter로 선택", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		if selected_index == RESOURCE_TYPES.size():
			sale_value = RunState.get_cargo_sale_value()
	draw_string(ThemeDB.fallback_font, center + Vector2(-196, 69), "판매액 %d원   보유 돈 %d원" % [sale_value, RunState.money], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, light)
	draw_rect(Rect2(center + Vector2(-200, 75), Vector2(400, 2)), ink)
	var sell_all_rect := Rect2(center + Vector2(-196, 79), Vector2(392, 27))
	draw_rect(sell_all_rect, Color("704d31"))
	draw_rect(sell_all_rect, light if selected_index == 4 else ink, false, 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-45, 99), "전체 판매", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var help_text := "방향키 이동 · Enter 선택 · Esc 닫기"
	if mode == "quantity":
		help_text = "← → 수량 · Enter 판매 · Backspace 취소 · Esc 닫기"
	elif mode == "confirm_all":
		help_text = "Enter 한 번 더 누르면 전체 판매 · Backspace 취소"
	draw_string(ThemeDB.fallback_font, center + Vector2(-196, 120), help_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _draw_resource_icon(origin: Vector2, resource_type: String) -> void:
	var ink := Color("38251d")
	draw_rect(Rect2(origin, Vector2(18, 18)), ink)
	if resource_type == "dirt":
		draw_rect(Rect2(origin + Vector2(2, 2), Vector2(14, 14)), Color("9a5f39"))
		draw_rect(Rect2(origin + Vector2(4, 5), Vector2(3, 2)), Color("c0824b"))
		draw_rect(Rect2(origin + Vector2(11, 3), Vector2(2, 2)), Color("d09a60"))
		draw_rect(Rect2(origin + Vector2(9, 11), Vector2(3, 2)), Color("704127"))
		return
	var colors: Dictionary = {
		"coal": [Color("282b30"), Color("777b80"), Color("b2b4b2")],
		"copper": [Color("4a261c"), Color("bf642f"), Color("edaa57")],
		"iron": [Color("343941"), Color("8795a2"), Color("c7d1d8")]
	}
	var palette: Array = colors[resource_type]
	draw_rect(Rect2(origin + Vector2(3, 6), Vector2(12, 9)), palette[0])
	draw_rect(Rect2(origin + Vector2(5, 3), Vector2(8, 12)), palette[0])
	draw_rect(Rect2(origin + Vector2(5, 6), Vector2(8, 6)), palette[1])
	draw_rect(Rect2(origin + Vector2(7, 4), Vector2(3, 3)), palette[2])
	draw_rect(Rect2(origin + Vector2(10, 10), Vector2(3, 2)), palette[2])
