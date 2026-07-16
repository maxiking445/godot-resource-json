extends RefCounted


static var VALUE_DECODERS := [
	preload("res://addons/resource2JSON/decoder/ResourceReferenceDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/NonFiniteFloatDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/ColorDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Vector2Decoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Vector2iDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Rect2Decoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Rect2iDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Vector3Decoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Vector3iDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Transform2DDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Vector4Decoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Vector4iDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/PlaneDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/QuaternionDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/AABBDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/BasisDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/Transform3DDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/ProjectionDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/NodePathDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/ArrayDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/DictionaryDecoder.gd").new(),
	preload("res://addons/resource2JSON/decoder/StringDecoder.gd").new(),
]


static func convert(json: String, resource_type: Variant) -> Resource:
	var parser := JSON.new()
	var error := parser.parse(json)
	if error != OK:
		push_error(
			"Invalid JSON at line %d: %s"
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return null

	if not parser.data is Dictionary:
		push_error("The JSON root must be an object.")
		return null

	var result := _create_target_resource(resource_type)
	if result == null:
		return null
	var context := {"resources": {}, "next_resource_id": 1}
	_decode_into_resource(parser.data, result, context)
	return result


static func _decode_value(value: Variant, context: Dictionary) -> Variant:
	for decoder in VALUE_DECODERS:
		if decoder.can_decode(value, context):
			return decoder.decode(value, context, _decode_value)
	return value


static func _decode_into_resource(
	properties: Dictionary,
	resource: Resource,
	context: Dictionary
) -> void:
	var resource_id: int = context.next_resource_id
	context.next_resource_id = resource_id + 1
	context.resources[resource_id] = resource

	for property_name in properties:
		var raw_value: Variant = properties[property_name]
		var current_value: Variant = resource.get(property_name)
		var property_info := _find_property(resource, property_name)
		var decoded_value: Variant
		if raw_value is Dictionary and int(property_info.get("type", TYPE_NIL)) == TYPE_OBJECT:
			var nested := _create_native_resource(StringName(property_info.get("class_name", "Resource")))
			_decode_into_resource(raw_value, nested, context)
			decoded_value = nested
		else:
			decoded_value = _decode_value(raw_value, context)
		if current_value is Array and decoded_value is Array:
			current_value.assign(decoded_value)
			decoded_value = current_value
		elif current_value is Dictionary and decoded_value is Dictionary:
			current_value.assign(decoded_value)
			decoded_value = current_value
		elif _is_packed_array(current_value) and decoded_value is Array:
			decoded_value = _convert_packed_array(decoded_value, typeof(current_value))
		resource.set(property_name, decoded_value)


static func _find_property(resource: Resource, property_name: String) -> Dictionary:
	for property in resource.get_property_list():
		if String(property.name) == property_name:
			return property
	return {}


static func _is_packed_array(value: Variant) -> bool:
	var value_type := typeof(value)
	return value_type >= TYPE_PACKED_BYTE_ARRAY and value_type <= TYPE_PACKED_VECTOR4_ARRAY


static func _convert_packed_array(value: Array, target_type: int) -> Variant:
	if target_type == TYPE_PACKED_COLOR_ARRAY:
		var colors := PackedColorArray()
		for item in value:
			if item is Array and item.size() == 4:
				colors.append(Color(
					float(item[0]), float(item[1]), float(item[2]), float(item[3])
				))
			elif item is Color:
				colors.append(item)
		return colors
	return type_convert(value, target_type)


static func _create_target_resource(resource_type: Variant) -> Resource:
	if resource_type is Script:
		var instance: Variant = resource_type.new()
		if instance is Resource:
			return instance
		push_error("The provided script does not create a Resource.")
		return null
	if resource_type is String or resource_type is StringName:
		return _create_native_resource(StringName(resource_type))
	push_error("A Resource script or native class name must be provided.")
	return null


static func _create_native_resource(native_class_name: StringName) -> Resource:
	if ClassDB.class_exists(native_class_name) and ClassDB.can_instantiate(native_class_name):
		var instance: Variant = ClassDB.instantiate(native_class_name)
		if instance is Resource:
			return instance

	return Resource.new()
