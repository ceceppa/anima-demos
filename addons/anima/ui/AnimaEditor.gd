tool
extends Control

signal switch_position
signal connections_updated(new_list)

var _shader_code: String = ""
var _anima_node: AnimaNode
var _node_offset: Vector2
var _is_restoring_data := false

onready var _graph_edit: GraphEdit = find_node("AnimaNodeEditor")
onready var _nodes_popup: PopupPanel = find_node("NodesPopup")
onready var _warning_label = find_node("WarningLabel")

func edit(node: AnimaNode) -> void:
	_is_restoring_data = true

	print_debug('editing node', node)
	_anima_node = node

	clear_all_nodes()

	var data = node.__anima_visual_editor_data
	AnimaUI.debug(self, 'restoring visual editor data', data)

	if data == null || not data.has('nodes') || data.nodes.size() == 0:
		var start_node = _graph_edit.get_anima_start_node(node, [], [])

		_graph_edit.add_child(start_node)
	else:
		_add_nodes(data.nodes, data.animations_slots, data.events_slots)
		_connect_nodes(data.connection_list)

		_graph_edit.set_scroll_ofs(data.scroll_offset)
		_graph_edit.set_zoom(data.zoom)

	_nodes_popup.set_source_node(_anima_node)

	_is_restoring_data = false

func clear_all_nodes() -> void:
	for node in _graph_edit.get_children():
		if node is GraphNode:
			_graph_edit.remove_child(node)
			node.free()

func _add_nodes(nodes_data: Array, animations_slots: Array, events_slots: Array) -> void:
	AnimaUI.debug(self, 'adding nodes: ', nodes_data.size())

	for node_data in nodes_data:
		var node: Node
		
		if node_data.id == 'AnimaNode':
			node = _graph_edit.get_anima_start_node(_anima_node, animations_slots, events_slots)
		else:
			var root = _anima_node.get_parent()

			if root == null:
				root = _anima_node

			var node_to_animate = root.find_node(node_data.node_to_animate, false)

			AnimaUI.debug(self, 'set node to animate', node_to_animate)
			node = _graph_edit.add_node(node_data.id, node_to_animate, false)

		node.name = node_data.name
		node.set_offset(node_data.position)
		node.set_title(node_data.title)
		node.restore_data(node_data.data)

		node.render()
		_graph_edit.add_child(node)

func _connect_nodes(connection_list: Array) -> void:
	for connection in connection_list:
		_graph_edit.connect_node(connection.from, connection.from_port, connection.to, connection.to_port)

func set_anima_node(node) -> void:
	_anima_node = node

	_maybe_show_graph_edit()

func show() -> void:
	.show()

func _maybe_show_graph_edit() -> bool:
	var is_graph_edit_visible = _anima_node is AnimaNode
	
	_graph_edit.visible = is_graph_edit_visible
	_warning_label.visible = !is_graph_edit_visible

	return is_graph_edit_visible

func _on_Right_pressed():
	emit_signal("switch_position")

func _on_AddButton_pressed():
	if _nodes_popup.visible:
		_nodes_popup.hide()
	else:
		_nodes_popup.show()

func _on_animaEditor_visibility_changed():
	if not visible:
		_nodes_popup.hide()

	_maybe_show_graph_edit()

func _on_GraphEdit_hide_nodes_list():
	_nodes_popup.hide()

func _on_NodesPopup_node_selected(node: Node):
	_nodes_popup.hide()

	var graph_node: GraphNode = _graph_edit.add_node('', node)
	graph_node.set_offset(_node_offset)

	_update_anima_node_data()

func _update_anima_node_data() -> void:
	# This method is also invoked when restoring the Visual Editor using the
	# AnimaNode data, and in this case we don't need to do anything here
	# or will lose some informations.
	if _is_restoring_data:
		return

	var data:= {
		nodes = [],
		animations_slots = [],
		events_slots = [],
		connection_list = _graph_edit.get_connection_list(),
		scroll_offset = _graph_edit.get_scroll_ofs(),
		zoom = _graph_edit.get_zoom(),
	}

	for child in _graph_edit.get_children():
		if child.is_queued_for_deletion():
			continue

		if child is GraphNode:
			var node_to_animate = null

			if child.has_method('get_node_to_animate'):
				node_to_animate = child.get_node_to_animate().name

			data.nodes.push_back({
				name = child.name,
				title = child.get_title(),
				position = child.get_offset(),
				node_to_animate = node_to_animate,
				id = child.get_id(),
				data = child.get_data()
			})

	data.animations_slots = _graph_edit.get_animations_slots()
	data.events_slots = _graph_edit.get_events_slots()

	AnimaUI.debug(self, 'updating visual editor data', data)

	emit_signal("connections_updated", data)

func _on_AnimaNodeEditor_show_nodes_list(offset: Vector2, position: Vector2):
	_node_offset = offset
	_nodes_popup.set_global_position(position)
	_nodes_popup.show()

func _on_AnimaNodeEditor_hide_nodes_list():
	_nodes_popup.hide()

func _on_AnimaNodeEditor_node_connected():
	_update_anima_node_data()

func _on_AnimaNodeEditor_node_updated():
	_update_anima_node_data()
