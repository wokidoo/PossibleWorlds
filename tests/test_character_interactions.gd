extends GutTest

# Tests for Character interaction behaviors: rumor propagation, absorbing
# propositions between characters, theme/ideal adoption, and synchronization
# with the canonical WorldServer. Each test uses small helper factories below
# so intent is focused on behavior rather than setup details.

# -------- Helpers --------
## Reset the global WorldServer to a clean deterministic state for tests.
## This clears registered propositions, the next id counter, world_name,
## and canonical themes when supported. Called from before_each.
func _reset_ws() -> void:
	if WorldServer.has_method("reset_for_tests"):
		WorldServer.reset_for_tests()
	else:
		WorldServer._propositions.clear()
		WorldServer._next_id = 1
		WorldServer.world_name = "Actual"
		if WorldServer.has_method("clear_themes"):
			WorldServer.clear_themes()

## Convenience: register three canonical propositions and return them as a map.
## Tests call this to get consistent IDs and descriptions.
func _mk_props() -> Dictionary:
	return {
		door   = WorldServer.create_proposition("DoorLocked", true),
		night  = WorldServer.create_proposition("IsNight", false),
		hungry = WorldServer.create_proposition("IsHungry", false),
	}

## Convenience: register two example canonical themes used in theme tests.
func _mk_themes() -> void:
	WorldServer.register_theme(&"family")
	WorldServer.register_theme(&"political")

## Return a clone of proposition `p` with value `v` to simulate a rumor.
func _rumor(p: Proposition, v: bool) -> Proposition:
	return p.make_clone(v)

## Create a Character instance with the given name for interaction tests.
func _C(nm: String) -> Character:
	var c := Character.new()
	c.name = nm
	return c

# -------- Setup --------
## Run before each test: ensure WorldServer is reset for deterministic ids
func before_each() -> void:
	_reset_ws()

# -------- Tests --------
func test_rumor_propagates_across_characters() -> void:
	# Scenario: one character believes a rumor, others absorb that belief.
	# Expectation: belief propagates when absorb_from_character is used.
	var P = _mk_props()
	var alice := _C("Alice")
	var bob := _C("Bob")
	var carol := _C("Carol")
	alice.absorb_proposition(_rumor(P.night, true))
	bob.absorb_from_character(alice)
	assert_true(bob.perceived_world.propositions.has(P.night._prop_id))
	assert_true(bob.perceived_world.propositions[P.night._prop_id].value)
	carol.absorb_from_character(bob, PackedInt32Array([P.night._prop_id]))
	assert_true(carol.perceived_world.propositions.has(P.night._prop_id))
	assert_true(carol.perceived_world.propositions[P.night._prop_id].value)

func test_absorb_propositions_respects_override_flag() -> void:
	# Scenario: absorb_propositions called with override=false and override=true
	# Expectation: existing values are preserved when override=false,
	# and updated when override=true.
	var P = _mk_props()
	var c := _C("C")
	c.absorb_proposition(_rumor(P.door, false))
	assert_false(c.perceived_world.propositions[P.door._prop_id].value)
	c.absorb_propositions([_rumor(P.door, true)], false)
	assert_false(c.perceived_world.propositions[P.door._prop_id].value)
	c.absorb_propositions([_rumor(P.door, true)], true)
	assert_true(c.perceived_world.propositions[P.door._prop_id].value)

func test_absorb_from_character_attach_missing_controls_new_slots() -> void:
	# Scenario: when absorbing from another character, control whether new slots
	# are attached via the attach_missing flag.
	# Expectation: with attach_missing=false no new slot is created; with true it is.
	var P = _mk_props()
	var alice := _C("Alice")
	var bob := _C("Bob")
	alice.absorb_proposition(_rumor(P.door, false))
	bob.absorb_from_character(alice, PackedInt32Array([P.door._prop_id]), false)
	assert_false(bob.perceived_world.propositions.has(P.door._prop_id))
	bob.absorb_from_character(alice, PackedInt32Array([P.door._prop_id]), true)
	assert_true(bob.perceived_world.propositions.has(P.door._prop_id))
	assert_false(bob.perceived_world.propositions[P.door._prop_id].value)

func test_adopt_ideals_from_other_character_template() -> void:
	# Scenario: adopt ideals from another character's ideal World (template)
	# Expectation: only canonical propositions are copied; bogus (unregistered)
	# ids are filtered out.
	var P = _mk_props(); _mk_themes()
	var alice := _C("Alice"); var bob := _C("Bob")
	alice.set_ideal(&"family", P.door._prop_id, false)
	alice.set_ideal(&"family", P.night._prop_id, true)
	# sneak bogus id into Alice's ideal world (bypass guarded API)
	var bogus := Proposition.new(); bogus._prop_id = 55555; bogus.value = true
	alice.ideal_worlds[&"family"].propositions[bogus._prop_id] = bogus
	bob.adopt_ideals_from_world(&"family", alice.ideal_worlds[&"family"])
	assert_true(bob.ideal_worlds.has(&"family"))
	assert_true(bob.ideal_worlds[&"family"].propositions.has(P.door._prop_id))
	assert_true(bob.ideal_worlds[&"family"].propositions.has(P.night._prop_id))
	assert_false(bob.ideal_worlds[&"family"].propositions.has(55555))

func test_theme_sync_after_worldserver_changes() -> void:
	# Scenario: when WorldServer registers new themes, characters must sync.
	# Expectation: sync_required_themes creates missing theme Worlds and when
	# strict=true removes non-canonical themes from a character.
	WorldServer.register_theme(&"family")
	var alice := _C("Alice"); var bob := _C("Bob")
	alice.sync_required_themes(); bob.sync_required_themes()
	assert_true(alice.has_all_required_themes())
	assert_true(bob.has_all_required_themes())
	WorldServer.register_theme(&"career")
	var created_bob := bob.sync_required_themes()
	assert_true(created_bob.has(&"career"))
	alice.ideal_worlds[&"bogus"] = World.new()
	alice.sync_required_themes(true)
	assert_false(alice.themes().has(&"bogus"))

func test_observe_ids_can_correct_rumor_against_canonical() -> void:
	# Scenario: character holds a rumor that disagrees with canonical values.
	# Expectation: observe_ids clones canonical values into perceived_world,
	# reducing tension to 0 and correcting the local belief.
	var P = _mk_props()
	var c := _C("C")
	c.absorb_proposition(_rumor(P.night, true))
	assert_eq(c.tension_perceived_vs_canonical(0), 1)
	c.observe_ids(PackedInt32Array([P.night._prop_id]))
	assert_eq(c.tension_perceived_vs_canonical(0), 0)
	assert_false(c.perceived_world.propositions[P.night._prop_id].value)

func test_absorb_from_character_filters_unknown_ids() -> void:
	# Scenario: a character has a perceived_world with a bogus (unregistered)
	# proposition id inserted by bypassing the API. When another character
	# absorbs from them, bogus ids should be ignored.
	# Expectation: only canonical ids are absorbed; bogus ids are filtered.
	var P = _mk_props()
	var alice := _C("Alice"); var bob := _C("Bob")
	var other_world := World.new()
	# bypass guarded API to insert bogus
	var bogus := Proposition.new(); bogus._prop_id = 99999; bogus.value = true
	other_world.propositions[bogus._prop_id] = bogus
	other_world.add_or_update_prop(_rumor(P.door, false))
	alice.perceived_world = other_world
	bob.absorb_from_character(alice)
	assert_true(bob.perceived_world.propositions.has(P.door._prop_id))
	assert_false(bob.perceived_world.propositions.has(99999))
