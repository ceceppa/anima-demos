tool
extends WindowDialog

signal animation_selected(name)

onready var _list_container = find_node('ListContainer')
onready var _confirm_button = find_node('ConfirmButton')

var _animation_name: String

func _ready():
	_setup_list()

func _setup_list() -> void:
	var animations = Anima.get_available_animations()
	var base = Anima.BASE_PATH
	var old_category := ''
	var group = ButtonGroup.new()

	for item in animations:
		var category_and_file = item.replace(base, '').split('/')
		var category = category_and_file[0]
		var file_and_extension = category_and_file[1].split('.')
		var file = file_and_extension[0]

		if category != old_category:
			var header = create_new_header(category)
			_list_container.add_child(header)

		var button := Button.new()
		button.set_text(file.replace('_', ' ').capitalize())
		button.set_text_align(Button.ALIGN_LEFT)
		button.set_meta('script', file)
		button.toggle_mode = true
		button.group = group
		button.add_font_override("font", _confirm_button.get_font("font"))
		button.connect("pressed", self, '_on_animation_button_pressed', [button])

		_list_container.add_child(button)
		old_category = category

func create_new_header(text: String) -> PanelContainer:
	var container := PanelContainer.new()
	var label := Label.new()

	label.set_text(text.replace('_', ' ').capitalize())
	container.add_child(label)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color('#404553')
	style.content_margin_top = 12
	style.content_margin_left = 8
	style.content_margin_bottom = 12
	style.content_margin_right = 8

	container.add_stylebox_override('panel', style)

	return container

func _on_animation_button_pressed(button: Button) -> void:
	var script_name: String = button.get_meta('script')

	var duration = 0.5

	_play_animation($HBoxContainer/VBoxContainer/ControlContainer/ControlTest, button)
	_play_animation($HBoxContainer/VBoxContainer/SpriteContainer/Control2/SpriteTest, button)

	_animation_name = script_name

func _play_animation(node: Node, button: Button):
	var script_name: String = button.get_meta('script')

	var duration = float(0.5)
	var parent = node.get_parent()
	var clone = node.duplicate()

	_remove_duplicate(parent, node)

	parent.add_child(clone)
	clone.show()
	node.hide()

	var anima = Anima.begin(clone, 'control_test')
	anima.then({ node = clone, animation = script_name, duration = duration })
	anima.play()
	
	yield(anima, "animation_completed")

	if $Timer.is_stopped():
		$Timer.start()

func _remove_duplicate(parent: Node, node_to_ignore: Node) -> void:
	for child in parent.get_children():
		if child != node_to_ignore:
			child.queue_free()

func _on_control_animation_completed(animation_player: AnimationPlayer) -> void:
	print(animation_player)

func generate_animation(anima_tween: AnimaTween, data: Dictionary) -> void:
	anima_tween.add_animation_data(data)
	return

func _on_Timer_timeout():
	var control := $HBoxContainer/VBoxContainer/ControlContainer/ControlTest
	var sprite := $HBoxContainer/VBoxContainer/SpriteContainer/Control2/SpriteTest
	
	_remove_duplicate(control.get_parent(), control)
	_remove_duplicate(sprite.get_parent(), sprite)
	
	sprite.show()
	control.show()

func _on_CancelButton_pressed():
	hide()

func _on_ConfirmButton_pressed():
	emit_signal("animation_selected", _animation_name)
