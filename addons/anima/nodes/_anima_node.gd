tool
extends "./_base_node.gd"

const ANIMATION_CONTROL = preload("res://addons/anima/nodes/animation_control.tscn")

var row_slot_controls := []

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

func set_name(name: String, index: int = 1):
	var new_name = "{name}{index}".format({
		'name': name,
		'index': index,
	})

	.set_name(new_name)

	# Godot adds @ if the name collides with an existing connected_inputs
	if '@' in self.name:
		self.set_name(name, index + 1)

func add_input_slot(name: String, type: int, default_value = null) -> void:
	input_slots.push_back([name, true, type, default_value])

func add_output_slot(name: String, type: int) -> void:
	output_slots.push_back([name, true, type])

func add_row_animation_control() -> void:
	row_slot_controls.push_back(ANIMATION_CONTROL.instance())

# Godot automatically adds the slot next to the element added.
# So to have a right and left label, we need to wrap them inside
# a HBoxContainer
func add_slot_labels(index: int, input_label_text, output_label_text, input_default_value = null) -> void:
	var slots_row: PanelContainer = AnimaUI.get_row(index, input_label_text, output_label_text, input_default_value)

	add_child(slots_row)

func render() -> void:
	if self.node_id == '':
		printerr('Please specify your node id for', self.name)

		return

	print_debug('rendering node')
	AnimaUI.customise_node_style(self, _custom_title, _node_type)

	# Used when there is no matching input/output node for the row
	var default_empty_slot = ["", false, 0, Color.aliceblue]

	var total_input_slots = input_slots.size()
	var total_output_slots = output_slots.size()
	var total_slots = get_total_slots()

	for index in range(0, total_slots):
		var input_slot = input_slots[index] if total_input_slots > index else default_empty_slot
		var output_slot = output_slots[index] if total_output_slots > index else default_empty_slot

		# Both input and output labels needs to be added
		# regardless of the existance of the corresponding slot,
		# because we can't choose in which column they need to be.

		var input_default_value = input_slot[4] if input_slot.size() >= 5 else null
		add_slot_labels(index, input_slot[0], output_slot[0], input_default_value)

		var input_slot_type = input_slot[2]
		var input_slot_enabled = input_slot[1]

		var output_slot_type = output_slot[2]
		var output_slot_enabled = output_slot[1]

		if input_slot_type == AnimaUI.PortType.LABEL_ONLY:
			input_slot_enabled = false

		if output_slot_type == AnimaUI.PortType.LABEL_ONLY:
			output_slot_enabled = false

		var input_color: Color = AnimaUI.PortColor[input_slot_type]
		var output_color: Color = AnimaUI.PortColor[output_slot_type]

		.set_slot(index + 1, input_slot_enabled, input_slot_type, input_color, output_slot_enabled, output_slot_type, output_color, null, null)

	for row_slot_control in row_slot_controls:
		_add_row_slot_control(row_slot_control)

func _add_row_slot_control(row_slot_control: Control) -> void:
	var container = PanelContainer.new()
	container.set_name('RowSlot')
	container.add_stylebox_override("panel", AnimaUI.generate_row_slot_panel_style())

	container.add_child(row_slot_control)
	add_child(container)

func get_row_slot_values() -> Array:
	var values = []

#	pass
#	for row_slot in row_slot_controls:
#		for property in POSSIBLE_NODE_PROPERTIES:
#			var value = row_slot.get(property)
#			if value:
#				values.push_back({
#				'property': property,
#				'value': row_slot[property]
#			})

	return values

func set_row_slot_values(values: Array) -> void:
	for row_slot in row_slot_controls:
		for value in values:
			var property = value.property

			if row_slot.get(property):
				row_slot.set(property, value.value)

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
