extends Control

var parent

func _on_Back_pressed():
	queue_free()


func _on_Add_pressed():
	var tag = $"%Tag".text.to_upper()
	var mw = float($"%MW".text)
	var di = float($"%Di".text)
	var z = float($"%CompF".text)
	var volume = float($"%Volume".text)
	var dens = float($"%Dens".text)
	var k = float($"%Elasticity".text)
	var type = $"%Type".get_item_text($"%Type".get_selected_id())
	if type == "Ventil":
		type = "valve"
	else:
		type = "check"
	
	var dict : Dictionary = {tag: {"MW": mw, "Di:": di, "Z": z, "volume": volume, "Dens": dens, "K": k, "type": type}}
	VALVES.valves.merge(dict)
	parent.refresh("")
	queue_free()
