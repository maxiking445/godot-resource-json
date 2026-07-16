extends GutTest


const Converter := preload("res://addons/resource2JSON/JsonConverter.gd")
const ConverterTestResource := preload("res://tests/fixtures/converter_test_resource.gd")


func _print_json_result(test_name: String, json: String) -> void:
	print("\n[%s] JSON result:\n%s\n" % [test_name, json])


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
