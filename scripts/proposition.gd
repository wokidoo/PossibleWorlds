extends Resource
class_name  Proposition

@export var _prop_id: int = 0
@export var _is_canonical: bool = false
@export var description: String = "":
	set(val):
		description = val
		emit_changed()
		
@export var value: bool = false:
	set(val):
		value = val
		emit_changed()

func _init():
	changed.connect(_on_changed)

func _on_changed():
	var value_string := "[color=green]true[/color]" if value else "[color=red]false[/color]"
	print_rich("Proposition %s:'%s' changed! Value = %s" % [_prop_id,description,value_string])

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

## Returns wether the proposition provide matches this propositions value as an integer.
## return 0 if values match, 1 otherwise.
func diff(p:Proposition) -> int:
	return int(value != p.value)

func connect_changed_to_callable(cb:Callable) -> bool:
	if not changed.is_connected(cb):
		changed.connect(cb)
		return true
	else:
		return false

func disconnect_changed_from_callable(cb:Callable) -> bool:
	if changed.is_connected(cb):
		changed.disconnect(cb)
		return true
	else:
		return false