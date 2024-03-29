extends Control

var button = preload("res://UI/Tagbutton.tscn")
var new_valve = preload("res://UI/AddValve.tscn")

func _ready():
	refresh("")


func refresh(text):
	for child in $"%Valves".get_children():
		child.queue_free()
	for key in VALVES.valves:
		if key.match("*" + text.to_upper() + "*"):
			var a = button.instance()
			$"%Valves".add_child(a)
			a.get_node("%Tag").text = key
			a.name = key
			a.get_child(0).connect("pressed", get_parent(), "_set_valve", [key])
			a.get_child(0).connect("pressed", self, "close")


func close():
	queue_free()


func _on_New_pressed():
	var a = new_valve.instance()
	a.parent = self
	add_child(a)
