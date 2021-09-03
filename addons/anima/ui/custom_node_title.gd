tool
extends PanelContainer

signal toggle_preview
signal rename_node
signal remove_node

func _on_TogglePreview_toggled(button_pressed):
	var icon = ImageTexture.new()
	var icon_visibility_hidden = 'res://addons/anima/icons/visibility_hidden.svg'
	var icon_visibility_visible = 'res://addons/anima/icons/visibility_visible.svg'
	var icon_to_use = icon_visibility_visible if button_pressed else icon_visibility_hidden

	$Container/TogglePreview.set_button_icon(load(icon_to_use))

	emit_signal("toggle_preview", button_pressed)

func _on_RenameButton_pressed():
	emit_signal("rename_node")

func _on_CloseButton_pressed():
	emit_signal("remove_node")

func show_preview_toggle() -> void:
	$Container/TogglePreview.set_visible(true)

func set_style(style: StyleBoxFlat, selected_style: StyleBoxFlat) -> void:
	add_stylebox_override("panel", style)
	add_stylebox_override("selectedframe", selected_style)

func set_title(title: String) -> void:
	$Container/Title.set_text(title)

func set_icon(icon_path: String) -> void:
	$Container/Icon.set_texture(load(icon_path))

func get_title() -> String:
	return $Container/Title.get_text()
