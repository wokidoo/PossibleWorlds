@tool
extends Node

signal changed()
signal db_saved(path: String)
signal db_loaded(path: String)

# Feel free to rename/keep the old; this one reflects the broader scope.
const DEFAULT_STATE_PATH := "user://default_world_state.tres"

var _propositions: Dictionary[int, Proposition] = {}
var _next_id: int = 1
@export var world_name: String = "Actual"

# canonical theme registry
var _themes: Array[StringName] = []  # sorted, unique

var _characters: Array[Character] = []
var _char_index: Dictionary[int, Character] = {}  # instance_id or internal id -> Character
var _char_ids: Dictionary = {} # Character -> id mapping (keeps id assigned for resources)
var _next_char_id: int = 1


func _init():
	load_state()

func create_proposition(description: String, default_value: bool) -> Proposition:
	var p := Proposition.new()
	p.description = description
	p.value = default_value
	register_new_proposition(p)
	return p

func register_new_proposition(p: Proposition) -> bool:
	if p == null:
		return false
	if p._prop_id != 0:
		var existing: Proposition = _propositions.get(p._prop_id, null)
		if existing != null:
			# idempotent: same instance OK; different instance rejected
			return existing == p
		_propositions[p._prop_id] = p
		p._is_canonical = true
		_next_id = max(_next_id, p._prop_id + 1)
		emit_signal("changed")
		return true

	# assign new id
	p._prop_id = _allocate_id()
	p._is_canonical = true
	_propositions[p._prop_id] = p
	emit_signal("changed")
	return true

func remove_proposition(id: int) -> bool:
	var ok := _propositions.erase(id)
	if ok:
		emit_signal("changed")
	return ok

func is_registered_id(id: int) -> bool:
	return _propositions.has(id)

func get_proposition(id: int) -> Proposition:
	return _propositions.get(id, null)

func prop_ids() -> PackedInt32Array:
	var out := PackedInt32Array()
	for id in _propositions.keys():
		out.append(id)
	out.sort()
	return out

# -----------------------------------------------------------------------------
# Canonical propostion access
# -----------------------------------------------------------------------------

func set_canonical_value(id: int, value: bool) -> void:
	var p :Proposition = _propositions.get(id, null)
	if p == null:
		push_error("WorldServer.set_canonical_value: unknown id=%s" % id)
		return
	p.value = value
	emit_signal("changed")

func get_canonical_value(id: int, default: Variant = null) -> Variant:
	var p :Proposition = _propositions.get(id, null)
	return (p.value if p != null else default)

func create_clone_proposition(id: int, override_value: Variant = null) -> Proposition:
	var src: Proposition = _propositions.get(id, null)
	if src == null:
		push_error("WorldServer.create_clone_proposition: unknown id=%s" % id)
		return null
	return src.make_clone(override_value)

# -----------------------------------------------------------------------------
# Canonical theme access
# -----------------------------------------------------------------------------

func register_theme(theme: StringName) -> bool:
	var s := String(theme).strip_edges()
	if s == "": 
		push_error("register_theme: empty theme name"); 
		return false
	var idx := _theme_lower_bound(theme)
	if idx < _themes.size() and _themes[idx] == theme:
		return false  # already present (idempotent)
	_themes.insert(idx, theme)  # keep sorted & unique
	emit_signal("changed")
	return true

func ensure_theme(theme: StringName) -> void:
	var s := String(theme).strip_edges()
	if s == "": return
	var idx := _theme_lower_bound(theme)
	if idx < _themes.size() and _themes[idx] == theme:
		return
	_themes.insert(idx, theme)
	emit_signal("changed")

func remove_theme(theme: StringName) -> bool:
	var idx := _theme_lower_bound(theme)
	if idx < _themes.size() and _themes[idx] == theme:
		_themes.remove_at(idx)
		emit_signal("changed")
		return true
	return false

func has_theme(theme: StringName) -> bool:
	var idx := _theme_lower_bound(theme)
	return idx < _themes.size() and _themes[idx] == theme

func themes() -> Array[StringName]:
	# Already sorted; return a shallow copy if you want to protect internal state.
	return _themes.duplicate()

func clear_themes() -> void:
	_themes.clear()
	emit_signal("changed")

# -----------------------------------------------------------------------------
# Character access
# -----------------------------------------------------------------------------

func add_character(c: Character) -> int:
	if c == null:
		push_error("add_character: null")
		return -1
	if has_character(c):
		push_error("add_character: character already registerd in WorldServer")
		return -1
	_characters.append(c)
	# Use the object's instance id when available (>0). For Resource-based
	# Characters instance ids may be zero; in that case assign a server-side
	# stable id so callers receive a positive id and lookups work.
	var id: int = int(c.get_instance_id())
	if id <= 0:
		id = _next_char_id
		_next_char_id += 1
	_char_index[id] = c
	_char_ids[c] = id
	emit_signal("changed")
	return id

func remove_character_instance(c: Character) -> bool:
	var i := _characters.find(c)
	if i == -1:
		return false
	_characters.remove_at(i)
	# Erase the index using the stored id (handles resource-based characters).
	var id: int = int(_char_ids.get(c, -1))
	if id == -1:
		# fallback: find any index key that references this character and erase it
		for key in _char_index.keys():
			if _char_index[key] == c:
				_char_index.erase(key)
				break
	else:
		_char_index.erase(id)
		_char_ids.erase(c)
	emit_signal("changed")
	return true

func character_at(i: int) -> Character:
	return _characters[i] if i >= 0 and i < _characters.size() else null

func get_character_by_instance_id(id: int) -> Character:
	return _char_index.get(id, null)

func characters() -> Array[Character]:
	return _characters.duplicate()

func character_count() -> int:
	return _characters.size()

func has_character(c:Character) ->bool:
	return _characters.has(c)

# Call this after load_state(), or anytime you bulk-replace _characters.
func _rebuild_character_index() -> void:
	_char_index.clear()
	# Rebuild runtime lookup. Preserve any server-assigned ids stored in
	# _char_ids; if no id exists for an entry, assign a new stable id.
	for c in _characters:
		if c != null:
			var id: int = int(_char_ids.get(c, c.get_instance_id()))
			if id == 0:
				id = _next_char_id
				_next_char_id += 1
				_char_ids[c] = id
			_char_index[id] = c

# -----------------------------------------------------------------------------
# Interop with non-canonical World (your clone-only World.gd)
# -----------------------------------------------------------------------------

## Apply values from a non-canonical world to the canonical world (only for ids that exist canonically).
func match_props_from_world(src: World, ids: PackedInt32Array = PackedInt32Array()) -> void:
	if src == null: return
	var to_apply := ids
	if to_apply.is_empty():
		to_apply = src.prop_ids()
	to_apply.sort()
	for id in to_apply:
		var p_src :Proposition = src.propositions.get(id, null)
		if p_src == null:
			continue
		if not _propositions.has(id):
			# canonical world doesn't know this id; skip
			continue
		_propositions[id].value = p_src.value
	emit_signal("changed")

## Tension of canonical world (this server) against a given world.
func tension_against_world(src_world: World, lambda_missing: int = 0) -> int:
	if src_world == null: return 0
	var t := 0
	var ids := prop_ids(); ids.sort()
	for id in ids:
		var theirs :Proposition= src_world.propositions.get(id, null)
		if theirs == null:
			t += lambda_missing
		else:
			t += _distance_scalar(_propositions[id].value, theirs.value)
	return t

## Symmetric tension across union of canonical ids and src_world ids.
func tension_symmetric_with(src_world: World, lambda_missing_here: int = 0, lambda_missing_there: int = 0) -> int:
	if src_world == null: return 0
	var t := 0
	var visited := {}
	var ids_here := prop_ids(); ids_here.sort()
	for id in ids_here:
		visited[id] = true
		var theirs :Proposition= src_world.propositions.get(id, null)
		if theirs == null:
			t += lambda_missing_there
		else:
			t += _distance_scalar(_propositions[id].value, theirs.value)
	var ids_there := src_world.prop_ids(); ids_there.sort()
	for id in ids_there:
		if visited.has(id): continue
		t += lambda_missing_here
	return t

## Diff between canonical and src_world.
## Returns { id: { "canon": bool|Null, "world": bool|Null } }
func diff_with(src_world: World) -> Dictionary:
	var out := {}
	if src_world == null: return out
	var visited := {}
	for id in _propositions.keys():
		visited[id] = true
		var v_here := _propositions[id].value
		var p_there :Proposition= src_world.propositions.get(id, null)
		if p_there != null and v_here != p_there.value:
			out[id] = {"canon": v_here, "world": p_there.value}
	for id in src_world.propositions.keys():
		if visited.has(id): continue
		out[id] = {"canon": null, "world": src_world.propositions[id].value}
	return out

## Build a read-only view of the canonical world as a World (with CLONES).
func snapshot_as_world(out_name: String = world_name) -> World:
	var w := World.new()
	w.name = out_name
	var ids := prop_ids(); ids.sort()
	for id in ids:
		var p := _propositions[id]
		w.propositions[id] = p.make_clone(p.value)
	return w

func snapshot_as_world_state() ->WorldState:
	var state := WorldState.new()
	state.world_name = world_name
	state.schema_version = 1

	# Propositions (deterministic order)
	for id in prop_ids():
		state.propositions.append(_propositions[id])

	# Themes (already sorted)
	for t in themes():
		state.themes.append(t)

	# Characters: save in current array order
	for c in _characters:
		if c != null:
			state.characters.append(c)
	return state
# -----------------------------------------------------------------------------
# Persistence (single DB resource with all canonical propositions)
# -----------------------------------------------------------------------------

func save_state(path: String = DEFAULT_STATE_PATH) -> bool:
	var state := snapshot_as_world_state()
	print("WorldServer.save_state: attempting to save state to %s" % path)
	var err := ResourceSaver.save(state, path)
	if err != OK:
		push_error("WorldServer.save_state: failed to save %s (err=%s)" % [path, str(err)])
		return false

	print("WorldServer.save_state: saved state to %s" % path)
	emit_signal("db_saved", path)
	return true


func load_state(path: String = DEFAULT_STATE_PATH) -> bool:
	var state: WorldState = ResourceLoader.load(path)
	if state == null:
		push_error("WorldServer.load_state: failed to load %s" % path)
		return false

	# Rebuild propositions
	_propositions.clear()
	_next_id = 1
	var max_id := 0
	for p in state.propositions:
		if p == null: continue
		if p._prop_id == 0:
			push_error("WorldServer.load_state: proposition missing id; skipping")
			continue
		p._is_canonical = true
		_propositions[p._prop_id] = p
		max_id = max(max_id, p._prop_id)
	_next_id = max(_next_id, max_id + 1)

	# Rebuild themes
	_themes.clear()
	for t in state.themes:
		var s := String(t).strip_edges()
		if s != "":
			register_theme(StringName(s))

	# Rebuild characters (array order preserved) and runtime index
	_characters.clear()
	for ch in state.characters:
		if ch != null:
			_characters.append(ch)
	_rebuild_character_index()

	# Metadata
	world_name = (state.world_name if String(state.world_name).strip_edges() != "" else "Actual")

	emit_signal("db_loaded", path)
	emit_signal("changed")
	return true


# -----------------------------------------------------------------------------
# Internals
# -----------------------------------------------------------------------------

func _allocate_id() -> int:
	while _propositions.has(_next_id):
		_next_id += 1
	var id := _next_id
	_next_id += 1
	return id

## Test helper: reset internal state for unit tests without direct field mutation.
func _reset_for_tests() -> void:
	_propositions.clear()
	_next_id = 1
	world_name = "Actual"
	_themes.clear()
	emit_signal("changed")

static func _distance_scalar(a: Variant, b: Variant) -> int:
	if typeof(a) == TYPE_BOOL and typeof(b) == TYPE_BOOL:
		return int(a != b)
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return abs(int(a) - int(b))
	return int(a != b)

func _theme_lower_bound(theme: StringName) -> int:
	# binary search for insertion point; compares lexicographically by String
	var lo := 0
	var hi := _themes.size()
	var key := String(theme)
	while lo < hi:
		var mid := (lo + hi) >> 1
		if String(_themes[mid]) < key:
			lo = mid + 1
		else:
			hi = mid
	return lo