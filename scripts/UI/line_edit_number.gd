extends LineEdit
@onready var LineEditRegEx = RegEx.new()
var old_text = ""

func _ready() -> void:
	LineEditRegEx.compile("^[0-9.]*$")


func _on_text_changed(new_text):
	if LineEditRegEx.search(new_text):
		old_text = str(new_text)
	else:
		text = old_text
		set_caret_column(text.length())
