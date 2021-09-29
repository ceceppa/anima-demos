tool
extends Control

signal switch_position
signal connections_updated(new_list)

var _shader_code: String = ""
var _anima_node: AnimaNode
var _source_node: AnimaNode

onready var _graph_edit: GraphEdit = find_node("AnimaNodeEditor")
onready var _nodes_popup: PopupPanel = find_node("NodesPopup")
onready var _warning_label = find_node("WarningLabel")

func _ready():
	_graph_edit.connect("node_connected", self, '_on_node_connected')
	_graph_edit.connect("node_updated", self, '_on_node_updated')

func update__anima_node_nodes_info(connection_list: Array) -> void:
	var nodes = []
	var children = _graph_edit.get_children()

	if not _anima_node:
		return

	for node in children:
		if node is GraphNode and not node.node_id in 'anima/' and node.node_id:
			var node_data = {}
			var values = node.get_row_slot_values()

			node_data[node.name] = {
				"title": node.get_title(),
				"id": node.node_id,
				"position": node.get_position(),
				'values': values
			}

			nodes.push_back(node_data)

	_anima_node.set_nodes(nodes)
	
	# When saving the anima file we need to store the node id
	# rather than its reference, because that's the only useful
	# information we can use when we load a file
	var connection_list_for_save = []

	for item in connection_list:
		item.from = item.from.node_id
		item.to = item.to.node_id
		
		connection_list_for_save.push_back(item)

	_anima_node.set_connection_list(connection_list)

func edit(node: AnimaNode) -> void:
	print_debug('editing  node', node)
	_anima_node = node

#	clear_all_nodes()
#	add_nodes(node.__anima_visual_editor_data)

func clear_all_nodes() -> void:
	for node in _graph_edit.get_children():
		if node is GraphNode:
			node.free()
			_graph_edit.remove_child(node)

func add_nodes(nodes_data: Array) -> void:
	print_debug('adding nodes: ', nodes_data.size())

	for node_data in nodes_data:
		var node_info = _graph_edit.add_node(node_data.id, false)

		print_debug(node_data, node_info)

		var node_script = node_info.script
		var node = load(node_script).new()

		if node is GraphNode:
			node.name = node_data.name
			node.set_offset(Vector2(0, 0))
			node.set_title(node_data.title)
			node.set_row_slot_values(node_data.values)

			node.render()
			_graph_edit.add_child(node)

func set_source_node(node) -> void:
	_source_node = node

	visible = _maybe_show_graph_edit()

func show() -> void:
	.show()
	_maybe_show_graph_edit()

func _maybe_show_graph_edit() -> bool:
	var is_graph_edit_visible = _source_node is AnimaNode
	
	_graph_edit.visible = is_graph_edit_visible
	_warning_label.visible = !is_graph_edit_visible

	_nodes_popup.set_source_node(_source_node)
	
	return is_graph_edit_visible

func _on_node_connected(connection_list: Array) -> void:
	_update_anima_node()

func _on_node_updated() -> void:
	_update_anima_node()

func _on_Right_pressed():
	emit_signal("switch_position")

func _on_AddButton_pressed():
	if _nodes_popup.visible:
		_nodes_popup.hide()
	else:
		_nodes_popup.show()

func _on_GraphEdit_show_nodes_list(position: Vector2):
	_nodes_popup.set_global_position(position)
	_nodes_popup.show()

func _on_animaEditor_visibility_changed():
	if not visible:
		_nodes_popup.hide()

	_maybe_show_graph_edit()

func _on_GraphEdit_hide_nodes_list():
	_nodes_popup.hide()

func _on_NodesPopup_node_selected(node):
	_nodes_popup.hide()

	_graph_edit.add_node(node)
	_update_anima_node()

func _update_anima_node() -> void:
	emit_signal("connections_updated", _graph_edit.get_connection_list())
