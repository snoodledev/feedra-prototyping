extends Control
class_name FeedraLayerEditor

@onready var button_close: Control = %ButtonClose
@onready var layer_container: VBoxContainer = %LayerContainer

@export var layer_scene: PackedScene
@export var test_layers: Array[AudioStream]


func _ready() -> void:
	button_close.pressed.connect(on_button_close_pressed)


func init(audio_layers: Array[AudioStream], color: Global.PadColors) -> void:
	if !layer_container: return
	for child in layer_container.get_children():
		if child is FeedraLayer:
			child.queue_free()
	
	for layer in audio_layers:
		#if audio_layers.size() == 0: push_error("This pad has no layers!"); return
		var layer_instance: FeedraLayer = layer_scene.instantiate()
		layer_container.add_child(layer_instance)
		layer_instance.init(layer)


func close_editor() -> void:
	queue_free()


func on_button_close_pressed() -> void:
	close_editor()
