extends "res://addons/resource2JSON/decoder/ValueDecoder.gd"


func can_decode(value: Variant, _context: Dictionary) -> bool:
	return value is Array


func decode(value: Variant, context: Dictionary, decode_value: Callable) -> Variant:
	var decoded: Array = []
	for item in value:
		decoded.append(decode_value.call(item, context))
	return decoded
