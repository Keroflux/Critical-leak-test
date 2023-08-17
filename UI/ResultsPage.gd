extends Control

var kgs_crit = 0
var kgs_test = 0
var sec_crit = 0
var sec_test = 0
var ori_test = 0
var ori_crit = 0
var tag := ""
var type := ""
var result : Array = []
var parent : Control
var gc
var p0


func _ready():
	parent = get_parent()
	$"%Tag/Result".text = " " + tag
	$"%CriteriaKGS/Result".text = " " + str(kgs_crit) + " kg / s"
	$"%TestKGS/Result".text = " " + str(kgs_test) + " kg / s"
	$"%CriteriaTime/Result".text = " " + str(sec_crit) + " Sekunder"
	$"%TestTime/Result".text = " " + str(sec_test) + " Sekunder"
	$"%CriteriaOri/Result".text = " " + str(ori_crit) + " mm"
	$"%TestOri/Result".text = " " + str(ori_test) + " mm"
	
	if type == "valve":
		if kgs_test >= 0.5:
			$"%Accepted/Result".text = " Underkjent"
		elif kgs_test >= 0.05:
			$"%Accepted/Result".text = " Syk, bør skjekkes"
	else:
		if kgs_test > kgs_crit:
			$"%Accepted/Result".text = " Underkjent!"


func _on_Close_pressed():
	queue_free()


func store_result_as_csv():
	var time = 0.01
	var file_name = tag + ".csv"
	
	if OS.has_feature("wasm"): # Nettleser?
		var csv : String
		for i in result.size():
			if i == 0:
				csv = "Tag,Time,Pressure,kg / s"
			var pressure = result[i]
			var kgs = calc_leak_rate(pressure, time, gc, p0)
			var string = tag + "," + str(time) + "," + str(pressure - 1) + "," + str(kgs)
			csv += "\n" + string
			time += (0.01 * 15)
		# Last ned filen
		JavaScript.download_buffer(csv.to_utf8(), file_name)
	
	else:
		var dir := OS.get_system_dir(2)
		var file : File = File.new()
		file.open(dir + "\\" + file_name, File.WRITE)
		for i in result.size():
			if i == 0:
				file.store_line("Tag,Time,Pressure,kg / s")
			var pressure = result[i]
			var kgs = calc_leak_rate(pressure, time, gc, p0)
			var string = tag + "," + str(time) + "," + str(pressure - 1) + "," + str(kgs)
			file.store_line(string)
			time += (0.01 * 15)
		file.close()


func calc_leak_rate(p_end, time, gas_c, p_start = 1)->float:
	var m1: float = p_start * gas_c
	var m2: float = p_end * gas_c
	if time == 0:
		return 0.0
	var kg_s: float = (m1 - m2) / time
	kg_s = abs(kg_s)
	return kg_s
