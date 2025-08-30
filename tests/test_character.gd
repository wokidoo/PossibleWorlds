extends GutTest

# Tests for Character behavior: perception, ideals, themes, and tensions.

# ------------ Helpers ------------
func _reset_ws() -> void:
	# Reset the global WorldServer to a deterministic state before each test.
	if WorldServer.has_method("reset_for_tests"):
		WorldServer.reset_for_tests()
	else:
		WorldServer._propositions.clear()
		WorldServer._next_id = 1
		WorldServer.world_name = "Actual"
		if WorldServer.has_method("clear_themes"):
			WorldServer.clear_themes()

func _mk_props() -> Dictionary:
	# Create three canonical propositions used across tests.
	return {
		door   = WorldServer.create_proposition("DoorLocked", true),
		night  = WorldServer.create_proposition("IsNight", false),
		hungry = WorldServer.create_proposition("IsHungry", false),
	}

func _mk_themes() -> Array[StringName]:
	# Register a couple of themes on WorldServer for theme-related tests.
	WorldServer.register_theme(&"family")
	WorldServer.register_theme(&"political")
	return WorldServer.themes()

func _rumor(p: Proposition, v: bool) -> Proposition:
	# Helper to produce a clone (a "rumor") of a canonical proposition.
	return p.make_clone(v)

func _new_char(n: String = "A") -> Character:
	# Simple factory for Character instances with a name.
	var c := Character.new()
	c.name = n
	return c

# ------------ Setup ------------
func before_each() -> void:
	# Ensure deterministic WorldServer state before each test.
	_reset_ws()

# ------------ Theme tests ------------
func test_ensure_theme_rejects_noncanonical_theme() -> void:
	# ensure_theme must return null for unregistered themes and not add them.
	var c := _new_char()
	var w := c.ensure_theme(&"not_registered")
	assert_null(w)
	assert_false(c.themes().has(&"not_registered"))

func test_sync_required_themes_creates_all_and_strict_removes_extra() -> void:
	# sync_required_themes should create missing theme worlds and optionally remove extras.
	_mk_themes()
	var c := _new_char("Char")
	assert_false(c.has_all_required_themes())
	var created := c.sync_required_themes()
	created.sort()
	assert_eq_deep(created, WorldServer.themes())
	assert_true(c.has_all_required_themes())
	# Add an extra bogus theme world and ensure strict sync prunes it.
	c.ideal_worlds[&"bogus"] = World.new()
	c.sync_required_themes(true)
	assert_false(c.themes().has(&"bogus"))

func test_ensure_theme_returns_world_and_is_idempotent() -> void:
	# ensure_theme should be idempotent and return the same World instance each call.
	WorldServer.register_theme(&"family")
	var c := _new_char()
	var w1 := c.ensure_theme(&"family")
	var w2 := c.ensure_theme(&"family")
	assert_not_null(w1)
	assert_true(w1 == w2)

# ------------ Observe / Forget ------------
func test_observe_ids_clones_from_canonical_and_ignores_unknown() -> void:
	# observe_ids must clone canonical props into perceived_world and ignore unknown ids.
	var P = _mk_props()
	var c := _new_char()
	var ids := PackedInt32Array([P.door._prop_id, 99999])
	c.observe_ids(ids)
	assert_true(c.perceived_world.propositions.has(P.door._prop_id))
	var stored: Proposition = c.perceived_world.propositions[P.door._prop_id]
	assert_false(stored == P.door)
	assert_eq(stored.value, P.door.value)
	assert_false(c.perceived_world.propositions.has(99999))

func test_observe_all_adds_all_canonicals() -> void:
	# observe_all should attach clones of all canonical propositions.
	var P = _mk_props()
	var c := _new_char()
	c.observe_all()
	var ids := c.perceived_world.prop_ids()
	assert_eq_deep(ids, WorldServer.prop_ids())

func test_forget_ids_removes_perceived_beliefs() -> void:
	# forget_ids should remove listed ids from the character's perceived world.
	var P = _mk_props()
	var c := _new_char()
	c.observe_all()
	c.forget_ids(PackedInt32Array([P.night._prop_id]))
	assert_false(c.perceived_world.propositions.has(P.night._prop_id))

# ------------ Absorb ------------
func test_absorb_proposition_accepts_registered_and_clones_from_source() -> void:
	# Absorbing a registered (clone) proposition should attach a clone into perceived_world.
	var P = _mk_props()
	var c := _new_char()
	var rumor := _rumor(P.night, true)
	c.absorb_proposition(rumor, true)
	assert_true(c.perceived_world.propositions.has(P.night._prop_id))
	var stored := c.perceived_world.propositions[P.night._prop_id]
	assert_false(stored == rumor)
	assert_true(stored.value)

func test_absorb_proposition_rejects_unregistered_id() -> void:
	# Unregistered proposition ids must be rejected when absorbing.
	# We only need the canonical set to be registered; no local reference required.
	_mk_props()
	var c := _new_char()
	var fake := Proposition.new()
	fake._prop_id = 99999
	fake.description = "Fake"
	fake.value = true
	c.absorb_proposition(fake, true)
	assert_false(c.perceived_world.propositions.has(99999))

func test_absorb_world_filters_unknown_and_attaches_controlled_by_flag() -> void:
	# absorb_world should only attach propositions for known ids when attach_missing=true.
	var P = _mk_props()
	var c := _new_char()
	var other := World.new()
	other.add_or_update_prop(_rumor(P.door, false)) # door false
	other.add_or_update_prop(_rumor(P.night, true)) # night true
	# sneak bogus without using the guarded API
	var bogus := Proposition.new(); bogus._prop_id = 777777; bogus.value = true
	other.propositions[bogus._prop_id] = bogus

	c.absorb_world(other) # attach_missing=true
	assert_true(c.perceived_world.propositions.has(P.door._prop_id))
	assert_true(c.perceived_world.propositions.has(P.night._prop_id))
	assert_false(c.perceived_world.propositions.has(777777))

	var c2 := _new_char()
	c2.absorb_world(other, PackedInt32Array(), false)
	assert_eq(c2.perceived_world.prop_ids().size(), 0)

func test_absorb_from_character_copies_their_beliefs() -> void:
	# absorb_from_character should copy beliefs from another character's perceived world.
	var P = _mk_props()
	var alice := _new_char("Alice")
	var bob := _new_char("Bob")
	alice.absorb_proposition(_rumor(P.door, false))
	bob.absorb_from_character(alice)
	assert_true(bob.perceived_world.propositions.has(P.door._prop_id))
	assert_false(bob.perceived_world.propositions[P.door._prop_id].value)

# ------------ Believe ------------
func test_believe_updates_existing_and_can_attach_if_missing() -> void:
	# believe should update existing perceived props and may attach missing ones if allowed.
	var P = _mk_props()
	var c := _new_char()
	c.believe(P.night._prop_id, true, true)
	assert_true(c.perceived_world.propositions.has(P.night._prop_id))
	assert_true(c.perceived_world.propositions[P.night._prop_id].value)
	c.believe(P.night._prop_id, false, true)
	assert_false(c.perceived_world.propositions[P.night._prop_id].value)

func test_believe_no_attach_when_FLAG_false_and_rejects_unknown() -> void:
	# When attach_missing is false, believe must not attach previously unknown ids.
	var P = _mk_props()
	var c := _new_char()
	c.believe(P.door._prop_id, false, false)
	assert_false(c.perceived_world.propositions.has(P.door._prop_id))
	c.believe(99999, true, true)
	assert_false(c.perceived_world.propositions.has(99999))

# ------------ Ideals ------------
func test_set_ideal_creates_theme_world_and_sets_value() -> void:
	# set_ideal must create a theme world if the theme exists and set the ideal value.
	var P = _mk_props()
	WorldServer.register_theme(&"family")
	var c := _new_char()
	c.set_ideal(&"family", P.door._prop_id, false)
	assert_true(c.ideal_worlds.has(&"family"))
	assert_true(c.ideal_worlds[&"family"].propositions.has(P.door._prop_id))
	assert_false(c.ideal_worlds[&"family"].propositions[P.door._prop_id].value)

func test_set_ideal_rejects_unknown_theme_or_ID() -> void:
	# set_ideal should ignore unknown themes and must not create worlds for invalid ids.
	var P = _mk_props()
	var c := _new_char()
	c.set_ideal(&"not_registered", P.door._prop_id, false)
	assert_false(c.ideal_worlds.has(&"not_registered"))
	WorldServer.register_theme(&"family")
	c.set_ideal(&"family", 99999, true)
	assert_false(c.ideal_worlds.has(&"family"), "no world created when id invalid")

func test_adopt_ideals_from_world_filters_unknown_ids() -> void:
	# adopt_ideals_from_world should only copy valid ids from a template world.
	var P = _mk_props()
	WorldServer.register_theme(&"political")
	var tmpl := World.new()
	tmpl.add_or_update_prop(_rumor(P.hungry, true))
	var bogus := Proposition.new(); bogus._prop_id = 55555; bogus.value = true
	tmpl.propositions[bogus._prop_id] = bogus   # bypass guarded API
	var c := _new_char()
	c.adopt_ideals_from_world(&"political", tmpl)
	assert_true(c.ideal_worlds.has(&"political"))
	assert_true(c.ideal_worlds[&"political"].propositions.has(P.hungry._prop_id))
	assert_false(c.ideal_worlds[&"political"].propositions.has(55555))

# ------------ Tensions ------------
func test_tension_ideal_vs_perceived_and_top_theme() -> void:
	# tension_ideal_vs_perceived computes a theme's tension and top_theme picks the highest.
	var P = _mk_props()
	WorldServer.register_theme(&"family")
	WorldServer.register_theme(&"career")
	var c := _new_char()
	c.observe_ids(PackedInt32Array([P.door._prop_id, P.night._prop_id]))
	c.set_ideal(&"family", P.door._prop_id, false)
	c.set_ideal(&"career", P.night._prop_id, true)
	assert_eq(c.tension_ideal_vs_perceived(&"family", 0), 1)
	assert_eq(c.tension_ideal_vs_perceived(&"career", 0), 1)
	c.set_ideal(&"career", P.hungry._prop_id, true)
	assert_eq(c.tension_ideal_vs_perceived(&"career", 2), 3)
	var top := c.top_theme(2)
	assert_eq(top, &"career")

func test_tension_perceived_vs_canonical() -> void:
	# tension_perceived_vs_canonical compares the character's perceived world to the canonical one.
	var P = _mk_props()
	var c := _new_char()
	c.believe(P.door._prop_id, false, true)
	assert_eq(c.tension_perceived_vs_canonical(0), 1)
