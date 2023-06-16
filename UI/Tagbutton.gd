extends Control



func _on_STID_pressed():
	OS.shell_open("https://stid.equinor.com/JSV/tag/" + name)


func _on_Echo_pressed():
	var plant
	if name.begins_with("L"):
		plant = "JSL"
	if name.begins_with("A"):
		plant = "JSA"
	elif name.begins_with("D"):
		plant = "JSD"
	elif name.begins_with("R"):
		plant = "JSR"
	else:
		plant = "JSB"
	OS.shell_open("echo://tag/?tag=" + str(name) + "&plant=" + str(plant))



func _on_SAP_pressed():
	var plant
	if name.begins_with("L"):
		plant = "1900-"
	if name.begins_with("A"):
		plant = "1901-"
	elif name.begins_with("D"):
		plant = "1902-"
	elif name.begins_with("R"):
		name = "1903-"
	else:
		name = "1904-"
	OS.shell_open("https://p03web.statoil.no/sap/bc/webdynpro/sap/zompm_lookup_eq_info?run=x&tplnr=" + plant + name)


func _on_Hub_pressed():
	OS.shell_open("https://echo.equinor.com/tags?instCode=JSV&tagNo=" + name)
