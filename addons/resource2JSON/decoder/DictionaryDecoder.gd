extends "res://addons/resource2JSON/decoder/ValueDecoder.gd"


func can_decode(value: Variant, _context: Dictionary) -> bool:
	return value is Dictionary


func decode(value: Variant, context: Dictionary, decode_value: Callable) -> Variant:
	var decoded := {}
	for key in value:
		decoded[key] = decode_value.call(value[key], context)
	return decoded
