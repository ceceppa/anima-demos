tool
extends "./_base_signals.gd"

const ANIMATION_CONTROL = preload("res://addons/anima/nodes/animation_control.tscn")

signal node_updated

var _node_body_data := []
var _node_id: String

enum BodyDataType {
	SLOT,
	ROW
}
#var _row_slot_controls := []

func _init():
	_custom_title = load('res://addons/anima/ui/custom_node_title.tscn').instance()
	add_child(_custom_title)

	set_show_close_button(false)

	_custom_title.connect('toggle_preview', self, '_on_toggle_preview')
	_custom_title.connect('remove_node', self, '_on_remove_node')

	connect("offset_changed", self, "_on_offset_changed")

	rect_min_size = get_minimum_size() + Vector2(200, 150)

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

	if node_data.has('deletable') and not node_data.deletable:
		_custom_title.hide_close_button()

	if node_data.has('min_size'):
		rect_min_size = get_minimum_size() + node_data.min_size

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

func set_icon(icon) -> void:
	_custom_title.set_icon(icon)

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

func add_slot(data: Dictionary) -> void:
	_node_body_data.push_back({type = BodyDataType.SLOT, io_data = data})

func add_custom_slot(custom_row: Node, name: String, type: int) -> void:
	_node_body_data.push_back({type = BodyDataType.SLOT, custom_row = custom_row})

func add_custom_row(node = Node) -> void:
	_node_body_data.push_back({type = BodyDataType.ROW, node = node})

func add_divider() -> void:
	var separator := HSeparator.new()
	
	separator.size_flags_horizontal = SIZE_EXPAND_FILL
	_node_body_data.push_back({type = BodyDataType.ROW, node = separator})

func add_spacer() -> void:
	var separator := Label.new()
	
	separator.size_flags_horizontal = SIZE_EXPAND_FILL
	_node_body_data.push_back({type = BodyDataType.ROW, node = separator})

func add_label(v: String, tooltip: String) -> void:
	var label := Label.new()
	
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.align = VALIGN_CENTER
	label.modulate.a = 0.4
	label.set_text(v)
	label.hint_tooltip = tooltip

	_node_body_data.push_back({type = BodyDataType.ROW, node = label})

# Godot automatically adds the slot next to the element added.
# So to have a right and left label, we need to wrap them inside
# a HBoxContainer
func _add_slot_labels(index: int, input_slot: Dictionary, output_slot: Dictionary, add := true) -> PanelContainer:
	var input_label_text: String = input_slot.label if input_slot.has('label') else ''
	var input_tooltip: String = input_slot.tooltip if input_slot.has('tooltip') else ''
	var input_default_value = input_slot.default if input_slot.has('default') else ''

	var output_label_text: String = output_slot.label if output_slot.has('label') else ''
	var output_tooltip: String = output_slot.tooltip if output_slot.has('tooltip') else ''

	var slots_row: PanelContainer = AnimaUI.create_row_for_node(
		index,
		input_label_text,
		input_tooltip,
		output_label_text,
		output_tooltip,
		input_default_value
	)

	if add:
		add_child(slots_row)

	return slots_row

func render() -> void:
	if self.node_id == '':
		printerr('Please specify your node id for', self.name)

		return

	AnimaUI.customise_node_style(self, _custom_title, _node_type)

	for index in _node_body_data.size():
		var data: Dictionary = _node_body_data[index]

		if data.type == BodyDataType.ROW:
			add_child(data.node)

			continue
		elif data.has('custom_row'):
			add_child(data.custom_row)

			continue

		var io_data = data.io_data if data.has('io_data') else {}
		var input_slot: Dictionary = {}
		var output_slot: Dictionary = {}

		if io_data.has('input'):
			input_slot = io_data.input

		if io_data.has('output'):
			output_slot = io_data.output

		_add_slot_labels(index, input_slot, output_slot)

	_setup_slots()

func _setup_slots() -> void:
	clear_all_slots()

	for index in _node_body_data.size():
		var data: Dictionary = _node_body_data[index]

		if data.type == BodyDataType.ROW:
			.set_slot(index + 1, false, TYPE_NIL, Color.transparent, false, TYPE_NIL, Color.transparent)

			continue

		var input_slot: Dictionary = {}
		var output_slot: Dictionary = {}
		var io_data = data.io_data if data.has('io_data') else {}

		if io_data.has('input'):
			input_slot = io_data.input

		if io_data.has('output'):
			output_slot = io_data.output

		var input_default_value = input_slot.default if input_slot.has('default') else null
		var input_slot_type: int = input_slot.type if input_slot.has('type') else 0
		var input_slot_enabled: bool = input_slot.has('type')

		var output_slot_type: int = output_slot.type if output_slot.has('type') else 0
		var output_slot_enabled: bool = output_slot.has('type')

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

func _on_offset_changed() -> void:
	emit_signal("node_updated")

func _on_remove_node() -> void:
	queue_free()
