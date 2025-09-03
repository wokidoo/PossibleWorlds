@tool
extends Resource
class_name Character

@export var name: String = ""
@export var perceived_world: World = World.new()
@export var ideal_worlds: Dictionary[StringName, World] = {}

#region perceived world


func get_perceived_world():
	return perceived_world


func has_perceived_proposition(p:Proposition):
	return perceived_world.has_proposition(p)


func has_perceived_proposition_with_id(id:int):
	return perceived_world.has_proposition_id(id)


func get_perceived_proposition(p:Proposition):
	return perceived_world.get_proposition(p._prop_id)


func get_perceived_proposition_with_id(id:int):
	return perceived_world.get_proposition(id)


func get_perceived_proposition_value(p:Proposition):
	return perceived_world.get_proposition_value(p)


func get_perceived_proposition_value_with_id(id:int):
	return perceived_world.get_proposition_value_with_id(id)


#endregion


#region ideal worlds


func get_ideal_proposition(theme:String,p:Proposition) -> Proposition:
	return ideal_worlds.get(theme).get_proposition(p._prop_id)


func get_ideal_proposition_with_id(theme:String,id:int) -> Proposition:
	return ideal_worlds.get(theme).get_proposition_id(id)


func get_ideal_world(theme:String) -> World:
	return ideal_worlds.get(theme,null)


func has_ideal_world(theme:String) -> bool:
	return ideal_worlds.has(theme)


func set_ideal(theme:String,id:int,value:bool):
	if has_ideal_world(theme):
		get_ideal_world(theme).set_proposition_value_with_id(id,value)


func set_ideal_world(theme:String,w:World):
	var ideal_w := w.make_clone()
	return ideal_worlds.set(theme,ideal_w)


func set_ideal_proposition(theme:String, p:Proposition):
	if has_ideal_world(theme):
		get_ideal_world(theme).set_proposition(p)
	else:
		var ideal_w: World = World.new()
		ideal_w.set_proposition(p)
		ideal_worlds.set(theme,ideal_w)


#endregion


#region believe

func believe(id:int, value:bool):
	if WorldServer.has_canonical_proposition_with_id(id):
		var prop := WorldServer.get_canonical_proposition(id).make_clone()
		prop.value = value
		believe_proposition(prop)

func believe_proposition(p:Proposition,clone_if_missing:bool = true):
	return perceived_world.set_proposition(p,clone_if_missing)


func believe_world(w:World,clone_if_missing:bool = true):
	for id in w.get_proposition_ids():
		var prop := w.get_proposition(id)
		perceived_world.set_proposition(prop,clone_if_missing)


#region tension

func get_perceived_vs_world_tension(w:World, lambda_missing:int = 0) -> int:
	return perceived_world.tension_with_world(w, lambda_missing)


func get_ideal_vs_world_tension(w:World,theme:String,lambda_missing:int = 0) -> int:
	var tension:int = 0
	var iw:World = ideal_worlds.get(theme)
	if iw != null:
		tension += iw.tension_with_world(w,lambda_missing)
	return tension


func get_total_ideal_vs_world_tension(w:World, lambda_missing:int = 0) -> int:
	var tension:int = 0
	for theme in ideal_worlds.keys():
		var iw: World = ideal_worlds.get(theme, null)
		tension += w.tension_with_world(iw,lambda_missing)
	return tension


func get_perceived_vs_canonical_tension(lambda_missing:int=0) -> int:
	return WorldServer.get_canonical_world().tension_with_world(perceived_world,lambda_missing)


func get_perceived_vs_ideal_tension(lambda_missing:int =0) -> int:
	var tension: int = 0
	for theme in ideal_worlds.keys():
		var iw: World = ideal_worlds.get(theme)
		tension += iw.tension_with_world(perceived_world,lambda_missing)
	return tension


#region character interactions
