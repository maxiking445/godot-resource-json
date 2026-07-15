extends GutTest


const Converter := preload("res://addons/jsonConverter/JsonConverter.gd")
const ConverterTestResource := preload("res://tests/fixtures/converter_test_resource.gd")


func test_resource_to_json_produces_valid_json() -> void:
	var source := ConverterTestResource.new()
	source.title = "JSON example"
	source.count = 42

	var json := Converter.stringify(source)
	var parsed: Variant = JSON.parse_string(json)

	assert_not_null(parsed)
	assert_true(parsed is Dictionary)
	assert_eq(parsed.properties.title, "JSON example")
	assert_eq(parsed.properties.count, 42.0)


func test_json_to_resource_decodes_native_resource() -> void:
	var json := JSON.stringify({
		"id": 1,
		"class": "Resource",
		"script": "",
		"properties": {"resource_name": "Decoded resource"},
	})

	var decoded := Converter.parse(json)

	assert_not_null(decoded)
	assert_eq(decoded.resource_name, "Decoded resource")


func test_convert_dispatches_both_directions() -> void:
	var source := ConverterTestResource.new()
	source.title = "Facade"

	var json: Variant = Converter.convert(source)
	var decoded: Variant = Converter.convert(json)

	assert_true(json is String)
	assert_true(decoded is Resource)
	assert_eq(decoded.title, "Facade")
