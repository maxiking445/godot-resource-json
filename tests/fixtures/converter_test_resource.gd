extends Resource


@export var title: String = ""
@export var count: int = 0
@export var tags: Array[String] = []
@export var settings: Dictionary = {}
@export var child: Resource
@export var typed_numbers: Array[int] = []
@export var typed_lookup: Dictionary[String, int] = {}
