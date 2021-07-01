extends Control

func _ready():
	Anima.register_animation(self, 'fade_letters_in')
	Anima.register_animation(self, 'fade_with')

	var anima := Anima.begin(self)

	anima.then({ group = $AnimaSquare/Text/Can, animation = 'fade_letters_in', duration = 0.3, items_delay = 0.01, easing = Anima.EASING.EASE_OUT_BACK })
	anima.then({ node = $AnimaSquare/Text/With, animation = 'fade_with', duration = 0.3, delay = -0.1, easing = Anima.EASING.EASE_IN_CUBIC })
	anima.set_visibility_strategy(Anima.VISIBILITY.TRANSPARENT_ONLY)

	anima.play_with_delay(1.0)

func fade_letters_in(anima_tween: AnimaTween, data: Dictionary) -> void:
	var frames := [
		{ from = 50, to = 0 }
	]
	var opacity := [
		{ from = 0, to = 1 }
	]

	anima_tween.add_frames(data, '_text_offset:y', frames)
	anima_tween.add_frames(data, 'opacity', opacity)

func fade_with(anima_tween: AnimaTween, data: Dictionary) -> void:
	var frames := [
		{ from = $AnimaSquare/Text/With.rect_size.y, to = 0 }
	]

	anima_tween.add_frames(data, '_text_offset:y', frames)
