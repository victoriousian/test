extends RefCounted
class_name PoseSolver

const CENTER := Vector2i(16, 16)

const IDLE_BOB := [0, 1, 0, 1]
const IDLE_HEAD_BOB := [0, 0, -1, 0]
const IDLE_ARM_SWING := [0, 0, 1, 0]
const IDLE_LEG_SWING := [0, 0, 0, 0]
const IDLE_HAIR_LAG := [0, 0, 1, 0]

const WALK_BOB := [0, 1, 0, 0, 1, 0]
const WALK_HEAD_BOB := [0, 0, -1, 0, 0, -1]
const WALK_ARM_SWING := [-1, -1, 0, 1, 1, 0]
const WALK_LEG_SWING := [1, 1, 0, -1, -1, 0]
const WALK_HAIR_LAG := [0, 1, 1, 0, -1, 0]
const WALK_FOOT_LIFT := [0, 1, 0, 0, 1, 0]

func solve_pose(animation_name: String, direction: String, frame_index: int, total_frames: int, time_phase: float = 0.0) -> Dictionary:
	var phase_offset := int(floor(time_phase * max(total_frames, 1)))
	var resolved_index := posmod(frame_index + phase_offset, max(total_frames, 1))
	var bob_values := WALK_BOB if animation_name == "walk" else IDLE_BOB
	var head_values := WALK_HEAD_BOB if animation_name == "walk" else IDLE_HEAD_BOB
	var arm_values := WALK_ARM_SWING if animation_name == "walk" else IDLE_ARM_SWING
	var leg_values := WALK_LEG_SWING if animation_name == "walk" else IDLE_LEG_SWING
	var hair_values := WALK_HAIR_LAG if animation_name == "walk" else IDLE_HAIR_LAG
	var foot_lift_values := WALK_FOOT_LIFT if animation_name == "walk" else IDLE_LEG_SWING

	var bob := int(bob_values[resolved_index % bob_values.size()])
	var head_bob := int(head_values[resolved_index % head_values.size()])
	var arm_swing := int(arm_values[resolved_index % arm_values.size()])
	var leg_swing := int(leg_values[resolved_index % leg_values.size()])
	var hair_lag := int(hair_values[resolved_index % hair_values.size()])
	var foot_lift := int(foot_lift_values[resolved_index % foot_lift_values.size()])

	var pose := {
		"animation_name": animation_name,
		"direction": direction,
		"frame_index": resolved_index,
		"total_frames": total_frames,
		"bob": bob,
		"head_bob": head_bob,
		"arm_swing": arm_swing,
		"leg_swing": leg_swing,
		"hair_lag": hair_lag,
		"foot_lift": foot_lift,
		"head": Vector2i.ZERO,
		"torso": Vector2i.ZERO,
		"pelvis": Vector2i.ZERO,
		"shoulder_back": Vector2i.ZERO,
		"elbow_back": Vector2i.ZERO,
		"hand_back": Vector2i.ZERO,
		"shoulder_front": Vector2i.ZERO,
		"elbow_front": Vector2i.ZERO,
		"hand_front": Vector2i.ZERO,
		"knee_back": Vector2i.ZERO,
		"ankle_back": Vector2i.ZERO,
		"knee_front": Vector2i.ZERO,
		"ankle_front": Vector2i.ZERO
	}

	match direction:
		"up":
			_fill_up_pose(pose, bob, head_bob, arm_swing, leg_swing, foot_lift)
		"left":
			_fill_side_pose(pose, -1, bob, head_bob, arm_swing, leg_swing, foot_lift)
		"right":
			_fill_side_pose(pose, 1, bob, head_bob, arm_swing, leg_swing, foot_lift)
		_:
			_fill_down_pose(pose, bob, head_bob, arm_swing, leg_swing, foot_lift)

	return pose

func _fill_down_pose(pose: Dictionary, bob: int, head_bob: int, arm_swing: int, leg_swing: int, foot_lift: int) -> void:
	var torso := CENTER + Vector2i(0, bob)
	var pelvis := CENTER + Vector2i(0, 5 + bob)
	pose["torso"] = torso
	pose["pelvis"] = pelvis
	pose["head"] = CENTER + Vector2i(0, -6 + head_bob)
	pose["shoulder_back"] = torso + Vector2i(-4, -2)
	pose["shoulder_front"] = torso + Vector2i(4, -2)
	pose["elbow_back"] = torso + Vector2i(-4 - arm_swing, 1)
	pose["elbow_front"] = torso + Vector2i(4 + arm_swing, 1)
	pose["hand_back"] = torso + Vector2i(-4 - arm_swing, 5 + maxi(0, -arm_swing))
	pose["hand_front"] = torso + Vector2i(4 + arm_swing, 5 + maxi(0, arm_swing))
	pose["knee_back"] = pelvis + Vector2i(-2 - leg_swing, 4)
	pose["knee_front"] = pelvis + Vector2i(2 + leg_swing, 4)
	pose["ankle_back"] = pelvis + Vector2i(-2 - leg_swing, 9 + maxi(0, -leg_swing) - foot_lift)
	pose["ankle_front"] = pelvis + Vector2i(2 + leg_swing, 9 + maxi(0, leg_swing) - foot_lift)

func _fill_up_pose(pose: Dictionary, bob: int, head_bob: int, arm_swing: int, leg_swing: int, foot_lift: int) -> void:
	var torso := CENTER + Vector2i(0, bob)
	var pelvis := CENTER + Vector2i(0, 5 + bob)
	pose["torso"] = torso
	pose["pelvis"] = pelvis
	pose["head"] = CENTER + Vector2i(0, -6 + head_bob)
	pose["shoulder_back"] = torso + Vector2i(4, -2)
	pose["shoulder_front"] = torso + Vector2i(-4, -2)
	pose["elbow_back"] = torso + Vector2i(4 + arm_swing, 1)
	pose["elbow_front"] = torso + Vector2i(-4 - arm_swing, 1)
	pose["hand_back"] = torso + Vector2i(4 + arm_swing, 5 + maxi(0, arm_swing))
	pose["hand_front"] = torso + Vector2i(-4 - arm_swing, 5 + maxi(0, -arm_swing))
	pose["knee_back"] = pelvis + Vector2i(2 + leg_swing, 4)
	pose["knee_front"] = pelvis + Vector2i(-2 - leg_swing, 4)
	pose["ankle_back"] = pelvis + Vector2i(2 + leg_swing, 9 + maxi(0, leg_swing) - foot_lift)
	pose["ankle_front"] = pelvis + Vector2i(-2 - leg_swing, 9 + maxi(0, -leg_swing) - foot_lift)

func _fill_side_pose(pose: Dictionary, facing_sign: int, bob: int, head_bob: int, arm_swing: int, leg_swing: int, foot_lift: int) -> void:
	var torso := CENTER + Vector2i(0, bob)
	var pelvis := CENTER + Vector2i(0, 5 + bob)
	pose["torso"] = torso
	pose["pelvis"] = pelvis
	pose["head"] = CENTER + Vector2i(facing_sign, -6 + head_bob)
	pose["shoulder_back"] = torso + Vector2i(1, -2)
	pose["shoulder_front"] = torso + Vector2i(-1, -1)
	pose["elbow_back"] = torso + Vector2i(1 + facing_sign * arm_swing, 1)
	pose["elbow_front"] = torso + Vector2i(-1 - facing_sign * arm_swing, 2)
	pose["hand_back"] = torso + Vector2i(2 + facing_sign * arm_swing, 5 + maxi(0, facing_sign * arm_swing))
	pose["hand_front"] = torso + Vector2i(-2 - facing_sign * arm_swing, 5 + maxi(0, -facing_sign * arm_swing))
	pose["knee_back"] = pelvis + Vector2i(1 + facing_sign * leg_swing, 4)
	pose["knee_front"] = pelvis + Vector2i(-1 - facing_sign * leg_swing, 4)
	pose["ankle_back"] = pelvis + Vector2i(2 + facing_sign * leg_swing, 9 - foot_lift + maxi(0, facing_sign * leg_swing))
	pose["ankle_front"] = pelvis + Vector2i(-2 - facing_sign * leg_swing, 9 - foot_lift + maxi(0, -facing_sign * leg_swing))
