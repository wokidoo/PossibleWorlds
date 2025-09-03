@tool
extends Node

signal changed()
signal db_saved(path: String)
signal db_loaded(path: String)

# Feel free to rename/keep the old; this one reflects the broader scope.
const DEFAULT_STATE_PATH := "user://default_world_state.tres"

var _canonical_world: World = World.new()
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

#region propostion

func create_canonical_proposition(description: String, default_value: bool) -> Proposition:
	var p := Proposition.new()
	p.description = description
	p.value = default_value
	register_new_proposition(p)
	return p


func register_new_proposition(p: Proposition) -> bool:
	if p._prop_id != 0:
		var existing: Proposition = _canonical_world.get_proposition(p._prop_id)
		if existing != null:
			# idempotent: same id OK (instance may differ)
			return existing._prop_id == p._prop_id

		p._is_canonical = true
		_canonical_world.set_proposition(p)
		# ensure the stored (cloned) instance is marked canonical
		var stored := _canonical_world.get_proposition(p._prop_id)
		if stored != null:
			stored._is_canonical = true
		emit_signal("changed")
		return true

	# assign new id
	p._prop_id = _allocate_id()
	p._is_canonical = true
	_canonical_world.set_proposition(p)
	var stored2 := _canonical_world.get_proposition(p._prop_id)
	if stored2 != null:
		stored2._is_canonical = true
	emit_signal("changed")
	return true


func remove_canonical_proposition(id: int) -> bool:
	var ok := _canonical_world.remove_proposition_with_id(id)
	if ok:
		emit_signal("changed")
	return ok


func get_canonical_proposition(id:int) ->Proposition:
	return _canonical_world.get_proposition(id)


func has_canonical_proposition_with_id(id: int) -> bool:
	var prop := _canonical_world.get_proposition(id)
	if prop != null and prop._is_canonical:
		return true
	return false


func get_canonical_proposition_ids() -> Array[int]:
	return _canonical_world.get_proposition_ids()


func set_canonical_value(id: int, value: bool) -> void:
	if _canonical_world.has_proposition_id(id):
		_canonical_world.set_proposition_value_with_id(id,value)
		emit_signal("changed")
	else:
		return


func get_canonical_value(id: int, default: Variant = null) -> Variant:
	var v = _canonical_world.get_proposition_value_with_id(id)
	return (v if v != null else default)



#region canonical world

func get_canonical_world() ->World:
	return _canonical_world

#region theme

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


func get_themes() -> Array:
	# Already sorted; return a shallow copy if you want to protect internal state.
	return _themes


func clear_themes() -> void:
	_themes.clear()
	emit_signal("changed")

#endregion

#region characters

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


#endregion

func snapshot_as_world_state() ->WorldState:
	var state := WorldState.new()
	state.world_name = world_name
	state.schema_version = 1

	# Canonical world
	state.canonical_world = _canonical_world

	# Themes (already sorted)
	for t in get_themes():
		state.themes.append(t)

	# Characters: save in current array order
	for c in _characters:
		if c != null:
			state.characters.append(c)
	return state

#region save/load

#region save/load

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

	# --- Canonical world (direct from state) ---
	_canonical_world = (state.canonical_world if state.canonical_world != null else World.new())

	# Ensure canonical flags and rebuild next id from actual propositions
	var max_id := 0
	for id in _canonical_world.get_proposition_ids():
		var p: Proposition = _canonical_world.get_proposition(id)
		if p != null:
			p._is_canonical = true
			max_id = max(max_id, id)
	_next_id = max(1, max_id + 1)

	# --- Themes (already saved sorted/unique; sanitize and insert) ---
	_themes.clear()
	for t in state.themes:
		var s := String(t).strip_edges()
		if s != "":
			ensure_theme(StringName(s))

	# --- Characters (preserve array order) ---
	_characters.clear()
	for ch in state.characters:
		if ch != null:
			_characters.append(ch)
	_rebuild_character_index()

	# --- Metadata ---
	world_name = (state.world_name if String(state.world_name).strip_edges() != "" else "Actual")

	emit_signal("db_loaded", path)
	emit_signal("changed")
	return true


#region util

func _allocate_id() -> int:
	while _canonical_world.has_proposition_id(_next_id):
		_next_id += 1
	var id := _next_id
	_next_id += 1
	return id

func _reset_for_tests() -> void:
	_canonical_world = World.new()
	_next_id = 1
	world_name = "Actual"
	_themes.clear()

	_characters.clear()
	_char_index.clear()
	_char_ids.clear()
	_next_char_id = 1
	# Don't emit "changed" here so tests can count signals deterministically.


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

#endregion
