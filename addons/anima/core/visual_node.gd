tool
class_name AnimaVisualNode
extends Node

export (Dictionary) var __anima_visual_editor_data

#
# Returns the node that Anima will use when handling the animations
# done via visual editor
#
func get_source_node() -> Node:
	var parent = self.get_parent()

	if parent == null:
		return self

	return parent

func generate_from_visual_data(node: Node, visual_data: Dictionary) -> void:
	var anima: AnimaNode = Anima.begin(node)
	anima.set_single_shot(true)

	var data = {
		node = node,
		duration = visual_data.duration,
		delay = visual_data.delay
	}

	var is_first := true

	for animation in visual_data.animations:
		if animation.type == AnimaUI.VISUAL_ANIMATION_TYPE.ANIMATION:
			data.animation = animation.animation.name

		if is_first:
			anima.then(data)
		else:
			anima.also(data)

		is_first = false
