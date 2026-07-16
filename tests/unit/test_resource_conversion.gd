extends GutTest


const Converter := preload("res://addons/resource2JSON/JsonConverter.gd")
const ConverterTestResource := preload("res://tests/fixtures/converter_test_resource.gd")


func _round_trip(source: Resource, test_name: String) -> Resource:
	var json := Converter.stringify(source)
	print("\n[%s] JSON result:\n%s\n" % [test_name, json])
	return Converter.parse(json, source.get_script())


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


func test_fixture_round_trip_preserves_every_registered_value_type() -> void:
	var source := ConverterTestResource.new()
	source.string_value = "JSON text"
	source.string_name_value = &"identifier"
	source.array_value = [true, "nested", Vector2(3, 4)]
	source.dictionary_value = {"enabled": true, "color": Color.RED}
	source.color_value = Color(0.1, 0.2, 0.3, 0.4)
	source.vector2_value = Vector2(1.25, -2.5)
	source.vector2i_value = Vector2i(1, -2)
	source.rect2_value = Rect2(1, 2, 3, 4)
	source.rect2i_value = Rect2i(1, 2, 3, 4)
	source.vector3_value = Vector3(1, 2, 3)
	source.vector3i_value = Vector3i(1, 2, 3)
	source.transform2d_value = Transform2D(0.5, Vector2(3, 4))
	source.vector4_value = Vector4(1, 2, 3, 4)
	source.vector4i_value = Vector4i(1, 2, 3, 4)
	source.plane_value = Plane(1, 2, 3, 4)
	source.quaternion_value = Quaternion(0.1, 0.2, 0.3, 0.4)
	source.aabb_value = AABB(Vector3.ONE, Vector3(2, 3, 4))
	source.basis_value = Basis.from_scale(Vector3(2, 3, 4))
	source.transform3d_value = Transform3D(Basis.IDENTITY, Vector3(1, 2, 3))
	source.projection_value = Projection.IDENTITY
	source.node_path_value = NodePath("Root/Child:property")
	source.child = source

	var decoded := _round_trip(source, "all registered value types") as ConverterTestResource

	assert_eq(decoded.string_value, source.string_value)
	assert_eq(decoded.string_name_value, source.string_name_value)
	assert_eq(decoded.array_value, source.array_value)
	assert_eq(decoded.dictionary_value, source.dictionary_value)
	assert_eq(decoded.infinity_value, INF)
	assert_eq(decoded.negative_infinity_value, -INF)
	assert_true(is_nan(decoded.nan_value))
	assert_eq(decoded.color_value, source.color_value)
	assert_eq(decoded.vector2_value, source.vector2_value)
	assert_eq(decoded.vector2i_value, source.vector2i_value)
	assert_eq(decoded.rect2_value, source.rect2_value)
	assert_eq(decoded.rect2i_value, source.rect2i_value)
	assert_eq(decoded.vector3_value, source.vector3_value)
	assert_eq(decoded.vector3i_value, source.vector3i_value)
	assert_eq(decoded.transform2d_value, source.transform2d_value)
	assert_eq(decoded.vector4_value, source.vector4_value)
	assert_eq(decoded.vector4i_value, source.vector4i_value)
	assert_eq(decoded.plane_value, source.plane_value)
	assert_eq(decoded.quaternion_value, source.quaternion_value)
	assert_eq(decoded.aabb_value, source.aabb_value)
	assert_eq(decoded.basis_value, source.basis_value)
	assert_eq(decoded.transform3d_value, source.transform3d_value)
	assert_eq(decoded.projection_value, source.projection_value)
	assert_eq(decoded.node_path_value, source.node_path_value)
	assert_same(decoded.child, decoded)

	var type_checked_properties := [
		"string_value", "string_name_value", "array_value", "dictionary_value",
		"color_value", "vector2_value", "vector2i_value", "rect2_value",
		"rect2i_value", "vector3_value", "vector3i_value", "transform2d_value",
		"vector4_value", "vector4i_value", "plane_value", "quaternion_value",
		"aabb_value", "basis_value", "transform3d_value", "projection_value",
		"node_path_value",
	]
	for property_name in type_checked_properties:
		assert_eq(
			typeof(decoded.get(property_name)),
			typeof(source.get(property_name)),
			"Variant type mismatch for %s" % property_name
		)

	# Break both cycles so the test does not intentionally leak Resources.
	source.child = null
	decoded.child = null


func test_round_trip_preserves_variant_values_and_converts_string_names_to_json_strings() -> void:
	var source := ConverterTestResource.new()
	source.settings = {
		StringName("position"): Vector2(12.5, -3.0),
		"color": Color(0.1, 0.2, 0.3, 0.4),
		"nested": [Vector3.ONE, StringName("value")],
	}

	var decoded := _round_trip(source, "variant values and StringName keys")

	assert_true(decoded.settings.has("position"))
	assert_eq(decoded.settings.position, Vector2(12.5, -3.0))
	assert_eq(decoded.settings.color, source.settings.color)
	assert_eq(decoded.settings.nested, [Vector3.ONE, "value"])


func test_round_trip_preserves_cyclic_resource_reference() -> void:
	var source := ConverterTestResource.new()
	source.child = source

	var decoded := _round_trip(source, "cyclic resource reference")

	assert_same(decoded, decoded.child)

	# Break both reference cycles so the test does not intentionally leak Resources.
	source.child = null
	decoded.child = null


func test_round_trip_preserves_shared_exported_resource_references() -> void:
	var source := ConverterTestResource.new()
	var shared := Resource.new()
	source.child = shared
	source.second_child = shared

	var decoded := _round_trip(source, "shared exported resource")

	assert_not_null(decoded.child)
	assert_same(decoded.child, decoded.second_child)


func test_round_trip_preserves_exported_packed_arrays() -> void:
	var source := ConverterTestResource.new()
	source.packed_bytes_value = PackedByteArray([0, 127, 255])
	source.packed_int32_value = PackedInt32Array([1, -2, 3])
	source.packed_int64_value = PackedInt64Array([1, -2, 9007199254740991])
	source.packed_float32_value = PackedFloat32Array([1.25, -2.5])
	source.packed_float64_value = PackedFloat64Array([1.25, -2.5])
	source.packed_strings_value = PackedStringArray(["one", "two"])
	source.packed_vector2_value = PackedVector2Array([Vector2.ONE, Vector2.ZERO])
	source.packed_vector3_value = PackedVector3Array([Vector3.ONE, Vector3.ZERO])
	source.packed_colors_value = PackedColorArray([Color.RED, Color.TRANSPARENT])
	source.packed_vector4_value = PackedVector4Array([Vector4.ONE, Vector4.ZERO])

	var decoded := _round_trip(source, "exported packed arrays")
	var property_names := [
		"packed_bytes_value", "packed_int32_value", "packed_int64_value",
		"packed_float32_value", "packed_float64_value", "packed_strings_value",
		"packed_vector2_value", "packed_vector3_value", "packed_colors_value",
		"packed_vector4_value",
	]

	for property_name in property_names:
		assert_eq(decoded.get(property_name), source.get(property_name), property_name)
		assert_eq(
			typeof(decoded.get(property_name)),
			typeof(source.get(property_name)),
			"Packed array type mismatch for %s" % property_name
		)


func test_round_trip_preserves_nested_json_containers() -> void:
	var source := ConverterTestResource.new()
	source.settings = {
		"levels": [
			{"enabled": true, "positions": [Vector2(1, 2), Vector2(3, 4)]},
			{"enabled": false, "positions": []},
		],
	}

	var decoded := _round_trip(source, "nested JSON containers")

	assert_eq(decoded.settings, source.settings)


func test_strings_with_type_like_text_remain_strings() -> void:
	var source := ConverterTestResource.new()
	source.settings = {
		"missing_parenthesis": "Vector2(1, 2",
		"unknown_type": "CustomType(1, 2)",
		"plain_text": "Color is red",
	}

	var decoded := _round_trip(source, "type-like strings")

	assert_eq(decoded.settings, source.settings)


func test_round_trip_uses_native_json_numbers_and_preserves_non_finite_variants() -> void:
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

	# Godot's JSON parser represents JSON numbers as floats. JSON cannot retain
	# the int/float distinction or arbitrary 64-bit integer precision.
	assert_eq(typeof(decoded.settings.maximum_integer), TYPE_FLOAT)
	assert_eq(typeof(decoded.settings.minimum_integer), TYPE_FLOAT)
	assert_eq(typeof(decoded.settings.integer), TYPE_FLOAT)
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

	var packed_keys := [
		"packed_bytes", "packed_int32", "packed_int64", "packed_float32",
		"packed_float64", "packed_strings", "packed_vector2", "packed_vector3",
		"packed_colors", "packed_vector4",
	]
	for key in source.settings:
		if key in packed_keys:
			assert_true(decoded.settings[key] is Array, "%s should be a JSON Array" % key)
			continue
		if key == "color":
			assert_eq(decoded.settings[key], source.settings[key])
			continue
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
	assert_false(decoded.settings.array.is_typed())
	assert_false(decoded.settings.dictionary.is_typed())
	assert_eq(decoded.settings.array, [4.0, 5.0, 6.0])
	assert_eq(decoded.settings.dictionary, {"answer": 42.0})
