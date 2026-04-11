extends Node2D
class_name DemoController

const HAIR_COLOR_KEYS := {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2
}

const CLOTH_COLOR_KEYS := {
	KEY_4: 0,
	KEY_5: 1,
	KEY_6: 2
}

const ACCESSORY_SEQUENCE := [
	PartLibrary.ACCESSORY_SCARF,
	PartLibrary.ACCESSORY_SATCHEL,
	PartLibrary.ACCESSORY_CLIP
]

@onready var character: ProceduralCharacter = $Character
@onready var status_label: Label = $CanvasLayer/StatusLabel

var current_seed: int = 240411
var current_state: String = "idle"
var current_direction: String = "down"
var hair_palette_index: int = 0
var cloth_palette_index: int = 0
var accessory_cursor: int = 0
var self_check_summary: String = "pending"

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color8(214, 225, 235))
	character.dna_changed.connect(_on_character_changed)
	character.frames_rebuilt.connect(_on_frames_rebuilt)
	character.scale = Vector2(4, 4)
	character.randomize_from_seed(current_seed)
	character.play_animation_state(current_state, current_direction)
	_run_self_check()
	_update_status_label()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if HAIR_COLOR_KEYS.has(key_event.keycode):
		_set_hair_palette(int(HAIR_COLOR_KEYS[key_event.keycode]))
		return
	if CLOTH_COLOR_KEYS.has(key_event.keycode):
		_set_cloth_palette(int(CLOTH_COLOR_KEYS[key_event.keycode]))
		return

	match key_event.keycode:
		KEY_R:
			current_seed = int(Time.get_ticks_usec() & 0x7fffffff)
			character.randomize_from_seed(current_seed)
		KEY_H:
			var dna := character.dna.clone()
			dna.cycle_hair_style()
			character.set_dna(dna)
		KEY_T:
			var top_dna := character.dna.clone()
			top_dna.cycle_top_style()
			character.set_dna(top_dna)
		KEY_B:
			var bottom_dna := character.dna.clone()
			bottom_dna.cycle_bottom_style()
			character.set_dna(bottom_dna)
		KEY_A:
			var accessory_dna := character.dna.clone()
			accessory_dna.toggle_accessory(int(ACCESSORY_SEQUENCE[accessory_cursor]))
			accessory_cursor = (accessory_cursor + 1) % ACCESSORY_SEQUENCE.size()
			character.set_dna(accessory_dna)
		KEY_SPACE:
			current_state = "walk" if current_state == "idle" else "idle"
			character.play_animation_state(current_state, current_direction)
		KEY_LEFT:
			_set_direction("left")
		KEY_RIGHT:
			_set_direction("right")
		KEY_UP:
			_set_direction("up")
		KEY_DOWN:
			_set_direction("down")
		KEY_C:
			_run_self_check()

	_update_status_label()

func _set_direction(direction: String) -> void:
	current_direction = direction
	character.play_animation_state(current_state, current_direction)

func _set_hair_palette(index: int) -> void:
	hair_palette_index = index
	var dna := character.dna.clone()
	dna.set_palette_slot("hair", CharacterDNA.get_hair_palette_preset(index))
	character.set_dna(dna)

func _set_cloth_palette(index: int) -> void:
	cloth_palette_index = index
	var dna := character.dna.clone()
	dna.set_palette_slot("top", CharacterDNA.get_top_palette_preset(index))
	dna.set_palette_slot("bottom", CharacterDNA.get_bottom_palette_preset(index))
	character.set_dna(dna)

func _run_self_check() -> void:
	var result := ProceduralCharacterSelfCheck.run()
	self_check_summary = "PASS" if bool(result["passed"]) else "FAIL: %s" % ", ".join(result["messages"])
	print("[ProceduralCharacterSelfCheck] ", self_check_summary)

func _on_character_changed(_dna: CharacterDNA) -> void:
	current_seed = character.dna.seed
	_update_status_label()

func _on_frames_rebuilt(_cache_key: String) -> void:
	character.play_animation_state(current_state, current_direction)
	_update_status_label()

func _update_status_label() -> void:
	var dna := character.dna
	status_label.text = "\n".join([
		"Procedural 32x32 Character Demo",
		"Seed: %d | Body: %s | Dir: %s | State: %s" % [current_seed, dna.body_type, current_direction, current_state],
		"Hair: %s | Top: %s | Bottom: %s" % [
			PartLibrary.describe_hair_style(dna.hair_style),
			PartLibrary.describe_top_style(dna.top_style),
			PartLibrary.describe_bottom_style(dna.bottom_style)
		],
		"Accessories: %s | Self-check: %s" % [PartLibrary.describe_accessories(dna.accessory_flags), self_check_summary],
		"Controls: R random | 1-3 hair | 4-6 clothes | H/T/B styles | A accessory | Arrows direction | Space idle/walk | C self-check"
	])
