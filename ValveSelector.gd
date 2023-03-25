extends Control


func _ready():
	refresh("")


func refresh(text):
	for child in $"%Valves".get_children():
		child.queue_free()
	for key in VALVES.valves:
		if key.begins_with(text.to_upper()):
			print(key)
			var button = Button.new()
			$"%Valves".add_child(button)
			button.text = key
			button.name = key
