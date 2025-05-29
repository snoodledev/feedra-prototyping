@tool
extends Control
class_name FeedraPanel

signal oneshot_ended

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var button_edit: Button = %ButtonEdit
@onready var layer_editor_container: MarginContainer = get_tree().get_first_node_in_group("LayerEditorContainer")

@export var pad_color: Global.PadColors = Global.PadColors.White
@export var is_small: bool = false
@export var is_loop_mode: bool = false
@export var pad_background_image: Texture2D
@export var volume_fade_time: float = 2
@export var pitch_random: float
@export var label_text: String = ""
@export var audio_layers: Array[AudioStream]
@export var randomise_loop_start: bool = true

@export_group("Internal")
@export var is_slider_vertical: bool = false
@export var layer_editor_scene: PackedScene
@export var button_border: TextureRect
@export var background_image: TextureRect
@export var background_flat_color: ColorRect
@export var background_image_container: Control
@export var loop_icon: TextureRect
@export var label: Label
@export var fade_tint: Panel
@export var fade_tint_constant: Panel
@export var image_border_cover: TextureRect
@export var divider_line: TextureRect

var is_mouse_in: bool = false
var is_current_pad_controlled: bool = false
var is_transitioning: bool = false
var is_button_active: bool = false
var is_oneshot_playing: bool = false
var volume: float = 0
var border_fade_value: float = 0
var volume_tween: Tween
var visuals_tween: Tween
var divider_tween: Tween
var snap_threshold_lower: float = .1
var snap_threshold_upper: float = .9

var border_tint: Color

var pad_cursor_offset: float
var pad_cursor_size: float
var pad_size: float

var time: float

var pad_large_graphics: Dictionary[Global.PadColors, CompressedTexture2D] = {
	Global.PadColors.Blue: preload("res://assets/graphics/pad/PanelLargeBlue.svg"),
	Global.PadColors.Green: preload("res://assets/graphics/pad/PanelLargeGreen.svg"),
	Global.PadColors.LightBlue: preload("res://assets/graphics/pad/PanelLargeLightBlue.svg"),
	Global.PadColors.Magenta: preload("res://assets/graphics/pad/PanelLargeMagenta.svg"),
	Global.PadColors.Orange: preload("res://assets/graphics/pad/PanelLargeOrange.svg"),
	Global.PadColors.Purple: preload("res://assets/graphics/pad/PanelLargePurple.svg"),
	Global.PadColors.Red: preload("res://assets/graphics/pad/PanelLargeRed.svg"),
	Global.PadColors.Teal: preload("res://assets/graphics/pad/PanelLargeTeal.svg"),
	Global.PadColors.White: preload("res://assets/graphics/pad/PanelLargeWhite.svg"),
	Global.PadColors.Yellow: preload("res://assets/graphics/pad/PanelLargeYellow.svg")
}

var pad_small_graphics: Dictionary[Global.PadColors, CompressedTexture2D] = {
	Global.PadColors.Blue: preload("res://assets/graphics/pad/PanelSmallBlue.svg"),
	Global.PadColors.Green: preload("res://assets/graphics/pad/PanelSmallGreen.svg"),
	Global.PadColors.LightBlue: preload("res://assets/graphics/pad/PanelSmallLightBlue.svg"),
	Global.PadColors.Magenta: preload("res://assets/graphics/pad/PanelSmallMagenta.svg"),
	Global.PadColors.Orange: preload("res://assets/graphics/pad/PanelSmallOrange.svg"),
	Global.PadColors.Purple: preload("res://assets/graphics/pad/PanelSmallPurple.svg"),
	Global.PadColors.Red: preload("res://assets/graphics/pad/PanelSmallRed.svg"),
	Global.PadColors.Teal: preload("res://assets/graphics/pad/PanelSmallTeal.svg"),
	Global.PadColors.White: preload("res://assets/graphics/pad/PanelSmallWhite.svg"),
	Global.PadColors.Yellow: preload("res://assets/graphics/pad/PanelSmallYellow.svg")
}

var pad_symbol_loop_large: CompressedTexture2D = preload("res://assets/graphics/pad/PanelLargeSymbolLoop.svg")
var pad_symbol_loop_small: CompressedTexture2D = preload("res://assets/graphics/pad/PanelSmallSymbolLoop.svg")
var pad_symbol_oneshot_large: CompressedTexture2D = preload("res://assets/graphics/pad/PanelLargeSymbolOneshot.svg")
var pad_symbol_oneshot_small: CompressedTexture2D = preload("res://assets/graphics/pad/PanelSmallSymbolOneshot.svg")


func _ready() -> void:
	if Engine.is_editor_hint(): return
	Global.edit_mode_changed.connect(on_edit_mode_changed)
	button_edit.pressed.connect(on_button_edit_pressed)
	toggle_edit_mode()
	toggle_divider_state(false, 0)
	
	border_tint = button_border.modulate
	init_audio()

# Cursor start and end pos
var c_start: float
var c_end: float

func _process(delta: float) -> void:
	background_image.texture = pad_background_image
	background_flat_color.color = get_border_color_approx(pad_color)
	background_flat_color.color *= 0.6
	label.text = label_text
	if is_small: set_size_small()
	else: set_size_large()
	if Engine.is_editor_hint(): return
	
	time += delta
	
	c_start = pad_cursor_offset
	c_end = pad_cursor_offset + pad_cursor_size
	# DEBUG: display volume in label
	#label.text = str(snappedf(volume, .01))
	
	if is_slider_vertical:
		fade_tint.size.y = remap(volume, 0, 1, pad_cursor_size, 0)
	else:
		fade_tint.size.x = remap(volume, 0, 1, pad_cursor_size, 0)
		fade_tint.position.x = remap(volume, 0, 1, c_start, c_end)
	
	audio_stream_player.volume_db = linear_to_db(volume)
	
	var border_fade_value_scaled: float = remap(border_fade_value, 0, 1, 0.4, 1)
	button_border.modulate = Color(border_fade_value_scaled, border_fade_value_scaled, border_fade_value_scaled)
	
	is_button_active = volume > 0
	
	if is_loop_mode:
		handle_loop()
	else:
		if Input.is_action_just_pressed("toggle_button") and is_mouse_in:
			if !is_oneshot_playing:
				play_oneshot()
			else:
				#is_oneshot_playing = false
				oneshot_ended.emit()
	
	var border_pulse_modulate: float = (sin(time * 3) * 0.5 + 0.5) * 2
	
	
	button_border.self_modulate = Color.WHITE + (Color(border_pulse_modulate, border_pulse_modulate, border_pulse_modulate) * 1) * border_fade_value
	divider_line.global_position.y = clamp(
		fade_tint.global_position.y + fade_tint.size.y - divider_line.size.y / 2, 
		fade_tint_constant.global_position.y,
		fade_tint_constant.global_position.y + fade_tint_constant.size.y - 4,
		)
	# if volume != 0: print(divider_line.global_position.y)


func handle_loop() -> void:
	if Input.is_action_just_pressed("toggle_button") and is_mouse_in:
		if Input.is_action_pressed("control_button_volume"): return
		
		is_transitioning = true
		
		tween_volume()
		tween_visuals()
		
		await volume_tween.finished
		is_transitioning = false
	
	if Input.is_action_just_pressed("control_button_volume") and is_mouse_in:
		is_current_pad_controlled = true
		toggle_divider_state(true)
	if Input.is_action_just_released("control_button_volume"):
		is_current_pad_controlled = false
		if !is_mouse_in:
			toggle_divider_state(false)
		if volume <= snap_threshold_lower:
			volume = 0
		elif volume >= snap_threshold_upper:
			volume = 1
	if Input.is_action_pressed("control_button_volume") and is_current_pad_controlled:
		if border_fade_value == 0 and volume != 0:
			tween_visuals(1)
		if volume_tween and volume_tween.is_running(): volume_tween.kill()
		var volume_target: float
		if is_slider_vertical:
			volume_target = remap(clamp(get_global_mouse_position().y - global_position.y, c_start, c_end), c_start, c_end, 1, 0)
		else:
			volume_target = remap(clamp(get_global_mouse_position().x - global_position.x, c_start, c_end), c_start, c_end, 0, 1)
		#volume = lerpf(volume, volume_target, 0.02) # lerp volume (removed)
		volume = move_toward(volume, volume_target, 0.01)
	audio_stream_player.stream_paused = bool(!volume)
	
	if volume == 0 and border_fade_value == 1:
		tween_visuals(0)


func play_oneshot() -> void:
	if audio_layers.size() == 0: push_error(self.name + " has no audio layers!"); return
	
	is_oneshot_playing = true
	tween_visuals(1)
	tween_volume(1)
	# fixes the double-playback bug
	audio_stream_player.stop()
	audio_stream_player.play()
	
	var player: AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	var track_lengths: Array[float]
	for layer in audio_layers: 
		if layer is AudioStreamRandomizer:
			var picked_layer: AudioStream = layer.get_stream(randi_range(0, layer.streams_count - 1))
			player.play_stream(picked_layer)
			track_lengths.append(picked_layer.get_length())
		else:
			player.play_stream(layer)
			track_lengths.append(layer.get_length())
	audio_stream_player.pitch_scale = 1 + randf_range(-pitch_random / 2, pitch_random / 2)
	audio_stream_player.stream_paused = false
	await get_tree().create_timer(track_lengths.max()).timeout
	oneshot_ended.emit()
	tween_visuals(0)
	tween_volume(0)
	is_oneshot_playing = false


func set_size_small() -> void:
	pad_size = 90
	pad_cursor_size = 90
	pad_cursor_offset = 0
	
	custom_minimum_size = Vector2.ONE * pad_size
	size = Vector2.ONE * pad_size
	button_border.texture = pad_small_graphics[pad_color]
	
	fade_tint.size = Vector2.ONE * pad_size
	fade_tint_constant.size = Vector2.ONE * pad_size
	loop_icon.size = Vector2(52, 56)
	button_border.size = Vector2.ONE * pad_size
	image_border_cover.scale = Vector2.ONE * 0.475
	
	background_image.size = Vector2.ONE * pad_size
	background_image.position = Vector2.ZERO
	background_flat_color.size = Vector2.ONE * pad_size
	background_flat_color.position = Vector2.ZERO
	background_image_container.size = Vector2.ONE * pad_size
	background_image_container.position = Vector2.ZERO
	
	fade_tint_constant.position = Vector2.ZERO
	fade_tint.position = Vector2.ZERO
	loop_icon.position = Vector2(16, 16)
	button_border.position = Vector2.ZERO
	label.position = Vector2(0, 0)
	label.size = Vector2(90, 90)
	label.set("theme_override_font_sizes/font_size", 18)
	
	divider_line.size.x = 78
	
	if is_loop_mode: 
		loop_icon.texture = pad_symbol_loop_small
	else: 
		loop_icon.texture = pad_symbol_oneshot_small


func set_size_large() -> void:
	pad_size = 190
	pad_cursor_size = 190
	pad_cursor_offset = 0
	
	custom_minimum_size = Vector2.ONE * pad_size
	size = Vector2.ONE * pad_size
	button_border.texture = pad_large_graphics[pad_color]
	
	fade_tint.size = Vector2.ONE * pad_size
	fade_tint_constant.size = Vector2.ONE * pad_size
	loop_icon.size = Vector2(105, 113)
	button_border.size = Vector2.ONE * pad_size
	image_border_cover.scale = Vector2.ONE
	
	background_image.size = Vector2.ONE * pad_size
	background_image.position = Vector2.ZERO
	background_flat_color.size = Vector2.ONE * pad_size
	background_flat_color.position = Vector2.ZERO
	background_image_container.size = Vector2.ONE * pad_size
	background_image_container.position = Vector2.ZERO

	fade_tint_constant.position = Vector2.ZERO
	fade_tint.position = Vector2.ZERO
	loop_icon.position = Vector2(42.5, 38.5)
	button_border.position = Vector2.ZERO
	label.position = Vector2.ZERO
	label.size = Vector2.ONE * 190
	label.set("theme_override_font_sizes/font_size", 22)
	
	divider_line.size.x = 178
	
	if is_loop_mode: 
		loop_icon.texture = pad_symbol_loop_large
	else: 
		loop_icon.texture = pad_symbol_oneshot_large


func tween_volume(override_is_button_active: int = -1) -> void:
	if volume_tween and volume_tween.is_running(): volume_tween.kill()
	volume_tween = create_tween()
	if (!is_button_active or override_is_button_active == 1) and override_is_button_active != 0:
		volume_tween.tween_property(self, "volume", 1, volume_fade_time)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	else:
		volume_tween.tween_property(self, "volume", 0, volume_fade_time)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func tween_visuals(override_is_button_active: int = -1, duration: float = .4) -> void:
	if visuals_tween and visuals_tween.is_running(): visuals_tween.kill()
	visuals_tween = create_tween()
	## In
	if (!is_button_active or override_is_button_active == 1) and override_is_button_active != 0:
		visuals_tween.tween_property(self, "border_fade_value", 1, duration)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	## Out
	else:
		visuals_tween.tween_property(self, "border_fade_value", 0, duration)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func init_audio() -> void:
	audio_stream_player.play()
	audio_stream_player.stream_paused = true
	var player: AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	for layer in audio_layers:
		if !layer: print("Null layer found!"); continue
		if !is_loop_mode: audio_stream_player.stream_paused = true
		if is_loop_mode and randomise_loop_start:
			player.play_stream(layer, randf_range(0, layer.get_length()))
		else:
			player.play_stream(layer)


func toggle_edit_mode() -> void:
	if Global.is_edit_mode:
		button_edit.show()
	else:
		button_edit.hide()


func toggle_divider_state(is_in: bool = true, duration: float = .4) -> void:
	if !is_loop_mode: 
		divider_line.modulate = Color.TRANSPARENT
		return
	if divider_tween and divider_tween.is_running(): divider_tween.kill()
	divider_tween = create_tween()
	divider_tween.tween_property(divider_line, "modulate", Color.WHITE * int(is_in), duration)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func open_layer_editor() -> void:
	if !layer_editor_scene: push_error("Layer Editor scene not assigned to Pad!"); return
	var layer_editor_instance: FeedraLayerEditor = layer_editor_scene.instantiate()
	layer_editor_container.add_child(layer_editor_instance)
	layer_editor_instance.init(audio_layers, pad_color)


func get_border_color_approx(color: Global.PadColors) -> Color:
	match color:
		Global.PadColors.Blue:	
			return Color.BLUE
		Global.PadColors.Green:	
			return Color.GREEN
		Global.PadColors.LightBlue:	
			return Color.LIGHT_BLUE
		Global.PadColors.Magenta:	
			return Color.MAGENTA
		Global.PadColors.Orange:	
			return Color.ORANGE
		Global.PadColors.Purple:	
			return Color.PURPLE
		Global.PadColors.Red:	
			return Color.RED
		Global.PadColors.Teal:	
			return Color.TEAL
		Global.PadColors.White:	
			return Color.WHITE
		Global.PadColors.Yellow:	
			return Color.YELLOW
		_: return Color.WHITE


func _on_button_border_mouse_entered() -> void:
	if Engine.is_editor_hint(): return
	is_mouse_in = true
	#if (volume >= 0.05 and volume <= 0.95):
	toggle_divider_state(true)


func _on_button_border_mouse_exited() -> void:
	if Engine.is_editor_hint(): return
	is_mouse_in = false
	if !Input.is_action_pressed("control_button_volume"):
		toggle_divider_state(false)


func on_edit_mode_changed() -> void:
	toggle_edit_mode()


func on_button_edit_pressed() -> void:
	open_layer_editor()
