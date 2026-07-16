extends GutTest


const Converter := preload("res://addons/resource2JSON/JsonConverter.gd")
const ConverterTestResource := preload("res://tests/fixtures/converter_test_resource.gd")


func _print_json_result(test_name: String, json: String) -> void:
	print("\n[%s] JSON result:\n%s\n" % [test_name, json])


func _stored_script_property_names(resource: Resource) -> Array[String]:
	var names: Array[String] = []
	for property in resource.get_property_list():
		var usage: int = property.usage
		if usage & PROPERTY_USAGE_STORAGE and usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(String(property.name))
	names.sort()
	return names


func test_resource_to_json_produces_valid_json() -> void:
	var source := ConverterTestResource.new()
	source.title = "JSON example"
	source.count = 42

	var json := Converter.stringify(source)
	_print_json_result("resource_to_json", json)
	var parsed: Variant = JSON.parse_string(json)

	assert_not_null(parsed)
	assert_true(parsed is Dictionary)
	assert_eq(parsed.title, "JSON example")
	assert_eq(parsed.count, 42.0)
	assert_true(parsed.tags is Array)
	assert_true(parsed.settings is Dictionary)
	assert_false(parsed.has("script"))
	assert_false(parsed.has("class"))
	assert_false(json.contains("res://"))


func test_resource_to_json_excludes_internal_resource_fields_and_metadata() -> void:
	var source := ConverterTestResource.new()
	source.title = "Only script data"
	source.resource_name = "Internal resource name"
	source.resource_local_to_scene = true
	source.set_meta("author", "Must not be serialized")

	var parsed: Dictionary = JSON.parse_string(Converter.stringify(source))

	assert_eq(parsed.title, "Only script data")
	assert_false(parsed.has("script"))
	assert_false(parsed.has("resource_name"))
	assert_false(parsed.has("resource_local_to_scene"))
	assert_false(parsed.has("metadata/author"))


func test_json_contains_every_stored_script_property() -> void:
	var source := ConverterTestResource.new()
	var parsed: Dictionary = JSON.parse_string(Converter.stringify(source))
	var actual_keys: Array = parsed.keys()
	actual_keys.sort()

	assert_eq(actual_keys, _stored_script_property_names(source))
	assert_eq(parsed.size(), _stored_script_property_names(source).size())


func test_json_contains_complete_populated_resource_data() -> void:
	var source := ConverterTestResource.new()
	source.title = "Complete JSON"
	source.count = 99
	source.tags = ["alpha", "beta"]
	source.settings = {
		"enabled": true,
		"ratio": 0.75,
		"position": Vector2(5, -6),
		"nested": {"color": Color(0.1, 0.2, 0.3, 1)},
	}
	source.string_value = "Text"
	source.string_name_value = &"identifier"
	source.color_value = Color.RED
	source.vector3_value = Vector3(1, 2, 3)
	source.node_path_value = NodePath("Root/Child")

	var json := Converter.stringify(source)
	var parsed: Dictionary = JSON.parse_string(json)
	var decoded := Converter.parse(json, ConverterTestResource)

	assert_eq(parsed.title, "Complete JSON")
	assert_eq(parsed.count, 99.0)
	assert_eq(parsed.tags, ["alpha", "beta"])
	assert_eq(parsed.settings.enabled, true)
	assert_eq(parsed.settings.ratio, 0.75)
	assert_eq(parsed.settings.position, "Vector2(5, -6)")
	assert_eq(parsed.settings.nested.color, "Color(0.1, 0.2, 0.3, 1)")
	assert_eq(parsed.string_value, "Text")
	assert_eq(parsed.string_name_value, "identifier")
	assert_eq(parsed.color_value, "Color(1, 0, 0, 1)")
	assert_eq(parsed.vector3_value, "Vector3(1, 2, 3)")
	assert_eq(parsed.node_path_value, "NodePath(\"Root/Child\")")

	assert_eq(decoded.title, source.title)
	assert_eq(decoded.count, source.count)
	assert_eq(decoded.tags, source.tags)
	assert_eq(decoded.settings, source.settings)
	assert_eq(decoded.string_value, source.string_value)
	assert_eq(decoded.string_name_value, source.string_name_value)
	assert_eq(decoded.color_value, source.color_value)
	assert_eq(decoded.vector3_value, source.vector3_value)
	assert_eq(decoded.node_path_value, source.node_path_value)


func test_json_packed_arrays_are_complete_native_arrays() -> void:
	var source := ConverterTestResource.new()
	source.packed_bytes_value = PackedByteArray([0, 127, 255])
	source.packed_int32_value = PackedInt32Array([-10, 0, 10])
	source.packed_float64_value = PackedFloat64Array([1.25, -2.5, 3.75])
	source.packed_strings_value = PackedStringArray(["one", "two"])
	source.packed_vector2_value = PackedVector2Array([Vector2(1, 2), Vector2(3, 4)])
	source.packed_colors_value = PackedColorArray([Color.RED, Color.BLUE])

	var json := Converter.stringify(source)
	var parsed: Dictionary = JSON.parse_string(json)
	var decoded := Converter.parse(json, ConverterTestResource)

	assert_eq(parsed.packed_bytes_value, [0.0, 127.0, 255.0])
	assert_eq(parsed.packed_int32_value, [-10.0, 0.0, 10.0])
	assert_eq(parsed.packed_float64_value, [1.25, -2.5, 3.75])
	assert_eq(parsed.packed_strings_value, ["one", "two"])
	assert_eq(parsed.packed_vector2_value, ["Vector2(1, 2)", "Vector2(3, 4)"])
	assert_eq(parsed.packed_colors_value, ["Color(1, 0, 0, 1)", "Color(0, 0, 1, 1)"])
	assert_eq(decoded.packed_bytes_value, source.packed_bytes_value)
	assert_eq(decoded.packed_int32_value, source.packed_int32_value)
	assert_eq(decoded.packed_float64_value, source.packed_float64_value)
	assert_eq(decoded.packed_strings_value, source.packed_strings_value)
	assert_eq(decoded.packed_vector2_value, source.packed_vector2_value)
	assert_eq(decoded.packed_colors_value, source.packed_colors_value)


func test_json_resource_references_keep_all_relationship_information() -> void:
	var source := ConverterTestResource.new()
	var shared := Resource.new()
	source.child = shared
	source.second_child = shared

	var json := Converter.stringify(source)
	var parsed: Dictionary = JSON.parse_string(json)
	var decoded := Converter.parse(json, ConverterTestResource)

	assert_true(parsed.child is Dictionary)
	assert_true(parsed.child.is_empty())
	assert_eq(parsed.second_child, "ResourceRef(2)")
	assert_not_null(decoded.child)
	assert_same(decoded.child, decoded.second_child)


func test_convert_dispatches_both_directions() -> void:
	var source := ConverterTestResource.new()
	source.title = "Facade"

	var json: Variant = Converter.convert(source)
	_print_json_result("convert resource", json)
	var decoded: Variant = Converter.convert(json, ConverterTestResource)
	print("[convert JSON] Resource result: %s" % var_to_str(decoded))

	assert_true(json is String)
	assert_true(decoded is Resource)
	assert_eq(decoded.title, "Facade")


func test_supported_value_types_use_plain_json_strings() -> void:
	var source := ConverterTestResource.new()
	source.settings = {
		"color": Color.RED,
		"vector2": Vector2(1, 2),
		"vector2i": Vector2i(1, 2),
		"rect2": Rect2(1, 2, 3, 4),
		"rect2i": Rect2i(1, 2, 3, 4),
		"vector3": Vector3(1, 2, 3),
		"vector3i": Vector3i(1, 2, 3),
		"transform2d": Transform2D.IDENTITY,
		"vector4": Vector4(1, 2, 3, 4),
		"vector4i": Vector4i(1, 2, 3, 4),
	}

	var json := Converter.stringify(source)
	var parsed: Dictionary = JSON.parse_string(json)
	var decoded := Converter.parse(json, ConverterTestResource)

	for key in source.settings:
		assert_true(parsed.settings[key] is String)
		assert_eq(decoded.settings[key], source.settings[key])


func test_parse_accepts_manual_json_for_custom_resource_script() -> void:
	var json := JSON.stringify({
		"title": "Manual JSON",
		"count": 12,
		"tags": ["one", "two"],
		"color_value": "Color(0.25, 0.5, 0.75, 1)",
		"vector2_value": "Vector2(4, -8)",
	})

	var decoded := Converter.parse(json, ConverterTestResource)

	assert_not_null(decoded)
	assert_eq(decoded.title, "Manual JSON")
	assert_eq(decoded.count, 12)
	assert_eq(decoded.tags, ["one", "two"])
	assert_eq(decoded.color_value, Color(0.25, 0.5, 0.75, 1))
	assert_eq(decoded.vector2_value, Vector2(4, -8))


func test_alias_methods_round_trip_custom_resource() -> void:
	var source := ConverterTestResource.new()
	source.title = "Alias API"

	var json := Converter.resource_to_json(source)
	var decoded := Converter.json_to_resource(json, ConverterTestResource)

	assert_eq(decoded.title, source.title)


func test_compact_json_preserves_escaped_and_unicode_strings() -> void:
	var source := ConverterTestResource.new()
	source.string_value = "Quotes: \"JSON\"\nUnicode: Grüße 🚀"

	var json := Converter.stringify(source, "")
	var decoded := Converter.parse(json, ConverterTestResource)

	assert_false(json.contains("\n"))
	assert_eq(decoded.string_value, source.string_value)
