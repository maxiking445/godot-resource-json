extends GutTest


const Converter := preload("res://addons/jsonConverter/JsonConverter.gd")
const ConverterTestResource := preload("res://tests/fixtures/converter_test_resource.gd")


func test_resource_round_trip_preserves_exported_properties() -> void:
	var source := ConverterTestResource.new()
	source.title = "Round trip"
	source.count = 7
	source.tags = ["json", "resource"]
	source.settings = {"enabled": true, "ratio": 1.5}

	var decoded := Converter.parse(Converter.stringify(source))

	assert_not_null(decoded)
	assert_eq(decoded.get_script(), ConverterTestResource)
	assert_eq(decoded.title, source.title)
	assert_eq(decoded.count, source.count)
	assert_eq(decoded.tags, source.tags)
	assert_eq(decoded.settings, source.settings)


func test_resource_round_trip_preserves_shared_references() -> void:
	var shared_child := Resource.new()
	shared_child.resource_name = "Shared child"
	var source := ConverterTestResource.new()
	source.child = shared_child
	source.settings = {"same_child": shared_child}

	var decoded := Converter.parse(Converter.stringify(source))

	assert_not_null(decoded.child)
	assert_eq(decoded.child.resource_name, "Shared child")
	assert_same(decoded.child, decoded.settings.same_child)


func test_round_trip_preserves_variant_values_and_string_name_keys() -> void:
	var source := ConverterTestResource.new()
	source.settings = {
		StringName("position"): Vector2(12.5, -3.0),
		"color": Color(0.1, 0.2, 0.3, 0.4),
		"nested": [Vector3.ONE, StringName("value")],
	}

	var decoded := Converter.parse(Converter.stringify(source))

	assert_true(decoded.settings.has(StringName("position")))
	assert_eq(decoded.settings[StringName("position")], Vector2(12.5, -3.0))
	assert_eq(decoded.settings.color, Color(0.1, 0.2, 0.3, 0.4))
	assert_eq(decoded.settings.nested, [Vector3.ONE, StringName("value")])


func test_round_trip_preserves_cyclic_resource_reference() -> void:
	var source := ConverterTestResource.new()
	source.child = source

	var decoded := Converter.parse(Converter.stringify(source))

	assert_same(decoded, decoded.child)

	# Break both reference cycles so the test does not intentionally leak Resources.
	source.child = null
	decoded.child = null
