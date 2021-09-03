tool
extends Node

enum Port {
	INPUT,
	OUTPUT
}

enum PortType {
	LABEL_ONLY,
	START,
	ANIMATION,
	ACTION
}

const PortColor = {
	PortType.LABEL_ONLY: Color.transparent,
	PortType.START: Color('#008484'),
	PortType.ANIMATION: Color('#008484'),
	PortType.ACTION: Color.green
}

# Title
const TITLE_BORDER_BOTTOM = Color(0.0, 0.0, 0.0, 0.8)
const TITLE_BORDER_WIDTH = 1.0
const TITLE_MARGIN_LEFT = 8.0
const TITLE_MARGIN_TOP = 4.0
const TITLE_BORDER_RADIUS = 8.0
const TITLE_MARGIN_BOTTOM = TITLE_MARGIN_TOP + TITLE_BORDER_WIDTH

# Frame
const FRAME_BG_COLOR = Color(0.101, 0.125, 0.172, 1.0)
const FRAME_BG_SELECTED_COLOR = FRAME_BG_COLOR
const FRAME_SHADOW_COLOR = Color(0, 0, 0, 0.1)
const FRAME_SHADOW_SELECTED_COLOR = Color.white
const FRAME_BODER_WIDTH = 0.0
const FRAME_SHADOW_SIZE = 8.0
const FRAME_CONTENT_MARGIN = 0.0
const FRAME_CONTENT_RADIUS = 8.0

const PORT_OFFSET = 0.0

# Row
const ROW_CONTENT_MARGIN_LEFT = 18.0
const ROW_CONTENT_MARGIN_RIGHT = 18.0
const ROW_SEPARATION = 1.0
const DISCONNECTED_LABEL_COLOR = Color(1.0, 1.0, 1.0, 0.5)
const CONNECTED_LABEL_COLOR = Color.white

func get_row(index: int, input_label_text: String, output_label_text: String, input_default_value = null) -> PanelContainer:
	var row_container = load("res://addons/anima/ui/anima_node_row_container.tscn")
	var row: PanelContainer = row_container.instance()

	row.set_name("Row" + str(index))
	row.add_stylebox_override('panel', generate_row_style())

	var input_label = row.find_node("Label1")
	input_label.set_name("Input" + str(index))
	input_label.set_text(input_label_text)

	var output_label = row.find_node("Label2")
	output_label.set_name("Output" + str(index))
	output_label.set_text(output_label_text)

	if input_default_value == null:
		row.hide_default_input_container()

	return row

func customise_node_style(node: GraphNode, title_node: PanelContainer, node_type: int) -> void:
	var node_color = PortColor[node_type] if PortColor.has(node_type) else Color.black
	var title_color = node_color

	apply_style_to_graph_node(node, node_color)
	apply_style_to_custom_title(title_node, title_color)

func apply_style_to_graph_node(node: GraphNode, node_color: Color) -> void:
	var frame_style = generate_frame_style(node_color)

	node.add_stylebox_override("frame", frame_style)

	# selected style
	var selected_style = generate_selected_frame_style(frame_style)
	node.add_stylebox_override("selectedframe", selected_style)

	# Port offset
	override_port_offset(node)

	# Space between rows
	override_row_separation(node)

func apply_style_to_custom_title(title_node: PanelContainer , node_color: Color) -> void:
	var title_style = generate_title_style(node_color)
	var selected_style = generate_title_selected_style(node_color)

	title_node.set_style(title_style, selected_style)

func generate_frame_style(border_color: Color) -> StyleBoxFlat:
	var scale: float = get_dpi_scale()
	var style = StyleBoxFlat.new()

	style.border_color = border_color
	style.set_border_width_all(FRAME_BODER_WIDTH)

	style.set_bg_color(FRAME_BG_COLOR)
	style.content_margin_left = FRAME_CONTENT_MARGIN;
	style.content_margin_right = FRAME_CONTENT_MARGIN;

	style.set_corner_radius_all(FRAME_CONTENT_RADIUS * scale)

	style.shadow_size = FRAME_SHADOW_SIZE * scale
	style.shadow_color = FRAME_SHADOW_COLOR

	return style
	
func generate_selected_frame_style(base_style: StyleBoxFlat):
	var style = base_style.duplicate()

	style.border_color = FRAME_BG_SELECTED_COLOR
	style.shadow_color = FRAME_SHADOW_SELECTED_COLOR
	style.shadow_size = FRAME_SHADOW_SIZE / 2

	return style

func generate_row_style() -> StyleBoxEmpty:
	var scale: float = get_dpi_scale()
	var style: StyleBoxEmpty = StyleBoxEmpty.new()

	style.content_margin_left = ROW_CONTENT_MARGIN_LEFT * scale;
	style.content_margin_right = ROW_CONTENT_MARGIN_RIGHT * scale;

	return style

func override_port_offset(node: GraphNode):
	node.add_constant_override("port_offset", PORT_OFFSET)

func override_row_separation(node: GraphNode):
	node.add_constant_override("separation", ROW_SEPARATION)

func generate_title_style(color: Color):
	var scale: float = get_dpi_scale()
	var style = StyleBoxFlat.new()

	style.border_color = color
	style.set_bg_color(color)

	style.content_margin_left = TITLE_MARGIN_LEFT * scale;
	style.content_margin_right = TITLE_MARGIN_LEFT * scale;
	style.content_margin_top = TITLE_MARGIN_TOP * scale;
	style.content_margin_bottom = TITLE_MARGIN_BOTTOM * scale;

	style.set_corner_radius(CORNER_TOP_LEFT, TITLE_BORDER_RADIUS * scale)
	style.set_corner_radius(CORNER_TOP_RIGHT, TITLE_BORDER_RADIUS * scale)

	style.set_border_width(MARGIN_BOTTOM, TITLE_BORDER_WIDTH)
	style.border_color = TITLE_BORDER_BOTTOM

	return style

func generate_title_selected_style(color: Color):
	var style = generate_title_style(color)

	style.border_color = color
	style.set_bg_color(color)

	style.border_color = FRAME_BG_SELECTED_COLOR

	return style

func generate_row_slot_panel_style():
	var scale: float = get_dpi_scale()
	var style = StyleBoxFlat.new()

	var color = Color.transparent
	style.border_color = color
	style.set_bg_color(color)

	return style

func get_dpi_scale() -> float:
	return 1.0
