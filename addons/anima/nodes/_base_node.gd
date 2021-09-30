tool
extends "./_base_signals.gd"

const ANIMATION_CONTROL = preload("res://addons/anima/nodes/animation_control.tscn")

var _node_body_data := []
var _node_id: String

enum BodyDataType {
	INPUT_SLOT,
	OUTPUT_SLOT,
	ROW
}
#var _row_slot_controls := []

func _init():
	_custom_title = load('res://addons/anima/ui/custom_node_title.tscn').instance()
	add_child(_custom_title)

	set_show_close_button(false)

	_custom_title.connect('toggle_preview', self, '_on_toggle_preview')

func _ready():
	setup()
	render()

func register_node(node_data: Dictionary) -> void:
	if node_data.has('category'):
		set_category(node_data.category)

	if node_data.has('name'):
		self.set_name(title)
		set_title(node_data.name)

	if node_data.has('category') and node_data.has('name'):
		set_id(node_data.category + '/' + node_data.name)

	if not node_data.has('type'):
		printerr("Specify node type!")

		return

	if node_data.has('icon'):
		set_icon(node_data.icon)

	if node_data.has('playable') and not node_data.playable:
		_custom_title.hide_play_button()

	if node_data.has('closable') and not node_data.closable:
		_custom_title.hide_close_button()

	_node_id = node_data.id

	set_type(node_data.type)

func set_category(category: String) -> void:
	node_category = category

func set_id(fullQualifiedName: String) -> void:
	if not '/' in fullQualifiedName:
		printerr('Invalid node identifier, please use: [Category]/[Node]')
		
		return

	node_id = fullQualifiedName

func set_type(type: int) -> void:
	_node_type = type

func set_icon(icon_path) -> void:
	_custom_title.set_icon(icon_path)

func set_title(title: String) -> void:
	self.name = title
	_custom_title.set_title(title)

func get_title() -> String:
	return _custom_title.get_title()

func get_id() -> String:
	return _node_id

func set_name(name: String, index: int = 1):
	var new_name = "{name}{index}".format({
		'name': name,
		'index': index,
	})

	.set_name(new_name)

	# Godot adds @ if the name collides with an existing connected_inputs
	if '@' in self.name:
		self.set_name(name, index + 1)

func add_input_slot(name: String, tooltip: String, type: int, default_value = null) -> void:
	_node_body_data.push_back({type = BodyDataType.INPUT_SLOT, data = [name, tooltip, true, type, default_value]})

func add_output_slot(name: String, tooltip: String, type: int) -> void:
	_node_body_data.push_back({type = BodyDataType.OUTPUT_SLOT, data = [name, tooltip, true, type]})

func add_row_animation_control() -> void:
	_node_body_data.push_back({type = BodyDataType.ROW, node = ANIMATION_CONTROL.instance()})

func add_divider() -> void:
	var separator := HSeparator.new()
	
	separator.size_flags_horizontal = SIZE_EXPAND_FILL
	_node_body_data.push_back({type = BodyDataType.ROW, node = separator})

func add_spacer() -> void:
	var separator := Label.new()
	
	separator.size_flags_horizontal = SIZE_EXPAND_FILL
	_node_body_data.push_back({type = BodyDataType.ROW, node = separator})

func add_label(v: String) -> void:
	var label := Label.new()
	
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.align = VALIGN_CENTER
	label.modulate.a = 0.4
	label.set_text(v)

	_node_body_data.push_back({type = BodyDataType.ROW, node = label})

# Godot automatically adds the slot next to the element added.
# So to have a right and left label, we need to wrap them inside
# a HBoxContainer
func _add_slot_labels(index: int, input_label_text, input_tooltip, output_label_text, output_tooltip, input_default_value = null) -> void:
	var slots_row: PanelContainer = AnimaUI.create_row_for_node(index, input_label_text, input_tooltip, output_label_text, output_tooltip, input_default_value)

	add_child(slots_row)

func render() -> void:
	if self.node_id == '':
		printerr('Please specify your node id for', self.name)

		return

	print_debug('rendering node')
	AnimaUI.customise_node_style(self, _custom_title, _node_type)

	# Used when there is no matching input/output node for the row
	var default_empty_slot = ["", "", false, 0, Color.aliceblue]

	var total_slots := 0
	for data in _node_body_data:
		if data.type == BodyDataType.INPUT_SLOT or data.type == BodyDataType.OUTPUT_SLOT:
			total_slots += 1

	for index in _node_body_data.size():
		var data: Dictionary = _node_body_data[index]

		if data.type == BodyDataType.ROW:
			add_child(data.node)

			continue

		var input_slot = default_empty_slot
		var output_slot = default_empty_slot

		if data.type == BodyDataType.INPUT_SLOT:
			input_slot = data.data
		else:
			output_slot = data.data

		# Both input and output labels needs to be added
		# regardless of the existance of the corresponding slot,
		# because we can't choose in which column they need to be.

		var input_default_value = input_slot[5] if input_slot.size() >= 6 else null
		_add_slot_labels(index, input_slot[0], input_slot[1], output_slot[0], output_slot[1], input_default_value)

		var input_slot_type = input_slot[3]
		var input_slot_enabled = input_slot[2]

		var output_slot_type = output_slot[3]
		var output_slot_enabled = output_slot[2]

		if input_slot_type == AnimaUI.PortType.LABEL_ONLY:
			input_slot_enabled = false

		if output_slot_type == AnimaUI.PortType.LABEL_ONLY:
			output_slot_enabled = false

		var input_color: Color = AnimaUI.PortColor[input_slot_type]
		var output_color: Color = AnimaUI.PortColor[output_slot_type]

		.set_slot(index + 1, input_slot_enabled, input_slot_type, input_color, output_slot_enabled, output_slot_type, output_color, null, null)

func _add_row_slot_control(row_slot_control: Control) -> void:
	var container = PanelContainer.new()
	container.set_name('RowSlot')
	container.add_stylebox_override("panel", AnimaUI.generate_row_slot_panel_style())

	container.add_child(row_slot_control)
	add_child(container)

func get_row_slot_values() -> Array:
	var values = []

#	pass
#	for row_slot in _row_slot_controls:
#		for property in POSSIBLE_NODE_PROPERTIES:
#			var value = row_slot.get(property)
#			if value:
#				values.push_back({
#				'property': property,
#				'value': row_slot[property]
#			})

	return values

func _on_toggle_preview(visible: bool):
	# Hiding the panel does not "restore" the previous
	# node height, so we're going to store the original
	# size and restore it manually once the panel is hidden
	if visible:
		if node_size_with_preview_panel_closed == Vector2.ZERO:
			var rect := self.get_rect()

			node_size_with_preview_panel_closed = rect.size

		preview_panel.show()
	else:
		preview_panel.hide()
		self._set_size(node_size_with_preview_panel_closed)

#	self.update_preview_shader()
