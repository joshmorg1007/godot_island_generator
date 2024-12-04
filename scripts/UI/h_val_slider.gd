extends Control

@onready var val: RichTextLabel = $HBoxContainer/Val

func _on_slider_value_changed(value):
	val.text = "[right]" + str(value) + "[/right]"
	pass # Replace with function body.
