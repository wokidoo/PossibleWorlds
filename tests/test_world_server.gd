# res://tests/test_world_server.gd
extends GutTest

# Only preload the autoload script so we can instantiate a fresh server per test.
const WorldServerScript: Script = preload("res://autoloads/world_server.gd")

var srv: Node

func before_each() -> void:
	srv = WorldServerScript.new()   # _init() may try to load; we reset right after
	if "_reset_for_tests" in srv:
		srv._reset_for_tests()
	watch_signals(srv)

func after_each() -> void:
	if is_instance_valid(srv):
		srv.free()

# --- helpers ----------------------------------------------------------------
func _p(id:int, val:bool, desc:="") -> Proposition:
	var p := Proposition.new()
	p._prop_id = id
	p._is_canonical = true
	p.description = desc
	p.value = val
	return p

func _mk_character(label:="TestCharacter") -> Character:
	var c := Character.new()
	if "name" in c:
		c.name = label
	return c

# ----------------------------------------------------------------------------
#                           PROPOSITIONS / CANONICAL
# ----------------------------------------------------------------------------

func test_create_canonical_proposition_assigns_id_and_registers() -> void:
	var p: Proposition = srv.create_canonical_proposition("Light is on", true)
	assert_true(p._prop_id > 0)
	assert_signal_emitted(srv, "changed")
	assert_true(get_signal_emit_count(srv, "changed") >= 1)

	var stored: Proposition = srv.get_canonical_proposition(p._prop_id)
	assert_not_null(stored)
	assert_true(stored.value)

func test_register_new_proposition_with_existing_id_is_idempotent_by_id() -> void:
	var p1: Proposition = Proposition.new()
	p1.description = "A"
	p1.value = true
	assert_true(srv.register_new_proposition(p1))
	var id: int = p1._prop_id
	assert_true(id > 0)

	var p2: Proposition = Proposition.new()
	p2._prop_id = id
	p2.description = "B"
	p2.value = false
	assert_true(srv.register_new_proposition(p2))

func test_remove_canonical_proposition_emits_changed() -> void:
	var p: Proposition = srv.create_canonical_proposition("Door open", false)
	var before: int = get_signal_emit_count(srv, "changed")
	assert_true(srv.remove_canonical_proposition(p._prop_id))
	assert_eq(get_signal_emit_count(srv, "changed"), before + 1)

func test_get_canonical_proposition_ids_contains_registered_ids() -> void:
	var a: Proposition = srv.create_canonical_proposition("A", true)
	var b: Proposition = srv.create_canonical_proposition("B", false)
	var ids: Array = srv.get_canonical_proposition_ids()
	assert_true(ids.has(a._prop_id) and ids.has(b._prop_id))

func test_has_canonical_proposition_with_id_is_true() -> void:
	var p: Proposition = srv.create_canonical_proposition("Flag check", true)
	assert_true(srv.has_canonical_proposition_with_id(p._prop_id))

func test_set_canonical_value_updates_and_emits_changed() -> void:
	var p: Proposition = srv.create_canonical_proposition("Switch", false)
	var before: int = get_signal_emit_count(srv, "changed")
	srv.set_canonical_value(p._prop_id, true)
	assert_eq(get_signal_emit_count(srv, "changed"), before + 1)
	var stored :Proposition= srv.get_canonical_proposition(p._prop_id)
	assert_true(stored.value)

func test_get_canonical_value_returns_bool_with_default() -> void:
	var p: Proposition = srv.create_canonical_proposition("Get val", true)
	# existing id: returns actual value
	assert_true(srv.get_canonical_value(p._prop_id, false))
	# missing id: returns default
	assert_eq(srv.get_canonical_value(999999, false), false)


# ----------------------------------------------------------------------------
#                                     THEMES
# ----------------------------------------------------------------------------

func test_register_theme_sorted_unique_and_changed() -> void:
	var base: int = get_signal_emit_count(srv, "changed")
	assert_true(srv.register_theme(&"forest"))
	assert_true(srv.register_theme(&"desert"))
	assert_false(srv.register_theme(&"forest"))
	assert_eq(get_signal_emit_count(srv, "changed"), base + 2)

	var list: Array[StringName] = srv.get_themes()
	var as_str: Array[String] = []
	for t in list:
		as_str.append(String(t))
	var sorted := as_str.duplicate()
	sorted.sort()  # in-place, alphabetical
	assert_eq(as_str, sorted, "Themes should be maintained in lexicographic order.")


func test_register_theme_rejects_empty_string() -> void:
	assert_false(srv.register_theme(&"  "))

func test_ensure_theme_adds_when_missing_idempotent_when_present() -> void:
	var base: int = get_signal_emit_count(srv, "changed")
	srv.ensure_theme(&"ocean")
	var after_first: int = get_signal_emit_count(srv, "changed")
	srv.ensure_theme(&"ocean")
	assert_eq(get_signal_emit_count(srv, "changed"), after_first)
	assert_true(srv.has_theme(&"ocean"))

func test_remove_theme_removes_and_changed() -> void:
	srv.ensure_theme(&"mountain")
	var before: int = get_signal_emit_count(srv, "changed")
	assert_true(srv.remove_theme(&"mountain"))
	assert_eq(get_signal_emit_count(srv, "changed"), before + 1)
	assert_false(srv.has_theme(&"mountain"))

# ----------------------------------------------------------------------------
#                                   CHARACTERS
# ----------------------------------------------------------------------------

func test_add_character_assigns_positive_id_and_indexes() -> void:
	var c: Character = _mk_character("Alice")
	var before: int = get_signal_emit_count(srv, "changed")
	var id: int = srv.add_character(c)
	assert_true(id > 0)
	assert_true(srv.has_character(c))
	assert_true(srv.get_character_by_instance_id(id) == c)
	assert_eq(get_signal_emit_count(srv, "changed"), before + 1)

func test_add_character_rejects_null_and_duplicates() -> void:
	assert_eq(srv.add_character(null), -1)
	var c: Character = _mk_character("Bob")
	var id: int = srv.add_character(c)
	assert_true(id > 0)
	assert_eq(srv.add_character(c), -1)

func test_remove_character_instance_updates_indexes_and_signal() -> void:
	var c: Character = _mk_character("Cara")
	var id: int = srv.add_character(c)
	var before: int = get_signal_emit_count(srv, "changed")
	assert_true(srv.remove_character_instance(c))
	assert_false(srv.has_character(c))
	assert_null(srv.get_character_by_instance_id(id))
	assert_eq(get_signal_emit_count(srv, "changed"), before + 1)

func test_character_array_access_and_counts() -> void:
	var a: Character = _mk_character("A")
	var b: Character = _mk_character("B")
	srv.add_character(a)
	srv.add_character(b)
	assert_eq(srv.character_count(), 2)
	assert_true(srv.character_at(0) == a and srv.character_at(1) == b)
	assert_null(srv.character_at(-1))
	assert_null(srv.character_at(99))

# ----------------------------------------------------------------------------
#                               SAVE / LOAD / STATE
# ----------------------------------------------------------------------------

func test_snapshot_and_roundtrip_save_load_world_state() -> void:
	var p1: Proposition = srv.create_canonical_proposition("P1", true)
	var p2: Proposition = srv.create_canonical_proposition("P2", false)
	srv.ensure_theme(&"alpha")
	srv.ensure_theme(&"beta")
	var ch: Character = _mk_character("Saver")
	srv.add_character(ch)
	srv.world_name = "Story-1"

	var path := "user://gut_world_state_%s.tres" % str(Time.get_ticks_usec())
	assert_true(srv.save_state(path))

	var srv2: Node = WorldServerScript.new()
	if "_reset_for_tests" in srv2:
		srv2._reset_for_tests()
	assert_true(srv2.load_state(path))
	assert_eq(srv2.world_name, "Story-1")

	var ids: Array = srv2.get_canonical_proposition_ids()
	assert_true(ids.has(p1._prop_id) and ids.has(p2._prop_id))
	var loaded_p1: Proposition = srv2.get_canonical_proposition(p1._prop_id)
	assert_not_null(loaded_p1)
	assert_true(loaded_p1._is_canonical)

	assert_true(srv2.has_theme(&"alpha") and srv2.has_theme(&"beta"))
	var th: Array[StringName] = srv2.get_themes()
	var th_str: Array[String] = []
	for t in th:
		th_str.append(String(t))
	var th_sorted := th_str.duplicate()
	th_sorted.sort()
	assert_eq(th_str, th_sorted)

	if is_instance_valid(srv2):
		srv2.free()

	if FileAccess.file_exists(path):
		var rm_err := DirAccess.remove_absolute(path)
		assert_eq(rm_err, OK, "Cleanup: should delete temp world-state file.")


# ----------------------------------------------------------------------------
#                                    UTIL
# ----------------------------------------------------------------------------

func test_allocate_id_progresses_beyond_existing() -> void:
	var a: Proposition = Proposition.new()
	a.description = "A"
	a.value = false
	assert_true(srv.register_new_proposition(a))
	var first: int = a._prop_id

	var b: Proposition = Proposition.new()
	b.description = "B"
	b.value = true
	assert_true(srv.register_new_proposition(b))
	assert_true(b._prop_id > first)

func test_themes_clear_emits_changed() -> void:
	srv.ensure_theme(&"x")
	var before: int = get_signal_emit_count(srv, "changed")
	srv.clear_themes()
	assert_eq(srv.get_themes().size(), 0)
	assert_eq(get_signal_emit_count(srv, "changed"), before + 1)
