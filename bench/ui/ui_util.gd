extends RefCounted
class_name  UiUtil

static func make_table(col_titles: Array[String], expand: bool = false) -> Tree:
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
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = (Control.SIZE_EXPAND_FILL if expand else 0)
	return t

static func fit_tree_height(tree: Tree, rows: int, row_px: int = 22, header_px: int = 28, min_px: int = 44, max_px: int = 600) -> void:
	var h: float = clamp(header_px + rows * row_px, min_px, max_px)
	tree.scroll_vertical_enabled = false
	tree.custom_minimum_size.y = h

static func clear_children(container: Node) -> void:
	var to_free: Array = []
	for i in container.get_child_count():
		to_free.append(container.get_child(i))
	for c in to_free:
		container.remove_child(c)
		c.queue_free()

static func bg_match(match: bool) -> Color:
	return (Color(0.15, 0.6, 0.25, 0.25) if match else Color(0.80, 0.20, 0.20, 0.35))

static func bg_missing() -> Color:
	return Color(0.40, 0.40, 0.40, 0.20)

static func bg_for_tension(tension: int, max_possible: int) -> Color:
	var m: float = max(1, max_possible)
	var x: float = clamp(float(tension) / float(m), 0.0, 1.0)
	var r := 0.2 + 0.6 * x
	var g := 0.6 - 0.6 * x
	return Color(r, g, 0.2, 0.35)