tool
extends GraphNode

var node_id: String
var node_category: String
var _node_type: int
var input_slots: Array = []
var output_slots: Array = []
var connected_inputs: Array = []
var connected_outputs: Array = []

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
func input_connected(slot: int, from: Node, from_port: int) -> void:
	var row_container = find_node('Row' + str(slot), true, false)

	if row_container:
		row_container.set_connected(AnimaUI.Port.INPUT)

	var is_already_connected = false
	for index in range(0, connected_inputs.size()):
		var connected_input = connected_inputs[index]

		if connected_input[0] == slot:
			connected_inputs[index] = [slot, from, from_port]

			is_already_connected = true
			break

	if not is_already_connected:
		connected_inputs.push_back([slot, from, from_port])

#	self.update_preview_shader()

func output_connected(slot: int) -> void:
	var row_container = find_node('Row' + str(slot), true, false)

	if row_container:
		row_container.set_connected(AnimaUI.Port.OUTPUT)

	if not connected_outputs.has(slot):
		connected_outputs.push_back(slot)

func disconnect_all_inputs_and_outputs() -> void:
	var total_slots = get_total_slots()
	connected_outputs = []
	connected_inputs = []

	for row_index in range(0, total_slots):
		var row_container = find_node('Row' + str(row_index), true, false)

		row_container.set_disconnected(AnimaUI.Port.INPUT)
		row_container.set_disconnected(AnimaUI.Port.OUTPUT)

func get_total_slots() -> float:
	var total_input_slots = input_slots.size()
	var total_output_slots = output_slots.size()

	return max(total_input_slots, total_output_slots)
