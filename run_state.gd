extends Node

const BALANCE = preload("res://game_balance.gd")

# Kept outside the scene so carried dirt survives a retry reload.
var carried_dirt := 0
var carried_ores := {"coal": 0, "copper": 0, "iron": 0}
var excavation_power_level := 0
var money := 0

func get_resource_count(resource_type: String) -> int:
	if resource_type == "dirt":
		return carried_dirt
	return int(carried_ores.get(resource_type, 0))

func get_resource_price(resource_type: String) -> int:
	if resource_type == "dirt":
		return BALANCE.DIRT_SELL_VALUE
	return int(BALANCE.ORE_SELL_VALUE.get(resource_type, 0))

func get_cargo_sale_value() -> int:
	var total := carried_dirt * BALANCE.DIRT_SELL_VALUE
	for ore_type in carried_ores:
		total += int(carried_ores[ore_type]) * int(BALANCE.ORE_SELL_VALUE.get(ore_type, 0))
	return total

func sell_resource(resource_type: String, amount: int) -> int:
	var available := get_resource_count(resource_type)
	var unit_price := get_resource_price(resource_type)
	if amount <= 0 or amount > available or unit_price <= 0:
		return 0
	if resource_type == "dirt":
		carried_dirt -= amount
	else:
		carried_ores[resource_type] = available - amount
	var earned := amount * unit_price
	money += earned
	return earned

func sell_all_cargo() -> int:
	var earned := get_cargo_sale_value()
	if earned <= 0:
		return 0
	money += earned
	carried_dirt = 0
	for ore_type in carried_ores:
		carried_ores[ore_type] = 0
	return earned
