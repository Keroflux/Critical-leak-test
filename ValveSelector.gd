extends Control


func _ready():
	refresh("")


func refresh(text):
	for child in $"%Valves".get_children():
		child.queue_free()
	for key in VALVES.valves:
		if key.match("*" + text.to_upper() + "*"):
			var button = Button.new()
			$"%Valves".add_child(button)
			button.text = key
			button.name = key
			button.connect("pressed", get_parent(), "_set_valve", [key])
			button.connect("pressed", self, "close")


func close():
	queue_free()
