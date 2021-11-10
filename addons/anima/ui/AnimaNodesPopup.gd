tool
extends PopupPanel

var _anima_visual_node: AnimaVisualNode

signal node_selected(node)

onready var _search_filed: LineEdit = find_node("SearchField")
onready var _nodes_list: Tree = find_node("NodesList")
var _start_node: Node
var _search_text: String

func show() -> void:
	var anima: AnimaNode = Anima.begin(self)
	anima.then({ property = "scale", from = Vector2.ZERO, duration = 0.3, easing = Anima.EASING.EASE_OUT_BACK })
	anima.also({ property = "opacity", from = 0, to = 1 })
	anima.set_visibility_strategy(Anima.VISIBILITY.TRANSPARENT_ONLY)

	.show()

	_retrieves_list_of_nodes()

	_search_filed.clear()
	_search_filed.grab_focus()

	anima.play()

func set_source_node(node: AnimaVisualNode) -> void:
	_anima_visual_node = node

func _retrieves_list_of_nodes() -> void:
	_start_node = _anima_visual_node.get_source_node()

	_nodes_list.clear()

	var root_item := _nodes_list.create_item()
	root_item.set_text(0, _start_node.name)
	root_item.set_icon(0, AnimaUI.get_node_icon(_start_node))

	_add_children(_start_node, root_item)

func _add_children(start_node: Node, parent_item = null) -> void:
	if start_node is AnimaVisualNode or not _is_visible(start_node.name):
		_nodes_list.set_hide_root(true)

	for child in start_node.get_children():
		var item

		if child is AnimaVisualNode or child is AnimaNode:
			continue

		if _is_visible(child.name):
			item = _nodes_list.create_item(parent_item)
			item.set_text(0, child.name)
			item.set_icon(0, AnimaUI.get_node_icon(child))

		if child.get_child_count() > 0 and not child is AnimaShape:
			_add_children(child, item)

func _is_visible(name: String) -> bool:
	var search: String = _search_text.strip_edges()

	return search.length() == 0 or name.find(search) >= 0

func _on_SearchField_text_changed(new_text):
	_search_text = new_text

	_retrieves_list_of_nodes()

func _on_NodesList_item_activated():
	var node_name = _nodes_list.get_selected().get_text(0)
	var node = _start_node.find_node(node_name)

	emit_signal("node_selected", node)

func _on_SearchField_gui_input(event):
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		hide()
