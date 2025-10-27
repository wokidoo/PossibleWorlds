class_name WorldState
extends Resource

@export var name:String:
	set(value):
		resource_name = value
		emit_changed()
	get():
		return resource_name
		
@export var canonWorld: World:
	set(value):
		if canonWorld != null && canonWorld.changed.is_connected(emit_changed):
				canonWorld.changed.disconnect(emit_changed)
		canonWorld = value
		emit_changed()
		
@export var characters: Array[Character] = []

func _init() -> void:
	if canonWorld == null:
		canonWorld = World.new()
	if characters == null:
		characters = []
	call_deferred("_reconnect_signals")

func _reconnect_signals():
	if not canonWorld.changed.is_connected(emit_changed):
		canonWorld.changed.connect(emit_changed)
	for c in characters:
		if not c.changed.is_connected(emit_changed):
			c.changed.connect(emit_changed)
			c._reconnect_signals()

func add_character(c:Character)->bool:
	if characters.has(c):
		return false
	else:
		characters.append(c)
		c.changed.connect(emit_changed)
		emit_changed()
		return true

func remove_character(c:Character)->bool:
	if characters.has(c):
		if c.changed.is_connected(emit_changed):
			c.changed.disconnect(emit_changed)
		characters.erase(c)
		emit_changed()
		return true
	else:
		return false
	
func find_characters(filter:Callable) -> Array[Character]:
	return characters.filter(filter)

func map_characters(callable:Callable,c:Array[Character] = characters) ->Array:
	return c.map(callable)
