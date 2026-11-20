extends RefCounted

# Central runtime tuning values. Adjust these instead of scattering balance
# numbers across gameplay scripts.
const PLAYER_MOVE_INTERVAL := 0.15
const EXCAVATOR_MAX_HEALTH := 3
const HOUSE_MAX_HEALTH := 10
const PLAYER_CONTACT_DAMAGE := 1
const ENEMY_CONTACT_DAMAGE := 1
const STARTING_CARRY_CAPACITY := 50
const DIRT_WEIGHT := 1
const DIRT_SELL_VALUE := 1
const DIRT_DURABILITY := 2
const EXCAVATOR_STARTING_DIG_DURABILITY := 100
const DIRT_DIG_DURABILITY_COST := 1
const EXCAVATOR_STARTING_DIG_POWER := 1.0
const EXCAVATION_POWER_PER_UPGRADE := 0.2
const EXCAVATION_POWER_MAX_LEVEL := 5
const STAGE_ONE_RESOURCE_RATIOS := {"dirt": 70, "coal": 15, "copper": 10, "iron": 5}
const STAGE_ONE_ORE_TYPES := ["coal", "copper", "iron"]
const ORE_HARDNESS := {"coal": 3, "copper": 4, "iron": 8}
const ORE_DURABILITY_COST := {"coal": 2, "copper": 4, "iron": 8}
const ORE_WEIGHT := {"coal": 2, "copper": 4, "iron": 8}
const ORE_SELL_VALUE := {"coal": 2, "copper": 4, "iron": 8}
const SURFACE_CLEAR_ROWS := 2
const HOUSE_OFFSET_TILES := -2
const SHOP_OFFSET_TILES := 2
const SURFACE_BUILDING_Y_OFFSET := 24.0
const SHOP_INTERACTION_DISTANCE := 48.0

const ENEMY_SPAWN_CHANCE := 0.60
const ENEMY_SAFE_DEPTH := 4
const ENEMY_TIER_ONE_ROLL_MAX := 0.50
const ENEMY_TIER_TWO_ROLL_MAX := 0.80
const ENEMIES_PER_WARNING_BLOCK := 1
const ENEMY_HEALTH_MULTIPLIER := 2
const ENEMY_MOVE_INTERVAL := 0.38
const ENEMY_RANDOM_MOVE_CHANCE := 0.28
const ENEMY_PLAYER_CONTACT_DISTANCE := 32.0
const ENEMY_DIRT_DAMAGE := 1
const HOUSE_SIEGE_DAMAGE := 1
const HOUSE_SIEGE_INTERVAL := 3.0

const HOUSE_TURRET_LEVEL_TWO_INTERVAL := 10.0
const HOUSE_TURRET_LEVEL_THREE_INTERVAL := 5.0
