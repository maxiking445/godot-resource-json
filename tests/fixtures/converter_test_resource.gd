extends Resource


@export var title: String = ""
@export var count: int = 0
@export var tags: Array[String] = []
@export var settings: Dictionary = {}
@export var child: Resource
@export var typed_numbers: Array[int] = []
@export var typed_lookup: Dictionary[String, int] = {}

# Native JSON values and containers.
@export var string_value: String = ""
@export var string_name_value: StringName = &""
@export var array_value: Array = []
@export var dictionary_value: Dictionary = {}
@export var infinity_value: float = INF
@export var negative_infinity_value: float = -INF
@export var nan_value: float = NAN

# Godot Variant value types supported by dedicated encoders and decoders.
@export var color_value: Color = Color.WHITE
@export var vector2_value: Vector2 = Vector2.ZERO
@export var vector2i_value: Vector2i = Vector2i.ZERO
@export var rect2_value: Rect2 = Rect2()
@export var rect2i_value: Rect2i = Rect2i()
@export var vector3_value: Vector3 = Vector3.ZERO
@export var vector3i_value: Vector3i = Vector3i.ZERO
@export var transform2d_value: Transform2D = Transform2D.IDENTITY
@export var vector4_value: Vector4 = Vector4.ZERO
@export var vector4i_value: Vector4i = Vector4i.ZERO
@export var plane_value: Plane = Plane()
@export var quaternion_value: Quaternion = Quaternion.IDENTITY
@export var aabb_value: AABB = AABB()
@export var basis_value: Basis = Basis.IDENTITY
@export var transform3d_value: Transform3D = Transform3D.IDENTITY
@export var projection_value: Projection = Projection.IDENTITY
@export var node_path_value: NodePath = NodePath()
