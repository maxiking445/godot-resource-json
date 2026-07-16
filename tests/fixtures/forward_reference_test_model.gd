extends Resource


# Declaration order makes the full model receive its ID first. JSON key sorting
# then places a_reference before z_definition, creating a real forward reference.
@export var z_definition: ReferencedTestModel
@export var a_reference: ReferencedTestModel
