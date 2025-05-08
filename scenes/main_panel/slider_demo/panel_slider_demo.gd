@tool
extends Control
class_name FeedraPanel

@onready var fade_tint: Panel = %FadeTint
@onready var audio: AudioStreamPlayer = %Audio

#@export var is_pad_small: bool = false
@export var pad_color: PadColors = PadColors.White
@export var is_loop_mode: bool = false
@export var pad_background_image: Texture2D
@export var volume_fade_time: float = 2
@export var label_text: String = ""

@export_category("Internal")
@export var button_border: TextureRect
@export var background_image_layer: TextureRect
@export var loop_icon: TextureRect
@export var label: Label

var is_mouse_in: bool = false
var is_current_pad_controlled: bool = false
var is_transitioning: bool = false
var is_button_active: bool = false
var volume: float = 0
var activeness: float = 0
var volume_tween: Tween
var active_tween: Tween
var border_tint: Color


enum PadColors {
	Blue,
	Green,
	LightBlue,
	Magenta,
	Orange,
	Purple,
	Red,
	Teal,
	White,
	Yellow
}

var pad_large_graphics: Dictionary[PadColors, CompressedTexture2D] = {
	PadColors.Blue: preload("res://assets/graphics/pad/PanelLargeBlue.svg"),
	PadColors.Green: preload("res://assets/graphics/pad/PanelLargeGreen.svg"),
	PadColors.LightBlue: preload("res://assets/graphics/pad/PanelLargeLightBlue.svg"),
	PadColors.Magenta: preload("res://assets/graphics/pad/PanelLargeMagenta.svg"),
	PadColors.Orange: preload("res://assets/graphics/pad/PanelLargeOrange.svg"),
	PadColors.Purple: preload("res://assets/graphics/pad/PanelLargePurple.svg"),
	PadColors.Red: preload("res://assets/graphics/pad/PanelLargeRed.svg"),
	PadColors.Teal: preload("res://assets/graphics/pad/PanelLargeTeal.svg"),
	PadColors.White: preload("res://assets/graphics/pad/PanelLargeWhite.svg"),
	PadColors.Yellow: preload("res://assets/graphics/pad/PanelLargeYellow.svg")
}

var pad_small_graphics: Dictionary[PadColors, CompressedTexture2D] = {
	PadColors.Blue: preload("res://assets/graphics/pad/PanelSmallBlue.svg"),
	PadColors.Green: preload("res://assets/graphics/pad/PanelSmallGreen.svg"),
	PadColors.LightBlue: preload("res://assets/graphics/pad/PanelSmallLightBlue.svg"),
	PadColors.Magenta: preload("res://assets/graphics/pad/PanelSmallMagenta.svg"),
	PadColors.Orange: preload("res://assets/graphics/pad/PanelSmallOrange.svg"),
	PadColors.Purple: preload("res://assets/graphics/pad/PanelSmallPurple.svg"),
	PadColors.Red: preload("res://assets/graphics/pad/PanelSmallRed.svg"),
	PadColors.Teal: preload("res://assets/graphics/pad/PanelSmallTeal.svg"),
	PadColors.White: preload("res://assets/graphics/pad/PanelSmallWhite.svg"),
	PadColors.Yellow: preload("res://assets/graphics/pad/PanelSmallYellow.svg")
}

var pad_symbol_loop: CompressedTexture2D = preload("res://assets/graphics/pad/PanelLargeSymbolLoop.svg")
var pad_symbol_oneshot: CompressedTexture2D = preload("res://assets/graphics/pad/PanelLargeSymbolOneshot.svg")


func _ready() -> void:
	if Engine.is_editor_hint(): return
	border_tint = button_border.modulate


func _process(delta: float) -> void:
	button_border.texture = pad_large_graphics[pad_color]
	if is_loop_mode: 
		loop_icon.texture = pad_symbol_loop
	else: 
		loop_icon.texture = pad_symbol_oneshot
	background_image_layer.texture = pad_background_image
	label.text = label_text
	if Engine.is_editor_hint(): return
	
	#label.text = str(snappedf(volume, .01))
	fade_tint.size.x = remap(volume, 0, 1, 190, 0)
	fade_tint.position.x = remap(volume, 0, 1, 6, 196)
	audio.volume_db = linear_to_db(volume)
	
	var activeness_scaled: float = remap(activeness, 0, 1, 0.4, 1)
	button_border.modulate = Color(activeness_scaled, activeness_scaled, activeness_scaled)
	
	#print(volume)
	is_button_active = volume > 0
	
	if Input.is_action_just_pressed("toggle_button") and is_mouse_in:
		#if is_transitioning: return
		if Input.is_action_pressed("control_button_volume"): return
		
		is_transitioning = true
		if volume_tween and volume_tween.is_running(): volume_tween.kill()
		volume_tween = create_tween()
		if active_tween and active_tween.is_running(): active_tween.kill()
		active_tween = create_tween()
		
		if !is_button_active:
			volume_tween.tween_property(self, "volume", 1, 2)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			active_tween.tween_property(self, "activeness", 1, .4)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		else:
			volume_tween.tween_property(self, "volume", 0, 2)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			active_tween.tween_property(self, "activeness", 0, .4)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		await volume_tween.finished
		is_transitioning = false
	
	if Input.is_action_just_pressed("control_button_volume") and is_mouse_in:
		is_current_pad_controlled = true
	if Input.is_action_just_released("control_button_volume"):
		is_current_pad_controlled = false
	if Input.is_action_pressed("control_button_volume") and is_current_pad_controlled:
		if volume_tween and volume_tween.is_running(): volume_tween.kill()
		#print(remap(clamp(get_global_mouse_position().x - position.x, 6, 196), 6, 196, 0, 1))
		var volume_target = remap(clamp(get_global_mouse_position().x - position.x, 6, 196), 6, 196, 0, 1)
		#volume = lerpf(volume, volume_target, 0.02)
		volume = move_toward(volume, volume_target, 0.01)
		


func _on_button_border_mouse_entered() -> void:
	if Engine.is_editor_hint(): return
	is_mouse_in = true


func _on_button_border_mouse_exited() -> void:
	if Engine.is_editor_hint(): return
	is_mouse_in = false
