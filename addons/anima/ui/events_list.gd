tool
extends WindowDialog

signal event_selected(name)

var _signals_to_ignore := ['visibility_changed']
var _signals := []

func populate_events_list_for_node(node: AnimaNode, events_added: Array) -> void:
	var source_node = node.get_source_node()

	_signals.clear()

	for sig in source_node.get_signal_list():
		var signal_name = sig.name

		if _signals_to_ignore.find(signal_name) >= 0:
			continue

		_signals.push_back(signal_name)

	_signals.append('visibility_visible')
	_signals.append('visibility_hidden')

	_signals.sort()

	for signal_name in _signals:
		$MarginContainer/ItemList.add_item(signal_name)

		if events_added.find(signal_name) > 0:
			var index: int = $MarginContainer/ItemList.get_item_count() - 1

			$MarginContainer/ItemList.set_item_disabled(index)

func _on_ItemList_item_activated(index):
	emit_signal("event_selected", _signals[index])

	hide()
