tool
extends Button

var _ignore_animation := false

func _on_Button_pressed():
	var position: Vector2 = self.rect_global_position
	var size: Vector2 = Vector2(self.rect_size.x, 100)

	$PopupPanel.popup(Rect2(Vector2(1000, 1000), size))
	
	_animate_panel()

func _animate_panel(backwards: bool = false) -> AnimaNode:
	var anima: AnimaNode = Anima.begin($PopupPanel)
	anima.set_single_shot(true)
	anima.set_default_duration(0.15)

	anima.then({
		property = "y",
		from = 40,
		to = self.rect_size.y,
	})
	anima.also({
		property = "opacity",
		from = 0.0,
		to = 1.0
	})

	anima.set_visibility_strategy(Anima.VISIBILITY.TRANSPARENT_ONLY)

	if backwards:
		anima.play_backwards_with_speed(1.5)
	else:
		anima.play()

	return anima

func _on_PopupPanel_popup_hide():
	return
#	$PopupPanel.show()
#
#	var anima := _animate_panel(true)
#
#	yield(anima, "animation_completed")
#
#	$PopupPanel.hide()
