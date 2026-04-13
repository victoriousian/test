extends RefCounted
class_name CharacterDNA

const BODY_TYPES := ["slim", "average", "broad"]
const FRONT_HAIR_COUNT := 6
const BACK_HAIR_COUNT := 4
const TOP_STYLE_COUNT := 4
const BOTTOM_STYLE_COUNT := 3

const DEFAULT_OUTLINE_COLOR := Color8(24, 22, 30)

const SKIN_PRESETS := [
	[Color8(255, 223, 191), Color8(224, 176, 133), Color8(163, 112, 82)],
	[Color8(245, 207, 164), Color8(210, 154, 110), Color8(143, 93, 66)],
	[Color8(198, 141, 99), Color8(146, 95, 64), Color8(98, 59, 42)],
	[Color8(121, 82, 62), Color8(91, 57, 42), Color8(59, 33, 24)]
]

const HAIR_PRESETS := [
	[Color8(244, 219, 127), Color8(196, 151, 68), Color8(116, 76, 33)],
	[Color8(119, 75, 52), Color8(79, 48, 34), Color8(46, 27, 21)],
	[Color8(205, 91, 92), Color8(146, 50, 70), Color8(82, 27, 47)],
	[Color8(117, 115, 190), Color8(82, 76, 145), Color8(49, 45, 99)],
	[Color8(111, 168, 111), Color8(74, 117, 74), Color8(42, 71, 46)]
]

const TOP_PRESETS := [
	[Color8(116, 180, 255), Color8(67, 125, 198), Color8(33, 72, 124)],
	[Color8(245, 139, 81), Color8(198, 90, 54), Color8(120, 45, 31)],
	[Color8(121, 194, 153), Color8(73, 145, 107), Color8(39, 82, 58)],
	[Color8(231, 211, 99), Color8(176, 145, 58), Color8(105, 83, 26)]
]

const BOTTOM_PRESETS := [
	[Color8(108, 121, 171), Color8(72, 82, 129), Color8(43, 50, 83)],
	[Color8(113, 85, 140), Color8(74, 52, 100), Color8(41, 28, 57)],
	[Color8(89, 152, 173), Color8(48, 103, 127), Color8(22, 59, 77)],
	[Color8(163, 103, 93), Color8(114, 64, 58), Color8(65, 33, 31)]
]

const ACCESSORY_PRESETS := [
	[Color8(244, 232, 158), Color8(205, 172, 73), Color8(126, 91, 26)],
	[Color8(239, 133, 146), Color8(187, 71, 101), Color8(104, 30, 59)],
	[Color8(178, 224, 255), Color8(102, 164, 213), Color8(47, 93, 142)]
]

var seed: int = 1
var body_type: String = BODY_TYPES[1]
var skin_palette: Array[Color] = []
var hair_style: Dictionary = {"front": 0, "back": 0}
var hair_palette: Array[Color] = []
var top_style: int = 0
var top_palette: Array[Color] = []
var bottom_style: int = 0
var bottom_palette: Array[Color] = []
var accessory_flags: int = 0
var accessory_palette: Array[Color] = []
var outline_color: Color = DEFAULT_OUTLINE_COLOR
var height_bias: int = 0
var width_bias: int = 0

func _init() -> void:
	skin_palette = _copy_palette(SKIN_PRESETS[0])
	hair_palette = _copy_palette(HAIR_PRESETS[0])
	top_palette = _copy_palette(TOP_PRESETS[0])
	bottom_palette = _copy_palette(BOTTOM_PRESETS[0])
	accessory_palette = _copy_palette(ACCESSORY_PRESETS[0])

static func randomized(seed_value: int) -> CharacterDNA:
	var dna := CharacterDNA.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	dna.seed = seed_value
	dna.body_type = BODY_TYPES[rng.randi_range(0, BODY_TYPES.size() - 1)]
	dna.skin_palette = get_skin_palette_preset(rng.randi_range(0, SKIN_PRESETS.size() - 1))
	dna.hair_style = {
		"front": rng.randi_range(0, FRONT_HAIR_COUNT - 1),
		"back": rng.randi_range(0, BACK_HAIR_COUNT - 1)
	}
	dna.hair_palette = get_hair_palette_preset(rng.randi_range(0, HAIR_PRESETS.size() - 1))
	dna.top_style = rng.randi_range(0, TOP_STYLE_COUNT - 1)
	dna.top_palette = get_top_palette_preset(rng.randi_range(0, TOP_PRESETS.size() - 1))
	dna.bottom_style = rng.randi_range(0, BOTTOM_STYLE_COUNT - 1)
	dna.bottom_palette = get_bottom_palette_preset(rng.randi_range(0, BOTTOM_PRESETS.size() - 1))
	dna.accessory_flags = 0
	if rng.randf() > 0.45:
		dna.accessory_flags |= 1
	if rng.randf() > 0.55:
		dna.accessory_flags |= 2
	if rng.randf() > 0.65:
		dna.accessory_flags |= 4
	dna.accessory_palette = get_accessory_palette_preset(rng.randi_range(0, ACCESSORY_PRESETS.size() - 1))
	dna.height_bias = rng.randi_range(-1, 1)
	dna.width_bias = rng.randi_range(-1, 1)
	return dna

func clone() -> CharacterDNA:
	var copy := CharacterDNA.new()
	copy.seed = seed
	copy.body_type = body_type
	copy.skin_palette = _copy_palette(skin_palette)
	copy.hair_style = hair_style.duplicate(true)
	copy.hair_palette = _copy_palette(hair_palette)
	copy.top_style = top_style
	copy.top_palette = _copy_palette(top_palette)
	copy.bottom_style = bottom_style
	copy.bottom_palette = _copy_palette(bottom_palette)
	copy.accessory_flags = accessory_flags
	copy.accessory_palette = _copy_palette(accessory_palette)
	copy.outline_color = outline_color
	copy.height_bias = height_bias
	copy.width_bias = width_bias
	return copy

func cycle_hair_style() -> void:
	hair_style["front"] = (int(hair_style.get("front", 0)) + 1) % FRONT_HAIR_COUNT
	if int(hair_style["front"]) == 0:
		hair_style["back"] = (int(hair_style.get("back", 0)) + 1) % BACK_HAIR_COUNT

func cycle_top_style() -> void:
	top_style = (top_style + 1) % TOP_STYLE_COUNT

func cycle_bottom_style() -> void:
	bottom_style = (bottom_style + 1) % BOTTOM_STYLE_COUNT

func toggle_accessory(flag: int) -> void:
	accessory_flags ^= flag

func set_palette_slot(slot_name: String, palette: Array) -> void:
	var converted := _normalize_palette_array(palette)
	match slot_name:
		"skin", "skin_palette":
			skin_palette = converted
		"hair", "hair_palette":
			hair_palette = converted
		"top", "top_palette":
			top_palette = converted
		"bottom", "bottom_palette":
			bottom_palette = converted
		"accessory", "accessory_palette":
			accessory_palette = converted

func to_dictionary() -> Dictionary:
	return {
		"seed": seed,
		"body_type": body_type,
		"skin_palette": _palette_to_html_array(skin_palette),
		"hair_style": {
			"front": int(hair_style.get("front", 0)),
			"back": int(hair_style.get("back", 0))
		},
		"hair_palette": _palette_to_html_array(hair_palette),
		"top_style": top_style,
		"top_palette": _palette_to_html_array(top_palette),
		"bottom_style": bottom_style,
		"bottom_palette": _palette_to_html_array(bottom_palette),
		"accessory_flags": accessory_flags,
		"accessory_palette": _palette_to_html_array(accessory_palette),
		"outline_color": outline_color.to_html(true),
		"height_bias": height_bias,
		"width_bias": width_bias
	}

func to_json_string() -> String:
	return JSON.stringify(to_dictionary(), "\t")

static func from_dictionary(data: Dictionary) -> CharacterDNA:
	var dna := CharacterDNA.new()
	dna.seed = int(data.get("seed", dna.seed))
	var body_candidate := String(data.get("body_type", dna.body_type))
	if BODY_TYPES.has(body_candidate):
		dna.body_type = body_candidate
	var hair_data_variant: Variant = data.get("hair_style", {})
	if hair_data_variant is Dictionary:
		var hair_data: Dictionary = hair_data_variant
		dna.hair_style = {
			"front": clampi(int(hair_data.get("front", 0)), 0, FRONT_HAIR_COUNT - 1),
			"back": clampi(int(hair_data.get("back", 0)), 0, BACK_HAIR_COUNT - 1)
		}
	dna.top_style = clampi(int(data.get("top_style", dna.top_style)), 0, TOP_STYLE_COUNT - 1)
	dna.bottom_style = clampi(int(data.get("bottom_style", dna.bottom_style)), 0, BOTTOM_STYLE_COUNT - 1)
	dna.accessory_flags = int(data.get("accessory_flags", dna.accessory_flags))
	dna.height_bias = clampi(int(data.get("height_bias", dna.height_bias)), -2, 2)
	dna.width_bias = clampi(int(data.get("width_bias", dna.width_bias)), -2, 2)

	dna.skin_palette = _palette_from_variant(data.get("skin_palette", []), SKIN_PRESETS[0])
	dna.hair_palette = _palette_from_variant(data.get("hair_palette", []), HAIR_PRESETS[0])
	dna.top_palette = _palette_from_variant(data.get("top_palette", []), TOP_PRESETS[0])
	dna.bottom_palette = _palette_from_variant(data.get("bottom_palette", []), BOTTOM_PRESETS[0])
	dna.accessory_palette = _palette_from_variant(data.get("accessory_palette", []), ACCESSORY_PRESETS[0])

	var outline_value := String(data.get("outline_color", dna.outline_color.to_html(true)))
	dna.outline_color = Color.from_string(outline_value, DEFAULT_OUTLINE_COLOR)
	return dna

static func from_json_string(json_text: String) -> CharacterDNA:
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return CharacterDNA.new()
	if json.data is Dictionary:
		return from_dictionary(json.data)
	return CharacterDNA.new()

func get_visual_hash() -> String:
	return _fnv1a_string(to_signature_string(true, false))

func get_palette_signature() -> String:
	return _fnv1a_string(to_signature_string(false, true))

func to_signature_string(include_structure: bool = true, include_palettes: bool = true) -> String:
	var parts: Array[String] = []
	if include_structure:
		parts.append(str(seed))
		parts.append(body_type)
		parts.append(str(hair_style.get("front", 0)))
		parts.append(str(hair_style.get("back", 0)))
		parts.append(str(top_style))
		parts.append(str(bottom_style))
		parts.append(str(accessory_flags))
		parts.append(str(height_bias))
		parts.append(str(width_bias))
	if include_palettes:
		parts.append(_palette_signature(skin_palette))
		parts.append(_palette_signature(hair_palette))
		parts.append(_palette_signature(top_palette))
		parts.append(_palette_signature(bottom_palette))
		parts.append(_palette_signature(accessory_palette))
		parts.append(outline_color.to_html(true))
	return "|".join(parts)

func describe_hair_style() -> String:
	return "%s/%s" % [hair_style.get("front", 0), hair_style.get("back", 0)]

static func get_skin_palette_preset(index: int) -> Array[Color]:
	return _copy_palette(SKIN_PRESETS[posmod(index, SKIN_PRESETS.size())])

static func get_hair_palette_preset(index: int) -> Array[Color]:
	return _copy_palette(HAIR_PRESETS[posmod(index, HAIR_PRESETS.size())])

static func get_top_palette_preset(index: int) -> Array[Color]:
	return _copy_palette(TOP_PRESETS[posmod(index, TOP_PRESETS.size())])

static func get_bottom_palette_preset(index: int) -> Array[Color]:
	return _copy_palette(BOTTOM_PRESETS[posmod(index, BOTTOM_PRESETS.size())])

static func get_accessory_palette_preset(index: int) -> Array[Color]:
	return _copy_palette(ACCESSORY_PRESETS[posmod(index, ACCESSORY_PRESETS.size())])

static func get_palette_preset(slot_name: String, index: int) -> Array[Color]:
	var presets := _get_palette_presets(slot_name)
	if presets.is_empty():
		return []
	return _copy_palette(presets[posmod(index, presets.size())])

static func get_palette_preset_count(slot_name: String) -> int:
	return _get_palette_presets(slot_name).size()

static func get_palette_preset_index(slot_name: String, palette: Array) -> int:
	var normalized := _normalize_palette_array(palette)
	if normalized.is_empty():
		return 0
	var target_signature := _palette_signature_static(normalized)
	var presets := _get_palette_presets(slot_name)
	for index in range(presets.size()):
		if _palette_signature_static(_copy_palette(presets[index])) == target_signature:
			return index
	return 0

static func _get_palette_presets(slot_name: String) -> Array:
	match slot_name:
		"skin", "skin_palette":
			return SKIN_PRESETS
		"top", "top_palette":
			return TOP_PRESETS
		"bottom", "bottom_palette":
			return BOTTOM_PRESETS
		"accessory", "accessory_palette":
			return ACCESSORY_PRESETS
		_:
			return HAIR_PRESETS

static func _copy_palette(source: Array) -> Array[Color]:
	var output: Array[Color] = []
	for entry in source:
		output.append(entry if entry is Color else Color(entry))
	return output

static func _normalize_palette_array(source: Array) -> Array[Color]:
	var output: Array[Color] = []
	for entry in source:
		output.append(entry if entry is Color else Color(entry))
	return output

static func _palette_from_variant(source: Variant, fallback: Array) -> Array[Color]:
	if source is Array and not source.is_empty():
		var converted := _normalize_palette_array(source)
		if not converted.is_empty():
			return converted
	return _copy_palette(fallback)

static func _palette_to_html_array(source: Array[Color]) -> Array[String]:
	var output: Array[String] = []
	for color in source:
		output.append(color.to_html(true))
	return output

func _palette_signature(palette: Array[Color]) -> String:
	var parts: Array[String] = []
	for color in palette:
		parts.append(color.to_html(true))
	return ",".join(parts)

static func _palette_signature_static(palette: Array[Color]) -> String:
	var parts: Array[String] = []
	for color in palette:
		parts.append(color.to_html(true))
	return ",".join(parts)

static func _fnv1a_string(value: String) -> String:
	var hash_value: int = 2166136261
	for byte in value.to_utf8_buffer():
		hash_value = int((hash_value ^ byte) * 16777619) & 0xffffffff
	return "%08x" % hash_value
