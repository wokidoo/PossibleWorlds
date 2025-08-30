extends VBoxContainer
class_name WorldTabs

signal prop_selected(id: int)
signal theme_selected(name: StringName)
signal char_selected(char)

var _tabs: TabContainer
var _props_table: Tree
var _themes_table: Tree
var _chars_table: Tree

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lbl_left := Label.new()
	lbl_left.text = "World State"
	add_child(lbl_left)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_tabs)

	# Propositions tab
	var prop_page := VBoxContainer.new()
	prop_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prop_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.add_child(prop_page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Propositions")

	_props_table = UiUtil.make_table(["ID", "Description", "Value"], true)
	_props_table.connect("item_selected", Callable(self, "_on_props_selected"))
	prop_page.add_child(_props_table)

	# Themes tab
	var theme_page := VBoxContainer.new()
	theme_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	theme_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.add_child(theme_page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Themes")

	_themes_table = UiUtil.make_table(["Theme"], true)
	_themes_table.connect("item_selected", Callable(self, "_on_themes_selected"))
	theme_page.add_child(_themes_table)

	# Characters tab
	var char_page := VBoxContainer.new()
	char_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	char_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.add_child(char_page)
	_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Characters")

	_chars_table = UiUtil.make_table(["Name", "#Perceived", "#Themes", "Perc↔Canon", "Top Theme", "Top Tension"], true)
	_chars_table.connect("item_selected", Callable(self, "_on_chars_selected"))
	char_page.add_child(_chars_table)

func refresh_ui(lambda_missing: int = 0) -> void:
	_populate_props()
	_populate_themes()
	_populate_chars(lambda_missing)

func _populate_props() -> void:
	if _props_table == null: return
	_props_table.clear()
	var root = _props_table.create_item()
	if WorldServer.has_method("prop_ids"):
		for id in WorldServer.prop_ids():
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

func _populate_chars(lambda_missing: int) -> void:
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

		var t_perceived := (c.tension_perceived_vs_canonical(lambda_missing) if c.has_method("tension_perceived_vs_canonical") else 0)

		var top_theme := ""
		var top_score := -1
		for theme in c.ideal_worlds.keys():
			var s := c.tension_ideal_vs_perceived(theme, lambda_missing)
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

		it.set_custom_bg_color(3, UiUtil.bg_for_tension(t_perceived, max_props))
		if top_score >= 0:
			it.set_custom_bg_color(5, UiUtil.bg_for_tension(top_score, max_props))

		it.set_metadata(0, {"type":"character","char":c})

func _on_props_selected() -> void:
	var sel = _props_table.get_selected()
	if sel == null: return
	var md = sel.get_metadata(0)
	if typeof(md) == TYPE_DICTIONARY and md.has("id"):
		emit_signal("prop_selected", int(md["id"]))

func _on_themes_selected() -> void:
	var sel = _themes_table.get_selected()
	if sel == null: return
	var md = sel.get_metadata(0)
	if typeof(md) == TYPE_DICTIONARY and md.has("name"):
		emit_signal("theme_selected", StringName(md["name"]))

func _on_chars_selected() -> void:
	var sel = _chars_table.get_selected()
	if sel == null: return
	var md = sel.get_metadata(0)
	if typeof(md) == TYPE_DICTIONARY and md.has("char"):
		emit_signal("char_selected", md["char"])