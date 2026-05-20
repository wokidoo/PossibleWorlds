@tool
extends Resource
class_name PossibleWorldMind

signal proposition_added(prop:StringName)
signal mind_changed(mind:PossibleWorldMind)
signal proposition_removed(prop:StringName)

@export var perceived_world:PossibleWorld:
	set(val):
		perceived_world = val.duplicate()
		_connect_perceived_world_signals()

@export var ideal_world:PossibleWorld:
	set(val):
		ideal_world = val.duplicate()
		_connect_ideal_world_signals()

func _init() -> void:
	if is_built_in():
		resource_local_to_scene = true
	if not perceived_world:
		perceived_world = PossibleWorld.new()
	if not ideal_world:
		ideal_world = PossibleWorld.new()
	_connect_ideal_world_signals()
	_connect_perceived_world_signals()

func set_proposition(prop:StringName,ideal:float,perceived:float,overwrite:bool = true):
	ideal_world.set_proposition(prop,ideal,overwrite)
	perceived_world.set_proposition(prop,perceived,overwrite)

func set_ideal_proposition(prop:StringName,value:float,overwrite:bool = true):
	ideal_world.set_proposition(prop,value,overwrite)

func set_perceived_proposition(prop:StringName,value:float,overwrite:bool = true):
	perceived_world.set_proposition(prop,value,overwrite)

func get_ideal_proposition(prop:StringName)->float:
	return ideal_world.get_proposition(prop)

func get_perceived_proposition(prop:StringName)->float:
	return perceived_world.get_proposition(prop)

func remove_proposition(prop:StringName)->bool:
	return ideal_world.remove_proposition(prop)

func has_proposition(prop:StringName)->bool:
	return ideal_world.has_proposition(prop)

func get_internal_tension(prop:StringName)->float:
	var ideal := ideal_world.get_proposition(prop)
	var perceived := perceived_world.get_proposition(prop)
	var tension:float = PossibleWorld.get_tension(prop,perceived_world,ideal_world)
	return tension

func get_total_internal_tension()->float:
	var total_tension:= 0.0
	for prop in perceived_world.get_all_propositions().keys():
		total_tension += get_internal_tension(prop)
	return total_tension

func _connect_ideal_world_signals():
	if not ideal_world:
		return
	if not ideal_world.proposition_added.is_connected(_on_ideal_prop_added):
		ideal_world.proposition_added.connect(_on_ideal_prop_added)
	if not ideal_world.proposition_removed.is_connected(_on_ideal_prop_removed):
		ideal_world.proposition_removed.connect(_on_ideal_prop_removed)
	if not ideal_world.changed.is_connected(_on_possible_world_changed):
		ideal_world.changed.connect(_on_possible_world_changed)

func _connect_perceived_world_signals():
	if not perceived_world:
		return
	if not perceived_world.proposition_added.is_connected(_on_percieved_prop_added):
		perceived_world.proposition_added.connect(_on_percieved_prop_added)
	if not perceived_world.proposition_removed.is_connected(_on_perceived_prop_removed):
		perceived_world.proposition_removed.connect(_on_perceived_prop_removed)
	if not perceived_world.changed.is_connected(_on_possible_world_changed):
		perceived_world.changed.connect(_on_possible_world_changed)

#region static methods
static func get_ideal_tension(mind_a:PossibleWorldMind,mind_b:PossibleWorldMind,prop:StringName):
	var tension :float = PossibleWorld.get_tension(prop,mind_a.ideal_world,mind_b.ideal_world)
	return tension

static func get_total_ideal_tension(mind_a:PossibleWorldMind,mind_b:PossibleWorldMind):
	var tension :float = 0.0
	var merged = mind_a.ideal_world.get_all_propositions().duplicate()
	merged.merge(mind_b.ideal_world.get_all_propositions())
	# Get the combined keys
	var combined_keys = merged.keys()
	for prop in combined_keys:
		tension += get_ideal_tension(mind_a,mind_b,prop)
	return tension

static func get_perceived_tension(mind_a:PossibleWorldMind,mind_b:PossibleWorldMind,prop:StringName):
	var tension :float = PossibleWorld.get_tension(prop,mind_a.perceived_world,mind_b.perceived_world)
	return tension

static func get_total_perceived_tension(mind_a:PossibleWorldMind,mind_b:PossibleWorldMind):
	var tension :float = 0.0
	var merged = mind_a.perceived_world.get_all_propositions().duplicate()
	merged.merge(mind_b.perceived_world.get_all_propositions())
	# Get the combined keys
	var combined_keys = merged.keys()
	for prop in combined_keys:
		tension += get_ideal_tension(mind_a,mind_b,prop)
	return tension


#endregion

#region Signal
func _on_ideal_prop_added(prop:StringName):
	if not perceived_world.has_proposition(prop):
		perceived_world.set_proposition(prop,0.0)
		emit_changed()
		proposition_added.emit(prop)

func _on_ideal_prop_removed(prop:StringName):
	if perceived_world.has_proposition(prop):
		perceived_world.remove_proposition(prop)
		emit_changed()
		proposition_removed.emit(prop)

func _on_percieved_prop_added(prop:StringName):
	if not ideal_world.has_proposition(prop):
		ideal_world.set_proposition(prop,0.0)
		emit_changed()
		proposition_added.emit(prop)
	
func _on_perceived_prop_removed(prop:StringName):
	if ideal_world.has_proposition(prop):
		ideal_world.remove_proposition(prop)
		emit_changed()
		proposition_removed.emit(prop)

func _on_possible_world_changed():
	emit_changed()
	mind_changed.emit(self)
#endregion
