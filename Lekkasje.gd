extends Control

var tag = "1901-A-VC23-0263"
# Variabler til bruk i kalkulering av lekkasje kriterie
var MW: float = 28.01 	# MOL vekt for test medie
var P1: float = 1.0 	# Trykk utenfor testvolum
var P2: float = 1.0 	# Trykk i testvolum før test
var PB:float = 1.0 		# Trykk i testvolum etter test
var T:float = 15.0 		# Temperatur test medie
var Di: float= 372.0 	# Indre rør diameter
var Z: float = 0.98 	# Kompressabilitet til testmedie

# Variabler til kalkulering av lekkasjerate under test
var volume: float = 0.11876		# Testvolumet i m3
const R: float = 8314.5			# Gasskonstanten
var test_time: float = 900.0	# Testvarighet i sekunder

var kgs_crit: float = 0.0
var kgs_test: float = 0.0


var comp_f = 0.98
#var R = 0.000083145
var max_leak_rate = 6006

var k := 1.416

var leak_krit = 0.1
var Za = 0.9978


func _ready():
	pass


func calc_leak_crit_gas():
	var K = 273.15 + T
	var dP = P1 - P2
	if P1 == 0:
		P1 = 1
	var Pr = dP / P1
	var Do = Di/ 10
	var Yo = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg = (MW * P1) / (0.08314 * K * Z)
	var kg_h = Do * Do * Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)
	var kg_s = kg_h / 3600
	kgs_crit = kg_s
	$LeakRate2.text = str(kg_s)


func calc_leak_rate_gas():
	var K = 273.15 + T
	var m1 = P2 * 100000 * volume * MW / (Z * R * K)
	var m2 = PB * 100000 * volume * MW / (Z * R * K)
	var kg_s = (m1 - m2) / test_time
	kgs_test = kg_s
	$LeakRate3.text = str(abs(kg_s))




func calculate_leak_criteria():
	var K = 273.15 + T
	var total_A2 = pow(Di / 2, 2) * PI
	var max_A2 = total_A2 * (leak_krit / 100)
	max_A2 = 13.22905358
	var r = P2 / P1
	var rc = pow(2 / (k + 1), k / (k-1))
	var rcc = pow(2 / (k + 1), (k + 1) / (k-1))
	var C = 0
	if k == 0:
		C = 0
	elif r > rc:
		C = 0.62
	else:
		C = 0.84 - (0.84 - 0.75) * (r / rc)
	var kg_s = C / 10 * max_A2 * P1 * sqrt(k * (MW / (Za * 8314 * K)) * rcc)
	$LeakRate2.text = str(kg_s)
	kgs_crit = kg_s
	
#	var dP: float = P1 - P0
#	var n0 = (P0 * volume) / (R * K * comp_f)
#	var n1 = (P1 * volume) / (R * K * comp_f)
#	var dm = (n1 * MW - n0 * MW) / 1000
#	var dt = dm / max_leak_rate * 3600
#	if dt == 0:
#		dt = 1.0
#	var bar_s = dP / dt
#	$LeakRate.text = str(bar_s)


func calculate_leak_kgs():
	var K = 273.15 + T
	var m1 = P2 * 100000 * volume * MW / (Za * 8341 * K)
	var m2 = PB * 100000 * volume * MW / (Za * 8341 * K)
	var kg_s = (m1 - m2) / test_time
	$LeakRate3.text = str(kg_s)
	kgs_test = kg_s
	if kgs_test > kgs_crit:
		$ColorRect.self_modulate = Color(1.0, 0.0, 0.0)
	else:
		$ColorRect.self_modulate = Color(0.0, 1.0, 0.0)


func _on_TrykkOppstrms_text_changed(new_text):
	P2 = float(new_text) + 1.0


func _on_TrykkNedstrms_text_changed(new_text):
	P1 = float(new_text) + 1.0


func _on_Temperatur_text_changed(new_text):
	T = float(new_text)


func _on_TestTid_text_changed(new_text):
	test_time = float(new_text)


func _on_TrykkEtter_text_changed(new_text):
	PB = float(new_text) + 1.0


func _on_Button_pressed():
	calc_leak_crit_gas()
	calc_leak_rate_gas()
