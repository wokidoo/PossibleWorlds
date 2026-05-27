@tool
class_name PossibleWorld
extends Resource

signal proposition_added(prop:StringName)
signal proposition_removed(prop:StringName)

@export var _propositions: Dictionary[StringName,float]

func _init() -> void:
	if is_built_in():
		resource_local_to_scene = true

func set_proposition(prop:StringName,value:float,overwrite:bool = true)->void:
	if prop.is_empty():
		return
	prop = prop.to_snake_case()
	if _propositions.has(prop):
		if overwrite:
			_propositions.set(prop,clampf(value,-1.0,1.0))
			emit_changed()
		else:
			return
	else:
		_propositions.set(prop,clampf(value,-1.0,1.0))
		emit_changed()
		proposition_added.emit(prop)

func remove_proposition(prop:StringName)->bool:
	prop = prop.to_snake_case()
	if has_proposition(prop):
		_propositions.erase(prop)
		emit_changed()
		proposition_removed.emit(prop)
		return true
	return false

func get_proposition(prop:StringName)->float:
	prop = prop.to_snake_case()
	return _propositions.get(prop,0.0)

func has_proposition(prop:StringName)->bool:
	prop = prop.to_snake_case()
	return _propositions.has(prop)

func get_all_propositions()->Dictionary[StringName,float]:
	return _propositions.duplicate()

static func get_proposition_diff(prop:StringName,world_a:PossibleWorld,world_b:PossibleWorld)->float:
	var tension :float = absf(world_a.get_proposition(prop) - world_b.get_proposition(prop))
	return tension

static func get_total_proposition_diff(world_a:PossibleWorld,world_b:PossibleWorld)->float:
	var tension :float = 0.0
	var combined_keys = get_combined_propositions(world_a,world_b)
	for prop in combined_keys:
		tension += PossibleWorld.get_proposition_diff(prop,world_a,world_b)
	return tension

static func get_tension(prop:StringName,world_a:PossibleWorld,world_b:PossibleWorld)->float:
	var tension :float = absf(world_a.get_proposition(prop) - world_b.get_proposition(prop))*absf(world_a.get_proposition(prop))*absf(world_b.get_proposition(prop))
	return tension

static func get_total_tension(world_a:PossibleWorld,world_b:PossibleWorld)->float:
	var tension :float = 0.0
	# Get the combined keys
	var combined_keys = get_combined_propositions(world_a,world_b)
	for prop in combined_keys:
		tension += PossibleWorld.get_tension(prop,world_a,world_b)
	return tension

static func get_combined_propositions(world_a:PossibleWorld,world_b:PossibleWorld)->Array[StringName]:
	var merged = world_a.get_all_propositions().duplicate()
	merged.merge(world_b.get_all_propositions())
	# Get the combined keys
	var combined_keys = merged.keys()
	return combined_keys
