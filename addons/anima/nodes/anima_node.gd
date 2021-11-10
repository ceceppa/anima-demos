tool
extends "./_base_node.gd"

const ANIMATION_NAME_ROW = preload('res://addons/anima/ui/AnimationNameRow.tscn')
const EVENT_NAME_ROW = preload('res://addons/anima/ui/AnimaEventNameRow.tscn')

var _add_animation_button: Button
var _add_event_button: Button
var _animations_slots := []
var _events_slots := []
var _events_list_popup: WindowDialog
var _source_node: Node
var _animation_index: int

func _init():
	register_node({
		category = 'Anima',
		id = 'AnimaNode',
		name = 'AnimaNode',
		icon = 'res://addons/anima/icons/anima.svg',
		type = AnimaUI.NODE_TYPE.START,
		playable = false,
		deletable = false
	})

func set_source_node(node: Node) -> void:
	_source_node = node

func setup():
	_init_add_buttons()

	if _animations_slots.size() == 0:
		_animations_slots.push_back('default')

	for index in _animations_slots.size():
		var name = _animations_slots[index]

		add_custom_output_slot(_create_animation_row(name, index > 0), name, AnimaUI.PORT_TYPE.ANIMATION)

	add_custom_row(_add_animation_button)
	add_divider()
	add_label('On Event', 'Let Anima play the specified animation when an event occours')

	_events_list_popup = preload('res://addons/anima/ui/AnimaEventsList.tscn').instance()
	_events_list_popup.connect("event_selected", self, "_on_event_selected")
	add_child(_events_list_popup)

	for index in _events_slots.size():
		add_custom_output_slot(_create_event_name_row(_events_slots[index], index), _events_slots[index], AnimaUI.PORT_TYPE.EVENT)

	add_custom_row(_add_event_button)

func is_shader_output() -> bool:
	return true

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)

func get_animations_slots() -> Array:
	return _animations_slots

func get_events_slots() -> Array:
	return _events_slots

func set_animations_slots(animations: Array) -> void:
	_animations_slots = animations

func set_events_slots(events: Array) -> void:
	_events_slots = events

func get_data() -> Dictionary:
	return {}

func _create_animation_row(default_name: String, can_be_deleted := true) -> Node:
	var index = _animations_slots.size() - 1
	var row = ANIMATION_NAME_ROW.instance()

	row.set_default_name(default_name)
	row.connect("delete_animation", self, "_on_animation_deleted", [index])
	row.connect("play_animation", self, "_on_play_animation_by_index", [index])

	if not can_be_deleted:
		row.disable_delete_button()
		row.set_tooltip("This is the default animation that will be played when using any .play*() functions without specifying the animation name")

	return row

func _create_event_name_row(label: String, index: int) -> Node:
	var row = EVENT_NAME_ROW.instance()

	row.set_label(label)
	row.connect("delete_event", self, "_on_event_deleted", [index])

	return row

func _init_add_buttons():
	_add_animation_button = Button.new()
	_add_animation_button.text = "Add new animation"

	_add_animation_button.connect("pressed", self, "_on_add_new_animation_pressed")

	_add_event_button = Button.new()
	_add_event_button.text = "Add event"

	_add_event_button.connect("pressed", self, "_on_add_new_event_pressed")

func _on_add_new_animation_pressed() -> void:
	var name = "New animation " + str(_animations_slots.size() + 1)
	var button_index = _add_animation_button.get_position_in_parent()
	var previous = get_child(button_index - 1)
	var node = _create_animation_row(name)

	_animations_slots.push_back(name)

	add_child_below_node(previous, node)

	_node_body_data.insert(_animations_slots.size() - 1, {type = BodyDataType.OUTPUT_SLOT, node = node, data = [name, '', true, AnimaUI.PORT_TYPE.ANIMATION]})

	_setup_slots()

	emit_signal("node_updated")

func _on_add_new_event_pressed() -> void:
	_events_list_popup.populate_events_list_for_node(_source_node, _events_slots)
	_events_list_popup.popup_centered()

func _on_event_selected(name: String) -> void:
	var button_index = _add_event_button.get_position_in_parent()
	var previous = get_child(button_index - 1)
	var index = _events_slots.size()

	_events_slots.push_back(name)

	var node = _create_event_name_row(_events_slots[index], index)
	add_child_below_node(previous, node)

	_node_body_data.insert(_node_body_data.size() - 1, {type = BodyDataType.OUTPUT_SLOT, node = node, data = [name, '', true, AnimaUI.PORT_TYPE.EVENT]})

	_setup_slots()

	emit_signal("node_updated")

func _on_animation_deleted(index: int) -> void:
	printt('remove animation index', index)
	_animations_slots.remove(index)

	_setup_slots()

	emit_signal("node_updated")

func _on_event_deleted(index: int) -> void:
	_events_slots.remove(index)

	_setup_slots()

	emit_signal("node_updated")

func _on_play_animation_by_index(index: int) -> void:
	_animation_index = index

	_on_play_animation()
