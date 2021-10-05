tool
extends PanelContainer

signal toggle_preview
signal rename_node
signal remove_node

func _on_TogglePreview_toggled(button_pressed):
	emit_signal("toggle_preview", button_pressed)

func _on_RenameButton_pressed():
	emit_signal("rename_node")

func hide_play_button() -> void:
	$Container/PlayButton.set_visible(false)

func set_style(style: StyleBoxFlat, selected_style: StyleBoxFlat) -> void:
	add_stylebox_override("panel", style)
	add_stylebox_override("selectedframe", selected_style)

func set_title(title: String) -> void:
	$Container/Title.set_text(title)

func set_icon(icon) -> void:
	if icon is String:
		$Container/Icon.set_texture(load(icon))
	else:
		$Container/Icon.set_texture(icon)

func hide_close_button() -> void:
	$Container/CloseButton.set_visible(false)

func get_title() -> String:
	return $Container/Title.get_text()

func _on_RemoveButton_pressed():
	emit_signal("remove_node")
