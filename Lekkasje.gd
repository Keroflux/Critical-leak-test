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
var orifice: float = 0.0

var kgs_crit: float = 0.0
var kgs_test: float = 0.0
var sec_crit: float = 0.0


var comp_f = 0.98
#var R = 0.000083145
var max_leak_rate = 6006

var k := 1.416

var leak_krit = 0.1
var Za = 0.9978


func _ready():
	pass


func calc_leak_crit_gas()->float:
	var K: float = 273.15 + T
	var dP: float = P1 - P2
	if P1 == 0:
		P1 = 1
	var Pr: float = dP / P1
	var Do: float = Di/ 10
	var Yo: float = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg: float = (MW * P1) / (0.08314 * K * Z)
	var kg_h: float = Do * Do * Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)
	var ori = sqrt(kg_h / (Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)))
	var kg_s: float = kg_h / 3600
	kg_s = abs(kg_s)
	print(ori)
	return kg_s


func calc_leak_rate_gas()->float:
	var K: float = 273.15 + T
	var m1: float = P2 * 100000 * volume * MW / (Z * R * K)
	var m2: float = PB * 100000 * volume * MW / (Z * R * K)
	var kg_s: float = (m1 - m2) / test_time
	kg_s = abs(kg_s)
	return kg_s


func integrate_leak(step):
	var K: float = 273.15 + T
	var m1: float = P2 * 100000 * volume * MW / (Z * R * K)
	var m2: float = PB * 100000 * volume * MW / (Z * R * K)
	var kg_s: float = (m1 - m2) / test_time
	var kg_h = abs(kg_s * 3600)


func integrate_criteria(step)->float:
	var sec: float = 0.0
	while P2 < P1:
		var K: float = 273.15 + T
		var m1: float = P2 * 100000 * volume * MW / (Z * R * K)
		var leak: float = calc_leak_crit_gas()
		m1 += leak * 0.01
		P2 = m1 / (100000 * volume * MW / (Z * R * K))
		sec += step
	return sec


func _on_Button_pressed()->void:
	P2 = float($"%PressureStart".text) + 1
	P1 = float($"%PressureExternal".text) + 1
	PB = float($"%PressureAfter".text) + 1
	T = float($"%Temperatur".text)
	test_time = float($"%TestTime".text)
	kgs_crit = calc_leak_crit_gas()
	kgs_test = calc_leak_rate_gas()
	$"%LeakRate".text = str(kgs_test)
	$"%CritLeak".text = str(kgs_crit)
	
	sec_crit = integrate_criteria(0.01)
	$"%CritLeakSec".text = str(sec_crit)




# Gammel kode, som jeg kanskje får bruk for??
#func calculate_leak_criteria():
#	var K = 273.15 + T
#	var total_A2 = pow(Di / 2, 2) * PI
#	var max_A2 = total_A2 * (leak_krit / 100)
#	max_A2 = 13.22905358
#	var r = P2 / P1
#	var rc = pow(2 / (k + 1), k / (k-1))
#	var rcc = pow(2 / (k + 1), (k + 1) / (k-1))
#	var C = 0
#	if k == 0:
#		C = 0
#	elif r > rc:
#		C = 0.62
#	else:
#		C = 0.84 - (0.84 - 0.75) * (r / rc)
#	var kg_s = C / 10 * max_A2 * P1 * sqrt(k * (MW / (Za * 8314 * K)) * rcc)
#	$"%CritLeak".text = str(kg_s)
#	kgs_crit = kg_s
#
#	var dP: float = P1 - P0
#	var n0 = (P0 * volume) / (R * K * comp_f)
#	var n1 = (P1 * volume) / (R * K * comp_f)
#	var dm = (n1 * MW - n0 * MW) / 1000
#	var dt = dm / max_leak_rate * 3600
#	if dt == 0:
#		dt = 1.0
#	var bar_s = dP / dt
#	$LeakRate.text = str(bar_s)
#
#
#func calculate_leak_kgs():
#	var K = 273.15 + T
#	var m1 = P2 * 100000 * volume * MW / (Za * 8341 * K)
#	var m2 = PB * 100000 * volume * MW / (Za * 8341 * K)
#	var kg_s = (m1 - m2) / test_time
#	$LeakRate3.text = str(kg_s)
#	kgs_test = kg_s
#	if kgs_test > kgs_crit:
#		$ColorRect.self_modulate = Color(1.0, 0.0, 0.0)
#	else:
#		$ColorRect.self_modulate = Color(0.0, 1.0, 0.0)
