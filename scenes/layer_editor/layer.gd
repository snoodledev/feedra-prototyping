extends Control
class_name FeedraLayer

const BACKGROUND_COLLAPSED = preload("res://assets/graphics/LayerEditor/TempLayerCollapsed.svg")
const BACKGROUND_EXPANDED = preload("res://assets/graphics/LayerEditor/TempLayerExpanded.svg")

@onready var background: TextureRect = %Background
@onready var audio_preview: AudioStreamPlayer = %AudioPreview
@onready var layer_name: TextEdit = %LayerName
@onready var button_collapse: Control = %ButtonCollapse
@onready var button_play: Button = %ButtonPlay

@export var is_expanded: bool = false

var is_audio_preview_playing: bool = false



func _ready() -> void:
	button_collapse.pressed.connect(on_button_collapse_pressed)
	button_play.pressed.connect(on_button_play_pressed)
	change_expanded_state(false)


func init(layer: AudioStream) -> void:
	audio_preview.stream = layer
	var filename: String = layer.resource_path.get_file().get_slice(".", 0)
	layer_name.text = ""
	layer_name.placeholder_text = filename


func _process(_delta: float) -> void:
	# for some reason this takes an extra frame to update. hacky fix lol
	if custom_minimum_size != background.size:
		custom_minimum_size = background.size


func change_expanded_state(expand: bool) -> void:
	if expand:
		background.texture = BACKGROUND_EXPANDED
		button_play.show()
	else:
		background.texture = BACKGROUND_COLLAPSED
		button_play.hide()
	is_expanded = expand


func change_play_state(play: bool) -> void:
	if !audio_preview.stream: push_warning("No audio stream assigned!"); return
	if play:
		audio_preview.play()
		button_play.icon = Global.ICON_PAUSE_24
		is_audio_preview_playing = true
	else:
		audio_preview.stop()
		button_play.icon = Global.ICON_PLAY_24
		is_audio_preview_playing = false


func on_button_collapse_pressed() -> void:
	change_expanded_state(!is_expanded)

func on_button_play_pressed() -> void:
	change_play_state(!is_audio_preview_playing)
