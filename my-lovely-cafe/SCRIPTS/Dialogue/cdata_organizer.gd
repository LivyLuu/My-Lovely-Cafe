extends Node
class_name CDataOrganizer

static func get_property(property_name: StringName) -> Dictionary:
	var ids := PackedStringArray()
	for character in Characters.characters:
		if character:
			ids.append(character.display_name)
	return {
		"name": property_name,
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(ids),
		"usage": PROPERTY_USAGE_DEFAULT,
	}
