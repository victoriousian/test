extends Control
class_name CharacterCustomizationPanel

signal dna_applied(dna: CharacterDNA)

@export var character_path: NodePath
@export var apply_on_change: bool = true
@export var auto_sync_on_ready: bool = true

var _character: ProceduralCharacter
var _syncing_ui: bool = false
var _working_dna: CharacterDNA = CharacterDNA.new()

var _seed_spin: SpinBox
var _body_option: OptionButton
var _front_hair_option: OptionButton
var _back_hair_option: OptionButton
var _top_option: OptionButton
var _bottom_option: OptionButton
var _skin_palette_option: OptionButton
var _hair_palette_option: OptionButton
var _top_palette_option: OptionButton
var _bottom_palette_option: OptionButton
var _accessory_palette_option: OptionButton
var _scarf_toggle: CheckBox
var _satchel_toggle: CheckBox
var _clip_toggle: CheckBox
var _status_label: Label

func _ready() -> void:
	if get_child_count() == 0:
		_build_ui()
	if size == Vector2.ZERO:
		custom_minimum_size = Vector2(288, 440)
		size = custom_minimum_size
	_resolve_character()
	if auto_sync_on_ready:
		if _character != null:
			load_dna(_character.get_dna_copy())
		else:
			load_dna(CharacterDNA.randomized(240411))

func bind_character(character: ProceduralCharacter) -> void:
	var dna_changed_callable: Callable = Callable(self, "_on_bound_character_dna_changed")
	if _character != null and _character.dna_changed.is_connected(dna_changed_callable):
		_character.dna_changed.disconnect(dna_changed_callable)
	_character = character
	if _character != null and not _character.dna_changed.is_connected(dna_changed_callable):
		_character.dna_changed.connect(dna_changed_callable)
	if _character != null:
		load_dna(_character.get_dna_copy())

func pull_from_character() -> void:
	if _character != null:
		load_dna(_character.get_dna_copy())

func load_dna(dna: CharacterDNA) -> void:
	_working_dna = dna.clone()
	_syncing_ui = true
	_seed_spin.value = float(dna.seed)
	_body_option.select(maxi(CharacterDNA.BODY_TYPES.find(dna.body_type), 0))
	_front_hair_option.select(clampi(int(dna.hair_style.get("front", 0)), 0, CharacterDNA.FRONT_HAIR_COUNT - 1))
	_back_hair_option.select(clampi(int(dna.hair_style.get("back", 0)), 0, CharacterDNA.BACK_HAIR_COUNT - 1))
	_top_option.select(clampi(dna.top_style, 0, CharacterDNA.TOP_STYLE_COUNT - 1))
	_bottom_option.select(clampi(dna.bottom_style, 0, CharacterDNA.BOTTOM_STYLE_COUNT - 1))
	_skin_palette_option.select(CharacterDNA.get_palette_preset_index("skin", dna.skin_palette))
	_hair_palette_option.select(CharacterDNA.get_palette_preset_index("hair", dna.hair_palette))
	_top_palette_option.select(CharacterDNA.get_palette_preset_index("top", dna.top_palette))
	_bottom_palette_option.select(CharacterDNA.get_palette_preset_index("bottom", dna.bottom_palette))
	_accessory_palette_option.select(CharacterDNA.get_palette_preset_index("accessory", dna.accessory_palette))
	_scarf_toggle.button_pressed = (dna.accessory_flags & PartLibrary.ACCESSORY_SCARF) != 0
	_satchel_toggle.button_pressed = (dna.accessory_flags & PartLibrary.ACCESSORY_SATCHEL) != 0
	_clip_toggle.button_pressed = (dna.accessory_flags & PartLibrary.ACCESSORY_CLIP) != 0
	_syncing_ui = false
	_update_status_label(dna)

func get_current_dna() -> CharacterDNA:
	var dna: CharacterDNA = _working_dna.clone()
	dna.seed = int(_seed_spin.value)
	dna.body_type = CharacterDNA.BODY_TYPES[_body_option.get_selected_id()]
	dna.hair_style = {
		"front": _front_hair_option.get_selected_id(),
		"back": _back_hair_option.get_selected_id()
	}
	dna.hair_palette = CharacterDNA.get_palette_preset("hair", _hair_palette_option.get_selected_id())
	dna.skin_palette = CharacterDNA.get_palette_preset("skin", _skin_palette_option.get_selected_id())
	dna.top_style = _top_option.get_selected_id()
	dna.top_palette = CharacterDNA.get_palette_preset("top", _top_palette_option.get_selected_id())
	dna.bottom_style = _bottom_option.get_selected_id()
	dna.bottom_palette = CharacterDNA.get_palette_preset("bottom", _bottom_palette_option.get_selected_id())
	dna.accessory_flags = 0
	if _scarf_toggle.button_pressed:
		dna.accessory_flags |= PartLibrary.ACCESSORY_SCARF
	if _satchel_toggle.button_pressed:
		dna.accessory_flags |= PartLibrary.ACCESSORY_SATCHEL
	if _clip_toggle.button_pressed:
		dna.accessory_flags |= PartLibrary.ACCESSORY_CLIP
	dna.accessory_palette = CharacterDNA.get_palette_preset("accessory", _accessory_palette_option.get_selected_id())
	return dna

func apply_current_dna() -> CharacterDNA:
	var dna: CharacterDNA = get_current_dna()
	_push_dna(dna)
	return dna

func apply_seed() -> CharacterDNA:
	var dna: CharacterDNA = CharacterDNA.randomized(int(_seed_spin.value))
	load_dna(dna)
	_push_dna(dna)
	return dna

func randomize_seed() -> CharacterDNA:
	_seed_spin.value = float(int(Time.get_ticks_usec() & 0x7fffffff))
	return apply_seed()

func _resolve_character() -> void:
	if character_path.is_empty():
		return
	var candidate: Node = get_node_or_null(character_path)
	if candidate is ProceduralCharacter:
		bind_character(candidate as ProceduralCharacter)

func _push_dna(dna: CharacterDNA) -> void:
	_working_dna = dna.clone()
	if _character != null:
		_character.set_dna(dna)
	emit_signal("dna_applied", dna.clone())
	_update_status_label(dna)

func _build_ui() -> void:
	custom_minimum_size = Vector2(288, 440)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	var title: Label = Label.new()
	title.text = "Character Customization"
	content.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Bind this panel to a ProceduralCharacter node and it will live-edit the preview."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var seed_row: HBoxContainer = HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 6)
	content.add_child(seed_row)

	var seed_label: Label = Label.new()
	seed_label.text = "Seed"
	seed_row.add_child(seed_label)

	_seed_spin = SpinBox.new()
	_seed_spin.rounded = true
	_seed_spin.step = 1.0
	_seed_spin.min_value = 0.0
	_seed_spin.max_value = 2147483647.0
	_seed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(_seed_spin)

	var apply_seed_button: Button = Button.new()
	apply_seed_button.text = "Apply Seed"
	apply_seed_button.pressed.connect(_on_apply_seed_pressed)
	seed_row.add_child(apply_seed_button)

	var random_button: Button = Button.new()
	random_button.text = "New Random"
	random_button.pressed.connect(_on_randomize_pressed)
	seed_row.add_child(random_button)

	var refresh_button: Button = Button.new()
	refresh_button.text = "Refresh"
	refresh_button.pressed.connect(_on_refresh_pressed)
	seed_row.add_child(refresh_button)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)

	_body_option = _create_option_row(grid, "Body")
	_front_hair_option = _create_option_row(grid, "Front Hair")
	_back_hair_option = _create_option_row(grid, "Back Hair")
	_top_option = _create_option_row(grid, "Top")
	_bottom_option = _create_option_row(grid, "Bottom")
	_skin_palette_option = _create_option_row(grid, "Skin Palette")
	_hair_palette_option = _create_option_row(grid, "Hair Palette")
	_top_palette_option = _create_option_row(grid, "Top Palette")
	_bottom_palette_option = _create_option_row(grid, "Bottom Palette")
	_accessory_palette_option = _create_option_row(grid, "Accessory Palette")

	var accessory_header: Label = Label.new()
	accessory_header.text = "Accessories"
	content.add_child(accessory_header)

	var accessory_box: VBoxContainer = VBoxContainer.new()
	accessory_box.add_theme_constant_override("separation", 4)
	content.add_child(accessory_box)

	_scarf_toggle = _create_toggle(accessory_box, "Scarf")
	_satchel_toggle = _create_toggle(accessory_box, "Satchel")
	_clip_toggle = _create_toggle(accessory_box, "Clip")

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status_label)

	_populate_options()

func _create_option_row(grid: GridContainer, label_text: String) -> OptionButton:
	var label: Label = Label.new()
	label.text = label_text
	grid.add_child(label)

	var option: OptionButton = OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.item_selected.connect(_on_ui_value_changed)
	grid.add_child(option)
	return option

func _create_toggle(parent: VBoxContainer, label_text: String) -> CheckBox:
	var toggle: CheckBox = CheckBox.new()
	toggle.text = label_text
	toggle.toggled.connect(_on_ui_value_changed)
	parent.add_child(toggle)
	return toggle

func _populate_options() -> void:
	for index in range(CharacterDNA.BODY_TYPES.size()):
		_body_option.add_item(String(CharacterDNA.BODY_TYPES[index]).capitalize(), index)

	for index in range(CharacterDNA.FRONT_HAIR_COUNT):
		_front_hair_option.add_item(String(PartLibrary.get_front_hair(index)["name"]), index)

	for index in range(CharacterDNA.BACK_HAIR_COUNT):
		_back_hair_option.add_item(String(PartLibrary.get_back_hair(index)["name"]), index)

	for index in range(CharacterDNA.TOP_STYLE_COUNT):
		_top_option.add_item(String(PartLibrary.describe_top_style(index)), index)

	for index in range(CharacterDNA.BOTTOM_STYLE_COUNT):
		_bottom_option.add_item(String(PartLibrary.describe_bottom_style(index)), index)

	_populate_palette_option(_skin_palette_option, "skin")
	_populate_palette_option(_hair_palette_option, "hair")
	_populate_palette_option(_top_palette_option, "top")
	_populate_palette_option(_bottom_palette_option, "bottom")
	_populate_palette_option(_accessory_palette_option, "accessory")

func _populate_palette_option(option: OptionButton, slot_name: String) -> void:
	for index in range(CharacterDNA.get_palette_preset_count(slot_name)):
		option.add_item("Preset %d" % [index + 1], index)

func _update_status_label(dna: CharacterDNA) -> void:
	_status_label.text = "\n".join([
		"Seed: %d" % dna.seed,
		"Hair: %s" % PartLibrary.describe_hair_style(dna.hair_style),
		"Top/Bottom: %s / %s" % [PartLibrary.describe_top_style(dna.top_style), PartLibrary.describe_bottom_style(dna.bottom_style)],
		"Accessories: %s" % PartLibrary.describe_accessories(dna.accessory_flags),
		"Save data: character.get_dna_dictionary()"
	])

func _on_ui_value_changed(_value: Variant = null) -> void:
	if _syncing_ui:
		return
	if apply_on_change:
		apply_current_dna()
	else:
		_update_status_label(get_current_dna())

func _on_apply_seed_pressed() -> void:
	apply_seed()

func _on_randomize_pressed() -> void:
	randomize_seed()

func _on_refresh_pressed() -> void:
	pull_from_character()

func _on_bound_character_dna_changed(dna: CharacterDNA) -> void:
	load_dna(dna)
