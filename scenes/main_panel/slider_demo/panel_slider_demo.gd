@tool
extends Control
class_name FeedraPanel

signal oneshot_ended

@onready var fade_tint: Panel = %FadeTint
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

#@export var is_pad_small: bool = false
@export var pad_color: PadColors = PadColors.White
@export var is_loop_mode: bool = false
@export var pad_background_image: Texture2D
@export var volume_fade_time: float = 2
@export var pitch_random: float = 0
@export var label_text: String = ""
@export var audio_layers: Array[AudioStream]

@export_category("Internal")
@export var button_border: TextureRect
@export var background_image_layer: TextureRect
@export var background_image_container: Control
@export var loop_icon: TextureRect
@export var label: Label

var is_mouse_in: bool = false
var is_current_pad_controlled: bool = false
var is_transitioning: bool = false
var is_button_active: bool = false
var is_oneshot_playing: bool = false
var volume: float = 0
var activeness: float = 0
var volume_tween: Tween
var visuals_tween: Tween
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
	init_audio()


func _process(_delta: float) -> void:
	button_border.texture = pad_large_graphics[pad_color]
	if is_loop_mode: loop_icon.texture = pad_symbol_loop
	else: loop_icon.texture = pad_symbol_oneshot
	background_image_layer.texture = pad_background_image
	label.text = label_text
	background_image_layer.size = Vector2(190, 190)
	#background_image_container.position = position + Vector2(6, 6)
	if Engine.is_editor_hint(): return
	
	#label.text = str(snappedf(volume, .01)) # display volume in text
	fade_tint.size.x = remap(volume, 0, 1, 190, 0)
	fade_tint.position.x = remap(volume, 0, 1, 6, 196)
	audio_stream_player.volume_db = linear_to_db(volume)
	
	var activeness_scaled: float = remap(activeness, 0, 1, 0.4, 1)
	button_border.modulate = Color(activeness_scaled, activeness_scaled, activeness_scaled)
	
	#print(volume)
	is_button_active = volume > 0
	# LOOP
	if is_loop_mode:
		if Input.is_action_just_pressed("toggle_button") and is_mouse_in:
			#if is_transitioning: return
			if Input.is_action_pressed("control_button_volume"): return
			
			is_transitioning = true
			
			tween_volume()
			tween_visuals()
			
			await volume_tween.finished
			is_transitioning = false
		
		if Input.is_action_just_pressed("control_button_volume") and is_mouse_in:
			is_current_pad_controlled = true
		if Input.is_action_just_released("control_button_volume"):
			is_current_pad_controlled = false
		if Input.is_action_pressed("control_button_volume") and is_current_pad_controlled:
			if activeness == 0 and volume != 0:
				tween_visuals(1)
			if volume_tween and volume_tween.is_running(): volume_tween.kill()
			var volume_target = remap(clamp(get_global_mouse_position().x - global_position.x, 6, 196), 6, 196, 0, 1)
			#volume = lerpf(volume, volume_target, 0.02) # lerp volume (removed)
			volume = move_toward(volume, volume_target, 0.01)
		audio_stream_player.stream_paused = bool(!volume)
		
		if volume == 0 and activeness == 1:
			tween_visuals(0)
		
	# ONESHOT
	else:
		if Input.is_action_just_pressed("toggle_button") and is_mouse_in:
			if !is_oneshot_playing:
				play_oneshot()
			else:
				#is_oneshot_playing = false
				oneshot_ended.emit()


func tween_volume(override_is_button_active: int = -1) -> void:
	if volume_tween and volume_tween.is_running(): volume_tween.kill()
	volume_tween = create_tween()
	if (!is_button_active or override_is_button_active == 1) and override_is_button_active != 0:
		volume_tween.tween_property(self, "volume", 1, volume_fade_time)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	else:
		volume_tween.tween_property(self, "volume", 0, volume_fade_time)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func tween_visuals(override_is_button_active: int = -1) -> void:
	if visuals_tween and visuals_tween.is_running(): visuals_tween.kill()
	visuals_tween = create_tween()
	if (!is_button_active or override_is_button_active == 1) and override_is_button_active != 0:
		visuals_tween.tween_property(self, "activeness", 1, .4)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	else:
		visuals_tween.tween_property(self, "activeness", 0, .4)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func init_audio() -> void:
	audio_stream_player.play()
	audio_stream_player.stream_paused = true
	var player: AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	for layer in audio_layers:
		if layer == null: print("Null layer found!"); continue
		if !is_loop_mode: 	audio_stream_player.stream_paused = true
		player.play_stream(layer, randf_range(0, layer.get_length()))


func play_oneshot() -> void:
	is_oneshot_playing = true
	tween_visuals(1)
	tween_volume(1)
	
	audio_stream_player.pitch_scale = 1 + randf_range(-pitch_random / 2, pitch_random / 2)
	var player: AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	var track_lengths: Array[float]
	for layer in audio_layers: 
		player.play_stream(layer)
		track_lengths.append(layer.get_length())
	audio_stream_player.stream_paused = false
	await get_tree().create_timer(track_lengths.max()).timeout
	oneshot_ended.emit()
	is_oneshot_playing = false
	tween_visuals(0)
	tween_volume(0)


func _on_button_border_mouse_entered() -> void:
	if Engine.is_editor_hint(): return
	is_mouse_in = true


func _on_button_border_mouse_exited() -> void:
	if Engine.is_editor_hint(): return
	is_mouse_in = false
