tool
extends VBoxContainer

signal node_selected(node)

export (bool) var trigger_selected := false

onready var _search_filed: LineEdit = find_node("SearchField")
onready var _nodes_list: Tree = find_node("NodesList")

var _start_node: Node
var _search_text: String

func populate():
	var anima_visual_node: AnimaVisualNode = AnimaUI.get_selected_anima_visual_node()

	_retrieves_list_of_nodes()

	_search_filed.clear()
	_search_filed.grab_focus()

func select_node(node: Node) -> void:
	var root: TreeItem = _nodes_list.get_root()
	
	_select_node(root, node.name)

func _select_node(tree_item: TreeItem, name: String) -> void:
	var child := tree_item.get_children()

	while child != null:
		var child_name: String = child.get_text(0)

		if child_name == name:
			child.select(0)

			return

		var subchild = child.get_children()
		if subchild:
			_select_node(subchild, name)

		child = child.get_next()

func _retrieves_list_of_nodes() -> void:
	var anima_visual_node: AnimaVisualNode = AnimaUI.get_selected_anima_visual_node()
	_start_node = anima_visual_node.get_source_node()

	_nodes_list.clear()

	var root_item := _nodes_list.create_item()
	root_item.set_text(0, _start_node.name)
	root_item.set_icon(0, AnimaUI.get_node_icon(_start_node))

	_add_children(_start_node, root_item, true)

func _add_children(start_node: Node, parent_item = null, is_root := false) -> void:
	if is_root:
		_nodes_list.set_hide_root(start_node is AnimaVisualNode or not _is_visible(start_node.name))
		
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
	var is_visible: bool = search.length() == 0 or name.to_lower().find(search) >= 0

	return is_visible

func _on_SearchField_text_changed(new_text: String):
	_search_text = new_text.to_lower()

	_retrieves_list_of_nodes()

func _on_NodesList_item_activated():
	var node_name = _nodes_list.get_selected().get_text(0)
	var node = _start_node.find_node(node_name)

	AnimaUI.debug(self, 'node selected', node)

	emit_signal("node_selected", node)

func _on_SearchField_gui_input(event):
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		hide()

func _on_NodesList_item_selected():
	if trigger_selected:
		_on_NodesList_item_activated()
