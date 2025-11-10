extends Control

@onready var start_button: Button = $StartButton

func _ready() -> void:
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	# Load your main scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_options_button_pressed() -> void:
	# Replace this with your actual options scene path later
	var options_scene_path = "res://scenes/ui/options_menu.tscn"
	if ResourceLoader.exists(options_scene_path):
		var options = load(options_scene_path).instantiate()
		add_child(options)
	else:
		print("⚠️ Options menu scene not found:", options_scene_path)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
