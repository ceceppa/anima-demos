tool
extends AnimaAnimatedItem

func animate(value) -> void:
	print(value)
	_node[_property] = value
