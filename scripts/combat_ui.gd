extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var encounter_text: Label = $EncounterText

var encounter_fade_speed: float = 2.0
var encounter_alpha: float = 0.0
var encounter_visible: bool = false
var blink_timer: float = 0.0
var blink_speed: float = 5.0

func _ready() -> void:
	if encounter_text:
		encounter_text.modulate.a = 0.0
	print("🧠 Combat UI initialized.")

# Update HP bar externally
func set_hp(value: float):
	if hp_bar:
		hp_bar.value = clamp(value, 0, 100)

# Trigger encounter text fade
func show_encounter(show: bool):
	encounter_visible = show
	if show:
		blink_timer = 0.0

func _process(delta: float) -> void:
	# Fade-in/out encounter message
	if not encounter_text:
		return

	var target_alpha = 1.0 if encounter_visible else 0.0
	encounter_alpha = lerp(encounter_alpha, target_alpha, delta * encounter_fade_speed)
	encounter_text.modulate.a = encounter_alpha

	# Simple sci-fi blinking while visible
	if encounter_visible and encounter_alpha > 0.8:
		blink_timer += delta * blink_speed
		var pulse = 0.5 + sin(blink_timer) * 0.5
		encounter_text.scale = Vector2(1.0 + 0.05 * pulse, 1.0 + 0.05 * pulse)
	else:
		encounter_text.scale = Vector2.ONE
