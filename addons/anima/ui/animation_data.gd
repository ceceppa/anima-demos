tool
extends VBoxContainer

signal select_property
signal select_animation

func _ready():
	$GridContainer/AnimationTypeButton.add_item("Animation")
	$GridContainer/AnimationTypeButton.add_item("Property")
	
	$GridContainer/AnimationTypeButton.selected = 0

	_on_OptionButton_item_selected(0)

func _on_OptionButton_item_selected(index):
	var animation_container_visible = index == 0

	$AnimationContainer.visible = animation_container_visible
	$PropertyContainer.visible = not animation_container_visible

func _on_PropertyButton_pressed():
	emit_signal("select_property")

func _on_AnimationButton_pressed():
	emit_signal("select_animation")
