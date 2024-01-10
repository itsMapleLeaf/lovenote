@tool
class_name BetterPopupMenu
extends PopupMenu

var _items: Array[Item] = []
var _next_id := 0

func _ready() -> void:
	id_pressed.connect(_on_id_pressed)

func _on_id_pressed(id: int) -> void:
	var item := _items[id]
	if item._action:
		item._action.call()

func reset() -> void:
	for index in item_count:
		remove_item(0)
	for child in get_children():
		child.queue_free()
	_items = []
	_next_id = 0

func add(label: String, action: Callable) -> void:
	var item := Item.new()
	item._label = label
	item._action = action
	add_item(label, _next_id)
	_items.append(item)
	_next_id += 1

func add_submenu(label: String) -> BetterPopupMenu:
	var submenu := BetterPopupMenu.new()
	add_child(submenu)
	add_submenu_item(label, submenu.name)
	submenu.title = label
	return submenu

class Item:
	var _label: String
	var _action: Callable
