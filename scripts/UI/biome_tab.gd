extends HBoxContainer

@onready var elevation_min_spin_box = $NoiseRanges/ElevationTab/ElevationMinSpinBox
@onready var elevation_max_spin_box = $NoiseRanges/ElevationTab/ElevationMaxSpinBox

@onready var humidity_min_spin_box = $NoiseRanges/HumidityTab/HumidityMinSpinBox
@onready var humidity_max_spin_box = $NoiseRanges/HumidityTab/HumidityMaxSpinBox

@onready var color_picker_button = $VBoxContainer/ColorPickerButton

func get_elevation_range():
	return [elevation_min_spin_box.value, elevation_max_spin_box.value]
	
func get_humidity_range():
	return [humidity_min_spin_box.value, humidity_max_spin_box.value]

func get_color():
	return color_picker_button.get_picker().color
	
func _on_close_button_pressed():
	queue_free()
	pass # Replace with function body.
