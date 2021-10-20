extends Control

func _ready():
	var anima: AnimaNode = Anima.begin(self)
	anima.then({ node = $icon, property = "opacity", from = 0.0, to = 1.0, duration = 1.0 })
	anima.also({ property = "x", to = 100.0, relative = true, easing = Anima.EASING.EASE_OUT_BACK })

	anima.play_with_delay(0.5)
