extends GutTest

func test_default_values() -> void:
	var p := Proposition.new()
	assert_eq(p.get_proposition_id(), 0, "Default _prop_id should be 0.")
	assert_false(p.is_canonical_proposition(), "Default _is_canonical should be false.")
	assert_eq(p.description, "", "Default description should be empty string.")
	assert_false(p.value, "Default value should be false.")

func test_get_proposition_id_returns_set_value() -> void:
	var p := Proposition.new()
	p._prop_id = 42
	assert_eq(p.get_proposition_id(), 42, "Should return explicitly set _prop_id.")

func test_is_canonical_proposition_reflects_flag() -> void:
	var p := Proposition.new()
	p._is_canonical = true
	assert_true(p.is_canonical_proposition(), "Should reflect canonical when set true.")
	p._is_canonical = false
	assert_false(p.is_canonical_proposition(), "Should reflect non-canonical when set false.")

func test_make_clone_returns_null_when_unregistered() -> void:
	var p := Proposition.new()
	# _prop_id is 0 by default -> should return null and push_error
	var clone := p.make_clone()
	assert_null(clone, "Clone should be null if _prop_id == 0 (not registered).")

func test_make_clone_copies_fields_and_resets_is_canonical() -> void:
	var p := Proposition.new()
	p._prop_id = 7
	p._is_canonical = true
	p.description = "Hello"
	p.value = true

	var clone := p.make_clone()
	assert_not_null(clone, "Clone should not be null when _prop_id != 0.")
	assert_true(clone is Proposition, "Clone should be a Proposition.")
	assert_true(clone != p, "Clone should be a different instance.")

	assert_eq(clone.get_proposition_id(), 7, "_prop_id should be copied to clone.")
	assert_false(clone.is_canonical_proposition(), "_is_canonical should always reset to false on clone.")
	assert_eq(clone.description, "Hello", "Description should be copied to clone.")
	assert_true(clone.value, "Value should be copied when no override is provided.")

func test_make_clone_respects_boolean_override_true() -> void:
	var p := Proposition.new()
	p._prop_id = 1
	p.value = false
	var clone := p.make_clone(true)
	assert_not_null(clone)
	assert_true(clone.value, "Boolean override true should set clone.value to true.")

func test_make_clone_respects_boolean_override_false() -> void:
	var p := Proposition.new()
	p._prop_id = 1
	p.value = true
	var clone := p.make_clone(false)
	assert_not_null(clone)
	assert_false(clone.value, "Boolean override false should set clone.value to false.")

func test_make_clone_ignores_non_boolean_override() -> void:
	var p := Proposition.new()
	p._prop_id = 1
	p.value = true

	var clone_number := p.make_clone(1) # not bool
	assert_not_null(clone_number)
	assert_true(clone_number.value, "Non-bool override (int) should be ignored; keep original value.")

	var clone_string := p.make_clone("true") # not bool, still a String
	assert_not_null(clone_string)
	assert_true(clone_string.value, "Non-bool override (String) should be ignored; keep original value.")

func test_diff_returns_0_when_values_match() -> void:
	var a := Proposition.new()
	var b := Proposition.new()
	a.value = true
	b.value = true
	assert_eq(a.diff(b), 0, "diff should be 0 when values match (true/true).")

	a.value = false
	b.value = false
	assert_eq(a.diff(b), 0, "diff should be 0 when values match (false/false).")

func test_diff_returns_1_when_values_differ() -> void:
	var a := Proposition.new()
	var b := Proposition.new()
	a.value = true
	b.value = false
	assert_eq(a.diff(b), 1, "diff should be 1 when values differ (true/false).")

	a.value = false
	b.value = true
	assert_eq(a.diff(b), 1, "diff should be 1 when values differ (false/true).")