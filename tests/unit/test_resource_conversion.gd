extends GutTest


const Converter := preload("res://addons/resource2JSON/JsonConverter.gd")
const ConverterTestResource := preload("res://tests/fixtures/converter_test_resource.gd")


func _round_trip(source: Resource, test_name: String) -> Resource:
	var json := Converter.stringify(source)
	print("\n[%s] JSON result:\n%s\n" % [test_name, json])
	return Converter.parse(json)


func test_resource_round_trip_preserves_exported_properties() -> void:
	var source := ConverterTestResource.new()
	source.title = "Round trip"
	source.count = 7
	source.tags = ["json", "resource"]
	source.settings = {"enabled": true, "ratio": 1.5}

	var decoded := _round_trip(source, "exported properties")

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

	var decoded := _round_trip(source, "shared references")

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

	var decoded := _round_trip(source, "variant values and StringName keys")

	assert_true(decoded.settings.has(StringName("position")))
	assert_eq(decoded.settings[StringName("position")], Vector2(12.5, -3.0))
	assert_eq(decoded.settings.color, Color(0.1, 0.2, 0.3, 0.4))
	assert_eq(decoded.settings.nested, [Vector3.ONE, StringName("value")])


func test_round_trip_preserves_cyclic_resource_reference() -> void:
	var source := ConverterTestResource.new()
	source.child = source

	var decoded := _round_trip(source, "cyclic resource reference")

	assert_same(decoded, decoded.child)

	# Break both reference cycles so the test does not intentionally leak Resources.
	source.child = null
	decoded.child = null


func test_round_trip_preserves_integer_and_float_types_without_precision_loss() -> void:
	var source := ConverterTestResource.new()
	source.settings = {
		"maximum_integer": 9223372036854775807,
		"minimum_integer": -9223372036854775808,
		"integer": 1,
		"float": 1.0,
		"infinity": INF,
		"negative_infinity": -INF,
		"not_a_number": NAN,
	}

	var decoded := _round_trip(source, "exact number types")

	assert_eq(typeof(decoded.settings.maximum_integer), TYPE_INT)
	assert_eq(decoded.settings.maximum_integer, 9223372036854775807)
	assert_eq(decoded.settings.minimum_integer, -9223372036854775808)
	assert_eq(typeof(decoded.settings.integer), TYPE_INT)
	assert_eq(typeof(decoded.settings.float), TYPE_FLOAT)
	assert_eq(decoded.settings.float, 1.0)
	assert_eq(decoded.settings.infinity, INF)
	assert_eq(decoded.settings.negative_infinity, -INF)
	assert_true(is_nan(decoded.settings.not_a_number))


func test_round_trip_preserves_serializable_variant_types() -> void:
	var source := ConverterTestResource.new()
	source.settings = {
		"vector2": Vector2(1.25, -2.5),
		"vector2i": Vector2i(1, -2),
		"rect2": Rect2(1.0, 2.0, 3.0, 4.0),
		"rect2i": Rect2i(1, 2, 3, 4),
		"vector3": Vector3(1.0, 2.0, 3.0),
		"vector3i": Vector3i(1, 2, 3),
		"transform2d": Transform2D(1.0, Vector2(3.0, 4.0)),
		"vector4": Vector4(1.0, 2.0, 3.0, 4.0),
		"vector4i": Vector4i(1, 2, 3, 4),
		"plane": Plane(1.0, 2.0, 3.0, 4.0),
		"quaternion": Quaternion(0.1, 0.2, 0.3, 0.4),
		"aabb": AABB(Vector3.ONE, Vector3(2.0, 3.0, 4.0)),
		"basis": Basis.from_scale(Vector3(2.0, 3.0, 4.0)),
		"transform3d": Transform3D(Basis.IDENTITY, Vector3(1.0, 2.0, 3.0)),
		"projection": Projection.IDENTITY,
		"color": Color(0.1, 0.2, 0.3, 0.4),
		"node_path": NodePath("Root/Child:property"),
		"packed_bytes": PackedByteArray([0, 127, 255]),
		"packed_int32": PackedInt32Array([1, -2, 3]),
		"packed_int64": PackedInt64Array([1, -2, 9223372036854775807]),
		"packed_float32": PackedFloat32Array([1.25, -2.5]),
		"packed_float64": PackedFloat64Array([1.25, -2.5]),
		"packed_strings": PackedStringArray(["one", "two"]),
		"packed_vector2": PackedVector2Array([Vector2.ONE, Vector2.ZERO]),
		"packed_vector3": PackedVector3Array([Vector3.ONE, Vector3.ZERO]),
		"packed_colors": PackedColorArray([Color.RED, Color.TRANSPARENT]),
		"packed_vector4": PackedVector4Array([Vector4.ONE, Vector4.ZERO]),
	}

	var decoded := _round_trip(source, "serializable Variant types")

	for key in source.settings:
		assert_eq(decoded.settings[key], source.settings[key], "Variant mismatch for %s" % key)
		assert_eq(
			typeof(decoded.settings[key]),
			typeof(source.settings[key]),
			"Variant type mismatch for %s" % key
		)


func test_round_trip_preserves_typed_containers() -> void:
	var source := ConverterTestResource.new()
	source.typed_numbers = [1, 2, 3]
	source.typed_lookup = {"one": 1, "two": 2}
	var nested_array: Array[int] = [4, 5, 6]
	var nested_dictionary: Dictionary[String, int] = {"answer": 42}
	source.settings = {
		"array": nested_array,
		"dictionary": nested_dictionary,
	}

	var decoded := _round_trip(source, "typed containers")

	assert_true(decoded.typed_numbers.is_typed())
	assert_eq(decoded.typed_numbers.get_typed_builtin(), TYPE_INT)
	assert_eq(decoded.typed_numbers, source.typed_numbers)
	assert_true(decoded.typed_lookup.is_typed())
	assert_eq(decoded.typed_lookup.get_typed_key_builtin(), TYPE_STRING)
	assert_eq(decoded.typed_lookup.get_typed_value_builtin(), TYPE_INT)
	assert_eq(decoded.typed_lookup, source.typed_lookup)
	assert_true(decoded.settings.array.is_typed())
	assert_eq(decoded.settings.array.get_typed_builtin(), TYPE_INT)
	assert_true(decoded.settings.dictionary.is_typed())
	assert_eq(decoded.settings.dictionary.get_typed_key_builtin(), TYPE_STRING)
	assert_eq(decoded.settings.dictionary.get_typed_value_builtin(), TYPE_INT)


func test_round_trip_preserves_typed_resource_containers() -> void:
	var source := ConverterTestResource.new()
	var child := ConverterTestResource.new()
	child.title = "Typed child"
	var typed_resources: Array[ConverterTestResource] = [child]
	source.settings = {"resources": typed_resources}

	var decoded := _round_trip(source, "typed Resource containers")
	var decoded_resources: Array = decoded.settings.resources

	assert_true(decoded_resources.is_typed())
	assert_eq(decoded_resources.get_typed_builtin(), TYPE_OBJECT)
	assert_eq(decoded_resources.get_typed_script(), ConverterTestResource)
	assert_eq(decoded_resources.size(), 1)
	assert_true(decoded_resources[0] is ConverterTestResource)
	assert_eq(decoded_resources[0].title, "Typed child")


func test_round_trip_preserves_native_resource_properties() -> void:
	var source := Gradient.new()
	source.resource_name = "Native gradient"
	source.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	source.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	source.colors = PackedColorArray([Color.RED, Color.GREEN, Color.BLUE])

	var decoded := _round_trip(source, "native Resource properties")

	assert_true(decoded is Gradient)
	assert_eq(decoded.resource_name, source.resource_name)
	assert_eq(decoded.interpolation_mode, source.interpolation_mode)
	assert_eq(decoded.offsets, source.offsets)
	assert_eq(decoded.colors, source.colors)


func test_round_trip_preserves_resource_metadata() -> void:
	var source := ConverterTestResource.new()
	source.set_meta("author", "ResourceJSON")
	source.set_meta("revision", 9223372036854775807)

	var decoded := _round_trip(source, "Resource metadata")

	assert_true(decoded.has_meta("author"))
	assert_eq(decoded.get_meta("author"), "ResourceJSON")
	assert_eq(decoded.get_meta("revision"), 9223372036854775807)
