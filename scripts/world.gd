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
		_propositions.set(p._prop_id,p.make_clone())
		return true
	else:
		return false

## Set the value of a given proposition value contained in the world
func set_proposition_value(p:Proposition, v:bool) ->bool:
	if has_proposition(p):
		get_proposition(p._prop_id).value = v
		return true
	else:
		var prop := WorldServer.get_canonical_proposition(p._prop_id)
		prop.value = v
		set_proposition(prop)
		return true

## Set the value of a given propostion value contained in the world using the propostion id
func set_proposition_value_with_id(id:int,value:bool) ->bool:
	if has_proposition_id(id):
		get_proposition(id).value = value
		return true
	else:
		var prop := WorldServer.get_canonical_proposition(id)
		prop.value = value
		set_proposition(prop)
		return true

## Remove proposition with matching id from world
func remove_proposition(p:Proposition):
	if has_proposition(p):
		return _propositions.erase(p._prop_id)

## Remove proposition from world with the id provided
func remove_proposition_with_id(id: int) -> bool:
	return _propositions.erase(id)

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
			_propositions.set(id,w.get_proposition(id).make_clone())
		

#endregion

#region util

func make_clone() ->World:
	var clone := World.new()
	clone.name = name
	for id in _propositions:
		var prop := get_proposition(id)
		clone.set_proposition(prop,true)

	return clone