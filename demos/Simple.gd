extends Control

var _anima: AnimaNode

func _ready() -> void:
	_anima = Anima.begin($icon)
	_anima.group(
		[
			{ node = $icon },
			{ group = $Node }
		],
		{
			animation = "fadeInUp",
			items_delay = 0.1,
			duration = 0.3,
			on_started = [funcref(self, '_test'), ['started normal'], ['completed backwards']] ,
			on_completed = [funcref(self, '_test'), ['completed normal'], ['started backwards']] 
		}
	)
#	_anima.then({ property = "x", from = -100.0, relative = true, duration = 0.3, on_started = [funcref(self, '_test'), [false], [true]] })
	_anima.set_visibility_strategy(Anima.VISIBILITY.TRANSPARENT_ONLY)

#	$Tween.interpolate_property($icon, "position", Vector2.ZERO, Vector2(100, 100), 0.3);

func _on_Button_pressed():
	_anima.play()

func _on_Button2_pressed():
	_anima.play_backwards()

func _on_Button3_pressed():
	$icon.modulate.a = 1.0

	_anima.clear()

	_anima.then({ property = "x", from = 300.0, to = 500, duration = 0.3 })
	_anima.loop_in_circle()

func _on_Button4_pressed():
	$Tween.resume_all()

func _on_Tween_tween_completed(object, key):
	$Tween.stop_all()

func _test(a) -> void:
	printt('a', a)
