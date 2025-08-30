extends Resource
class_name  Proposition

@export var _prop_id: int = 0
@export var _is_canonical: bool = false
@export var description: String = ""
@export var value: bool = false

func get_proposition_id() -> int: 
	return _prop_id

func is_canonical_proposition() -> bool: 
	return _is_canonical

func make_clone(override_value: Variant = null) -> Proposition:
	if _prop_id == 0:
		push_error("Proposition.make_clone: no prop_id; register first.")
		return null
	var clone := Proposition.new()
	clone._prop_id = _prop_id
	clone._is_canonical = false
	clone.description = description
	clone.value = override_value if override_value is bool else value
	return clone