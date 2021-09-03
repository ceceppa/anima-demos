tool
extends Control

signal switch_position

var _shader_code: String = ""
var _anima_node: AnimaNode
onready var _graph_edit = find_node("GraphEdit")

func _ready():
	_graph_edit.connect("node_connected", self, '_on_node_connected')
	_graph_edit.connect("node_updated", self, '_on_node_updated')
	_graph_edit.connect("generate_full_shader", self, '_on_generate_full_shader')

func get_editor_preview() -> Node:
	return get_node('EditorPreview')

func graph_edit_children_reset_all_connections_info() -> void:
	for child in _graph_edit.get_children():
		var is_graph_node = child.is_class('GraphNode')

		if not is_graph_node:
			continue

		child.disconnect_all_inputs_outputs()

func update_preview_shaders(connection_list: Array):
	var connected_nodes := []

	for connection in connection_list:
		var from_node = connection.from
		var from_port = connection.from_port
		var to_node = connection.to
		var to_port = connection.to_port

		from_node.output_connected(from_port)
		
		if to_node:
			to_node.input_connected(to_port, from_node, from_port)

		if not connected_nodes.has(from_node):
			connected_nodes.push_back(from_node)

		if to_node and not connected_nodes.has(to_node):
			connected_nodes.push_back(to_node)

	# Todo: find a way to test me with GUT
	# In "real life" if we connect three or more nodes, for example:
	# Time (0) -> ABS1 (0) -> ABS2 (0)
	#
	# and then update the ABS1 input like:
	# Time (1) -> ABS1 (0) -> ABS2 (0)
	#
	# the abs1 shader code is updated to use the sin(TIME) as input
	# while the ABS2 is still using the TIME.
	# So, to avoid this bug we need to ask all the connected nodes
	# to refresh the preview shader
	for node in connected_nodes:
		node.update_preview_shader()

	update__anima_node_nodes_info(connection_list)

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

func edit(shader: AnimaNode) -> void:
	print_debug('edit', shader)
	_anima_node = shader

	clear_all_nodes()
	add_nodes(shader.get_nodes())

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

func _on_node_connected(connection_list: Array) -> void:
	graph_edit_children_reset_all_connections_info()

	update_preview_shaders(connection_list)

func _on_node_updated() -> void:
	update_preview_shaders(_graph_edit.get_connections())
#
#func _on_generate_full_shader(shader_output_node: Node) -> String:
#	var shader_code = _anima_node_Generator.generate_full_shader(shader_output_node)
#
##	get_editor_preview().update_shader(shader_code)
#	if _anima_node:
#		_anima_node.set_code(shader_code)
#
#	return shader_code

func _on_Right_pressed():
	emit_signal("switch_position")
