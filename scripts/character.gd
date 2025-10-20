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

func idealPerceivedDiff() -> Array[StringName]:
	return perceivedWorld.diff(idealWorld)

func idealDiff(other:Character) -> Array[StringName]:
	return idealWorld.diff(other.idealWorld)

func perceivedDiff(other:Character) -> Array[StringName]:
	return perceivedWorld.diff(other.perceivedWorld)

func setIdeal(id:String,truth:PW.TriBool) ->bool:
	if not perceivedWorld.hasProposition(id):
		perceivedWorld.setTruth(id,PW.TriBool.UNKNOWN)
	return idealWorld.setTruth(id,truth)

func setPerceived(id:String,truth:PW.TriBool) ->bool:
	if not idealWorld.hasProposition(id):
		idealWorld.setTruth(id,PW.TriBool.UNKNOWN)
	return perceivedWorld.setTruth(id,truth)

func getIdeal(id:String) ->PW.TriBool:
	return idealWorld.getTruth(id)

func getPerceived(id:String) -> PW.TriBool:
	return perceivedWorld.getTruth(id)
