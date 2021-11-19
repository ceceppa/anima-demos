tool
extends PopupPanel

signal node_selected(node)

onready var _anima_nodes_list: VBoxContainer = find_node('AnimaNodesList')

var _anima_visual_node: AnimaVisualNode

func show() -> void:
	var anima: AnimaNode = Anima.begin(self)
	anima.then({ property = "scale", from = Vector2.ZERO, duration = 0.3, easing = Anima.EASING.EASE_OUT_BACK })
	anima.also({ property = "opacity", from = 0, to = 1 })
	anima.set_visibility_strategy(Anima.VISIBILITY.TRANSPARENT_ONLY)

	.show()

	_anima_nodes_list.populate(_anima_visual_node)

	anima.play()

func set_source_node(node: AnimaVisualNode) -> void:
	AnimaUI.debug(self, "set_source_node", node)

	_anima_visual_node = node

func _on_AnimaNodesList_node_selected(node: Node):
	emit_signal("node_selected", node)
