extends Control
class_name BenchUI

const LAMBDA_MISSING := 0

var _tabs_pane: WorldTabs
var _details_panel: DetailsPanel
var _log_edit: TextEdit = null

func _ready() -> void:
	# Root layout
	var root_vb := VBoxContainer.new()
	root_vb.anchor_right = 1.0
	root_vb.anchor_bottom = 1.0
	add_child(root_vb)

	# Toolbar
	var toolbar := BenchToolbar.new()
	root_vb.add_child(toolbar)
	toolbar.connect("refresh_requested", Callable(self, "refresh_ui"))
	toolbar.connect("seed_requested",    Callable(self, "seed_default"))
	toolbar.connect("save_requested",    Callable(self, "save_state"))
	toolbar.connect("load_requested",    Callable(self, "load_state"))
	toolbar.connect("snapshot_requested",Callable(self, "snapshot_state"))
	toolbar.connect("clear_console_requested", Callable(self, "clear_console"))

	# Main split
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vb.add_child(split)

	# Left
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(left_vb)

	_tabs_pane = WorldTabs.new()
	left_vb.add_child(_tabs_pane)

	# Connect selection → details
	_tabs_pane.connect("prop_selected", Callable(self, "_on_prop_selected"))
	_tabs_pane.connect("theme_selected", Callable(self, "_on_theme_selected"))
	_tabs_pane.connect("char_selected", Callable(self, "_on_char_selected"))

	# Right (scrollable details)
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right_vb)

	var lbl_right := Label.new(); lbl_right.text = "Details"
	right_vb.add_child(lbl_right)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vb.add_child(sc)

	_details_panel = DetailsPanel.new()
	_details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_panel.custom_minimum_size = Vector2(320, 0)
	sc.add_child(_details_panel)

	# First fill
	refresh_ui()

# Public (optional): attach a TextEdit from your scene if you add one.
func attach_log_edit(te: TextEdit) -> void:
	_log_edit = te

func refresh_ui() -> void:
	_tabs_pane.refresh_ui(LAMBDA_MISSING)

func _bench_log(msg: String) -> void:
	print(msg)
	if _log_edit:
		_log_edit.text += "%s\n" % msg
		_log_edit.scroll_vertical = _log_edit.get_line_count()

# Selection handlers → DetailsPanel
func _on_prop_selected(id: int) -> void:
	_details_panel.show_prop_details(id)

func _on_theme_selected(name: StringName) -> void:
	_details_panel.show_theme_details(name)

func _on_char_selected(c) -> void:
	_details_panel.show_character_details(c, LAMBDA_MISSING)

# Buttons
func seed_default() -> void:
	var path := "res://utility/create_default_world_state.tscn"
	var scn := ResourceLoader.load(path)
	if scn == null:
		_bench_log("seed_default: failed to load %s" % path)
		return
	var inst = scn.instantiate()
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
		_bench_log("snapshot: props=%s themes=%s chars=%s" % [
			str(state.propositions.size()), str(state.themes.size()), str(state.characters.size())
		])
	else:
		var props_n := (WorldServer.prop_ids().size() if WorldServer.has_method("prop_ids") else 0)
		var themes_n := (WorldServer.themes().size() if WorldServer.has_method("themes") else 0)
		var chars_n := (WorldServer.characters().size() if WorldServer.has_method("characters") else 0)
		_bench_log("snapshot: props=%s themes=%s chars=%s" % [str(props_n), str(themes_n), str(chars_n)])

func clear_console() -> void:
	if _log_edit:
		_log_edit.text = ""
	print("Bench: console cleared")
