extends GutTest

func _mk_prop(id:int, val:bool, canonical:bool=true, desc:String="") -> Proposition:
	var p := Proposition.new()
	p._prop_id = id
	p._is_canonical = canonical
	p.description = desc
	p.value = val
	return p

func _mk_world(props:Array[Proposition], name:="") -> World:
	var w := World.new()
	w.name = name
	for p in props:
		w.set_proposition(p, true)
	return w

#region basics

func test_defaults() -> void:
	var w := World.new()
	assert_eq(w.name, "", "Default world name should be empty.")
	assert_true(w.get_propositions().is_empty(), "Default propositions should be empty.")
	assert_true(w.get_proposition_ids().is_empty(), "Default proposition id list should be empty.")

func test_set_and_get_proposition_clones_source() -> void:
	var src := _mk_prop(1, true, true, "src")
	var w := World.new()
	var ok := w.set_proposition(src, true)
	assert_true(ok, "set_proposition should return true when adding new.")
	var stored := w.get_proposition(1)
	assert_not_null(stored, "Stored proposition should exist.")
	assert_true(stored is Proposition, "Stored value should be a Proposition.")
	assert_ne(stored, src, "World should store a CLONE, not the original instance.")
	assert_false(stored.is_canonical_proposition(), "Clone should not be canonical.")
	assert_true(stored.value, "Clone value should match source when no override is used.")

func test_getters_and_has_checks() -> void:
	var a := _mk_prop(1, true)
	var b := _mk_prop(2, false)
	var w := _mk_world([a, b])

	assert_true(w.has_proposition_id(1), "World should have id=1.")
	assert_true(w.has_proposition(a), "World should have a proposition matching a's id.")
	assert_false(w.has_proposition_id(99), "Unknown id should be false.")
	assert_null(w.get_proposition(99), "Unknown id should return null.")

	var ids := w.get_proposition_ids()
	assert_true(ids.has(1) and ids.has(2), "IDs should contain 1 and 2.")

func test_get_proposition_value_variants() -> void:
	var a := _mk_prop(10, true)
	var w := _mk_world([a])

	assert_true(w.get_proposition_value(a), "Value via Proposition should be true.")
	assert_true(w.get_proposition_value_with_id(10), "Value via id should be true.")
	assert_null(w.get_proposition_value_with_id(999), "Unknown id -> null.")
	assert_null(w.get_proposition_value(_mk_prop(999, false)), "Unknown prop -> null.")

#region proposition

func test_set_proposition_overwrite_behaviour() -> void:
	var src1 := _mk_prop(5, true)
	var src2 := _mk_prop(5, false) # same id, different value
	var w := _mk_world([src1])

	# overwrite=false -> no change, returns false
	var changed := w.set_proposition(src2, false)
	assert_false(changed, "Should not overwrite when overwrite=false and id exists.")
	assert_true(w.get_proposition_value_with_id(5), "Value should remain true.")

	# overwrite=true -> replaced with clone of src2
	changed = w.set_proposition(src2, true)
	assert_true(changed, "Should overwrite when overwrite=true.")
	assert_false(w.get_proposition_value_with_id(5), "Value should now be false.")

func test_set_proposition_value_update() -> void:
	var a := _mk_prop(3, false)
	var w := _mk_world([a])

	assert_true(w.set_proposition_value(a, true), "Set by Proposition should succeed.")
	assert_true(w.get_proposition_value_with_id(3), "Value should be true after update.")

	assert_true(w.set_proposition_value_with_id(3, false), "Set by id should succeed.")
	assert_false(w.get_proposition_value_with_id(3), "Value should be false after update.")

	assert_false(w.set_proposition_value_with_id(999, true), "Unknown id -> false.")
	assert_false(w.set_proposition_value(_mk_prop(999, true), true), "Unknown prop -> false.")

#region remove

func test_remove_proposition_paths() -> void:
	var a := _mk_prop(8, true)
	var w := _mk_world([a])

	# remove by id
	assert_true(w.remove_proposition_with_id(8), "remove_proposition_with_id should return true when it removes.")
	assert_null(w.get_proposition(8), "Should be gone.")

	# remove by Proposition (present)
	w.set_proposition(a)
	assert_true(w.remove_proposition(a), "remove_proposition should return true when it removes.")
	assert_null(w.get_proposition(8))

	# remove by Proposition (absent) -> function has no explicit return -> null
	assert_null(w.remove_proposition(a), "When absent, remove_proposition returns null (no-op).")

	# remove by id (absent) -> Dictionary.erase returns false
	assert_false(w.remove_proposition_with_id(8), "Absent id should return false.")

#region tension

func test_tension_with_world_shared_and_missing() -> void:
	# w1: id1=true, id2=false
	var w1 := _mk_world([_mk_prop(1, true), _mk_prop(2, false)])
	# w2: id1=true, id2=true, id3=true
	var w2 := _mk_world([_mk_prop(1, true), _mk_prop(2, true), _mk_prop(3, true)])

	# Shared ids (1,2) -> diffs are 0 and 1 => total 1, no missing counted here
	assert_eq(w1.tension_with_world(w2), 1, "Tension should be 1 (only id=2 differs).")

	# If other world is missing our id, lambda_missing is added per-miss
	var w3 := _mk_world([])  # empty
	assert_eq(w1.tension_with_world(w3, 2), 4, "Two missing ids with lambda=2 => 4.")

func test_tension_vector_between_worlds_only_shared_ids() -> void:
	var w1 := _mk_world([_mk_prop(1, true), _mk_prop(2, false)])
	var w2 := _mk_world([_mk_prop(1, true), _mk_prop(2, true), _mk_prop(3, true)])

	var vec := w1.tension_vector_between_worlds(w2)
	assert_eq(vec.size(), 2, "Vector should only contain shared ids.")
	assert_eq(vec[1], 0, "id=1 matches => 0.")
	assert_eq(vec[2], 1, "id=2 differs => 1.")
	assert_false(vec.has(3), "id=3 not present in w1 => not included.")

#region world transforms

func test_match_propositions_with_world_updates_existing_only_when_clone_missing_false() -> void:
	var w_target := _mk_world([_mk_prop(1, false), _mk_prop(2, true)])
	var w_source := _mk_world([_mk_prop(1, true), _mk_prop(3, true)])

	# clone_missing_props = false -> only common ids updated; missing are NOT created
	w_target.match_propositions_with_world(w_source, false)

	assert_true(w_target.get_proposition_value_with_id(1), "id=1 should be updated to true to match source.")
	assert_true(w_target.get_proposition_value_with_id(2), "id=2 should remain as it was (true).")
	assert_false(w_target.has_proposition_id(3), "id=3 should not be cloned in when clone_missing_props=false.")


func test_match_propositions_with_world_clones_missing_props() -> void:
	var w_target := _mk_world([_mk_prop(1, false)], "target")

	var src_p1 := _mk_prop(1, true)   # common id -> should update value
	var src_p3 := _mk_prop(3, true)   # missing in target -> should be cloned in
	var w_source := _mk_world([src_p1, src_p3], "source")

	# clone_missing_props defaults to true, but set it explicitly for clarity
	w_target.match_propositions_with_world(w_source, true)

	# Common id updated to match source
	assert_true(w_target.get_proposition_value_with_id(1), "Common id should be updated to source's value (true).")

	# Missing id cloned from source
	assert_true(w_target.has_proposition_id(3), "Missing id should be cloned from source.")
	assert_true(w_target.get_proposition_value_with_id(3), "Cloned prop value should match source (true).")

	# Ensure it's a proper clone (not the same instance, and not canonical)
	var stored := w_target.get_proposition(3)
	var original := w_source.get_proposition(3)
	assert_true(stored is Proposition, "Cloned entry must be a Proposition.")
	assert_ne(stored, original, "Target should store a clone, not the same instance from source.")
	assert_false(stored.is_canonical_proposition(), "Cloned Proposition should not be canonical.")

	# Deep copy check: mutating source after matching must not affect target
	w_source.set_proposition_value_with_id(3, false)
	assert_true(w_target.get_proposition_value_with_id(3), "Target remains true after source mutation.")


#region clone

func test_make_clone_world_deep_copies_name_and_props() -> void:
	var p1 := _mk_prop(100, true, true, "p1")
	var p2 := _mk_prop(200, false, true, "p2")
	var w := _mk_world([p1, p2], "original")

	var clone := w.make_clone()
	assert_not_null(clone)
	assert_ne(clone, w, "World clone should be a different instance.")
	assert_eq(clone.name, "original", "Name should be copied.")

	# IDs preserved and clones are distinct instances
	for id in w.get_proposition_ids():
		assert_true(clone.has_proposition_id(id), "Clone should contain same ids.")
		var a := w.get_proposition(id)
		var b := clone.get_proposition(id)
		assert_ne(a, b, "Each Proposition in clone should be a separate instance.")
		assert_eq(a.value, b.value, "Cloned Proposition values should match.")

	# Mutating clone should not affect original
	clone.set_proposition_value_with_id(100, false)
	assert_true(w.get_proposition_value_with_id(100), "Original should remain true after clone mutation.")