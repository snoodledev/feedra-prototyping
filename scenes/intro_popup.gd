extends Control


func _ready() -> void:
	%AnimationPlayer.play("in")


func _on_button_pressed() -> void:
	%AnimationPlayer.play("out")
