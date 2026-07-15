extends RefCounted
class_name JSONConverter


const ResourceToJSON := preload("res://addons/jsonConverter/Resource2Json.gd")
const JSONToResource := preload("res://addons/jsonConverter/Json2Resource.gd")


static func convert(input: Variant) -> Variant:
	if input is Resource:
		return stringify(input)
	if input is String:
		return parse(input)

	push_error("Converter input must be a Resource or a JSON String.")
	return null


static func stringify(resource: Resource, indent: String = "\t") -> String:
	return ResourceToJSON.convert(resource, indent)


static func parse(json: String) -> Resource:
	return JSONToResource.convert(json)


static func resource_to_json(resource: Resource, indent: String = "\t") -> String:
	return stringify(resource, indent)


static func json_to_resource(json: String) -> Resource:
	return parse(json)
