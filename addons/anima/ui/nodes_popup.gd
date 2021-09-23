tool
extends PopupPanel

var _source_node: AnimaNode

onready var _search_filed: LineEdit = find_node("SearchField")
onready var _item_list: ItemList = find_node("NodesList")

func show() -> void:
	.show()

	_retrieves_list_of_nodes()

	_search_filed.clear()
	_search_filed.grab_focus()

func set_source_node(node: AnimaNode) -> void:
	_source_node = node

func _retrieves_list_of_nodes() -> void:
	var start_node = _source_node.get_parent()

	if start_node == null:
		start_node = _source_node

	_item_list.clear()

	for child in start_node.get_children():
		if child is AnimaNode:
			continue

		_item_list.add_item(child.name)

func _on_SearchField_text_changed(new_text):
	var item = _item_list.items
	print(item)

	for index in _item_list.get_item_count():
#		var item = _item_list.items
		pass
