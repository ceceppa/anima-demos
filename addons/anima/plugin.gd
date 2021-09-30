tool
extends EditorPlugin

enum EditorPosition { 
	BOTTOM,
	RIGHT
}

var _anima_editor: Control
var _anima_node: AnimaNode
var _current_position = EditorPosition.BOTTOM

func get_name():
	return 'Anima'

func _enter_tree():
	add_autoload_singleton("Anima", 'res://addons/anima/core/anima.gd')
	add_autoload_singleton("AnimaUI", 'res://addons/anima/ui/anima_ui.gd')

	_anima_editor = preload("res://addons/anima/ui/anima_editor.tscn").instance()
	_anima_editor.connect("switch_position", self, "_on_anima_editor_switch_position")
	_anima_editor.connect("connections_updated", self, '_on_connections_updated')

	add_control_to_bottom_panel(_anima_editor, "Anima")

func _exit_tree():
	remove_autoload_singleton('Anima')
	remove_control_from_bottom_panel(_anima_editor)

	if _anima_editor:
		_anima_editor.queue_free()

func handles(object):
	var is_anima_node = object is AnimaNode

	if is_anima_node:
		_anima_editor.set_source_node(object)
	else:
		_anima_editor.set_source_node(null)

	return is_anima_node

func edit(object):
	print('editing anima node', object)
	_anima_node = object
	_anima_editor.edit(object)

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

func _on_connections_updated(data: Dictionary) -> void:
	var current_data: Dictionary = _anima_node.__anima_visual_editor_data
	var undo_redo = get_undo_redo() # Method of EditorPlugin.

	undo_redo.create_action('Updated AnimaNode')
#	undo_redo.add_do_method(self, "_do_update_anima_node")
#	undo_redo.add_undo_method(self, "_do_update_anima_node")
	undo_redo.add_do_property(_anima_node, "__anima_visual_editor_data", data)
	undo_redo.add_undo_property(_anima_node, "__anima_visual_editor_data", current_data)
	undo_redo.commit_action()

