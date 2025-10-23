class_name Character
extends Resource

@export var name: String:
	set(value):
		name = value
		resource_name = name
		emit_changed()
		
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

func _reconnect_signals():
	if not perceivedWorld.changed.is_connected(emit_changed):
		perceivedWorld.changed.connect(emit_changed)
	if not idealWorld.changed.is_connected(emit_changed):
		idealWorld.changed.connect(emit_changed)

func ideal_perceived_diff() -> Array[StringName]:
	return perceivedWorld.diff(idealWorld)

func ideal_perceived_tension() -> float:
	return perceivedWorld.tension(idealWorld)

func ideal_diff(other:Character) -> Array[StringName]:
	return idealWorld.diff(other.idealWorld)

func ideal_tension(other:Character) -> float:
	return idealWorld.tension(other.idealWorld)

func perceived_diff(other:Character) -> Array[StringName]:
	return perceivedWorld.diff(other.perceivedWorld)

func perceived_tension(other:Character) -> float:
	return perceivedWorld.tension(other.perceivedWorld)

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

func get_ideal(id:String) ->PW.TriBool:
	return idealWorld.get_truth(id)

func get_ideal_confidence(id:String) -> float:
	return idealWorld.get_confidence(id)

func get_perceived(id:String) -> PW.TriBool:
	return perceivedWorld.get_truth(id)

func get_perceived_confidence(id:String) -> float:
	return perceivedWorld.get_confidence(id)
