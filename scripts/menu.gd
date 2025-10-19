extends Control

func _ready():
	$StartButton.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene("#")


func _on_options_button_pressed() -> void:
	var options = load("#").instance()
	get_tree().current_scene.add_child(options)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
