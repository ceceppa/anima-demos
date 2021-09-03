tool
extends "./_anima_node.gd"

signal generate_full_shader

func _init():
	register_node({
		category = 'Sciamano',
		name = 'Anima',
		icon = 'res://addons/anima/icons/sciamano.svg',
		type = AnimaUI.PortType.START,
		editable = false
	})

func setup():
	add_output_slot("Animation", AnimaUI.PortType.START)
	add_output_slot("Animation", AnimaUI.PortType.ACTION)
	add_output_slot("Animation", AnimaUI.PortType.ANIMATION)

func is_shader_output() -> bool:
	return true

func generate_shader_output_code(inputs: Array) -> String:
	var mapped_shader_names = [
		'ALBEDO',
		'ALPHA',
		'METALLIC',
		'ROUGHNESS',
		'SPECULAR',
		'EMISSION',
		'AO',
		'AO_LIGHT_AFFECT',
		'NORMAL',
		'NORMALMAP',
		'NORMALMAP_DEPTH',
		'RIM',
		'RIM_TINT',
		'CLEARCOAT',
		'CLEARCOAT_GLOSS',
		'ANISOTROPY',
		'ANISOTROPY_FLOW',
		'SSS_STRENGTH',
		'TRANSMISSION',
		'ALPHA_SCISSOR'
	]

	var output = []
	for index in range(0, inputs.size()):
		var input = inputs[index]

		if input != null:
			var code = "{shader_output} = {input_variable_name};"

			output.push_back(code.format({
				'shader_output': mapped_shader_names[index],
				'input_variable_name': input
			}))

	return PoolStringArray(output).join('\n');

func input_connected(slot: int, from: Node, from_port: int) -> void:
	.input_connected(slot, from, from_port)

	emit_signal('generate_full_shader')
