extends RefCounted
class_name PartLibrary

const ACCESSORY_SCARF := 1
const ACCESSORY_SATCHEL := 2
const ACCESSORY_CLIP := 4

const FRONT_HAIR_STYLES := [
	{
		"name": "Blunt",
		"mask": [
			"..######..",
			".########.",
			"##########",
			".##....##.",
			".#......#.",
			".#......#."
		],
		"offset": Vector2i(-5, -3),
		"mirrorable": false
	},
	{
		"name": "Sweep",
		"mask": [
			"..####....",
			".#######..",
			"#########.",
			".#####....",
			".###......",
			"..##......"
		],
		"offset": Vector2i(-5, -3),
		"mirrorable": true
	},
	{
		"name": "Curtain",
		"mask": [
			".##..##...",
			"########..",
			".##..##...",
			".##..##...",
			"..#..#....",
			"..#..#...."
		],
		"offset": Vector2i(-5, -3),
		"mirrorable": false
	},
	{
		"name": "Spiky",
		"mask": [
			"...#.#....",
			".########.",
			"##########",
			".##....##.",
			".#......#.",
			"..#....#.."
		],
		"offset": Vector2i(-5, -4),
		"mirrorable": false
	},
	{
		"name": "Bob",
		"mask": [
			".########.",
			"##########",
			"##########",
			".##....##.",
			".##....##.",
			".##....##."
		],
		"offset": Vector2i(-5, -3),
		"mirrorable": false
	},
	{
		"name": "Widow",
		"mask": [
			"...##.....",
			"..####....",
			".######...",
			"########..",
			".##..##...",
			".#....#..."
		],
		"offset": Vector2i(-5, -4),
		"mirrorable": true
	}
]

const BACK_HAIR_STYLES := [
	{
		"name": "Crop",
		"mask": [
			"..######..",
			".########.",
			"##########",
			".########.",
			"..######..",
			"...####..."
		],
		"offset": Vector2i(-5, -3)
	},
	{
		"name": "Long",
		"mask": [
			"..######..",
			".########.",
			"##########",
			".########.",
			".########.",
			".########.",
			"..######..",
			"..######..",
			"...####..."
		],
		"offset": Vector2i(-5, -3)
	},
	{
		"name": "Ponytail",
		"mask": [
			"..######..",
			".########.",
			"##########",
			".########.",
			"..######..",
			"...####...",
			"...####...",
			"....##....",
			"....##...."
		],
		"offset": Vector2i(-5, -3)
	},
	{
		"name": "Bun",
		"mask": [
			"...####...",
			"..######..",
			".########.",
			"##########",
			".########.",
			"..######..",
			"...####..."
		],
		"offset": Vector2i(-5, -5)
	}
]

const TOP_STYLES := [
	{
		"name": "Tee",
		"shoulder_extra": 0,
		"hem_extra": 0,
		"sleeve_cover": 0.45,
		"body_shape": [0, 1, 1, 1, 1, 1, 0],
		"collar_width": 2,
		"detail": "collar"
	},
	{
		"name": "Jacket",
		"shoulder_extra": 1,
		"hem_extra": 1,
		"sleeve_cover": 0.9,
		"body_shape": [1, 1, 1, 1, 1, 1, 1],
		"collar_width": 3,
		"detail": "open_front"
	},
	{
		"name": "Poncho",
		"shoulder_extra": 2,
		"hem_extra": 2,
		"sleeve_cover": 0.25,
		"body_shape": [2, 2, 2, 1, 1, 1, 0],
		"collar_width": 2,
		"detail": "hem_band"
	},
	{
		"name": "Hoodie",
		"shoulder_extra": 1,
		"hem_extra": 1,
		"sleeve_cover": 0.85,
		"body_shape": [1, 1, 1, 1, 1, 1, 1],
		"collar_width": 3,
		"detail": "pouch"
	}
]

const BOTTOM_STYLES := [
	{
		"name": "Shorts",
		"leg_cover": 0.42,
		"flare": 0,
		"skirt": false,
		"shoe_height": 1
	},
	{
		"name": "Pants",
		"leg_cover": 1.0,
		"flare": 0,
		"skirt": false,
		"shoe_height": 1
	},
	{
		"name": "Skirt",
		"leg_cover": 0.18,
		"flare": 2,
		"skirt": true,
		"shoe_height": 1
	}
]

static func get_front_hair(index: int) -> Dictionary:
	return FRONT_HAIR_STYLES[posmod(index, FRONT_HAIR_STYLES.size())]

static func get_back_hair(index: int) -> Dictionary:
	return BACK_HAIR_STYLES[posmod(index, BACK_HAIR_STYLES.size())]

static func get_top(index: int) -> Dictionary:
	return TOP_STYLES[posmod(index, TOP_STYLES.size())]

static func get_bottom(index: int) -> Dictionary:
	return BOTTOM_STYLES[posmod(index, BOTTOM_STYLES.size())]

static func get_front_hair_points(index: int, mirror: bool = false) -> Array[Vector2i]:
	var style := get_front_hair(index)
	return _mask_to_points(style["mask"], style["offset"], mirror and bool(style.get("mirrorable", false)))

static func get_back_hair_points(index: int, mirror: bool = false) -> Array[Vector2i]:
	var style := get_back_hair(index)
	return _mask_to_points(style["mask"], style["offset"], mirror)

static func get_accessory_definitions(flags: int) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	if (flags & ACCESSORY_SCARF) != 0:
		definitions.append({
			"name": "Scarf",
			"type": "scarf"
		})
	if (flags & ACCESSORY_SATCHEL) != 0:
		definitions.append({
			"name": "Satchel",
			"type": "satchel"
		})
	if (flags & ACCESSORY_CLIP) != 0:
		definitions.append({
			"name": "Clip",
			"type": "clip"
		})
	return definitions

static func describe_hair_style(style: Dictionary) -> String:
	return "%s/%s" % [
		get_front_hair(int(style.get("front", 0)))["name"],
		get_back_hair(int(style.get("back", 0)))["name"]
	]

static func describe_top_style(index: int) -> String:
	return get_top(index)["name"]

static func describe_bottom_style(index: int) -> String:
	return get_bottom(index)["name"]

static func describe_accessories(flags: int) -> String:
	var names: Array[String] = []
	for accessory in get_accessory_definitions(flags):
		names.append(String(accessory["name"]))
	return "None" if names.is_empty() else ",".join(names)

static func _mask_to_points(mask: Array, offset: Vector2i, mirror: bool) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var width := 0
	for row in mask:
		width = maxi(width, String(row).length())
	for y in range(mask.size()):
		var row := String(mask[y])
		for x in range(row.length()):
			if row.substr(x, 1) != "#":
				continue
			var px := width - 1 - x if mirror else x
			points.append(offset + Vector2i(px, y))
	return points
