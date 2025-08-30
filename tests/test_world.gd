extends GutTest

# Tests for the World resource: verify clone behavior, matching between
# worlds, tension calculations, and that non-canonical ids are ignored.

# ---------------- Helpers ----------------
## Reset WorldServer to a clean deterministic state used by tests.
func _reset_ws() -> void:
	if WorldServer.has_method("reset_for_tests"):
		WorldServer.reset_for_tests()
	else:
		WorldServer._propositions.clear()
		WorldServer._next_id = 1
		WorldServer.world_name = "Actual"
		if WorldServer.has_method("clear_themes"):
			WorldServer.clear_themes()

## Create three canonical propositions for tests (door, night, hungry).
func _mk_props() -> Dictionary:
	return {
		door   = WorldServer.create_proposition("DoorLocked", true),
		night  = WorldServer.create_proposition("IsNight", false),
		hungry = WorldServer.create_proposition("IsHungry", false),
	}

## Helper to produce a clone of a proposition with a chosen value.
func _rumor(p: Proposition, v: bool) -> Proposition:
	return p.make_clone(v)

# -------------- Setup ---------------
## Reset WorldServer before each test for deterministic ids and state.
func before_each() -> void:
	_reset_ws()

# -------------- Tests ---------------

func test_add_or_update_prop_rejects_non_canonical_ids() -> void:
	# Ensure the World refuses to accept propositions that aren't
	# registered in the canonical WorldServer (non-canonical IDs).
	var w := World.new()
	var bogus := Proposition.new()
	bogus._prop_id = 99999
	bogus.value = true
	w.add_or_update_prop(bogus, true)   # should be rejected
	assert_false(w.propositions.has(99999))

func test_add_or_update_prop_stores_a_clone_not_the_provided_instance() -> void:
	# When adding a proposition, the World must store a clone of the
	# provided instance (never the canonical instance itself).
	var P = _mk_props()
	var w := World.new()
	w.add_or_update_prop(P.door, true)
	assert_true(w.propositions.has(P.door._prop_id))
	var stored := w.propositions[P.door._prop_id]
	assert_false(stored == P.door)
	assert_eq(stored.value, P.door.value)

func test_add_or_update_prop_override_false_keeps_existing_instance_and_value() -> void:
	# With override=false the world should keep the existing instance and value.
	var P = _mk_props()
	var w := World.new()
	w.add_or_update_prop(_rumor(P.night, true), true) # store true
	var inst := w.propositions[P.night._prop_id]
	# attempt to change via override=false
	w.add_or_update_prop(_rumor(P.night, false), false)
	assert_true(w.propositions[P.night._prop_id] == inst)
	assert_true(w.propositions[P.night._prop_id].value)

func test_add_or_update_prop_override_true_updates_in_place_without_swapping_instance() -> void:
	# With override=true the value is updated in-place and the stored
	# object identity is preserved.
	var P = _mk_props()
	var w := World.new()
	w.add_or_update_prop(_rumor(P.hungry, false), true)
	var inst := w.propositions[P.hungry._prop_id]
	w.add_or_update_prop(_rumor(P.hungry, true), true)
	assert_true(w.propositions[P.hungry._prop_id] == inst) # same object
	assert_true(w.propositions[P.hungry._prop_id].value)   # value updated

func test_set_value_by_prop_id_is_noop_when_missing() -> void:
	# set_value_by_prop_id should not auto-attach a missing proposition.
	var P = _mk_props()
	var w := World.new()
	w.set_value_by_prop_id(P.door._prop_id, false)  # not present -> no-op
	assert_false(w.propositions.has(P.door._prop_id))

func test_set_value_by_prop_id_updates_present_clone_only() -> void:
	# set_value_by_prop_id should update the stored clone's value only.
	var P = _mk_props()
	var w := World.new()
	w.add_or_update_prop(P.door, true)
	w.set_value_by_prop_id(P.door._prop_id, false)
	assert_false(w.propositions[P.door._prop_id].value)

func test_get_value_by_prop_id_returns_default_when_absent() -> void:
	# When an id is absent, get_value_by_prop_id should return the provided default.
	var w := World.new()
	assert_eq(w.get_value_by_prop_id(123, "x"), "x")

func test_remove_prop_and_prop_ids_sorted_check() -> void:
	# Removing a proposition should free the slot and prop_ids should reflect it.
	var P = _mk_props()
	var w := World.new()
	w.add_or_update_prop(P.door, true)
	w.add_or_update_prop(P.night, true)
	var ids := w.prop_ids()
	assert_true(ids.has(P.door._prop_id))
	assert_true(ids.has(P.night._prop_id))
	w.remove_prop(P.door._prop_id)
	assert_false(w.propositions.has(P.door._prop_id))

func test_match_props_from_world_clones_from_source_when_missing_and_ignores_noncanonical() -> void:
	# match_props_from_world should clone values from the source World for
	# canonical ids and ignore any non-canonical ids that were inserted
	# improperly into the source's propositions map.
	var P = _mk_props()
	var src := World.new()
	var dst := World.new()

	# legit values in src
	src.add_or_update_prop(_rumor(P.door, false), true)  # door=false
	src.add_or_update_prop(_rumor(P.night, true), true)  # night=true

	# sneak a bogus id into src by bypassing API guard
	var bogus := Proposition.new()
	bogus._prop_id = 55555
	bogus.value = true
	src.propositions[bogus._prop_id] = bogus

	dst.match_props_from_world(src)  # default: clone_missing_props=true

	assert_true(dst.propositions.has(P.door._prop_id))
	assert_true(dst.propositions.has(P.night._prop_id))
	assert_false(dst.propositions.has(55555), "non-canonical must be ignored")

func test_match_props_from_world_updates_existing_via_setter() -> void:
	# If a slot already exists in the destination World, its value should
	# be updated in-place (preserving object identity) when matching.
	var P = _mk_props()
	var src := World.new()
	var dst := World.new()
	dst.add_or_update_prop(_rumor(P.door, false), true)
	var inst := dst.propositions[P.door._prop_id]
	src.add_or_update_prop(_rumor(P.door, true), true)   # source says true
	dst.match_props_from_world(src)
	assert_true(dst.propositions[P.door._prop_id] == inst)
	assert_true(dst.propositions[P.door._prop_id].value)

func test_match_props_from_world_subset_and_flag_false() -> void:
	# When passing a subset of ids to match_props_from_world, test both
	# behaviors: with clone_missing_props=false nothing should be attached;
	# with true the requested subset should be attached.
	var P = _mk_props()
	var src := World.new()
	var dst := World.new()
	src.add_or_update_prop(P.door, true)
	src.add_or_update_prop(P.night, true)
	dst.match_props_from_world(src, PackedInt32Array([P.door._prop_id]), false)
	assert_false(dst.propositions.has(P.door._prop_id))
	dst.match_props_from_world(src, PackedInt32Array([P.door._prop_id]), true)
	assert_true(dst.propositions.has(P.door._prop_id))
	assert_false(dst.propositions.has(P.night._prop_id))

func test_tension_against_respects_lambda_missing() -> void:
	# Tension should account for value differences and optionally penalize
	# missing propositions via lambda_missing parameter.
	var P = _mk_props()
	var a := World.new()
	var b := World.new()
	a.add_or_update_prop(_rumor(P.door, true), true)
	a.add_or_update_prop(_rumor(P.night, false), true)
	b.add_or_update_prop(_rumor(P.door, false), true)  # differs door
	# b missing night
	assert_eq(a.tension_against(b, 0), 1)
	assert_eq(a.tension_against(b, 2), 3) # 1 diff + 1 missing*2

func test_tension_symmetric_counts_union_and_missing_both_sides() -> void:
	# Symmetric tension should consider the union of ids and apply missing
	# penalties on both sides appropriately.
	var P = _mk_props()
	var a := World.new()
	var b := World.new()
	a.add_or_update_prop(_rumor(P.door, true), true)
	b.add_or_update_prop(_rumor(P.night, true), true)
	# union {door, night}: both missing one each
	assert_eq(a.tension_symmetric(b, 5, 2), 7)

func test_diff_is_directional_and_reports_missing_on_other_side() -> void:
	# diff should be directional: entries reflect values present in self and
	# other; missing entries should be represented with null on the missing side.
	var P = _mk_props()
	var a := World.new()
	var b := World.new()
	a.add_or_update_prop(_rumor(P.door, true), true)
	b.add_or_update_prop(_rumor(P.door, false), true)
	b.add_or_update_prop(_rumor(P.night, true), true)

	var d_ab := a.diff(b)
	assert_true(d_ab.has(P.door._prop_id))
	assert_eq_deep(d_ab[P.door._prop_id], {"self": true, "other": false})
	assert_true(d_ab.has(P.night._prop_id))
	assert_eq_deep(d_ab[P.night._prop_id], {"self": null, "other": true})
