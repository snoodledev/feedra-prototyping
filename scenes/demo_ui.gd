extends Control

const MODE_BUTTON_EDIT = preload("res://assets/graphics/interface/ModeButtonEdit.svg")
const MODE_BUTTON_PLAY = preload("res://assets/graphics/interface/ModeButtonPlay.svg")

@onready var button_edit: Button = %ButtonEdit

func _ready() -> void:
	button_edit.pressed.connect(on_button_edit_pressed)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_toggle_edit_mode"):
		toggle_edit_mode()


func toggle_edit_mode() -> void:
	Global.is_edit_mode = !Global.is_edit_mode
	print("Edit Mode: " + str(Global.is_edit_mode))
	Global.edit_mode_changed.emit()
	if Global.is_edit_mode:
		button_edit.icon = MODE_BUTTON_EDIT
	else:
		button_edit.icon = MODE_BUTTON_PLAY


func on_button_edit_pressed() -> void:
	toggle_edit_mode()
