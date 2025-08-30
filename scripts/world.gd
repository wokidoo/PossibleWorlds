@tool
extends Resource
class_name World

## Non-canonical world: holds only propositions it cares about.
## Keys: prop_id -> Proposition (always CLONES, never canonical instances)
@export var propositions: Dictionary[int, Proposition] = {}
@export var name: String = ""

# -----------------------------------------------------------------------------
# CRUD (never call PropositionServer here)
# -----------------------------------------------------------------------------

## Add/replace a proposition. Always store a CLONE of the PROVIDED instance.
## If override=false and id exists, keep existing instance & value.
func add_or_update_prop(p: Proposition, override: bool = true) -> void:
	if not WorldServer.is_registered_id(p._prop_id):
		push_error("World.add_or_update_prop: proposition must be registered in WorldeServer with _prop_id")
		return
	var id := p._prop_id

	if propositions.has(id):
		if not override:
			return
		# Update in place to preserve identity
		propositions[id].value = p.value
		return

	var clone :Proposition = p.make_clone(p.value)
	if clone == null:
		push_error("World.add_or_update_prop: failed to clone id=%s" % id)
		return
	propositions[id] = clone

## Set value for an id that THIS world already tracks. If missing -> no-op.
func set_value_by_prop_id(id: int, value: bool) -> void:
	var prop :Proposition = propositions.get(id, null)
	if prop == null:
		return
	prop.value = value

## Get value if present; else default (null by default).
func get_value_by_prop_id(id: int, default: Variant = null) -> Variant:
	var p : Proposition = propositions.get(id, null)
	return (p.value if p != null else default)

## Remove slot (does not affect server).
func remove_prop(id: int) -> void:
	propositions.erase(id)

## Present prop ids.
func prop_ids() -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(propositions.size())
	var i := 0
	for id in propositions.keys():
		out[i] = id
		i += 1
	out.sort()
	return out

# -----------------------------------------------------------------------------
# Tension / distance
# -----------------------------------------------------------------------------

func tension_against(other: World, lambda_missing: int = 0) -> int:
	if other == null:
		return 0
	var t := 0
	var ids := prop_ids(); ids.sort()
	for id in ids:
		var mine : Proposition = propositions[id]
		var theirs :Proposition = other.propositions.get(id, null)
		t += (lambda_missing if theirs == null else _distance_scalar(mine.value, theirs.value))
	return t

func tension_symmetric(other: World, lambda_missing_self: int = 0, lambda_missing_other: int = 0) -> int:
	if other == null:
		return 0
	var t := 0
	var visited := {}
	var ids_self := prop_ids(); ids_self.sort()
	for id in ids_self:
		visited[id] = true
		var mine : Proposition = propositions[id]
		var theirs :Proposition = other.propositions.get(id, null)
		t += (lambda_missing_other if theirs == null else _distance_scalar(mine.value, theirs.value))
	var ids_other := other.prop_ids(); ids_other.sort()
	for id in ids_other:
		if visited.has(id): continue
		t += lambda_missing_self
	return t

# -----------------------------------------------------------------------------
# World-to-world transforms
# -----------------------------------------------------------------------------

## Copy values from another world.
## If clone_missing_props: attach a CLONE made from the SOURCE instance (p_other).
func match_props_from_world(
	other: World,
	ids: PackedInt32Array = PackedInt32Array(),
	clone_missing_props: bool = true
) -> void:
	if other == null:
		return
	var to_apply := ids
	if to_apply.is_empty():
		to_apply = other.prop_ids()
	to_apply.sort()

	for id in to_apply:
		if not WorldServer.is_registered_id(id):
			continue

		var p_other: Proposition = other.propositions.get(id, null)
		if p_other == null:
			continue

		if propositions.has(id):
			set_value_by_prop_id(id, p_other.value)
		elif clone_missing_props:
			var clone: Proposition = p_other.make_clone(p_other.value)
			if clone != null:
				propositions[id] = clone

## Differences: { id: { "self": bool|Null, "other": bool } }
func diff(other: World) -> Dictionary:
	var out := {}
	if other == null: return out
	var visited := {}
	for id in propositions.keys():
		visited[id] = true
		var a :Proposition = propositions[id]
		var b :Proposition = other.propositions.get(id, null)
		if b != null and a.value != b.value:
			out[id] = {"self": a.value, "other": b.value}
	for id in other.propositions.keys():
		if visited.has(id): continue
		out[id] = {"self": null, "other": other.propositions[id].value}
	return out

# -----------------------------------------------------------------------------
# Internals
# -----------------------------------------------------------------------------

static func _distance_scalar(a: Variant, b: Variant) -> int:
	if typeof(a) == TYPE_BOOL and typeof(b) == TYPE_BOOL:
		return int(a != b)
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return abs(int(a) - int(b))
	return int(a != b)
