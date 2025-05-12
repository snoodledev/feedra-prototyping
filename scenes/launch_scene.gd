extends Control

var main_scene_path: String = "res://scenes/demo_ui.tscn"


func _ready() -> void:
	ResourceLoader.load_threaded_request(main_scene_path)


func _process(_delta: float) -> void:
	var progress: Array
	ResourceLoader.load_threaded_get_status(main_scene_path, progress)
	%ProgressBar.value = progress[0]
	
	if progress[0] == 1.0:
		var loaded_scene: PackedScene = ResourceLoader.load_threaded_get(main_scene_path)
		get_tree().change_scene_to_packed(loaded_scene)
