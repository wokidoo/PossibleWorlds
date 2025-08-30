extends HBoxContainer
class_name BenchToolbar

signal refresh_requested
signal seed_requested
signal save_requested
signal load_requested
signal snapshot_requested
signal clear_console_requested

func _ready() -> void:
	var btn_refresh := Button.new()
	btn_refresh.text = "Refresh"
	btn_refresh.tooltip_text = "Refresh counts and tables"
	btn_refresh.connect("pressed", Callable(self, "_emit_refresh"))
	add_child(btn_refresh)

	var btn_seed := Button.new()
	btn_seed.text = "Seed Default"
	btn_seed.tooltip_text = "Seed a default world state (utility/create_default_world_state.tscn)"
	btn_seed.connect("pressed", Callable(self, "_emit_seed"))
	add_child(btn_seed)

	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.tooltip_text = "Persist to user://world_state.tres"
	btn_save.connect("pressed", Callable(self, "_emit_save"))
	add_child(btn_save)

	var btn_load := Button.new()
	btn_load.text = "Load"
	btn_load.tooltip_text = "Load from user://world_state.tres"
	btn_load.connect("pressed", Callable(self, "_emit_load"))
	add_child(btn_load)

	var btn_snap := Button.new()
	btn_snap.text = "Snapshot"
	btn_snap.tooltip_text = "Show what would be saved"
	btn_snap.connect("pressed", Callable(self, "_emit_snapshot"))
	add_child(btn_snap)

	var btn_clear := Button.new()
	btn_clear.text = "Clear Console"
	btn_clear.tooltip_text = "Clear the bench console log"
	btn_clear.connect("pressed", Callable(self, "_emit_clear"))
	add_child(btn_clear)

func _emit_refresh() -> void: emit_signal("refresh_requested")
func _emit_seed() -> void: emit_signal("seed_requested")
func _emit_save() -> void: emit_signal("save_requested")
func _emit_load() -> void: emit_signal("load_requested")
func _emit_snapshot() -> void: emit_signal("snapshot_requested")
func _emit_clear() -> void: emit_signal("clear_console_requested")