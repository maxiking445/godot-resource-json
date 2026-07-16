extends RefCounted


static var VALUE_ENCODERS := [
	preload("res://addons/resource2JSON/encoder/ResourceReferenceEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/NonFiniteFloatEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/ColorEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Vector2Encoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Vector2iEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Rect2Encoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Rect2iEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Vector3Encoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Vector3iEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Transform2DEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Vector4Encoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Vector4iEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/PlaneEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/QuaternionEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/AABBEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/BasisEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/Transform3DEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/ProjectionEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/NodePathEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/ArrayEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/DictionaryEncoder.gd").new(),
	preload("res://addons/resource2JSON/encoder/StringEncoder.gd").new(),
]


static func convert(resource: Resource, indent: String = "\t") -> String:
	if resource == null:
		push_error("Cannot convert a null Resource to JSON.")
		return ""

	var context := {
		"resource_ids": {},
		"next_id": 1,
	}
	return JSON.stringify(_encode_resource(resource, context), indent)


static func _encode_value(value: Variant, context: Dictionary) -> Variant:
	if value == null or value is bool or value is int:
		return value
	if value is float:
		if is_finite(value):
			return value
	if _is_packed_array(value):
		var encoded_items: Array = []
		for item in value:
			encoded_items.append(_encode_value(item, context))
		return encoded_items
	for encoder in VALUE_ENCODERS:
		if encoder.can_encode(value, context):
			return encoder.encode(value, context, _encode_value)
	if value is Resource:
		return _encode_resource(value, context)

	return var_to_str(value)


static func _is_packed_array(value: Variant) -> bool:
	var value_type := typeof(value)
	return value_type >= TYPE_PACKED_BYTE_ARRAY and value_type <= TYPE_PACKED_VECTOR4_ARRAY


static func _encode_resource(resource: Resource, context: Dictionary) -> Variant:
	var instance_id := resource.get_instance_id()
	var known_ids: Dictionary = context.resource_ids
	var resource_id: int = context.next_id
	context.next_id = resource_id + 1
	known_ids[instance_id] = resource_id

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

	return properties
