extends RefCounted


const RESOURCE_REFERENCE_KEY := "$ref"
const STRING_NAME_KEY := "$stringName"
const DICTIONARY_KEY := "$dictionary"
const VARIANT_KEY := "$variant"


static func convert(json: String) -> Resource:
	var parser := JSON.new()
	var error := parser.parse(json)
	if error != OK:
		push_error(
			"Invalid JSON at line %d: %s"
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return null

	var context := {"resources": {}}
	_register_resources(parser.data, context)
	var result: Variant = _decode_value(parser.data, context)
	if result == null or not result is Resource:
		push_error("The JSON root does not describe a Resource.")
		return null

	return result as Resource


static func _decode_value(value: Variant, context: Dictionary) -> Variant:
	if value is Array:
		var decoded_array: Array = []
		for item in value:
			decoded_array.append(_decode_value(item, context))
		return decoded_array
	if not value is Dictionary:
		return value
	if value.has(RESOURCE_REFERENCE_KEY):
		return context.resources.get(int(value.get(RESOURCE_REFERENCE_KEY, 0)))
	if value.has("properties") and (value.has("script") or value.has("class")):
		return _decode_resource(value, context)
	if value.has(STRING_NAME_KEY):
		return StringName(value.get(STRING_NAME_KEY, ""))
	if value.has(DICTIONARY_KEY):
		var decoded_dictionary := {}
		for entry in value.get(DICTIONARY_KEY, []):
			var key: Variant = _decode_value(entry.get("key"), context)
			decoded_dictionary[key] = _decode_value(entry.get("value"), context)
		return decoded_dictionary
	if value.has(VARIANT_KEY):
		return str_to_var(value.get(VARIANT_KEY, ""))

	var decoded_dictionary := {}
	for key in value:
		decoded_dictionary[key] = _decode_value(value[key], context)
	return decoded_dictionary


static func _decode_resource(data: Dictionary, context: Dictionary) -> Resource:
	var resource_id := int(data.get("id", 0))
	var resource := context.resources.get(resource_id) as Resource
	if resource == null:
		resource = _create_resource(data)
	if resource == null:
		return null

	if resource_id > 0:
		context.resources[resource_id] = resource

	var properties: Dictionary = data.get("properties", {})
	for property_name in properties:
		var decoded_value: Variant = _decode_value(properties[property_name], context)
		var current_value: Variant = resource.get(property_name)
		if current_value is Array and decoded_value is Array:
			current_value.assign(decoded_value)
			decoded_value = current_value
		elif current_value is Dictionary and decoded_value is Dictionary:
			current_value.assign(decoded_value)
			decoded_value = current_value
		resource.set(property_name, decoded_value)
	return resource


static func _register_resources(value: Variant, context: Dictionary) -> void:
	if value is Array:
		for item in value:
			_register_resources(item, context)
		return
	if not value is Dictionary:
		return

	if value.has("properties") and (value.has("script") or value.has("class")):
		var resource_id := int(value.get("id", 0))
		if resource_id > 0 and not context.resources.has(resource_id):
			var resource := _create_resource(value)
			if resource != null:
				context.resources[resource_id] = resource

	for child in value.values():
		_register_resources(child, context)


static func _create_resource(data: Dictionary) -> Resource:
	var script_path := String(data.get("script", ""))
	if not script_path.is_empty():
		var script := load(script_path) as Script
		if script == null:
			push_error("Could not load Resource script: %s" % script_path)
			return null
		var scripted_resource: Variant = script.new()
		if scripted_resource is Resource:
			return scripted_resource
		push_error("Script does not create a Resource: %s" % script_path)
		return null

	var native_class_name := StringName(data.get("class", "Resource"))
	if ClassDB.class_exists(native_class_name) and ClassDB.can_instantiate(native_class_name):
		var instance: Variant = ClassDB.instantiate(native_class_name)
		if instance is Resource:
			return instance

	return Resource.new()
