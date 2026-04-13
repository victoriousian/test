extends RefCounted
class_name CharacterArchetypeLibrary

const ARCHETYPE_IDS: Array[String] = [
	"traveler",
	"guardian",
	"courier"
]

const ARCHETYPE_LABELS := {
	"traveler": "Traveler",
	"guardian": "Guardian",
	"courier": "Courier"
}

static func get_ids() -> Array[String]:
	return ARCHETYPE_IDS.duplicate()

static func get_display_name(archetype_id: String) -> String:
	return String(ARCHETYPE_LABELS.get(archetype_id, archetype_id.capitalize()))

static func make_dna(archetype_id: String) -> CharacterDNA:
	var dna := CharacterDNA.new()
	match archetype_id:
		"guardian":
			dna.seed = 1202
			dna.body_type = "broad"
			dna.skin_palette = CharacterDNA.get_skin_palette_preset(2)
			dna.hair_style = {"front": 0, "back": 3}
			dna.hair_palette = CharacterDNA.get_hair_palette_preset(1)
			dna.top_style = 1
			dna.top_palette = CharacterDNA.get_top_palette_preset(2)
			dna.bottom_style = 1
			dna.bottom_palette = CharacterDNA.get_bottom_palette_preset(0)
			dna.accessory_flags = PartLibrary.ACCESSORY_SCARF
			dna.accessory_palette = CharacterDNA.get_accessory_palette_preset(0)
			dna.height_bias = 1
			dna.width_bias = 1
		"courier":
			dna.seed = 1203
			dna.body_type = "slim"
			dna.skin_palette = CharacterDNA.get_skin_palette_preset(1)
			dna.hair_style = {"front": 1, "back": 2}
			dna.hair_palette = CharacterDNA.get_hair_palette_preset(4)
			dna.top_style = 3
			dna.top_palette = CharacterDNA.get_top_palette_preset(0)
			dna.bottom_style = 0
			dna.bottom_palette = CharacterDNA.get_bottom_palette_preset(2)
			dna.accessory_flags = PartLibrary.ACCESSORY_SATCHEL | PartLibrary.ACCESSORY_CLIP
			dna.accessory_palette = CharacterDNA.get_accessory_palette_preset(2)
			dna.height_bias = 0
			dna.width_bias = -1
		_:
			dna.seed = 1201
			dna.body_type = "average"
			dna.skin_palette = CharacterDNA.get_skin_palette_preset(0)
			dna.hair_style = {"front": 5, "back": 1}
			dna.hair_palette = CharacterDNA.get_hair_palette_preset(1)
			dna.top_style = 0
			dna.top_palette = CharacterDNA.get_top_palette_preset(1)
			dna.bottom_style = 1
			dna.bottom_palette = CharacterDNA.get_bottom_palette_preset(3)
			dna.accessory_flags = PartLibrary.ACCESSORY_SATCHEL
			dna.accessory_palette = CharacterDNA.get_accessory_palette_preset(0)
			dna.height_bias = 0
			dna.width_bias = 0
	return dna

static func make_dictionary(archetype_id: String) -> Dictionary:
	return make_dna(archetype_id).to_dictionary()
