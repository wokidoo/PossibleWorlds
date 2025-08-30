@tool
extends Resource
class_name Character

@export var name: String = ""
@export var perceived_world: World = World.new()
@export var ideal_worlds: Dictionary[StringName, World] = {}

## Returns the ideal World for a canonical theme, creating it if missing locally.
## Returns null if the theme is not registered in WorldServer.
func ensure_theme(theme: StringName) -> World:
	if not WorldServer.has_theme(theme):
		push_error("ensure_theme: unknown canonical theme '%s'" % String(theme))
		return null
	if not ideal_worlds.has(theme):
		var w := World.new()
		w.name = "%s::%s" % [name, String(theme)]
		ideal_worlds[theme] = w
	return ideal_worlds[theme]

## Ensures this character has all canonical themes, creating empty Worlds as needed.
## If strict=true, removes any non-canonical themes from the character.
## Returns an array of newly created theme names.
func sync_required_themes(strict: bool = false) -> Array[StringName]:
	var created: Array[StringName] = []
	var canonical := WorldServer.themes()
	for t in canonical:
		if not ideal_worlds.has(t):
			var w := World.new()
			w.name = "%s::%s" % [name, String(t)]
			ideal_worlds[t] = w
			created.append(t)
	if strict:
		var to_remove: Array[StringName] = []
		for t in ideal_worlds.keys():
			if not WorldServer.has_theme(t):
				to_remove.append(t)
		for t in to_remove:
			ideal_worlds.erase(t)
	return created

## Returns true if the character has all canonical themes, false otherwise.
func has_all_required_themes() -> bool:
	for t in WorldServer.themes():
		if not ideal_worlds.has(t):
			return false
	return true

## Returns an array of all theme names currently present in ideal_worlds.
func themes() -> Array[StringName]:
	return ideal_worlds.keys()

# ------------------------------------
# Observe / Absorb
# ------------------------------------

## Observes the given canonical proposition IDs, cloning them from WorldServer into perceived_world.
func observe_ids(ids: PackedInt32Array) -> void:
	for id in ids:
		if not WorldServer.is_registered_id(id):
			push_warning("observe_ids: unknown canonical id=%s" % id)
			continue
		var clone := WorldServer.create_clone_proposition(id)
		perceived_world.add_or_update_prop(clone, true)

## Observes all canonical proposition IDs from WorldServer into perceived_world.
func observe_all() -> void:
	observe_ids(WorldServer.prop_ids())

## Removes the given proposition IDs from perceived_world.
func forget_ids(ids: PackedInt32Array) -> void:
	for id in ids:
		perceived_world.remove_prop(id)

## Absorbs a single proposition into perceived_world, optionally overriding existing value.
## Only accepts valid, registered canonical propositions.
func absorb_proposition(p: Proposition, override: bool = true) -> void:
	if p == null or p._prop_id == 0:
		push_error("absorb_proposition: invalid proposition instance"); return
	if not WorldServer.is_registered_id(p._prop_id):
		push_error("absorb_proposition: id=%s not in canonical registry" % p._prop_id); return
	perceived_world.add_or_update_prop(p, override)

## Absorbs an array of Proposition instances into perceived_world, optionally overriding existing values.
func absorb_propositions(props: Array, override: bool = true) -> void:
	for p in props:
		if p is Proposition:
			absorb_proposition(p, override)

## Absorbs propositions from another World into perceived_world, filtered by IDs.
## Only registered canonical IDs are absorbed. Optionally attaches missing propositions.
func absorb_world(other: World, ids: PackedInt32Array = PackedInt32Array(), attach_missing: bool = true) -> void:
	if other == null: return
	var to_apply := (ids if not ids.is_empty() else other.prop_ids())
	var filtered := PackedInt32Array()
	for id in to_apply:
		if WorldServer.is_registered_id(id):
			filtered.append(id)
		else:
			push_warning("absorb_world: skipping unknown id=%s" % id)
	perceived_world.match_props_from_world(other, filtered, attach_missing)

## Absorbs propositions from another Character's perceived_world into this character's perceived_world.
## Optionally filters by IDs and attaches missing propositions.
func absorb_from_character(other: Character, ids: PackedInt32Array = PackedInt32Array(), attach_missing: bool = true) -> void:
	if other == null: return
	absorb_world(other.perceived_world, ids, attach_missing)

## Sets the belief (value) for a proposition ID in perceived_world.
## If the proposition is missing and attach_if_missing is true, clones it from WorldServer.
func believe(id: int, value: bool, attach_if_missing: bool = true) -> void:
	if perceived_world.propositions.has(id):
		perceived_world.set_value_by_prop_id(id, value)
		return
	if not attach_if_missing:
		return
	if not WorldServer.is_registered_id(id):
		push_error("believe: unknown canonical id=%s" % id)
		return
	var clone := WorldServer.create_clone_proposition(id, value)
	perceived_world.add_or_update_prop(clone, true)

# ------------------------------------
# Ideals / goals
# ------------------------------------

## Sets the ideal value for a proposition ID under a given theme.
## Creates the theme World if missing. Only accepts valid, registered canonical IDs and themes.
func set_ideal(theme: StringName, id: int, value: bool) -> void:
	if not WorldServer.has_theme(theme):
		push_error("set_ideal: unknown canonical theme '%s'" % String(theme)); return
	if not WorldServer.is_registered_id(id):
		push_error("set_ideal: unknown canonical id=%s" % id); return
	var w := ensure_theme(theme)
	if w == null: 
		return
	if w.propositions.has(id):
		w.set_value_by_prop_id(id, value)
	else:
		var clone := WorldServer.create_clone_proposition(id, value)
		w.add_or_update_prop(clone, true)

## Adopts ideals from another World into the ideal World for a given theme.
## Only registered canonical IDs are adopted. Optionally clones missing propositions.
func adopt_ideals_from_world(theme: StringName, other: World, ids: PackedInt32Array = PackedInt32Array(), clone_missing_props: bool = true) -> void:
	if not WorldServer.has_theme(theme):
		push_error("adopt_ideals_from_world: unknown canonical theme '%s'" % String(theme)); return
	if other == null: return
	var to_apply := (ids if not ids.is_empty() else other.prop_ids())
	var filtered := PackedInt32Array()
	for id in to_apply:
		if WorldServer.is_registered_id(id):
			filtered.append(id)
		else:
			push_warning("adopt_ideals_from_world: skipping unknown id=%s" % id)
	var w := ensure_theme(theme)
	if w == null: return
	w.match_props_from_world(other, filtered, clone_missing_props)

# ------------------------------------
# Tension helpers
# ------------------------------------

## Returns the tension score between the ideal World for a theme and the perceived_world.
## Tension is computed using World.tension_against.
func tension_ideal_vs_perceived(theme: StringName, lambda_missing: int = 0) -> int:
	if not ideal_worlds.has(theme): return 0
	return ideal_worlds[theme].tension_against(perceived_world, lambda_missing)

## Returns the tension score between perceived_world and the canonical WorldServer snapshot.
func tension_perceived_vs_canonical(lambda_missing: int = 0) -> int:
	var canonical_snapshot := WorldServer.snapshot_as_world("canonical@now")
	return perceived_world.tension_against(canonical_snapshot, lambda_missing)

## Returns a dictionary mapping each theme to its tension score against perceived_world.
func tensions_by_theme(lambda_missing: int = 0) -> Dictionary:
	var out := {}
	for theme in ideal_worlds.keys():
		out[theme] = tension_ideal_vs_perceived(theme, lambda_missing)
	return out

## Returns the theme with the highest tension score (breaks ties lexicographically).
func top_theme(lambda_missing: int = 0) -> StringName:
	var best: StringName = ""
	var best_val := -1
	for theme in ideal_worlds.keys():
		var t := tension_ideal_vs_perceived(theme, lambda_missing)
		if t > best_val or (t == best_val and String(theme) < String(best)):
			best = theme; best_val = t
	return best
