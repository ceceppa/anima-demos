extends Spatial

func _on_Button_pressed():
	var anima: AnimaNode = Anima.begin_single_shot(self)
	
	anima.then({ node = $MeshInstance, animation = "flash", duration = 1.0 })
	anima.also({ node = $MeshInstance2 })

	anima.play()
