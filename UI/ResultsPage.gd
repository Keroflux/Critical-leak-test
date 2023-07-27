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


func _ready():
	parent = get_parent()
	$"%Tag/Result".text = " " + tag
	$"%CriteriaKGS/Result".text = " " + str(snappedf(kgs_crit, 0.0001)) + " kg / s"
	$"%TestKGS/Result".text = " " + str(snappedf(kgs_test, 0.0001)) + " kg / s"
	$"%CriteriaTime/Result".text = " " + str(snappedf(sec_crit, 0.1)) + " Sekunder"
	$"%TestTime/Result".text = " " + str(snappedf(sec_test, 0.1)) + " Sekunder"
	$"%CriteriaOri/Result".text = " " + str(snappedf(ori_crit, 0.0001)) + " mm"
	$"%TestOri/Result".text = " " + str(snappedf(ori_test, 0.0001)) + " mm"
	
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
			var kgs = parent.calc_leak_rate_trend(pressure, time)
			var string = tag + "," + str(time) + "," + str(pressure - 1) + "," + str(kgs)
			csv += "\n" + string
			time += (0.01 * 15)
		# Last ned filen
		JavaScriptBridge.download_buffer(csv.to_utf8_buffer(), file_name)
	
	else:
		var dir := OS.get_system_dir(2)
		var file : FileAccess = FileAccess.open(dir + "\\" + file_name, FileAccess.WRITE)
		for i in result.size():
			if i == 0:
				file.store_line("Tag,Time,Pressure,kg / s")
			var pressure = result[i]
			var kgs = parent.calc_leak_rate_trend(pressure, time)
			var string = tag + "," + str(time) + "," + str(pressure - 1) + "," + str(kgs)
			file.store_line(string)
			time += (0.01 * 15)
		file.close()
