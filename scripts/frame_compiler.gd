extends RefCounted
class_name FrameCompiler

const FRAME_SIZE := Vector2i(32, 32)
const ANIMATION_SET_VERSION := "pc_v1"
const ANIMATION_STATES := ["idle", "walk"]
const DIRECTIONS := ["down", "left", "right", "up"]
const ANIMATION_FRAME_COUNTS := {
	"idle": 4,
	"walk": 6
}
const ANIMATION_FPS := {
	"idle": 5.0,
	"walk": 8.0
}

var frame_size: Vector2i = FRAME_SIZE
var debug_output_root: String = "user://generated_debug"
var pose_solver := PoseSolver.new()
var pixel_rasterizer := PixelRasterizer.new()

func compile_bundle(dna: CharacterDNA, debug_save_png: bool = false) -> Dictionary:
	var sprite_frames := SpriteFrames.new()
	var image_bundle := {}
	for animation_name in ANIMATION_STATES:
		for direction in DIRECTIONS:
			var resolved_name := get_animation_name(animation_name, direction)
			sprite_frames.add_animation(resolved_name)
			sprite_frames.set_animation_loop(resolved_name, true)
			sprite_frames.set_animation_speed(resolved_name, float(ANIMATION_FPS[animation_name]))
			var frames: Array[Image] = []
			var frame_total := int(ANIMATION_FRAME_COUNTS[animation_name])
			for frame_index in range(frame_total):
				var pose := pose_solver.solve_pose(animation_name, direction, frame_index, frame_total)
				var image := pixel_rasterizer.rasterize_character(dna, pose, frame_size)
				frames.append(image)
				var texture := ImageTexture.create_from_image(image)
				sprite_frames.add_frame(resolved_name, texture)
				if debug_save_png:
					_save_debug_image(dna, resolved_name, frame_index, image)
			image_bundle[resolved_name] = frames
	return {
		"sprite_frames": sprite_frames,
		"images": image_bundle,
		"bundle_signature": compute_bundle_signature(image_bundle),
		"frame_size": frame_size,
		"version": ANIMATION_SET_VERSION
	}

func get_required_animation_names() -> Array[String]:
	var output: Array[String] = []
	for state in ANIMATION_STATES:
		for direction in DIRECTIONS:
			output.append(get_animation_name(state, direction))
	return output

func get_animation_name(state: String, direction: String) -> String:
	return "%s_%s" % [state, direction]

func compute_bundle_signature(image_bundle: Dictionary) -> String:
	var keys := image_bundle.keys()
	keys.sort()
	var hash_value: int = 2166136261
	for animation_name in keys:
		hash_value = _fnv1a_bytes(str(animation_name).to_utf8_buffer(), hash_value)
		for image in image_bundle[animation_name]:
			hash_value = _fnv1a_bytes(str(image.get_width()).to_utf8_buffer(), hash_value)
			hash_value = _fnv1a_bytes(str(image.get_height()).to_utf8_buffer(), hash_value)
			hash_value = _fnv1a_bytes(image.get_data(), hash_value)
	return "%08x" % hash_value

func _save_debug_image(dna: CharacterDNA, animation_name: String, frame_index: int, image: Image) -> void:
	var folder_path := "%s/%s_%s" % [debug_output_root, str(dna.seed), animation_name]
	var absolute_path := ProjectSettings.globalize_path(folder_path)
	DirAccess.make_dir_recursive_absolute(absolute_path)
	image.save_png("%s/%02d.png" % [absolute_path, frame_index])

func _fnv1a_bytes(data: PackedByteArray, seed_value: int) -> int:
	var hash_value := seed_value
	for byte in data:
		hash_value = int((hash_value ^ byte) * 16777619) & 0xffffffff
	return hash_value
