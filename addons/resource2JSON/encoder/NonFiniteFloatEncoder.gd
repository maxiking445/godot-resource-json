extends "res://addons/resource2JSON/encoder/ValueEncoder.gd"


func can_encode(value: Variant, _context: Dictionary) -> bool:
	return value is float and not is_finite(value)


func encode(value: Variant, _context: Dictionary, _encode_value: Callable) -> Variant:
	return var_to_str(value)
