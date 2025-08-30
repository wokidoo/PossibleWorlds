extends VBoxContainer
class_name DetailsPanel

func clear_panel() -> void:
	UiUtil.clear_children(self)

func show_prop_details(id: int) -> void:
	clear_panel()
	var hdr = Label.new(); hdr.text = "Proposition %s" % str(id)
	add_child(hdr)

	var p = WorldServer.get_proposition(id) if WorldServer.has_method("get_proposition") else null
	if p != null:
		var t = UiUtil.make_table(["Field", "Value"], false)
		add_child(t)
		var root = t.create_item()
		var it1 = t.create_item(root); it1.set_text(0, "Description"); it1.set_text(1, p.description)
		var it2 = t.create_item(root); it2.set_text(0, "Canonical Value"); it2.set_text(1, str(p.value))
		UiUtil.fit_tree_height(t, 2)
	else:
		var lbl = Label.new(); lbl.text = "<missing canonical proposition>"
		add_child(lbl)

func show_theme_details(theme_name: StringName) -> void:
	clear_panel()
	var hdr = Label.new(); hdr.text = "Theme: %s" % String(theme_name)
	add_child(hdr)
	var registered := WorldServer.has_theme(theme_name) if WorldServer.has_method("has_theme") else false
	var t = UiUtil.make_table(["Field", "Value"], false)
	add_child(t)
	var root = t.create_item()
	var it = t.create_item(root)
	it.set_text(0, "Registered")
	it.set_text(1, str(registered))
	UiUtil.fit_tree_height(t, 1)

func show_character_details(c, lambda_missing: int = 0) -> void:
	clear_panel()
	var hdr_lbl = Label.new()
	hdr_lbl.text = "Character: %s" % c.name
	add_child(hdr_lbl)

	# Summary tree (expandable)
	var t_summary := UiUtil.make_table(["Target", "Score"], false)
	add_child(t_summary)
	var troot := t_summary.create_item()

	var all_prop_count :int = (WorldServer.prop_ids().size() if WorldServer.has_method("prop_ids") else 1)

	# Row 1: Perceived ↔ Canon (kept flat)
	var t_perc :int = c.tension_perceived_vs_canonical(lambda_missing)
	var rowP := t_summary.create_item(troot)
	rowP.set_text(0, "Perceived ↔ Canon")
	rowP.set_text(1, str(t_perc))
	rowP.set_custom_bg_color(1, UiUtil.bg_for_tension(t_perc, all_prop_count))

	# One master row for ALL ideal worlds
	var themes_count :int = c.ideal_worlds.size()
	var total_all :int = 0
	for theme_name in c.ideal_worlds.keys():
		total_all += c.tension_ideal_vs_perceived(theme_name, lambda_missing)

	var master := t_summary.create_item(troot)
	master.set_text(0, "Ideal ↔ Perceived")
	master.set_text(1, str(total_all))
	# color scale across all themes (sum of per-theme maxima)
	master.set_custom_bg_color(1, UiUtil.bg_for_tension(total_all, max(1, all_prop_count * max(1, themes_count))))
	master.collapsed = true

	# Children: each theme (each of these can expand to per-prop breakdown)
	for theme_name in c.ideal_worlds.keys():
		var total :int = c.tension_ideal_vs_perceived(theme_name, lambda_missing)
		var parent := t_summary.create_item(master)
		parent.set_text(0, "Ideal(%s) ↔ Perceived" % String(theme_name))
		parent.set_text(1, str(total))
		parent.set_custom_bg_color(1, UiUtil.bg_for_tension(total, all_prop_count))
		parent.collapsed = true  # collapsed by default

		var breakdown := _ideal_vs_perceived_breakdown(c, theme_name, lambda_missing)
		for d in breakdown:
			var child := t_summary.create_item(parent)
			var desc :String = d.get("desc", "")
			var id   :int    = d.get("id", -1)
			var iv           = d.get("ideal")
			var pv           = d.get("perc")
			var reason:String= d.get("reason", "")
			child.set_text(0, "#%s %s  (ideal:%s ↔ perc:%s)  [%s]" % [str(id), desc, str(iv), str(pv), reason])
			child.set_text(1, str(d.get("contrib", 0)))

			# Visual cue: missing vs mismatch
			if reason == "missing":
				child.set_custom_bg_color(1, UiUtil.bg_missing())
			else:
				child.set_custom_bg_color(1, UiUtil.bg_match(false))

	# Let the tree resize when expanding/collapsing any level
	t_summary.connect("item_collapsed", Callable(self, "_recalc_tree_height").bind(t_summary))
	UiUtil.fit_tree_height(t_summary, _visible_rows_count(t_summary))
	# ── Perceived vs Canon table (unchanged) ──
	var per_label := Label.new(); per_label.text = "Perceived World (vs Canon)"
	add_child(per_label)

	var per_tree := UiUtil.make_table(["ID", "Description", "Value", "Canon"], false)
	add_child(per_tree)
	var per_root := per_tree.create_item()
	var per_rows := 0
	if c.perceived_world != null and c.perceived_world.has_method("prop_ids"):
		for id in c.perceived_world.prop_ids():
			per_rows += 1
			var p = c.perceived_world.propositions.get(id, null)
			var canon = WorldServer.get_proposition(id) if WorldServer.has_method("get_proposition") else null
			var it = per_tree.create_item(per_root)
			it.set_text(0, str(id))
			it.set_text(1, (p.description if p != null else "<missing>"))
			it.set_text(2, (str(p.value) if p != null else ""))
			it.set_text(3, (str(canon.value) if canon != null else ""))
			if p == null or canon == null:
				it.set_custom_bg_color(0, UiUtil.bg_missing())
				it.set_custom_bg_color(2, UiUtil.bg_missing())
				it.set_custom_bg_color(3, UiUtil.bg_missing())
			else:
				var match: bool = (p.value == canon.value)
				for col in [2, 3]:
					it.set_custom_bg_color(col, UiUtil.bg_match(match))
	else:
		per_rows = 1
		var it_none = per_tree.create_item(per_root)
		it_none.set_text(1, "<no perceived world>")
	UiUtil.fit_tree_height(per_tree, per_rows)

		# ── Unified Ideal vs Perceived table (COLLAPSIBLE THEMES) ──
	var ideals_lbl := Label.new(); ideals_lbl.text = "Ideal Worlds (vs Perceived)"
	add_child(ideals_lbl)

	var all_tree := UiUtil.make_table(["Theme", "ID", "Description", "Ideal", "Perceived"], false)
	add_child(all_tree)
	var all_root := all_tree.create_item()

	# Stable ordering
	var theme_keys :Array = c.ideal_worlds.keys()
	theme_keys.sort()

	var total_rows :int = 0
	for theme_name in theme_keys:
		total_rows += 1
		var parent := all_tree.create_item(all_root)
		parent.set_text(0, String(theme_name))
		parent.collapsed = true  # collapsed by default
		# (optional) make parent row non-selectable in value columns
		for col in range(1, 5):
			parent.set_selectable(col, false)

		var w = c.ideal_worlds[theme_name]
		var has_rows := false
		if w != null and w.has_method("prop_ids"):
			var ids :Array= w.prop_ids()
			ids.sort()
			for id in ids:
				has_rows = true
				total_rows += 1
				var ideal_p = w.propositions.get(id, null)
				var perc_p  = (c.perceived_world.propositions.get(id, null) if c.perceived_world != null else null)

				var it = all_tree.create_item(parent)
				it.set_text(0, "")  # theme shown on parent only
				it.set_text(1, str(id))
				it.set_text(2, (ideal_p.description if ideal_p != null else (perc_p.description if perc_p != null else "<missing>")))
				it.set_text(3, (str(ideal_p.value) if ideal_p != null else ""))
				it.set_text(4, (str(perc_p.value)  if perc_p  != null else ""))

				# Color coding (match/miss/missing)
				if ideal_p == null or perc_p == null:
					for col in [1, 3, 4]:
						it.set_custom_bg_color(col, UiUtil.bg_missing())
				else:
					var match: bool = (ideal_p.value == perc_p.value)
					for col in [3, 4]:
						it.set_custom_bg_color(col, UiUtil.bg_match(match))
		if not has_rows:
			total_rows += 1
			var none = all_tree.create_item(parent)
			none.set_text(2, "<empty>")
			for col in [1, 3, 4]:
				none.set_custom_bg_color(col, UiUtil.bg_missing())

	# Re-fit height as users expand/collapse themes
	all_tree.connect("item_collapsed", Callable(self, "_recalc_tree_height").bind(all_tree))
	UiUtil.fit_tree_height(all_tree, _visible_rows_count(all_tree))


func _ideal_vs_perceived_breakdown(c, theme_name: StringName, lambda_missing: int) -> Array:
	var w = c.ideal_worlds[theme_name]
	var ids := {}
	if w != null and w.has_method("prop_ids"):
		for id in w.prop_ids(): ids[id] = true
	if c.perceived_world != null and c.perceived_world.has_method("prop_ids"):
		for id in c.perceived_world.prop_ids(): ids[id] = true

	var results: Array = []
	for id in ids.keys():
		var ideal_p = (w.propositions.get(id, null) if w != null else null)
		var perc_p  = (c.perceived_world.propositions.get(id, null) if c.perceived_world != null else null)
		var contrib := 0
		var reason := ""
		if ideal_p == null or perc_p == null:
			contrib = lambda_missing
			reason = "missing"
		elif ideal_p.value != perc_p.value:
			contrib = 1
			reason = "mismatch"
		if contrib != 0:
			results.append({
				"id": id,
				"desc": (ideal_p.description if ideal_p != null else (perc_p.description if perc_p != null else "")),
				"ideal": (ideal_p.value if ideal_p != null else null),
				"perc":  (perc_p.value  if perc_p  != null else null),
				"contrib": contrib,
				"reason": reason,
			})
	# Sort largest contrib first, then by id
	results.sort_custom(Callable(self, "_sort_contrib"))
	return results

func _sort_contrib(a, b) -> bool:
	if a.contrib == b.contrib:
		return int(a.id) < int(b.id)
	return int(a.contrib) > int(b.contrib)

func _recalc_tree_height(_item: Object, tree: Tree) -> void:
	UiUtil.fit_tree_height(tree, _visible_rows_count(tree))

func _visible_rows_count(tree: Tree) -> int:
	var root := tree.get_root()
	if root == null: return 0
	return _count_visible_from(root)

func _count_visible_from(parent: TreeItem) -> int:
	var total := 0
	var item := parent.get_first_child()
	while item:
		total += 1
		if not item.collapsed:
			total += _count_visible_from(item)
		item = item.get_next()
	return total