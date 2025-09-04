@tool
extends Resource
class_name World

## Non-canonical world: holds only propositions it cares about.
## Keys: prop_id -> Proposition (always CLONES, never canonical instances)
@export var _propositions: Dictionary[int, Proposition] = {}
@export var name: String = ""

#region proposition

## Return the Proposition with the id provided.
## Returns null if World does not contain a Proposition with a matching id
func get_proposition(id:int) -> Proposition:
	return _propositions.get(id,null)

## Return the dictionary containing all Propositions within this world.
## Mapped using _prop_id -> Proposition
func get_propositions() -> Dictionary[int,Proposition]:
	return _propositions

## Return an array of all Propostion ids within this world
func get_proposition_ids() -> Array[int]:
	return _propositions.keys()


func get_proposition_value(p:Proposition):
	var prop := get_proposition(p._prop_id)
	if prop != null:
		return prop.value

func get_proposition_value_with_id(id:int):
	var prop := get_proposition(id)
	if prop != null:
		return prop.value


## Evaluates whether this World has a Proposition with an id matching the id of the Proposition provided.
func has_proposition(p:Proposition) -> bool:
	var found_prop:Proposition = _propositions.get(p._prop_id,null)
	if found_prop != null:
		return true
	else:
		return false

## Evaluates whether this World has a Propostion with the id provided
func has_proposition_id(id:int) -> bool:
	return _propositions.has(id)

## Set (add or modify) a proposition to this World.
## If world already has proposition (or a clone) and 'overwrite' is true,
## set the propostion to 'p'. If world has a clone but 'overwrite' is false, no-op
func set_proposition(p:Proposition,overwrite:bool = true) ->bool:
	if not _propositions.has(p._prop_id) or overwrite:
		_store_prop(p)
		emit_changed()
		return true
	else:
		return false

## Set the value of a given proposition value contained in the world
func set_proposition_value(p:Proposition, v:bool) ->bool:
	if has_proposition(p):
		get_proposition(p._prop_id).value = v
		emit_changed()
		return true
	else:
		var prop := WorldServer.get_canonical_proposition(p._prop_id)
		prop.value = v
		_store_prop(p)
		emit_changed()
		return true

## Set the value of a given propostion value contained in the world using the propostion id
func set_proposition_value_with_id(id:int,value:bool) ->bool:
	if has_proposition_id(id):
		get_proposition(id).value = value
		emit_changed()
		return true
	else:
		var prop := WorldServer.get_canonical_proposition(id)
		prop.value = value
		_store_prop(prop)
		emit_changed()
		return true

## Remove proposition with matching id from world
func remove_proposition(p:Proposition):
	if has_proposition(p):
		var prop := get_proposition(p._prop_id)
		if _propositions.erase(p._prop_id):
			_unwire_prop(prop)
			emit_changed()
			return true
		else:
			return false


## Remove proposition from world with the id provided
func remove_proposition_with_id(id: int) -> bool:
	var prop := get_proposition(id)
	if _propositions.erase(id):
		_unwire_prop(prop)
		emit_changed()
		return true
	else:
		return false

#endregion

#region tension

## Calculate the magnitude proposition tension between this World and the World provided.
## Returns 0 if all Propositions match. 
func tension_with_world(w:World, lambda_missing:int = 0) ->int:
	var tension:int = 0
	for id in get_proposition_ids():
		if w.has_proposition_id(id):
			var p_self:Proposition = get_proposition(id)
			var p_other:Proposition = w.get_proposition(id)
			tension += p_self.diff(p_other)
		else:
			tension += lambda_missing
	return tension

## Returns the tension dictionary between this World and the World provided.
## Each key is a proposition id shared by both worlds.
## Values of '1' represent a mismatch in Proposition values.
## Values of '0' represent matching Proposition values 
func tension_vector_between_worlds(w:World) -> Dictionary[int,int]:
	var tension_vector:Dictionary[int,int] = {}
	for id in get_proposition_ids():
		if w.has_proposition_id(id):
			var p_self:Proposition = get_proposition(id)
			var p_other:Proposition = w.get_proposition(id)
			tension_vector.set(id,p_self.diff(p_other))
	return tension_vector

#endregion

#region world transforms

## Match Propsition values with Propostions from World 'w'.
## If clone_missing_props: attach a CLONE made from the SOURCE instance (p_other).
func match_propositions_with_world(w: World, clone_missing_props: bool = true) -> void:
	for id in w.get_proposition_ids():
		if has_proposition_id(id):
			set_proposition_value_with_id(id,w.get_proposition_value_with_id(id))
		elif clone_missing_props:
			_store_prop(w.get_proposition(id))		

#endregion

#region util

func make_clone() ->World:
	var clone := World.new()
	clone.name = name
	for id in _propositions:
		var prop := get_proposition(id)
		clone.set_proposition(prop,true)

	return clone

func _wire_prop(prop:Proposition):
	var cb := Callable(_on_prop_changed)
	if not prop.changed.is_connected(cb):
		print("Prop wired")
		prop.changed.connect(cb)

func _unwire_prop(prop:Proposition):
	var cb := Callable(_on_prop_changed)
	if prop != null and prop.changed.is_connected(cb):
		prop.changed.disconnect(cb)

func _on_prop_changed():
	print("World '%s' changed!" % name)
	emit_changed()

func _clear_wires():
	for id in _propositions.keys():
		_unwire_prop(_propositions[id])

func _store_prop(source_prop:Proposition) -> Proposition:
	var clone := source_prop.make_clone()
	_propositions.set(source_prop._prop_id,clone)
	_wire_prop(clone)
	return clone

func _rewire_all_props():
	var cb := Callable(_on_prop_changed)
	for id in _propositions.keys():
		var p: Proposition = _propositions[id]
		if p == null:
			continue
		if p.changed.is_connected(cb):
			p.changed.disconnect(cb)
		p.changed.connect(cb)

func connect_all_changed_to_callable(cb:Callable):
	for id in _propositions.keys():
		var prop:Proposition = _propositions[id]
		prop.connect_changed_to_callable(cb)

func disconnect_all_changed_from_callable(cb:Callable):
	for id in _propositions.keys():
		var prop:Proposition = _propositions[id]
		prop.disconnect_changed_from_callable(cb)
