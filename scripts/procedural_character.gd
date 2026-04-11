extends Node2D
class_name ProceduralCharacter

signal dna_changed(dna: CharacterDNA)
signal frames_rebuilt(cache_key: String)

@export var debug_save_png: bool = false

var dna: CharacterDNA = CharacterDNA.new()
var current_state: String = "idle"
var current_direction: String = "down"
var frame_cache := FrameCache.new()
var frame_compiler := FrameCompiler.new()
var animated_sprite: AnimatedSprite2D

func _ready() -> void:
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite == null:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		add_child(animated_sprite)
	animated_sprite.centered = false
	animated_sprite.position = Vector2(-16, -16)
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if animated_sprite.sprite_frames == null or animated_sprite.sprite_frames.get_animation_names().is_empty():
		rebuild_frames()

func randomize_from_seed(seed_value: int) -> void:
	set_dna(CharacterDNA.randomized(seed_value))

func set_dna(new_dna: CharacterDNA) -> void:
	dna = new_dna.clone()
	emit_signal("dna_changed", dna)
	if is_inside_tree():
		rebuild_frames()

func rebuild_frames(force_rebuild: bool = false) -> void:
	var bundle := frame_cache.get_or_build(dna, frame_compiler, debug_save_png, force_rebuild or debug_save_png)
	animated_sprite.sprite_frames = bundle["sprite_frames"]
	play_animation_state(current_state, current_direction)
	emit_signal("frames_rebuilt", String(bundle["cache_key"]))

func play_animation_state(state: String, direction: String) -> void:
	current_state = state
	current_direction = direction
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var animation_name := frame_compiler.get_animation_name(state, direction)
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	animated_sprite.play(animation_name)

func set_palette_slot(slot_name: String, palette: Array) -> void:
	dna.set_palette_slot(slot_name, palette)
	if is_inside_tree():
		rebuild_frames()
