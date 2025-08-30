extends GutTest

# Tests for Proposition resource: id handling, canonical flag, and clone behavior.
## _new_prop creates a Proposition instance with controlled fields for tests.
func _new_prop(id:int, desc:String, val:bool, is_canon:bool=false) -> Proposition:
	var p := Proposition.new()
	p._prop_id = id
	p._is_canonical = is_canon
	p.description = desc
	p.value = val
	return p

# -------------------------------------------------------------------
# Basics
# -------------------------------------------------------------------

func test_get_proposition_id_returns_internal_id() -> void:
	# Confirm get_proposition_id returns the internal _prop_id field.
	var p := _new_prop(42, "DoorLocked", true, true)
	assert_eq(p.get_proposition_id(), 42)

func test_is_canonical_proposition_reflects_flag() -> void:
	# is_canonical_proposition reads the _is_canonical flag.
	var a := _new_prop(1, "A", true, true)
	var b := _new_prop(2, "B", false, false)
	assert_true(a.is_canonical_proposition())
	assert_false(b.is_canonical_proposition())

# -------------------------------------------------------------------
# make_clone guard
# -------------------------------------------------------------------

func test_make_clone_requires_nonzero_id_returns_null_when_zero() -> void:
	# make_clone must refuse to clone propositions with no id (id==0).
	var p := _new_prop(0, "NoId", true, true)
	var c := p.make_clone()
	assert_null(c, "Clone should be null when _prop_id == 0")

# -------------------------------------------------------------------
# Cloning behavior
# -------------------------------------------------------------------

func test_make_clone_copies_id_description_value_and_clears_canonical_flag() -> void:
	# Verify clone copies id/description/value and is not canonical.
	var p := _new_prop(7, "IsNight", false, true)
	var c := p.make_clone()
	assert_not_null(c)
	assert_true(c is Proposition)
	assert_false(c == p, "Clone must be a new instance")
	assert_eq(c._prop_id, p._prop_id, "Same prop_id on clone")
	assert_eq(c.description, p.description, "Description copied")
	assert_eq(c.value, p.value, "Value copied")
	assert_false(c._is_canonical, "Clone must never be canonical")

func test_make_clone_override_true_sets_true() -> void:
	# When passing override true, the clone's value should be true.
	var p := _new_prop(5, "IsHungry", false, true)
	var c := p.make_clone(true)
	assert_true(c.value)

func test_make_clone_override_false_sets_false() -> void:
	# When passing override false, the clone's value should be false.
	var p := _new_prop(6, "IsOpen", true, true)
	var c := p.make_clone(false)
	assert_false(c.value)

func test_make_clone_override_ignored_when_not_bool() -> void:
	# Non-boolean override values should be ignored and preserve original.
	var p := _new_prop(8, "IsVisible", true, true)
	var c1 := p.make_clone(1)          # int -> ignore
	var c2 := p.make_clone("true")     # string -> ignore
	var c3 := p.make_clone(null)       # null -> ignore
	assert_true(c1.value)
	assert_true(c2.value)
	assert_true(c3.value)

# -------------------------------------------------------------------
# Independence (no shared state between source and clone)
# -------------------------------------------------------------------

func test_changing_clone_does_not_affect_source() -> void:
	# Verify that changing the clone's fields does not mutate the source.
	var p := _new_prop(10, "DoorLocked", true, true)
	var c := p.make_clone()
	c.value = false
	c.description = "DoorLocked (clone)"
	assert_true(p.value, "Source value unchanged")
	assert_eq(p.description, "DoorLocked", "Source description unchanged")

func test_changing_source_after_clone_does_not_affect_clone() -> void:
	# Mutating the source after cloning should not affect the clone.
	var p := _new_prop(11, "IsNight", false, true)
	var c := p.make_clone()
	# mutate source after cloning
	p.value = true
	p.description = "IsNight (source updated)"
	assert_false(c.value, "Clone keeps original copied value")
	assert_eq(c.description, "IsNight", "Clone keeps original copied description")

# -------------------------------------------------------------------
# Identity & type checks
# -------------------------------------------------------------------

func test_clone_is_distinct_object_with_same_type() -> void:
	# Clone must be a distinct object instance of the same type.
	var p := _new_prop(12, "IsRainy", false, true)
	var c := p.make_clone()
	assert_true(c is Proposition)
	assert_false(c == p)