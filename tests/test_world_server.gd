extends GutTest

var _changed_count := 0
var _db_saved := ""
var _db_loaded := ""

# Local ephemeral server for test isolation. Access via S() which returns the
# ephemeral instance when created by before_each, otherwise falls back to the
# autoload WorldServer. This keeps tests deterministic and avoids mutating the
# running autoload during the test suite.
var _server = null

func S():
	return _server if _server != null else WorldServer

func before_each() -> void:
	# Create an ephemeral WorldServer instance to avoid mutating autoload.
	_server = preload("res://autoloads/world_server.gd").new()
	_ws_reset()

	_changed_count = 0
	_db_saved = ""
	_db_loaded = ""

	# Track signals on the ephemeral server so tests can assert side-effects.
	if not S().is_connected("changed", Callable(self, "_on_changed")):
		S().connect("changed", Callable(self, "_on_changed"))
	if not S().is_connected("db_saved", Callable(self, "_on_db_saved")):
		S().connect("db_saved", Callable(self, "_on_db_saved"))
	if not S().is_connected("db_loaded", Callable(self, "_on_db_loaded")):
		S().connect("db_loaded", Callable(self, "_on_db_loaded"))

func after_each() -> void:
	# Disconnect signals and free ephemeral server to avoid leaks and orphans.
	if S().is_connected("changed", Callable(self, "_on_changed")):
		S().disconnect("changed", Callable(self, "_on_changed"))
	if S().is_connected("db_saved", Callable(self, "_on_db_saved")):
		S().disconnect("db_saved", Callable(self, "_on_db_saved"))
	if S().is_connected("db_loaded", Callable(self, "_on_db_loaded")):
		S().disconnect("db_loaded", Callable(self, "_on_db_loaded"))

	if _server != null and is_instance_valid(_server):
		_server.free()
	_server = null

func _on_changed() -> void: _changed_count += 1
func _on_db_saved(path:String) -> void: _db_saved = path
func _on_db_loaded(path:String) -> void: _db_loaded = path

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------
func _mk3() -> Dictionary:
	# Initialize a clean server state then create three canonical props used by tests.
	_ws_reset()
	return {
		door = S().create_proposition("DoorLocked", true),
		night = S().create_proposition("IsNight", false),
		hungry = S().create_proposition("IsHungry", false),
	}

### WorldServer compatibility helpers ###
func _ws_reset() -> void:
	# Compatibility shim: support multiple autoload API names used historically.
	var server = S()
	if server == null:
		return
	if server.has_method("reset_for_tests"):
		server.reset_for_tests()
	elif server.has_method("_reset_for_tests"):
		server._reset_for_tests()
	else:
		server._propositions.clear()
		server._next_id = 1
		server.world_name = "Actual"

func _ws_save(path: String) -> bool:
	# Compatibility wrapper that tries several persistence method names.
	var server = S()
	if server == null:
		return false
	if server.has_method("save_db"):
		return server.save_db(path)
	if server.has_method("save_state"):
		return server.save_state(path)
	return false

func _ws_load(path: String) -> bool:
	var server = S()
	if server == null:
		return false
	if server.has_method("load_db"):
		return server.load_db(path)
	if server.has_method("load_state"):
		return server.load_state(path)
	return false

func _ws_match_from_world(src: World, ids: PackedInt32Array = PackedInt32Array()) -> void:
	# Compatibility wrapper to invoke the correct match-from-world API.
	var server = S()
	if server == null:
		return
	if server.has_method("match_props_from_world"):
		server.match_props_from_world(src, ids)
	elif server.has_method("match_from_world"):
		server.match_from_world(src, ids)

# -------------------------------------------------------------------
# Registration / Ids
# -------------------------------------------------------------------

func test_create_proposition_assigns_id_and_registers() -> void:
	# Creating a canonical proposition must assign a positive id, register it,
	# and emit a 'changed' signal at least once.
	var p = S().create_proposition("A", true)
	assert_true(p._prop_id > 0)
	assert_true(S().is_registered_id(p._prop_id))
	assert_true(S().get_proposition(p._prop_id) == p)
	assert_gt(_changed_count, 0, "creating should emit changed at least once")

func test_register_new_proposition_idempotent_same_instance() -> void:
	# Re-registering the same instance should succeed and not emit extra change.
	var p = S().create_proposition("A", true)
	var changed_before := _changed_count
	var ok = S().register_new_proposition(p)
	assert_true(ok, "re-register same instance is ok")
	assert_eq(_changed_count, changed_before, "no extra change when idempotent")

func test_register_new_proposition_rejects_different_instance_same_id() -> void:
	# Registering a different object with an existing id must be rejected.
	var p = S().create_proposition("A", true)
	var p2 := Proposition.new()
	p2._prop_id = p._prop_id  # simulate deserialized conflicting instance
	p2.description = "A2"
	p2.value = false

	var ok = S().register_new_proposition(p2)
	assert_false(ok, "different instance with same id should be rejected")
	assert_true(S().get_proposition(p._prop_id) == p, "original kept")

func test_remove_proposition_removes_and_emits_changed() -> void:
	# remove_proposition should unregister and emit a changed signal.
	var p = S().create_proposition("A", true)
	var changed_before := _changed_count
	assert_true(S().remove_proposition(p._prop_id))
	assert_false(S().is_registered_id(p._prop_id))
	assert_gt(_changed_count, changed_before)

func test_prop_ids_returns_all_registered_ids_sortedable() -> void:
	# prop_ids must return the list of registered ids; test sorting behavior.
	var _P = _mk3()
	var ids: PackedInt32Array = S().prop_ids()
	ids.sort()
	var sorted_array:PackedInt32Array = [_P.door._prop_id, _P.hungry._prop_id, _P.night._prop_id]
	sorted_array.sort()
	assert_eq_deep(ids, sorted_array)

# -------------------------------------------------------------------
# Character tracking (new APIs)
# -------------------------------------------------------------------

func test_add_character_registers_and_indexes() -> void:
	# add_character should append the character, return its instance id,
	# and make it queryable via get_character_by_instance_id and character_at.
	var c := Character.new()
	var id: int = S().add_character(c)
	assert_true(id > 0)
	assert_true(S().has_character(c))
	assert_eq(S().get_character_by_instance_id(id), c)
	assert_eq(S().character_at(0), c)
	assert_eq(S().character_count(), 1)
	# characters() returns an array copy that should contain our character
	assert_true(S().characters().has(c))

func test_add_character_rejects_null_and_duplicate() -> void:
	# add_character must reject null and duplicate registrations.
	assert_eq(S().add_character(null), -1)
	var c := Character.new()
	var ok: int = S().add_character(c)
	assert_true(ok > 0)
	var dup: int = S().add_character(c)
	assert_eq(dup, -1)

func test_remove_character_instance_removes_and_updates_index() -> void:
	# remove_character_instance should remove the character and clear its index entry.
	var c := Character.new()
	var id :int= S().add_character(c)
	assert_true(S().has_character(c))
	assert_true(S().remove_character_instance(c))
	assert_false(S().has_character(c))
	assert_null(S().get_character_by_instance_id(id))
	assert_eq(S().character_count(), 0)

func test_rebuild_character_index_restores_lookup_when_cleared() -> void:
	# _rebuild_character_index should repopulate the runtime index from the characters array.
	var server :WorldServer= S()
	var c1 := Character.new()
	var c2 := Character.new()
	var id1 := server.add_character(c1)
	var id2 := server.add_character(c2)
	# sanity
	assert_eq(server.get_character_by_instance_id(id1), c1)
	# clear the runtime index and verify lookup is broken
	server._char_index.clear()
	assert_null(server.get_character_by_instance_id(id1))
	# now rebuild and verify lookups work again
	server._rebuild_character_index()
	assert_eq(server.get_character_by_instance_id(id1), c1)
	assert_eq(server.get_character_by_instance_id(id2), c2)

# -------------------------------------------------------------------
# Canonical value APIs
# -------------------------------------------------------------------

func test_set_and_get_canonical_value() -> void:
	# set_canonical_value and get_canonical_value should set values and accept defaults.
	var p = S().create_proposition("A", true)
	S().set_canonical_value(p._prop_id, false)
	assert_false(S().get_canonical_value(p._prop_id))
	assert_true(S().get_canonical_value(123456, "x") == "x", "default for unknown id")

# -------------------------------------------------------------------
# Cloning
# -------------------------------------------------------------------

func test_create_clone_proposition_returns_independent_clone() -> void:
	# create_clone_proposition must return a distinct clone instance that doesn't
	# mutate the canonical when changed.
	var p = S().create_proposition("A", true)
	var clone = S().create_clone_proposition(p._prop_id)
	assert_not_null(clone)
	assert_false(clone == p, "clone is different instance")
	assert_eq(clone._prop_id, p._prop_id, "same id")
	assert_true(clone.value, "copied value initially")
	clone.value = false
	assert_true(S().get_canonical_value(p._prop_id), "changing clone does not change canonical")

# -------------------------------------------------------------------
# match_from_world (apply values from a non-canonical World)
# -------------------------------------------------------------------

func test_match_from_world_applies_only_known_ids() -> void:
	# match_from_world must only apply values for known proposition ids and ignore unknowns.
	var _P = _mk3()
	# Canonical: door=true, night=false, hungry=false

	# Build a non-canonical world with clones
	var w := World.new()
	w.add_or_update_prop(_P.door, true)                 # clone door=true (same as canonical)
	w.add_or_update_prop(_P.night.make_clone(true), true)  # clone night=true (DIFFERS)
	# Add an unknown-id proposition into world to ensure it's skipped
	var bogus := Proposition.new()
	bogus._prop_id = 99999
	bogus.description = "Bogus"
	bogus.value = true
	w.add_or_update_prop(bogus, true)

	_ws_match_from_world(w)
	# door stays true, night becomes true, hungry unchanged
	assert_true(S().get_canonical_value(_P.door._prop_id))
	assert_true(S().get_canonical_value(_P.night._prop_id))   # now true
	assert_false(S().get_canonical_value(_P.hungry._prop_id)) # unchanged
	# unknown id must be ignored
	assert_null(S().get_proposition(99999))

func test_match_from_world_with_subset_ids_only() -> void:
	# When provided with a subset of ids, only those should be applied.
	var _P = _mk3()
	var w := World.new()
	w.add_or_update_prop(_P.door, true)
	w.add_or_update_prop(_P.night, true)
	w.add_or_update_prop(_P.hungry, true)

	_ws_match_from_world(w, PackedInt32Array([_P.door._prop_id])) # only door
	assert_true(S().get_canonical_value(_P.door._prop_id))
	assert_false(S().get_canonical_value(_P.night._prop_id))
	assert_false(S().get_canonical_value(_P.hungry._prop_id))

# -------------------------------------------------------------------
# Tension / Diff
# -------------------------------------------------------------------

func test_tension_against_world_and_symmetric() -> void:
	var _P = _mk3()
	# Canonical: door=true, night=false, hungry=false
	var w := World.new()
	w.add_or_update_prop(_P.door.make_clone(false), true) # 1 diff (door)
	# w has no night/hungry -> two missings

	assert_eq(S().tension_against_world(w, 0), 1)
	assert_eq(S().tension_against_world(w, 2), 5, "1 diff + two missing (2 each) = 5")

	assert_eq(S().tension_symmetric_with(w, 5, 2), 1 + 2 + 2, "1 diff + two others-missing=2 each")


func test_diff_with_reports_differences_and_missing() -> void:
	var _P = _mk3()
	var w := World.new()
	w.add_or_update_prop(_P.door.make_clone(false), true)  # differs
	# w missing night & hungry

	var d = S().diff_with(w)
	assert_true(d.has(_P.door._prop_id))
	assert_eq_deep(d[_P.door._prop_id], {"canon": true, "world": false})
	assert_false(d.has(_P.night._prop_id), "canonical-only not listed in first pass")

	# now world has hungry only (different)
	var w2 := World.new()
	w2.add_or_update_prop(_P.hungry.make_clone(true), true)

	var d2 = S().diff_with(w2)
	assert_true(d2.has(_P.hungry._prop_id))
	assert_eq_deep(d2[_P.hungry._prop_id], {"canon": false, "world": true})

# -------------------------------------------------------------------
# snapshot_as_world (produces a World of clones)
# -------------------------------------------------------------------

func test_snapshot_as_world_returns_clones_not_canonicals() -> void:
	var _P = _mk3()
	var snap: World = S().snapshot_as_world("Snapshot")
	assert_eq(snap.name, "Snapshot")
	var ids: PackedInt32Array = snap.prop_ids(); ids.sort()
	var world_id_array = S().prop_ids()
	world_id_array.sort()
	assert_eq_deep(ids, world_id_array)
	for id in ids:
		var clone: Proposition = snap.propositions[id]
		var canon: Proposition = S().get_proposition(id)
		assert_false(clone == canon, "snapshot holds clones, not canonical instances")
		assert_eq(clone._prop_id, canon._prop_id)
		assert_eq(clone.value, canon.value)

# -------------------------------------------------------------------
# Persistence: save_db / load_db round-trip
# -------------------------------------------------------------------

func test_save_and_load_db_roundtrip() -> void:
	var _P = _mk3()
	S().set_canonical_value(_P.night._prop_id, true)

	var path := "user://worldserver_props_test.tres"
	assert_true(_ws_save(path))
	assert_eq(_db_saved, path)

	_ws_reset()
	assert_eq(S().prop_ids().size(), 0)

	assert_true(_ws_load(path))
	assert_eq(_db_loaded, path)

	var ids :Array= S().prop_ids(); ids.sort()
	assert_eq(ids.size(), 3)
	assert_true(ids.has(_P.door._prop_id))
	assert_true(ids.has(_P.night._prop_id))
	assert_true(ids.has(_P.hungry._prop_id))

	assert_true(S().get_canonical_value(_P.door._prop_id))
	assert_true(S().get_canonical_value(_P.night._prop_id))
	assert_false(S().get_canonical_value(_P.hungry._prop_id))

	var next = S().create_proposition("NewOne", false)
	assert_true(next._prop_id > ids.max())

	# ---- cleanup on success ----
	_remove_if_exists(path)

# -------------------------------------------------------------------
# Utilities
# -------------------------------------------------------------------

# add near the top of the file
func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)  # Godot 4
		if err != OK:
			push_warning("Couldn't delete %s: %s" % [path, error_string(err)])
