tool
extends EditorPlugin

enum EditorPosition { 
	BOTTOM,
	RIGHT
}

var _anima_editor: Control
var _current_position = EditorPosition.BOTTOM

func get_name():
	return 'Anima'

func _enter_tree():
	add_autoload_singleton("Anima", 'res://addons/anima/core/anima.gd')
	add_autoload_singleton("AnimaUI", 'res://addons/anima/ui/anima_ui.gd')

	_anima_editor = preload("res://addons/anima/ui/anima_editor.tscn").instance()
#	_anima_editor.set_custom_minimum_size(Vector2(0, 300))
	_anima_editor.connect("switch_position", self, "_on_anima_editor_switch_position")

	add_control_to_bottom_panel(_anima_editor, "Anima")

func _exit_tree():
	remove_autoload_singleton('Anima')
	remove_control_from_bottom_panel(_anima_editor)

	if _anima_editor:
		_anima_editor.queue_free()

func _on_anima_editor_switch_position() -> void:
	if _current_position == EditorPosition.BOTTOM:
		remove_control_from_bottom_panel(_anima_editor)
		add_control_to_container(
			EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, 
			_anima_editor
		)
		_current_position = EditorPosition.RIGHT
	else:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, _anima_editor)
		add_control_to_bottom_panel(_anima_editor, "Anima")
		_current_position = EditorPosition.BOTTOM

	_anima_editor.show()

