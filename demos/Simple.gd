extends Control

var _anima: AnimaNode

func _ready() -> void:
	_anima = Anima.begin($icon)
	_anima.then({ property = "x", from = -100.0, relative = true, duration = 0.3 })

func _on_Button_pressed():
	_anima.play()

func _on_Button2_pressed():
	_anima.play_backwards()

func _on_Button3_pressed():
	_anima.loop_in_circle_with_speed(1.0)
