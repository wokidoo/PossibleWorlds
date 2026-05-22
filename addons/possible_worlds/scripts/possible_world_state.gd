@tool
extends Resource
class_name PossibleWorldState

signal mind_added(mind:PossibleWorldMind)
signal mind_changed(mind:PossibleWorldMind)
signal mind_removed(mind:PossibleWorldMind)
signal canon_world_changed(canon_world:PossibleWorld)

@export var canonical_world:PossibleWorld:
	set(val):
		if not val:
			canonical_world = null
		else:
			canonical_world = val.duplicate()
			canonical_world.changed.connect(_on_canon_world_changed)
		emit_changed()

@export var possible_minds:Dictionary[StringName,PossibleWorldMind]

func _init() -> void:
	if not canonical_world:
		canonical_world = PossibleWorld.new()
	_connect_all_signals.call_deferred()

func _connect_all_signals():
	if not canonical_world.changed.is_connected(_on_canon_world_changed):
		canonical_world.changed.connect(_on_canon_world_changed)
	for key in possible_minds.keys():
		var mind:PossibleWorldMind = possible_minds.get(key)
		if not mind.mind_changed.is_connected(_on_mind_changed):
			mind.mind_changed.connect(_on_mind_changed)
		if not mind.changed.is_connected(_on_changed):
			mind.changed.connect(_on_changed)

func set_mind(key:StringName,mind:PossibleWorldMind,overwrite:bool=true):
	if key.is_empty():
		return
	key = key.to_snake_case()
	if possible_minds.has(key):
		if overwrite:
			possible_minds.set(key,mind)
			mind.mind_changed.connect(_on_mind_changed)
			mind.changed.connect(_on_changed)
			emit_changed()
		else:
			return
	else:
		possible_minds.set(key,mind)
		emit_changed()
		mind_added.emit(mind)

func get_mind(key:StringName):
	key = key.to_snake_case()
	return possible_minds.get(key,null)

func get_all_mind_keys()->Array[StringName]:
	return possible_minds.keys()

func has_mind(key:StringName)->bool:
	var test = possible_minds.get(key)
	return possible_minds.has(key)

func remove_mind(key:StringName)->bool:
	key = key.to_snake_case()
	if has_mind(key):
		var mind := possible_minds.get(key)
		possible_minds.erase(key)
		if mind:
			if mind.mind_changed.is_connected(_on_mind_changed):
				mind.mind_changed.disconnect(_on_mind_changed)
			if mind.changed.is_connected(_on_changed):
				mind.changed.disconnect(_on_changed)
		emit_changed()
		mind_removed.emit(mind)
		return true
	return false

func query_minds(filter:Callable)->Dictionary[StringName,PossibleWorldMind]:
	var minds:Array[PossibleWorldMind] = []
	minds = possible_minds.values().filter(filter)
	var dict:Dictionary[StringName,PossibleWorldMind] ={}
	for mind in minds:
		dict.set(possible_minds.find_key(mind),mind)
	return dict

func set_canonical_proposition(prop:StringName,value:float,overwrite:bool =true):
	canonical_world.set_proposition(prop,value,overwrite)

func get_canonical_propositon(prop:StringName)->float:
	return canonical_world.get_proposition(prop)

func has_canonical_proposition(prop:StringName)->bool:
	return canonical_world.has_proposition(prop)

func get_all_canonical_propositon_keys()->Array[StringName]:
	return canonical_world.get_all_propositions().keys()

func _on_changed():
	emit_changed()

func _on_mind_changed(mind:PossibleWorldMind):
	mind_changed.emit(mind)

func _on_canon_world_changed():
	emit_changed()
	canon_world_changed.emit(canonical_world)
