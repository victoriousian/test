extends RefCounted
class_name PixelRasterizer

const FRAME_SIZE := Vector2i(32, 32)
const OPAQUE_WHITE := Color(1.0, 1.0, 1.0, 1.0)
const TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)
const EYE_COLOR := Color8(33, 32, 38)

func rasterize_character(dna: CharacterDNA, pose: Dictionary, frame_size: Vector2i = FRAME_SIZE) -> Image:
	var direction := String(pose["direction"])
	var metrics := _build_metrics(dna, direction)
	var head_w := int(metrics["head_w"])
	var head_h := int(metrics["head_h"])
	var torso_w := int(metrics["torso_w"])
	var torso_h := int(metrics["torso_h"])
	var head_center: Vector2i = pose["head"]
	var torso_center: Vector2i = pose["torso"]
	var head_rect := Rect2i(
		head_center - Vector2i(int(floor(head_w / 2.0)), int(floor(head_h / 2.0))),
		Vector2i(head_w, head_h)
	)
	var torso_rect := Rect2i(
		torso_center - Vector2i(int(floor(torso_w / 2.0)), int(floor(torso_h / 2.0))),
		Vector2i(torso_w, torso_h)
	)

	var layers := {
		"back_leg": _create_layer(frame_size),
		"back_arm": _create_layer(frame_size),
		"torso": _create_layer(frame_size),
		"front_leg": _create_layer(frame_size),
		"front_arm": _create_layer(frame_size),
		"head": _create_layer(frame_size),
		"hair": _create_layer(frame_size),
		"cloth_detail": _create_layer(frame_size),
		"accessory": _create_layer(frame_size)
	}

	_draw_leg_layer(layers.back_leg, dna, pose, metrics, false)
	_draw_arm_layer(layers.back_arm, dna, pose, metrics, false)
	_draw_torso_layer(layers.torso, dna, pose, metrics, torso_rect)
	_draw_leg_layer(layers.front_leg, dna, pose, metrics, true)
	_draw_arm_layer(layers.front_arm, dna, pose, metrics, true)
	_draw_head_layer(layers.head, dna, pose, metrics, head_rect)
	_draw_hair_layer(layers.hair, dna, pose, metrics, head_rect)
	_draw_clothing_detail_layer(layers.cloth_detail, dna, pose, metrics, torso_rect, head_rect)
	_draw_accessory_layer(layers.accessory, dna, pose, metrics, torso_rect, head_rect)

	var result := _create_layer(frame_size)
	for name in ["back_leg", "back_arm", "torso", "front_leg", "front_arm", "head", "hair", "cloth_detail", "accessory"]:
		_blit_opaque(result, layers[name])
	_apply_outline(result, dna.outline_color)
	return result

func _build_metrics(dna: CharacterDNA, direction: String) -> Dictionary:
	var body_offset := CharacterDNA.BODY_TYPES.find(dna.body_type)
	var width_delta := dna.width_bias + (-1 if body_offset == 0 else 1 if body_offset == 2 else 0)
	var height_delta := dna.height_bias + (-1 if body_offset == 0 else 1 if body_offset == 2 else 0)
	var side_adjust := 1 if direction == "left" or direction == "right" else 0
	return {
		"head_w": clampi(9 + width_delta, 8, 11),
		"head_h": clampi(8 + maxi(height_delta, 0), 8, 10),
		"torso_w": clampi(8 + width_delta - side_adjust, 6, 10),
		"torso_h": clampi(8 + height_delta, 7, 10),
		"arm_thickness": clampi(2 + (1 if body_offset == 2 else 0), 2, 3),
		"leg_thickness": clampi(2 + (1 if body_offset == 2 else 0), 2, 3)
	}

func _draw_leg_layer(layer: Image, dna: CharacterDNA, pose: Dictionary, metrics: Dictionary, is_front: bool) -> void:
	var skin_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var cloth_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var foot_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var knee_key := "knee_front" if is_front else "knee_back"
	var ankle_key := "ankle_front" if is_front else "ankle_back"
	var hip := _get_leg_hip_anchor(pose, is_front)
	var knee: Vector2i = pose[knee_key]
	var ankle: Vector2i = pose[ankle_key]
	_stamp_line(skin_mask, hip, knee, int(metrics["leg_thickness"]))
	_stamp_line(skin_mask, knee, ankle, int(metrics["leg_thickness"]))
	var foot_dir := _foot_direction(String(pose["direction"]), is_front)
	_stamp_line(foot_mask, ankle, ankle + foot_dir, 2)

	var bottom_style := PartLibrary.get_bottom(dna.bottom_style)
	var cover := float(bottom_style["leg_cover"])
	var cloth_end := _lerp_point(knee, ankle, 0.0)
	if cover >= 1.0:
		_stamp_line(cloth_mask, hip, knee, int(metrics["leg_thickness"]) + 1)
		_stamp_line(cloth_mask, knee, ankle + foot_dir, int(metrics["leg_thickness"]) + 1)
	else:
		cloth_end = _lerp_point(hip, knee, clampf(cover * 1.2, 0.15, 1.0))
		_stamp_line(cloth_mask, hip, cloth_end, int(metrics["leg_thickness"]) + 1)
		if cover > 0.25:
			_stamp_rect(cloth_mask, Rect2i(cloth_end + Vector2i(-1, 0), Vector2i(3, 1)))

	_apply_shaded_mask_to_layer(layer, skin_mask, dna.skin_palette)
	_apply_shaded_mask_to_layer(layer, cloth_mask, dna.bottom_palette)
	_apply_shaded_mask_to_layer(layer, foot_mask, [dna.bottom_palette[2], dna.bottom_palette[1], dna.bottom_palette[2]])

func _draw_arm_layer(layer: Image, dna: CharacterDNA, pose: Dictionary, metrics: Dictionary, is_front: bool) -> void:
	var skin_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var cloth_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var shoulder_key := "shoulder_front" if is_front else "shoulder_back"
	var elbow_key := "elbow_front" if is_front else "elbow_back"
	var hand_key := "hand_front" if is_front else "hand_back"
	var shoulder: Vector2i = pose[shoulder_key]
	var elbow: Vector2i = pose[elbow_key]
	var hand: Vector2i = pose[hand_key]
	_stamp_line(skin_mask, shoulder, elbow, int(metrics["arm_thickness"]))
	_stamp_line(skin_mask, elbow, hand, int(metrics["arm_thickness"]))

	var top_style := PartLibrary.get_top(dna.top_style)
	var sleeve_cover := float(top_style["sleeve_cover"])
	var sleeve_end := _lerp_point(shoulder, elbow, clampf(sleeve_cover, 0.15, 1.0))
	_stamp_line(cloth_mask, shoulder, sleeve_end, int(metrics["arm_thickness"]) + 1)
	if sleeve_cover > 0.7:
		_stamp_line(cloth_mask, sleeve_end, _lerp_point(elbow, hand, 0.55), int(metrics["arm_thickness"]))

	_apply_shaded_mask_to_layer(layer, skin_mask, dna.skin_palette)
	_apply_shaded_mask_to_layer(layer, cloth_mask, dna.top_palette)

func _draw_torso_layer(layer: Image, dna: CharacterDNA, pose: Dictionary, metrics: Dictionary, torso_rect: Rect2i) -> void:
	var neck_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var top_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var bottom_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var top_style := PartLibrary.get_top(dna.top_style)
	var bottom_style := PartLibrary.get_bottom(dna.bottom_style)

	_stamp_rect(neck_mask, Rect2i(torso_rect.position + Vector2i(int(floor(torso_rect.size.x / 2.0)) - 1, -1), Vector2i(2, 2)))
	_stamp_torso_shape(top_mask, torso_rect, top_style, String(pose["direction"]))

	if bool(bottom_style["skirt"]):
		var skirt_rect := Rect2i(
			torso_rect.position + Vector2i(-1, torso_rect.size.y - 1),
			Vector2i(torso_rect.size.x + 2, 4)
		)
		_stamp_flared_shape(bottom_mask, skirt_rect, int(bottom_style["flare"]))
	else:
		var waist_rect := Rect2i(
			torso_rect.position + Vector2i(0, torso_rect.size.y - 2),
			Vector2i(torso_rect.size.x, 3)
		)
		_stamp_rect(bottom_mask, waist_rect)

	_apply_shaded_mask_to_layer(layer, neck_mask, dna.skin_palette)
	_apply_shaded_mask_to_layer(layer, top_mask, dna.top_palette)
	_apply_shaded_mask_to_layer(layer, bottom_mask, dna.bottom_palette)

func _draw_head_layer(layer: Image, dna: CharacterDNA, pose: Dictionary, metrics: Dictionary, head_rect: Rect2i) -> void:
	var head_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	_stamp_rounded_rect(head_mask, head_rect)
	var direction := String(pose["direction"])
	if direction == "left" or direction == "right":
		_stamp_pixel(head_mask, head_rect.position + Vector2i(head_rect.size.x - 1 if direction == "left" else 0, int(floor(head_rect.size.y / 2.0))))
	_apply_shaded_mask_to_layer(layer, head_mask, dna.skin_palette)
	_draw_face_details(layer, pose, head_rect)

func _draw_hair_layer(layer: Image, dna: CharacterDNA, pose: Dictionary, metrics: Dictionary, head_rect: Rect2i) -> void:
	var back_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var front_mask := _create_layer(Vector2i(layer.get_width(), layer.get_height()))
	var direction := String(pose["direction"])
	var mirror := direction == "right"
	var back_points := PartLibrary.get_back_hair_points(int(dna.hair_style.get("back", 0)), mirror)
	var front_points := PartLibrary.get_front_hair_points(int(dna.hair_style.get("front", 0)), mirror)
	var anchor := head_rect.position + Vector2i(int(floor(head_rect.size.x / 2.0)), 1)
	var hair_lag := int(pose["hair_lag"])
	for point in back_points:
		_stamp_pixel(back_mask, anchor + point + Vector2i(0, maxi(hair_lag, 0)))
	for point in front_points:
		var direction_offset := 1 if direction == "up" else 0
		_stamp_pixel(front_mask, anchor + point + Vector2i(0, direction_offset))
	if direction == "up":
		_stamp_rect(back_mask, Rect2i(head_rect.position + Vector2i(0, head_rect.size.y - 1), Vector2i(head_rect.size.x, 2)))
	_apply_shaded_mask_to_layer(layer, back_mask, dna.hair_palette)
	_apply_shaded_mask_to_layer(layer, front_mask, dna.hair_palette)

func _draw_clothing_detail_layer(layer: Image, dna: CharacterDNA, pose: Dictionary, metrics: Dictionary, torso_rect: Rect2i, head_rect: Rect2i) -> void:
	var top_style := PartLibrary.get_top(dna.top_style)
	var bottom_style := PartLibrary.get_bottom(dna.bottom_style)
	match String(top_style["detail"]):
		"collar":
			layer.fill_rect(Rect2i(torso_rect.position + Vector2i(int(floor(torso_rect.size.x / 2.0)) - 1, 0), Vector2i(2, 1)), dna.top_palette[2])
		"open_front":
			layer.fill_rect(Rect2i(torso_rect.position + Vector2i(int(floor(torso_rect.size.x / 2.0)), 1), Vector2i(1, torso_rect.size.y - 1)), dna.top_palette[2])
			layer.fill_rect(Rect2i(torso_rect.position + Vector2i(int(floor(torso_rect.size.x / 2.0)) - 2, 0), Vector2i(4, 1)), dna.top_palette[0])
		"hem_band":
			layer.fill_rect(Rect2i(torso_rect.position + Vector2i(0, torso_rect.size.y - 1), Vector2i(torso_rect.size.x, 1)), dna.top_palette[0])
		"pouch":
			layer.fill_rect(Rect2i(torso_rect.position + Vector2i(1, torso_rect.size.y - 3), Vector2i(maxi(2, torso_rect.size.x - 2), 2)), dna.top_palette[0])

	if bool(bottom_style["skirt"]):
		layer.fill_rect(Rect2i(torso_rect.position + Vector2i(1, torso_rect.size.y + 1), Vector2i(maxi(2, torso_rect.size.x - 2), 1)), dna.bottom_palette[0])
		for x in range(torso_rect.position.x + 1, torso_rect.position.x + torso_rect.size.x - 1, 2):
			_stamp_pixel(layer, Vector2i(x, torso_rect.end.y + 1), dna.bottom_palette[2])
	else:
		layer.fill_rect(Rect2i(torso_rect.position + Vector2i(0, torso_rect.size.y - 2), Vector2i(torso_rect.size.x, 1)), dna.bottom_palette[2])

	if String(pose["direction"]) == "up":
		layer.fill_rect(Rect2i(head_rect.position + Vector2i(1, head_rect.size.y - 1), Vector2i(maxi(2, head_rect.size.x - 2), 1)), dna.hair_palette[2])

func _draw_accessory_layer(layer: Image, dna: CharacterDNA, pose: Dictionary, metrics: Dictionary, torso_rect: Rect2i, head_rect: Rect2i) -> void:
	var direction := String(pose["direction"])
	for accessory in PartLibrary.get_accessory_definitions(dna.accessory_flags):
		match String(accessory["type"]):
			"scarf":
				layer.fill_rect(Rect2i(torso_rect.position + Vector2i(-1, 0), Vector2i(torso_rect.size.x + 2, 2)), dna.accessory_palette[1])
				layer.fill_rect(Rect2i(torso_rect.position + Vector2i(-1 if direction == "left" else torso_rect.size.x - 1, 2), Vector2i(2, 4)), dna.accessory_palette[2])
			"satchel":
				var strap_from := torso_rect.position + Vector2i(1 if direction != "right" else torso_rect.size.x - 2, 1)
				var strap_to := torso_rect.position + Vector2i(torso_rect.size.x - 2 if direction != "right" else 1, torso_rect.size.y + 2)
				_draw_direct_line(layer, strap_from, strap_to, dna.accessory_palette[2])
				layer.fill_rect(Rect2i(torso_rect.position + Vector2i(-2 if direction == "left" else torso_rect.size.x, torso_rect.size.y - 1), Vector2i(3, 4)), dna.accessory_palette[1])
			"clip":
				var clip_x := head_rect.position.x + (1 if direction != "right" else head_rect.size.x - 3)
				layer.fill_rect(Rect2i(Vector2i(clip_x, head_rect.position.y + 1), Vector2i(2, 2)), dna.accessory_palette[0])
				_stamp_pixel(layer, Vector2i(clip_x + (0 if direction == "right" else 2), head_rect.position.y + 2), dna.accessory_palette[1])

func _draw_face_details(layer: Image, pose: Dictionary, head_rect: Rect2i) -> void:
	match String(pose["direction"]):
		"down":
			_stamp_pixel(layer, head_rect.position + Vector2i(2, int(floor(head_rect.size.y / 2.0))), EYE_COLOR)
			_stamp_pixel(layer, head_rect.position + Vector2i(head_rect.size.x - 3, int(floor(head_rect.size.y / 2.0))), EYE_COLOR)
		"left":
			_stamp_pixel(layer, head_rect.position + Vector2i(2, int(floor(head_rect.size.y / 2.0))), EYE_COLOR)
		"right":
			_stamp_pixel(layer, head_rect.position + Vector2i(head_rect.size.x - 3, int(floor(head_rect.size.y / 2.0))), EYE_COLOR)

func _apply_outline(image: Image, outline_color: Color) -> void:
	var outline := _create_layer(Vector2i(image.get_width(), image.get_height()))
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				continue
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if ox == 0 and oy == 0:
						continue
					var nx := x + ox
					var ny := y + oy
					if nx < 0 or ny < 0 or nx >= image.get_width() or ny >= image.get_height():
						continue
					if image.get_pixel(nx, ny).a > 0.0:
						outline.set_pixel(x, y, outline_color)
						ox = 2
						oy = 2
	_blit_opaque(image, outline, true)

func _apply_shaded_mask_to_layer(layer: Image, mask: Image, palette: Array[Color]) -> void:
	var shaded := _shade_mask(mask, palette)
	_blit_opaque(layer, shaded)

func _shade_mask(mask: Image, palette: Array[Color]) -> Image:
	var shaded := _create_layer(Vector2i(mask.get_width(), mask.get_height()))
	var bounds := _opaque_bounds(mask)
	if bounds.size == Vector2i.ZERO:
		return shaded
	var light_y := bounds.position.y + int(floor(bounds.size.y * 0.33))
	var shadow_y := bounds.position.y + int(floor(bounds.size.y * 0.66))
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			if mask.get_pixel(x, y).a <= 0.0:
				continue
			var tone := 1
			var up := _is_opaque(mask, x, y - 1)
			var down := _is_opaque(mask, x, y + 1)
			var left := _is_opaque(mask, x - 1, y)
			var right := _is_opaque(mask, x + 1, y)
			if not up or (y <= light_y and not left):
				tone = 0
			elif not down or not right or y >= shadow_y:
				tone = min(2, palette.size() - 1)
			shaded.set_pixel(x, y, palette[min(tone, palette.size() - 1)])
	return shaded

func _stamp_torso_shape(mask: Image, torso_rect: Rect2i, top_style: Dictionary, direction: String) -> void:
	var shape: Array = top_style["body_shape"]
	for row in range(torso_rect.size.y):
		var sample := int(shape[min(row, shape.size() - 1)])
		var row_expand := sample
		if direction == "left" or direction == "right":
			row_expand = maxi(0, row_expand - 1)
		var width := torso_rect.size.x + row_expand * 2
		var start_x := torso_rect.position.x - row_expand
		mask.fill_rect(Rect2i(Vector2i(start_x, torso_rect.position.y + row), Vector2i(width, 1)), OPAQUE_WHITE)

func _stamp_flared_shape(mask: Image, base_rect: Rect2i, flare: int) -> void:
	for row in range(base_rect.size.y):
		var expand := maxi(0, flare - int(floor(row / 2.0)))
		mask.fill_rect(
			Rect2i(
				Vector2i(base_rect.position.x - expand, base_rect.position.y + row),
				Vector2i(base_rect.size.x + expand * 2, 1)
			),
			OPAQUE_WHITE
		)

func _stamp_rounded_rect(mask: Image, rect: Rect2i) -> void:
	mask.fill_rect(rect, OPAQUE_WHITE)
	_clear_pixel(mask, rect.position)
	_clear_pixel(mask, rect.position + Vector2i(rect.size.x - 1, 0))
	_clear_pixel(mask, rect.position + Vector2i(0, rect.size.y - 1))
	_clear_pixel(mask, rect.position + Vector2i(rect.size.x - 1, rect.size.y - 1))

func _stamp_rect(mask: Image, rect: Rect2i) -> void:
	var safe := _clip_rect(rect, Vector2i(mask.get_width(), mask.get_height()))
	if safe.size.x > 0 and safe.size.y > 0:
		mask.fill_rect(safe, OPAQUE_WHITE)

func _stamp_pixel(image: Image, position: Vector2i, color: Color = OPAQUE_WHITE) -> void:
	if position.x < 0 or position.y < 0 or position.x >= image.get_width() or position.y >= image.get_height():
		return
	image.set_pixel(position.x, position.y, color)

func _clear_pixel(image: Image, position: Vector2i) -> void:
	if position.x < 0 or position.y < 0 or position.x >= image.get_width() or position.y >= image.get_height():
		return
	image.set_pixel(position.x, position.y, TRANSPARENT)

func _stamp_line(mask: Image, from_point: Vector2i, to_point: Vector2i, thickness: int) -> void:
	for point in _line_points(from_point, to_point):
		_stamp_brush(mask, point, thickness)

func _draw_direct_line(image: Image, from_point: Vector2i, to_point: Vector2i, color: Color) -> void:
	for point in _line_points(from_point, to_point):
		_stamp_pixel(image, point, color)

func _stamp_brush(mask: Image, center: Vector2i, thickness: int) -> void:
	var half := int(floor(thickness / 2.0))
	for y in range(center.y - half, center.y - half + thickness):
		for x in range(center.x - half, center.x - half + thickness):
			_stamp_pixel(mask, Vector2i(x, y))

func _line_points(from_point: Vector2i, to_point: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0: int = from_point.x
	var y0: int = from_point.y
	var x1: int = to_point.x
	var y1: int = to_point.y
	var dx: int = absi(x1 - x0)
	var sx: int = 1 if x0 < x1 else -1
	var dy: int = -absi(y1 - y0)
	var sy: int = 1 if y0 < y1 else -1
	var error: int = dx + dy
	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var twice_error: int = error * 2
		if twice_error >= dy:
			error += dy
			x0 += sx
		if twice_error <= dx:
			error += dx
			y0 += sy
	return points

func _create_layer(size: Vector2i) -> Image:
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	return image

func _blit_opaque(destination: Image, source: Image, only_empty: bool = false) -> void:
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var color := source.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			if only_empty and destination.get_pixel(x, y).a > 0.0:
				continue
			destination.set_pixel(x, y, color)

func _opaque_bounds(mask: Image) -> Rect2i:
	var min_x := mask.get_width()
	var min_y := mask.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(mask.get_height()):
		for x in range(mask.get_width()):
			if mask.get_pixel(x, y).a <= 0.0:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))

func _clip_rect(rect: Rect2i, size: Vector2i) -> Rect2i:
	var start := Vector2i(clampi(rect.position.x, 0, size.x), clampi(rect.position.y, 0, size.y))
	var end := Vector2i(clampi(rect.end.x, 0, size.x), clampi(rect.end.y, 0, size.y))
	return Rect2i(start, end - start)

func _is_opaque(mask: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= mask.get_width() or y >= mask.get_height():
		return false
	return mask.get_pixel(x, y).a > 0.0

func _lerp_point(a: Vector2i, b: Vector2i, weight: float) -> Vector2i:
	return Vector2i(
		int(round(lerpf(a.x, b.x, weight))),
		int(round(lerpf(a.y, b.y, weight)))
	)

func _get_leg_hip_anchor(pose: Dictionary, is_front: bool) -> Vector2i:
	var direction := String(pose["direction"])
	var pelvis: Vector2i = pose["pelvis"]
	match direction:
		"left":
			return pelvis + (Vector2i(-1, 0) if is_front else Vector2i(1, 0))
		"right":
			return pelvis + (Vector2i(1, 0) if is_front else Vector2i(-1, 0))
		"up":
			return pelvis + (Vector2i(-2, 0) if is_front else Vector2i(2, 0))
		_:
			return pelvis + (Vector2i(2, 0) if is_front else Vector2i(-2, 0))

func _foot_direction(direction: String, is_front: bool) -> Vector2i:
	match direction:
		"left":
			return Vector2i(-2, 0 if is_front else 1)
		"right":
			return Vector2i(2, 0 if is_front else 1)
		"up":
			return Vector2i(0 if is_front else 1, -1)
		_:
			return Vector2i(0 if is_front else 1, 1)
