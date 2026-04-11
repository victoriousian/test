extends RefCounted
class_name FrameCache

static var _bundle_cache: Dictionary = {}

func build_key(dna: CharacterDNA, frame_size: Vector2i = FrameCompiler.FRAME_SIZE) -> String:
	return "%s::%s::%dx%d::%s" % [
		dna.get_visual_hash(),
		FrameCompiler.ANIMATION_SET_VERSION,
		frame_size.x,
		frame_size.y,
		dna.get_palette_signature()
	]

func get_or_build(dna: CharacterDNA, compiler: FrameCompiler, debug_save_png: bool = false, force_rebuild: bool = false) -> Dictionary:
	var key := build_key(dna, compiler.frame_size)
	if not force_rebuild and _bundle_cache.has(key):
		return _bundle_cache[key]
	var bundle := compiler.compile_bundle(dna, debug_save_png)
	bundle["cache_key"] = key
	_bundle_cache[key] = bundle
	return bundle

func clear() -> void:
	_bundle_cache.clear()
