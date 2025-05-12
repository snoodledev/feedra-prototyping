extends Control

@onready var menu_button: MenuButton = %MenuButton
@onready var button_icon: TextureRect = %ButtonIcon

@export var scenes: Dictionary[String, PackedScene]
@export var scene_container: Control

var menu: PopupMenu
var current_scene_instance: Control

func _ready() -> void:
	menu = menu_button.get_popup()
	menu.id_pressed.connect(on_id_pressed)
	menu_button.toggled.connect(on_toggled)
	
	menu.clear()
	for scene in scenes:
		menu.add_item(scene)
	
	#switch_scene("Example 1: Sci Fi")
	switch_scene("Example 1: Fantasy")


func switch_scene(id: String) -> void:
	if !scenes.has(id): push_error(self.name + ": Scene with specified id not found!"); return
	menu_button.text = id
	
	if current_scene_instance: current_scene_instance.queue_free()
	current_scene_instance = scenes[id].instantiate()
	scene_container.add_child(current_scene_instance)
	current_scene_instance.global_position = scene_container.global_position

func on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		button_icon.flip_v = true
	else:
		button_icon.flip_v = false


func on_id_pressed(id: int) -> void:
	switch_scene(menu.get_item_text(id))
