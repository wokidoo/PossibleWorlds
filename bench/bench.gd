extends Control

const LAMBDA_MISSING := 0  # tune if you want missing props to count in tensions

# ---------- refs we keep around ----------
var _tabs: TabContainer = null
var _props_table: Tree = null
var _themes_table: Tree = null
var _chars_table: Tree = null

var _details_container: VBoxContainer = null   # inner vbox INSIDE the ScrollContainer
var _log_edit: TextEdit = null  # (optional; if you add one to the scene later)

func _ready() -> void:
	# Root layout
	var root_vb := VBoxContainer.new()
	root_vb.anchor_right = 1.0
	root_vb.anchor_bottom = 1.0
	add_child(root_vb)

	# Toolbar
	var hb := HBoxContainer.new()
	root_vb.add_child(hb)

	var btn_refresh := Button.new()
	btn_refresh.text = "Refresh"
	btn_refresh.tooltip_text = "Refresh counts and tables"
	btn_refresh.connect("pressed", Callable(self, "refresh_ui"))
	hb.add_child(btn_refresh)

	var btn_seed := Button.new()
	btn_seed.text = "Seed Default"
	btn_seed.tooltip_text = "Seed a default world state (utility/create_default_world_state.tscn)"
	btn_seed.connect("pressed", Callable(self, "seed_default"))
	hb.add_child(btn_seed)

	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.tooltip_text = "Persist to user://world_state.tres"
	btn_save.connect("pressed", Callable(self, "save_state"))
	hb.add_child(btn_save)

	var btn_load := Button.new()
	btn_load.text = "Load"
	btn_load.tooltip_text = "Load from user://world_state.tres"
	btn_load.connect("pressed", Callable(self, "load_state"))
	hb.add_child(btn_load)

	var btn_snap := Button.new()
	btn_snap.text = "Snapshot"
	btn_snap.tooltip_text = "Show what would be saved"
	btn_snap.connect("pressed", Callable(self, "snapshot_state"))
	hb.add_child(btn_snap)

	var btn_clear := Button.new()
	btn_clear.text = "Clear Console"
	btn_clear.tooltip_text = "Clear the bench console log"
	btn_clear.connect("pressed", Callable(self, "clear_console"))
	hb.add_child(btn_clear)

	# Main split
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.add_child(split)

	# Left: tabs with tables
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(left_vb)

	var lbl_left := Label.new()
	lbl_left.text = "World State"
	left_vb.add_child(lbl_left)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.add_child(tabs)
	_tabs = tabs

	# Tab: Propositions
	var prop_page := VBoxContainer.new()
	prop_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prop_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.add_child(prop_page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Propositions")

	_props_table = _make_table(["ID", "Description", "Value"], true) # expand left tables
	_props_table.connect("item_selected", Callable(self, "_on_props_selected"))
	prop_page.add_child(_props_table)

	# Tab: Themes
	var theme_page := VBoxContainer.new()
	theme_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	theme_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.add_child(theme_page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Themes")

	_themes_table = _make_table(["Theme"], true)
	_themes_table.connect("item_selected", Callable(self, "_on_themes_selected"))
	theme_page.add_child(_themes_table)

	# Tab: Characters
	var char_page := VBoxContainer.new()
	char_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	char_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.add_child(char_page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Characters")

	# Extra columns for tensions
	_chars_table = _make_table(["Name", "#Perceived", "#Themes", "Perc↔Canon", "Top Theme", "Top Tension"], true)
	_chars_table.connect("item_selected", Callable(self, "_on_chars_selected"))
	char_page.add_child(_chars_table)

	# Right: SCROLLABLE details
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right_vb)

	var lbl_right := Label.new()
	lbl_right.text = "Details"
	right_vb.add_child(lbl_right)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED # vertical only
	right_vb.add_child(sc)

	var details_vbox := VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.custom_minimum_size = Vector2(320, 0)
	sc.add_child(details_vbox)
	_details_container = details_vbox

	refresh_ui()


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
func _make_table(col_titles: Array[String], expand: bool = false) -> Tree:
	var t := Tree.new()
	t.columns = col_titles.size()
	t.column_titles_visible = true
	t.hide_root = true
	for i in col_titles.size():
		t.set_column_title(i, col_titles[i])
		t.set_column_expand(i, true)
		t.set_column_custom_minimum_width(i, 60)
		t.set_column_clip_content(i, true)
	t.set_column_titles_visible(true)
	t.set_select_mode(Tree.SELECT_ROW)
	# expansion behavior differs for left (expand) vs right (no expand; let outer scroll)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = (Control.SIZE_EXPAND_FILL if expand else 0)
	return t

# For right-side tables: set a sensible height so outer ScrollContainer scrolls the page.
func _fit_tree_height(tree: Tree, rows: int, row_px: int = 22, header_px: int = 28, min_px: int = 44, max_px: int = 600) -> void:
	var h :float= clamp(header_px + rows * row_px, min_px, max_px)
	tree.scroll_vertical_enabled = false
	tree.custom_minimum_size.y = h

func _bench_log(msg: String) -> void:
	print(msg)
	if _log_edit:
		_log_edit.text += "%s\n" % msg
		_log_edit.scroll_vertical = _log_edit.get_line_count()

func _clear_details_container() -> void:
	if _details_container == null: return
	var children := []
	for i in _details_container.get_child_count():
		children.append(_details_container.get_child(i))
	for i in range(children.size() - 1, -1, -1):
		var child = children[i]
		_details_container.remove_child(child)
		child.queue_free()

# Colors for mismatches and tension heat
func _bg_match(match: bool) -> Color:
	return (Color(0.15, 0.6, 0.25, 0.25) if match else Color(0.80, 0.20, 0.20, 0.35))

func _bg_missing() -> Color:
	return Color(0.40, 0.40, 0.40, 0.20)

func _bg_for_tension(tension: int, max_possible: int) -> Color:
	var m :float= max(1, max_possible)
	var x :float= clamp(float(tension) / float(m), 0.0, 1.0)
	# simple green->red blend
	var r := 0.2 + 0.6 * x
	var g := 0.6 - 0.6 * x
	return Color(r, g, 0.2, 0.35)


# ─────────────────────────────────────────────────────────────────────────────
# Refresh + populate tables
# ─────────────────────────────────────────────────────────────────────────────
func refresh_ui() -> void:
	_populate_props()
	_populate_themes()
	_populate_chars()

func _populate_props() -> void:
	if _props_table == null: return
	_props_table.clear()
	var root = _props_table.create_item()
	if WorldServer.has_method("prop_ids"):
		var pids := WorldServer.prop_ids()
		for id in pids:
			var p = WorldServer.get_proposition(id) if WorldServer.has_method("get_proposition") else null
			var it = _props_table.create_item(root)
			it.set_text(0, str(id))
			it.set_text(1, (p.description if p != null else "<missing>"))
			it.set_text(2, (str(p.value) if p != null else ""))
			it.set_metadata(0, {"type":"prop","id":id})

func _populate_themes() -> void:
	if _themes_table == null: return
	_themes_table.clear()
	var root = _themes_table.create_item()
	if WorldServer.has_method("themes"):
		for t in WorldServer.themes():
			var it = _themes_table.create_item(root)
			it.set_text(0, String(t))
			it.set_metadata(0, {"type":"theme","name":t})

func _populate_chars() -> void:
	if _chars_table == null: return
	_chars_table.clear()
	var root = _chars_table.create_item()
	if not WorldServer.has_method("characters"):
		return

	var max_props := (WorldServer.prop_ids().size() if WorldServer.has_method("prop_ids") else 1)

	for c in WorldServer.characters():
		if c == null: continue
		var perceived_count := (c.perceived_world.propositions.size() if c.perceived_world != null else 0)
		var themes_count := c.ideal_worlds.size()

		var t_perceived := (c.tension_perceived_vs_canonical(LAMBDA_MISSING) if c.has_method("tension_perceived_vs_canonical") else 0)
		# find top theme + score
		var top_theme := ""
		var top_score := -1
		for theme in c.ideal_worlds.keys():
			var s := c.tension_ideal_vs_perceived(theme, LAMBDA_MISSING)
			if s > top_score or (s == top_score and String(theme) < top_theme):
				top_score = s
				top_theme = String(theme)

		var it = _chars_table.create_item(root)
		it.set_text(0, c.name)
		it.set_text(1, str(perceived_count))
		it.set_text(2, str(themes_count))
		it.set_text(3, str(t_perceived))
		it.set_text(4, top_theme)
		it.set_text(5, (str(top_score) if top_score >= 0 else "-"))

		# color the tension cells
		it.set_custom_bg_color(3, _bg_for_tension(t_perceived, max_props))
		if top_score >= 0:
			it.set_custom_bg_color(5, _bg_for_tension(top_score, max_props))

		it.set_metadata(0, {"type":"character","char":c})


# ─────────────────────────────────────────────────────────────────────────────
# Selection handlers (left tables → right detail)
# ─────────────────────────────────────────────────────────────────────────────
func _on_props_selected() -> void:
	var sel = _props_table.get_selected()
	if sel == null: return
	var md = sel.get_metadata(0)
	if typeof(md) == TYPE_DICTIONARY and md.has("id"):
		_show_prop_details(int(md["id"]))

func _on_themes_selected() -> void:
	var sel = _themes_table.get_selected()
	if sel == null: return
	var md = sel.get_metadata(0)
	if typeof(md) == TYPE_DICTIONARY and md.has("name"):
		_show_theme_details(StringName(md["name"]))

func _on_chars_selected() -> void:
	var sel = _chars_table.get_selected()
	if sel == null: return
	var md = sel.get_metadata(0)
	if typeof(md) == TYPE_DICTIONARY and md.has("char"):
		var c: Character = md["char"]
		_show_character_details(c)


# ─────────────────────────────────────────────────────────────────────────────
# Right-side detail builders (enhanced; now sized so outer scroll handles it)
# ─────────────────────────────────────────────────────────────────────────────
func _show_character_details(c: Character) -> void:
	if _details_container == null: return
	_clear_details_container()

	var hdr_lbl = Label.new()
	hdr_lbl.text = "Character: %s" % c.name
	_details_container.add_child(hdr_lbl)

	# Tension summary
	var t_summary = _make_table(["Target", "Score"], false)
	_details_container.add_child(t_summary)
	var troot = t_summary.create_item()
	var t_perc := c.tension_perceived_vs_canonical(LAMBDA_MISSING)
	var rowP = t_summary.create_item(troot); rowP.set_text(0, "Perceived ↔ Canon"); rowP.set_text(1, str(t_perc))
	rowP.set_custom_bg_color(1, _bg_for_tension(t_perc, WorldServer.prop_ids().size()))
	for theme in c.ideal_worlds.keys():
		var s := c.tension_ideal_vs_perceived(theme, LAMBDA_MISSING)
		var r = t_summary.create_item(troot)
		r.set_text(0, "Ideal(%s) ↔ Perceived" % String(theme))
		r.set_text(1, str(s))
		r.set_custom_bg_color(1, _bg_for_tension(s, WorldServer.prop_ids().size()))
	_fit_tree_height(t_summary, 1 + c.ideal_worlds.size())

	# Perceived world vs Canon table
	var per_label = Label.new(); per_label.text = "Perceived World (vs Canon)"
	_details_container.add_child(per_label)

	var per_tree = _make_table(["ID", "Description", "Value", "Canon"], false)
	_details_container.add_child(per_tree)
	var per_root = per_tree.create_item()
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
			# Coloring by match/mismatch to canonical
			if p == null or canon == null:
				it.set_custom_bg_color(0, _bg_missing())
				it.set_custom_bg_color(2, _bg_missing())
				it.set_custom_bg_color(3, _bg_missing())
			else:
				var match :bool= (p.value == canon.value)
				for col in [2, 3]:
					it.set_custom_bg_color(col, _bg_match(match))
	else:
		per_rows = 1
		var it_none = per_tree.create_item(per_root)
		it_none.set_text(1, "<no perceived world>")
	_fit_tree_height(per_tree, per_rows)

	# Ideal worlds: compare Ideal vs Perceived
	var ideals_lbl = Label.new(); ideals_lbl.text = "Ideal Worlds (vs Perceived)"
	_details_container.add_child(ideals_lbl)

	for theme_name in c.ideal_worlds.keys():
		var w = c.ideal_worlds[theme_name]
		var theme_lbl = Label.new()
		theme_lbl.text = "Theme: %s" % String(theme_name)
		_details_container.add_child(theme_lbl)

		var ttree = _make_table(["ID", "Description", "Ideal", "Perceived"], false)
		_details_container.add_child(ttree)
		var troot2 = ttree.create_item()
		var rows := 0
		if w != null and w.has_method("prop_ids"):
			for id in w.prop_ids():
				rows += 1
				var ideal_p = w.propositions.get(id, null)
				var perc_p = c.perceived_world.propositions.get(id, null) if c.perceived_world != null else null
				var it2 = ttree.create_item(troot2)
				it2.set_text(0, str(id))
				it2.set_text(1, (ideal_p.description if ideal_p != null else "<missing>"))
				it2.set_text(2, (str(ideal_p.value) if ideal_p != null else ""))
				it2.set_text(3, (str(perc_p.value) if perc_p != null else ""))
				if ideal_p == null or perc_p == null:
					it2.set_custom_bg_color(0, _bg_missing())
					it2.set_custom_bg_color(2, _bg_missing())
					it2.set_custom_bg_color(3, _bg_missing())
				else:
					var match2 :bool= (ideal_p.value == perc_p.value)
					for col in [2, 3]:
						it2.set_custom_bg_color(col, _bg_match(match2))
		else:
			rows = 1
			var none = ttree.create_item(troot2)
			none.set_text(1, "<empty>")
		_fit_tree_height(ttree, rows)

func _show_prop_details(id: int) -> void:
	if _details_container == null: return
	_clear_details_container()

	var hdr = Label.new(); hdr.text = "Proposition %s" % str(id)
	_details_container.add_child(hdr)

	var p = WorldServer.get_proposition(id) if WorldServer.has_method("get_proposition") else null
	if p != null:
		var t = _make_table(["Field", "Value"], false)
		_details_container.add_child(t)
		var root = t.create_item()
		var it1 = t.create_item(root); it1.set_text(0, "Description"); it1.set_text(1, p.description)
		var it2 = t.create_item(root); it2.set_text(0, "Canonical Value"); it2.set_text(1, str(p.value))
		_fit_tree_height(t, 2)
	else:
		var lbl = Label.new(); lbl.text = "<missing canonical proposition>"
		_details_container.add_child(lbl)

func _show_theme_details(theme_name: StringName) -> void:
	if _details_container == null: return
	_clear_details_container()
	var hdr = Label.new(); hdr.text = "Theme: %s" % String(theme_name)
	_details_container.add_child(hdr)
	var registered = WorldServer.has_theme(theme_name) if WorldServer.has_method("has_theme") else false
	var t = _make_table(["Field", "Value"], false)
	_details_container.add_child(t)
	var root = t.create_item()
	var it = t.create_item(root)
	it.set_text(0, "Registered")
	it.set_text(1, str(registered))
	_fit_tree_height(t, 1)


# ─────────────────────────────────────────────────────────────────────────────
# Buttons
# ─────────────────────────────────────────────────────────────────────────────
func seed_default() -> void:
	var path := "res://utility/create_default_world_state.tscn"
	var sc := ResourceLoader.load(path)
	if sc == null:
		_bench_log("seed_default: failed to load %s" % path)
		return
	var inst = sc.instantiate()
	add_child(inst)
	if inst.has_method("create_default_world_state"):
		var ok = inst.create_default_world_state()
		_bench_log("seed_default: created -> %s" % str(ok))
	else:
		_bench_log("seed_default: instance lacks create_default_world_state()")
	inst.queue_free()
	refresh_ui()

func save_state() -> void:
	if WorldServer.has_method("save_state"):
		var ok = WorldServer.save_state()
		_bench_log("save_state -> %s" % str(ok))
	else:
		_bench_log("save_state: WorldServer.save_state() not found")

func load_state() -> void:
	if WorldServer.has_method("load_state"):
		var ok = WorldServer.load_state()
		_bench_log("load_state -> %s" % str(ok))
		refresh_ui()
	else:
		_bench_log("load_state: WorldServer.load_state() not found")

func snapshot_state() -> void:
	if WorldServer.has_method("snapshot_as_world_state"):
		var state = WorldServer.snapshot_as_world_state()
		_bench_log("snapshot: props=%s themes=%s chars=%s" % [str(state.propositions.size()), str(state.themes.size()), str(state.characters.size())])
	else:
		var props_n := (WorldServer.prop_ids().size() if WorldServer.has_method("prop_ids") else 0)
		var themes_n := (WorldServer.themes().size() if WorldServer.has_method("themes") else 0)
		var chars_n := (WorldServer.characters().size() if WorldServer.has_method("characters") else 0)
		_bench_log("snapshot: props=%s themes=%s chars=%s" % [str(props_n), str(themes_n), str(chars_n)])

func clear_console() -> void:
	if _log_edit:
		_log_edit.text = ""
	print("Bench: console cleared")
