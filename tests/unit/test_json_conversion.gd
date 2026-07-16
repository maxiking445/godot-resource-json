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
	assert_eq(parsed.properties.title, "JSON example")
	assert_eq(parsed.properties.count["$integer"], "42")


func test_json_to_resource_decodes_native_resource() -> void:
	var json := JSON.stringify({
		"id": 1,
		"class": "Resource",
		"script": "",
		"properties": {"resource_name": "Decoded resource"},
	})
	_print_json_result("json_to_resource input", json)

	var decoded := Converter.parse(json)
	print("[json_to_resource] Resource result: %s" % var_to_str(decoded))

	assert_not_null(decoded)
	assert_eq(decoded.resource_name, "Decoded resource")


func test_convert_dispatches_both_directions() -> void:
	var source := ConverterTestResource.new()
	source.title = "Facade"

	var json: Variant = Converter.convert(source)
	_print_json_result("convert resource", json)
	var decoded: Variant = Converter.convert(json)
	print("[convert JSON] Resource result: %s" % var_to_str(decoded))

	assert_true(json is String)
	assert_true(decoded is Resource)
	assert_eq(decoded.title, "Facade")
