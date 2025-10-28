class_name Character
extends Resource

@export var name: String:
	set(value):
		name = value
		resource_name = name
		emit_changed()
	get():
		return resource_name
		
@export var perceivedWorld: World: 
	set(value):
		if perceivedWorld != null && perceivedWorld.changed.is_connected(emit_changed):
			perceivedWorld.changed.disconnect(emit_changed)
		perceivedWorld = value
		perceivedWorld.changed.connect(emit_changed)
		emit_changed()
		
@export var idealWorld: World: 
	set(value):
		if idealWorld != null && idealWorld.changed.is_connected(emit_changed):
			idealWorld.changed.disconnect(emit_changed)
		idealWorld = value
		idealWorld.changed.connect(emit_changed)
		emit_changed()

func _init() -> void:
	if perceivedWorld == null:
		perceivedWorld = World.new()
	if idealWorld == null:
		idealWorld = World.new()
	call_deferred("_reconnect_signals")

func _reconnect_signals():
	if not perceivedWorld.changed.is_connected(emit_changed):
		perceivedWorld.changed.connect(emit_changed)
	if not idealWorld.changed.is_connected(emit_changed):
		idealWorld.changed.connect(emit_changed)
	if not perceivedWorld.proposition_added.is_connected(_on_proposition_added):
		perceivedWorld.proposition_added.connect(_on_proposition_added)
	if not idealWorld.proposition_added.is_connected(_on_proposition_added):
		idealWorld.proposition_added.connect(_on_proposition_added)
	if not idealWorld.proposition_removed.is_connected(_on_proposition_removed):
		idealWorld.proposition_removed.connect(_on_proposition_removed)
	if not perceivedWorld.proposition_removed.is_connected(_on_proposition_removed):
		perceivedWorld.proposition_removed.connect(_on_proposition_removed)

func _on_proposition_added(id:StringName):
	if perceivedWorld.has_proposition(id):
		idealWorld.set_truth(id,perceivedWorld.get_truth(id))
	elif idealWorld.has_proposition(id):
		perceivedWorld.set_truth(id,idealWorld.get_truth(id))
	else:
		return

func _on_proposition_removed(id:StringName):
	if perceivedWorld.has_proposition(id):
		perceivedWorld.erase_truth(id)
	if idealWorld.has_proposition(id):
		idealWorld.erase_truth(id)
	else:
		return
	
func ideal_perceived_diff() -> Array[StringName]:
	return perceivedWorld.diff(idealWorld)

func internal_tension(id:StringName) -> float:
	return perceivedWorld.tension(id,idealWorld)

func total_internal_tension() -> float:
	return perceivedWorld.total_tension(idealWorld)

func ideal_diff(other:Character) -> Array[StringName]:
	return idealWorld.diff(other.idealWorld)

func ideal_tension(other:Character) -> float:
	return idealWorld.total_tension(other.idealWorld)

func perceived_diff(other:Character) -> Array[StringName]:
	return perceivedWorld.diff(other.perceivedWorld)

func perceived_tension(other:Character) -> float:
	return perceivedWorld.total_tension(other.perceivedWorld)

func set_ideal(id:String,truth:PW.TriBool,confidence:float = 1.0) ->bool:
	if not perceivedWorld.has_proposition(id):
		perceivedWorld.set_truth(id,PW.TriBool.UNKNOWN)
	return idealWorld.set_truth(id,truth,confidence)

func set_ideal_confidence(id:String,confidence:float) -> bool:
	return idealWorld.set_confidence(id,confidence)

func set_perceived(id:String,truth:PW.TriBool,confidence:float = 1.0) ->bool:
	if not idealWorld.has_proposition(id):
		idealWorld.set_truth(id,PW.TriBool.UNKNOWN)
	return perceivedWorld.set_truth(id,truth,confidence)

func set_perceived_confidence(id:String,confidence:float) -> bool:
	return perceivedWorld.set_confidence(id,confidence)

func get_ideal(id:String) -> PW.TriBool:
	return idealWorld.get_truth(id)

func get_ideal_confidence(id:String) -> float:
	return idealWorld.get_confidence(id)

func get_perceived(id:String) -> PW.TriBool:
	return perceivedWorld.get_truth(id)

func get_perceived_confidence(id:String) -> float:
	return perceivedWorld.get_confidence(id)
