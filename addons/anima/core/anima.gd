tool

extends Node

func begin(node, name: String = 'anima') -> AnimaNode:
	var node_name = 'AnimaNode_' + name
	var anima_node: AnimaNode

	for child in node.get_children():
		if child.name.find(node_name) >= 0:
			anima_node = child
			anima_node.clear()
			anima_node.stop()

			return anima_node

	if anima_node == null:
		anima_node = AnimaNode.new()
		anima_node.name = node_name

		anima_node._init_node(node)

	return anima_node

func player(node: Node) -> AnimaPlayer:
	var player = AnimaPlayer.new()

	node.add_child(player)

	return player

func register_animation(script, animation_name: String) -> void:
	AnimaConstants._register_animation(script, animation_name)

func _deregister_animation(animation_name: String) -> void:
	AnimaConstants._deregister_animation(animation_name)
