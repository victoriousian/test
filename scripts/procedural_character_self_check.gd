extends RefCounted
class_name ProceduralCharacterSelfCheck

static func run() -> Dictionary:
	var compiler := FrameCompiler.new()
	var messages: Array[String] = []
	var passed := true

	var baseline_bundle := compiler.compile_bundle(CharacterDNA.randomized(101), false)
	var sprite_frames: SpriteFrames = baseline_bundle["sprite_frames"]
	for animation_name in compiler.get_required_animation_names():
		if not sprite_frames.has_animation(animation_name):
			passed = false
			messages.append("Missing animation: %s" % animation_name)

	for direction in FrameCompiler.DIRECTIONS:
		var idle_name := compiler.get_animation_name("idle", direction)
		var walk_name := compiler.get_animation_name("walk", direction)
		if sprite_frames.get_frame_count(idle_name) < int(FrameCompiler.ANIMATION_FRAME_COUNTS["idle"]):
			passed = false
			messages.append("Idle frame count too low for %s" % idle_name)
		if sprite_frames.get_frame_count(walk_name) < int(FrameCompiler.ANIMATION_FRAME_COUNTS["walk"]):
			passed = false
			messages.append("Walk frame count too low for %s" % walk_name)

	var signatures: Array[String] = []
	for seed_value in [111, 222, 333]:
		signatures.append(String(compiler.compile_bundle(CharacterDNA.randomized(seed_value), false)["bundle_signature"]))
	if signatures[0] == signatures[1] or signatures[1] == signatures[2] or signatures[0] == signatures[2]:
		passed = false
		messages.append("Different seeds produced identical bundles")

	var deterministic_a := String(compiler.compile_bundle(CharacterDNA.randomized(444), false)["bundle_signature"])
	var deterministic_b := String(compiler.compile_bundle(CharacterDNA.randomized(444), false)["bundle_signature"])
	if deterministic_a != deterministic_b:
		passed = false
		messages.append("Same seed did not reproduce identical frames")

	if messages.is_empty():
		messages.append("All checks passed")

	return {
		"passed": passed,
		"messages": messages
	}
