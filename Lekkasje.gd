extends Control

var tag = "42ESV1271"
var MW = 28.01
var comp_f = 0.98
var R = 0.000083145
var max_leak_rate = 6006
var volume = 7.04
var P0 := 1.0
var P1 := 1.0
var PB := 1.0
var temperature = 15
var k = 1.416
var pipe_diameter = 396.84  
var leak_krit = 0.1
var Za = 0.9978
var test_time = 900
var kgs_crit = 0
var kgs_test = 0


func _ready():
	calculate_leak_criteria()
	calculate_leak_kgs()


func calculate_leak_criteria():
	var K = 273.15 + temperature
	var total_A2 = pow(pipe_diameter / 2, 2) * PI
	var max_A2 = total_A2 * (leak_krit / 100)
	max_A2 = 13.22905358
	var r = P1 / P0
	var rc = pow(2 / (k + 1), k / (k-1))
	var rcc = pow(2 / (k + 1), (k + 1) / (k-1))
	var C = 0
	if k == 0:
		C = 0
	elif r > rc:
		C = 0.62
	else:
		C = 0.84 - (0.84 - 0.75) * (r / rc)
	var kg_s = C / 10 * max_A2 * P0 * sqrt(k * (MW / (Za * 8314 * K)) * rcc)
	$LeakRate2.text = str(kg_s)
	kgs_crit = kg_s
	
	var dP: float = P1 - P0
	var n0 = (P0 * volume) / (R * K * comp_f)
	var n1 = (P1 * volume) / (R * K * comp_f)
	var dm = (n1 * MW - n0 * MW) / 1000
	var dt = dm / max_leak_rate * 3600
	if dt == 0:
		dt = 1.0
	var bar_s = dP / dt
	$LeakRate.text = str(bar_s)


func calculate_leak_kgs():
	var K = 273.15 + temperature
	var m1 = P0 * 100000 * volume * MW / (Za * 8341 * K)
	var m2 = PB * 100000 * volume * MW / (Za * 8341 * K)
	var kg_s = (m1 - m2) / test_time
	$LeakRate3.text = str(kg_s)
	kgs_test = kg_s
	if kgs_test > kgs_crit:
		$ColorRect.self_modulate = Color(1.0, 0.0, 0.0)
	else:
		$ColorRect.self_modulate = Color(0.0, 1.0, 0.0)


func _on_TrykkOppstrms_text_changed(new_text):
	P0 = float(new_text)
	if P0 == 0:
		P0 = float(1.0)
	calculate_leak_criteria()
	calculate_leak_kgs()


func _on_TrykkNedstrms_text_changed(new_text):
	P1 = float(new_text)
	calculate_leak_criteria()
	calculate_leak_kgs()


func _on_Temperatur_text_changed(new_text):
	temperature = float(new_text)
	calculate_leak_criteria()
	calculate_leak_kgs()


func _on_TestTid_text_changed(new_text):
	test_time = int(new_text)
	calculate_leak_criteria()
	calculate_leak_kgs()


func _on_TrykkEtter_text_changed(new_text):
	PB = float(new_text)
	calculate_leak_criteria()
	calculate_leak_kgs()
