tool
extends GraphNode

signal disconnect_request(from, from_slot, to, to_slot)

var node_id: String
var node_category: String
var _node_type: int
var input_slots: Array = []
var output_slots: Array = []

var preview_panel: Panel = null;
var _custom_title: Control
var node_size_with_preview_panel_closed: Vector2

func setup() -> void:
	pass

# interface methods
func get_shader_global_code() -> String:
	return ""

func get_shader_code(output_port: int, inputs: Array) -> String:
	return ""

# node stuff
func connect_input(slot: int, _from: Node, _from_slot: int) -> void:
	var row_container = find_node('Row' + str(slot), true, false)

	if row_container:
		row_container.set_connected(AnimaUI.PORT.INPUT)


func connect_output(slot: int) -> void:
	var row_container = find_node('Row' + str(slot), true, false)

	if row_container:
		row_container.set_connected(AnimaUI.PORT.OUTPUT)

# node stuff
func disconnect_input(slot: int) -> void:
	var row_container = find_node('Row' + str(slot), true, false)

	if row_container:
		row_container.set_disconnected(AnimaUI.PORT.INPUT)


func disconnect_output(slot: int) -> void:
	var row_container = find_node('Row' + str(slot), true, false)

	if row_container:
		row_container.set_disconnected(AnimaUI.PORT.OUTPUT)

func remove() -> void:
	emit_signal("close_request")

func disconnect_node(from: Node, from_slot: int, to_slot: int, message: String = '') -> void:
	if message.length() > 0:
		printerr(message)

	emit_signal("disconnect_request", from, from_slot, self, to_slot)
