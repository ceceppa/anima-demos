tool
extends PopupPanel

var _source_node: AnimaNode

signal node_selected(node, position)

onready var _search_filed: LineEdit = find_node("SearchField")
onready var _nodes_list: Tree = find_node("NodesList")
var _start_node: Node

func show() -> void:
	.show()

	_retrieves_list_of_nodes()

	_search_filed.clear()
	_search_filed.grab_focus()

func set_source_node(node: AnimaNode) -> void:
	_source_node = node

func _retrieves_list_of_nodes() -> void:
	_start_node = _source_node.get_parent()

	if _start_node == null:
		_start_node = _source_node

	_nodes_list.clear()

	var root_item := _nodes_list.create_item()
	root_item.set_text(0, _start_node.name)

	_add_children(root_item, _start_node)

func _add_children(parent_item: TreeItem, start_node: Node) -> void:
	for child in start_node.get_children():
		if child is AnimaNode:
			continue

		var item = _nodes_list.create_item(parent_item)
		item.set_text(0, child.name)

		if child.get_child_count() > 0 and not child is AnimaShape:
			_add_children(item, child)

func _on_SearchField_text_changed(new_text):
	pass
#	for item in _nodes_list.items:
##		if not item is String:
##			continue
#
#		print(item)

func _on_NodesList_item_activated():
	var node_name = _nodes_list.get_selected().get_text(0)
	var node = _start_node.find_node(node_name)

	emit_signal("node_selected", node, rect_position)
