extends Node2D
class_name GameIntegrationDemoController

const BACKGROUND_COLOR := Color8(223, 232, 238)
const GUIDE_COLOR := Color8(116, 137, 148)
const PREVIEW_POSITION := Vector2(430, 188)
const WORLD_LEFT_X := 620.0
const WORLD_RIGHT_X := 860.0
const WORLD_Y := 346.0
const WORLD_SPEED := 52.0

@onready var preview_character: ProceduralCharacter = $PreviewCharacter
@onready var world_character: ProceduralCharacter = $WorldCharacter
@onready var customization_panel: CharacterCustomizationPanel = $CanvasLayer/CustomizationPanel
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var _archetype_ids: Array[String] = CharacterArchetypeLibrary.get_ids()
var _current_archetype: String = "traveler"
var _applied_save_data: Dictionary = {}
var _world_velocity: Vector2 = Vector2.ZERO
var _moving_right: bool = true
var _archetype_option: OptionButton
var _status_label: Label
var _save_payload_edit: TextEdit

func _ready() -> void:
	RenderingServer.set_default_clear_color(BACKGROUND_COLOR)
	_build_world_guides()
	_build_info_panel()

	preview_character.position = PREVIEW_POSITION
	preview_character.scale = Vector2(4, 4)
	preview_character.play_animation_state("idle", "down")

	world_character.position = Vector2(WORLD_LEFT_X, WORLD_Y)
	world_character.scale = Vector2(4, 4)
	world_character.play_animation_state("idle", "right")

	customization_panel.bind_character(preview_character)
	customization_panel.dna_applied.connect(_on_preview_dna_applied)
	_populate_archetypes()
	_load_archetype(_current_archetype, true)

func _process(delta: float) -> void:
	if _applied_save_data.is_empty():
		return

	var target_x := WORLD_RIGHT_X if _moving_right else WORLD_LEFT_X
	var distance := target_x - world_character.position.x
	if absf(distance) <= WORLD_SPEED * delta:
		world_character.position.x = target_x
		_moving_right = not _moving_right
		target_x = WORLD_RIGHT_X if _moving_right else WORLD_LEFT_X
		distance = target_x - world_character.position.x

	var direction_sign := 1.0 if distance >= 0.0 else -1.0
	_world_velocity = Vector2(direction_sign * WORLD_SPEED, 0.0)
	world_character.position += _world_velocity * delta
	world_character.apply_motion_vector(_world_velocity)

func _build_world_guides() -> void:
	var preview_guide := Line2D.new()
	preview_guide.width = 4.0
	preview_guide.default_color = GUIDE_COLOR
	preview_guide.points = PackedVector2Array([
		PREVIEW_POSITION + Vector2(-74.0, 82.0),
		PREVIEW_POSITION + Vector2(74.0, 82.0)
	])
	add_child(preview_guide)
	move_child(preview_guide, 0)

	var world_guide := Line2D.new()
	world_guide.width = 5.0
	world_guide.default_color = GUIDE_COLOR
	world_guide.points = PackedVector2Array([
		Vector2(WORLD_LEFT_X - 72.0, WORLD_Y + 82.0),
		Vector2(WORLD_RIGHT_X + 72.0, WORLD_Y + 82.0)
	])
	add_child(world_guide)
	move_child(world_guide, 0)

	var preview_label := Label.new()
	preview_label.text = "Preview"
	preview_label.offset_left = PREVIEW_POSITION.x - 34.0
	preview_label.offset_top = PREVIEW_POSITION.y - 122.0
	preview_label.offset_right = preview_label.offset_left + 80.0
	preview_label.offset_bottom = preview_label.offset_top + 24.0
	preview_label.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(preview_label)

	var world_label := Label.new()
	world_label.text = "In-Game Actor"
	world_label.offset_left = WORLD_LEFT_X - 20.0
	world_label.offset_top = WORLD_Y - 122.0
	world_label.offset_right = world_label.offset_left + 180.0
	world_label.offset_bottom = world_label.offset_top + 24.0
	world_label.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(world_label)

func _build_info_panel() -> void:
	var info_panel := PanelContainer.new()
	info_panel.offset_left = 620.0
	info_panel.offset_top = 16.0
	info_panel.offset_right = 944.0
	info_panel.offset_bottom = 520.0
	canvas_layer.add_child(info_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	info_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Game Integration Flow"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	var intro := Label.new()
	intro.text = "Load a designed base character, customize the preview on the left, then apply that same DNA payload to the in-game actor."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)

	var archetype_row := HBoxContainer.new()
	archetype_row.add_theme_constant_override("separation", 6)
	content.add_child(archetype_row)

	_archetype_option = OptionButton.new()
	_archetype_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	archetype_row.add_child(_archetype_option)

	var load_base_button := Button.new()
	load_base_button.text = "Load Base"
	load_base_button.pressed.connect(_on_load_base_pressed)
	archetype_row.add_child(load_base_button)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	content.add_child(button_row)

	var apply_button := Button.new()
	apply_button.text = "Apply To Game"
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.pressed.connect(_on_apply_to_game_pressed)
	button_row.add_child(apply_button)

	var edit_applied_button := Button.new()
	edit_applied_button.text = "Edit Applied"
	edit_applied_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_applied_button.pressed.connect(_on_edit_applied_pressed)
	button_row.add_child(edit_applied_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status_label)

	var payload_title := Label.new()
	payload_title.text = "Saved DNA Payload"
	content.add_child(payload_title)

	_save_payload_edit = TextEdit.new()
	_save_payload_edit.custom_minimum_size = Vector2(0, 220)
	_save_payload_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_payload_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_save_payload_edit.editable = false
	content.add_child(_save_payload_edit)

func _populate_archetypes() -> void:
	_archetype_option.clear()
	for index in range(_archetype_ids.size()):
		var archetype_id := _archetype_ids[index]
		_archetype_option.add_item(CharacterArchetypeLibrary.get_display_name(archetype_id), index)
		if archetype_id == _current_archetype:
			_archetype_option.select(index)

func _load_archetype(archetype_id: String, apply_to_world: bool = false) -> void:
	_current_archetype = archetype_id
	var dna := CharacterArchetypeLibrary.make_dna(archetype_id)
	preview_character.set_dna(dna)
	customization_panel.load_dna(dna)
	preview_character.play_animation_state("idle", "down")
	if apply_to_world:
		_commit_preview_to_world("Base archetype applied to the world actor. Edit the preview, then apply again to rebuild gameplay visuals.")
	else:
		_refresh_status("Base archetype loaded into the preview. The in-game actor keeps its last applied look until you press Apply To Game.")

func _commit_preview_to_world(message: String = "") -> void:
	var dna := customization_panel.get_current_dna()
	_applied_save_data = dna.to_dictionary()
	world_character.set_dna_from_dictionary(_applied_save_data)
	world_character.position.y = WORLD_Y
	world_character.apply_motion_vector(_world_velocity if _world_velocity.length_squared() > 0.0 else Vector2(WORLD_SPEED, 0.0))
	_refresh_status(message if not message.is_empty() else "World actor rebuilt from the preview DNA. The walking animation now uses the customized look in actual gameplay.")

func _restore_applied_to_preview() -> void:
	if _applied_save_data.is_empty():
		_refresh_status("There is no applied payload yet. Pick a base archetype or press Apply To Game after customizing.")
		return
	var dna := CharacterDNA.from_dictionary(_applied_save_data)
	preview_character.set_dna(dna)
	customization_panel.load_dna(dna)
	preview_character.play_animation_state("idle", "down")
	_refresh_status("The applied in-game DNA was loaded back into the preview for further editing.")

func _refresh_status(message: String) -> void:
	var preview_dna := customization_panel.get_current_dna()
	var applied_seed := int(_applied_save_data.get("seed", -1))
	var applied_seed_text := str(applied_seed) if applied_seed >= 0 else "not applied"
	_status_label.text = "\n".join([
		"Designed Base: %s" % CharacterArchetypeLibrary.get_display_name(_current_archetype),
		"Preview Seed: %d | Applied Seed: %s" % [preview_dna.seed, applied_seed_text],
		"Preview on the left can change freely; the in-game actor only updates when you commit the payload.",
		"Gameplay animation is driven with character.apply_motion_vector(), so the same customized DNA keeps its walk cycle in-game.",
		message
	])
	_save_payload_edit.text = "{}" if _applied_save_data.is_empty() else JSON.stringify(_applied_save_data, "\t")

func _on_preview_dna_applied(_dna: CharacterDNA) -> void:
	preview_character.play_animation_state("idle", "down")
	_refresh_status("Preview DNA changed. Press Apply To Game to rebuild the in-game actor with this customized look.")

func _on_load_base_pressed() -> void:
	var selected_index := _archetype_option.get_selected_id()
	if selected_index < 0 or selected_index >= _archetype_ids.size():
		return
	_load_archetype(_archetype_ids[selected_index], false)

func _on_apply_to_game_pressed() -> void:
	_commit_preview_to_world()

func _on_edit_applied_pressed() -> void:
	_restore_applied_to_preview()
