extends RefCounted


const RESOURCE_REFERENCE_KEY := "$ref"
const STRING_NAME_KEY := "$stringName"
const INTEGER_KEY := "$integer"
const FLOAT_KEY := "$float"
const ARRAY_KEY := "$array"
const DICTIONARY_KEY := "$dictionary"
const VARIANT_KEY := "$variant"
const TYPE_KEY := "$type"


static func convert(resource: Resource, indent: String = "\t") -> String:
	if resource == null:
		push_error("Cannot convert a null Resource to JSON.")
		return ""

	var context := {
		"resource_ids": {},
		"next_id": 1,
	}
	return JSON.stringify(_encode_value(resource, context), indent)


static func _encode_value(value: Variant, context: Dictionary) -> Variant:
	if value == null or value is bool or value is String:
		return value
	if value is int:
		return {INTEGER_KEY: str(value)}
	if value is float:
		return {FLOAT_KEY: var_to_str(value)}
	if value is StringName:
		return {STRING_NAME_KEY: str(value)}
	if value is Resource:
		return _encode_resource(value, context)
	if value is Array:
		var encoded_items: Array = []
		for item in value:
			encoded_items.append(_encode_value(item, context))
		if value.is_typed():
			return {
				ARRAY_KEY: encoded_items,
				TYPE_KEY: _encode_type(
					value.get_typed_builtin(),
					value.get_typed_class_name(),
					value.get_typed_script()
				),
			}
		return encoded_items
	if value is Dictionary:
		var encoded_entries: Array = []
		for key in value:
			encoded_entries.append({
				"key": _encode_value(key, context),
				"value": _encode_value(value[key], context),
			})
		var encoded_dictionary := {DICTIONARY_KEY: encoded_entries}
		if value.is_typed():
			encoded_dictionary[TYPE_KEY] = {
				"key": _encode_type(
					value.get_typed_key_builtin(),
					value.get_typed_key_class_name(),
					value.get_typed_key_script()
				),
				"value": _encode_type(
					value.get_typed_value_builtin(),
					value.get_typed_value_class_name(),
					value.get_typed_value_script()
				),
			}
		return encoded_dictionary

	return {VARIANT_KEY: var_to_str(value)}


static func _encode_type(
	variant_type: int,
	typed_class_name: StringName,
	typed_script: Variant
) -> Dictionary:
	var script_path := ""
	if typed_script is Script:
		script_path = typed_script.resource_path
	return {
		"builtin": variant_type,
		"class": str(typed_class_name),
		"script": script_path,
	}


static func _encode_resource(resource: Resource, context: Dictionary) -> Dictionary:
	var instance_id := resource.get_instance_id()
	var known_ids: Dictionary = context.resource_ids
	if known_ids.has(instance_id):
		return {RESOURCE_REFERENCE_KEY: known_ids[instance_id]}

	var resource_id: int = context.next_id
	context.next_id = resource_id + 1
	known_ids[instance_id] = resource_id

	var script_path := ""
	var script := resource.get_script() as Script
	if script != null:
		script_path = script.resource_path

	var properties := {}
	for property in resource.get_property_list():
		var property_name := String(property.name)
		var usage: int = property.usage
		if not usage & PROPERTY_USAGE_STORAGE:
			continue
		if property_name == "script":
			continue
		if property_name == "resource_name" and resource.resource_name.is_empty():
			continue
		if property_name == "resource_local_to_scene" and not resource.resource_local_to_scene:
			continue
		properties[property_name] = _encode_value(resource.get(property_name), context)

	var encoded_resource := {
		"id": resource_id,
		"script": script_path,
		"properties": properties,
	}
	if script_path.is_empty():
		encoded_resource["class"] = resource.get_class()
	return encoded_resource
