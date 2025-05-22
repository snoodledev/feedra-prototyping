extends Control

const MODE_BUTTON_EDIT = preload("res://assets/graphics/interface/ModeButtonEdit.svg")
const MODE_BUTTON_PLAY = preload("res://assets/graphics/interface/ModeButtonPlay.svg")

@onready var button_edit: Button = %ButtonEdit
@onready var master_volume_control: HSlider = $MasterVolumeControl

func _ready() -> void:
	button_edit.pressed.connect(on_button_edit_pressed)
	master_volume_control.value_changed.connect(on_master_volume_changed)
	master_volume_control.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Playback"))


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


func set_master_volume(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Playback"), value)
	master_volume_control.value = value



func on_button_edit_pressed() -> void:
	toggle_edit_mode()


func on_master_volume_changed(value: float) -> void:
	set_master_volume(value)
