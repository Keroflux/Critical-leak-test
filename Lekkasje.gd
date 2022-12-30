extends Control

var tag : String = "A-VC23-0263"
var type : int = 0 # 0 = ventil, 1 = tilbakeslag

# Variabler til bruk i kalkulering av lekkasje kriterie
var MW: float = 28.01 	# MOL vekt for test medie
var P1: float = 2.0 	# Trykk utenfor testvolum
var P2: float = 1.0 	# Trykk i testvolum før test
var PB: float = 1.0 	# Trykk i testvolum etter test
var T: float = 15.0 	# Temperatur test medie
var Di: float= 372.0 	# Indre rør diameter
var Z: float = 0.98 	# Kompressabilitet til testmedie

# Variabler til kalkulering av lekkasjerate under test
var volume: float = 0.11876		# Testvolumet i m3
const R: float = 8314.5			# Gasskonstanten
var test_time: float = 900.0	# Testvarighet i sekunder

# Variabler for lagring av resultat av kalkulasjoner
var kgs_crit: float = 0.0	# Lekkasjekriterie i kg / s 
var kgs_test: float = 0.0	# Lekkasjerate under test i kg / s
var kgs_real: float	# Den faktiske lekkasjeraten under test i kg / s
var sec_crit: float = 0.0	# Hvor lang tid i sekunder det tar for å nå 0 dP ved kriterie
var sec_test: float = 0.0	# Hvor lang tid i sekunder det tar for å nå 0 dP ved test
var P2_crit: Array = []		# Lagring av trend ved integrering av kriterie
var P2_test: Array = []		# Lagring av trend ved integrering av test
var test_orifice: float = 0.0

# Ubrukt, tror jeg
var comp_f = 0.98
#var R = 0.000083145
var max_leak_rate = 6006
var k := 1.416
var leak_krit = 0.1
var Za = 0.9978


# Legger ventilene i nedrekkslisten
func _ready():
	for i in VALVES.valves:
		$"%OptionButton".add_item(i)


# Kalkulerer lekkasjekriterie i kg / s
func calc_leak_crit_gas(ori: float = 0.0)->float:
	var K: float = 273.15 + T
	var dP: float = P1 - P2
	if P1 == 0:
		P1 = 1
	var Pr: float = dP / P1
	var Do: float = Di/ 10.0
	if ori > 0:
		Do = ori
	var Yo: float = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg: float = (MW * P1) / (0.08314 * K * Z)
	var kg_h: float = Do * Do * Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)
	var kg_s: float = kg_h / 3600
	kg_s = abs(kg_s)
	return kg_s


# Kalkulerer (gjennimsnitt) lekkasje under test i kg / s
func calc_leak_rate_gas()->float:
	var K: float = 273.15 + T
	var m1: float = P2 * 100000 * volume * MW / (Z * R * K)
	var m2: float = PB * 100000 * volume * MW / (Z * R * K)
	var kg_s: float = (m1 - m2) / test_time
	var n: float = (m2 * 1000) / MW
	var z: float = (PB * 100000 * volume) / (n * (R / 1000) * K)
	kg_s = abs(kg_s)
	return kg_s


# Kalkulering orifice diameter ved gitt lekkasje
func calc_orifice(kgh: float)->float:
	var K: float = 273.15 + T
	var dP: float = P1 - P2
	if P1 == 0:
		P1 = 1
	var Pr: float = dP / P1
	var Yo: float = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg: float = (MW * P1) / (0.08314 * K * Z)
	var orifice = sqrt(kgh / (Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)))
	return orifice


# Mater test lekkasjeraten til integrerings funksjonen for å finne ut sekunder
# til 0 dP
func integrate_leak()->float:
	var kg_s: float = calc_leak_rate_gas()
	var kg_h: float = kgs_real * 3600
	var orifice: float = calc_orifice(kg_h)
	var sec: float = integrate_criteria(2, 0.01, orifice)
	return sec


# For ventiler med fast lekkasjerate på 0.05 kg / s
func integrate_leak_005()->float:
	var kg_s: float = 0.05
	var kg_h: float = 0.05 * 3600
	var orifice: float = calc_orifice(kg_h)
	var sec: float = integrate_criteria(1, 0.01, orifice)
	return sec


# Regner ut sekunder det vil ta å nå 0 dP i testsegmentet ved en gitt lekasjerate
# og lagrer punkter for å lage trend til forventet trykkutvikling
func integrate_criteria(P: int, step: float, ori: float = 0.0)->float:
	var sec: float = 0.0
	var count: int = 15
	var s: float = step
	if P == 1:
		P2_crit.clear()
	else:
		P2_test.clear()
	while P2 < P1:
		var K: float = 273.15 + T
		var m1: float = P2 * 100000 * volume * MW / (Z * R * K)
		var leak: float = calc_leak_crit_gas(ori)
		m1 += leak * s
		P2 = m1 / (100000 * volume * MW / (Z * R * K))
		sec += step
		if count == 15:
			if P == 1:
				P2_crit.append(P2-1)
			else:
				P2_test.append(P2-1)
			count = 0
		count += 1
	P2 = float($"%PressureStart".text) + 1
	return sec


func find_real_leak2():
	var p0 = P2
	var t0 := 0.0
	var t = test_time
	var p = PB
	var ori = calc_orifice(kgs_test * 3600)
	var kgs := 0.0
	
	var m0 = p0 * 100000 * volume * MW / (Z * R * (T + 273.15))
	var dt := 0.05
	for i in range (1000):
		ori += 0.01
		t0 = 0
		p0 = P2
		m0 = p0 * 100000 * volume * MW / (Z * R * (T + 273.15))
		while t0 <= test_time:
			var K: float = 273.15 + T
			var dP: float = P1 - p0
			if P1 == 0:
				P1 = 1
			var Pr: float = dP / P1
			var Do = ori
			var Yo: float = 1.008 - 0.338 * Pr
			if Pr < 0.29:
				Yo = 1 - 0.31 * Pr
			var dg: float = (MW * P1) / (0.08314 * K * Z)
			var kg_h: float = Do * Do * Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)
			var kg_s: float = kg_h / 3600
			kg_s = abs(kg_s)
			
			m0 += kg_s * dt
			p0 = m0 / (100000 * volume * MW / (Z * R * (T + 273.15)))
			t0 += dt
			
			if p0 >= p:
				kgs = kg_s
				break
			
		if p0 >= p:
			return calc_leak_crit_gas(ori)


# Kalkulerer den høyeste (første) lekkasjeraten under testen fra gjennomsnittet
func find_real_leak():
	var p0 = P2								#Trykk før test
	var t0 := 0.0							#Klakulert test varighet
	var t = test_time						#Test varighet
	var p = PB								#Trykk etter test
	var ori_pre = kgs_test / (P1 - P2) * 25	#Predikerer en sikker økning av orifice før loopen
	var ori = calc_orifice(kgs_test * 3600) #Orifice testraten tilsvarer
	var m0 := 0.0							#Masse ved teststart
	var dt := 1.0 / 50.0 					#Tidsenhet
	ori = ori + ori_pre
#	Loop som øker størrelsen på orificen for hver ieterasjon og simulerer trykkoppbygging.
#	Når simulert sluttrykk (p0) når testens sluttrykk (p) og simulert testvarighet (t0)
#	er større eller lik testvarighet (test_time) returneres lekkasjeraten for tilsvarende orifice
	for i in range (1000):
		ori += 0.01
		t0 = 0
		p0 = P2
		m0 = p0 * 100000 * volume * MW / (Z * R * (T + 273.15))
		while p0 < p:
			var K: float = 273.15 + T
			var dP: float = P1 - p0
			if P1 == 0:
				P1 = 1
			var Pr: float = dP / P1
			var Do : float = ori
			var Yo: float = 1.008 - 0.338 * Pr
			if Pr < 0.29:
				Yo = 1 - 0.31 * Pr
			var dg: float = (MW * P1) / (0.08314 * K * Z)
			var kg_h: float = Do * Do * Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)
			var kg_s: float = kg_h / 3600
			kg_s = abs(kg_s)
			
			m0 += kg_s * dt
			p0 = m0 / (100000 * volume * MW / (Z * R * (T + 273.15)))
			t0 += dt
			
			if p0 >= p:
				break
			
		if t0 <= test_time:
			return calc_leak_crit_gas(ori)


# Setter verdier for testmedie og ventil
func set_test_variables()->void:
	var valve = VALVES.valves[tag]
	
	if $"%Nitrogen".pressed:
		MW = 28.01
		Z = 0.98
	else:
		MW = valve["MW"]
		Z = valve["Z"]
	
	if valve["Di"] == 0:
		type = 0
	else:
		type = 1
		Di = valve["Di"]
		volume = valve["volume"]


# Sender verdier til trend og starter tegning
func init_trend()->void:
	$"%Trend".test = P2_test
	$"%Trend".crit = P2_crit
	if sec_test >= sec_crit:
		$"%Trend".seconds = sec_test
	else:
		$"%Trend".seconds = sec_crit
	$"%Trend".max_pressure = P1 - 1
	$"%Trend".min_pressure = P2 - 1
	$"%Trend".calculate_point_distance()
	$"%Trend".place_sec_marks()
	$"%TrendLine".data_points = P2_test
	$"%TrendLine2".data_points = P2_crit
	$"%TrendLine".trend_run()
	$"%TrendLine2".trend_run()


# Klikkevent fra "kalkuler" kanppen
func _on_Button_pressed()->void:
	P2 = float($"%PressureStart".text) + 1
	P1 = float($"%PressureExternal".text) + 1
	PB = float($"%PressureAfter".text) + 1
	T = float($"%Temperatur".text)
	test_time = float($"%TestTime".text)
	
	set_test_variables()
	
	if type == 0:
		sec_crit = integrate_leak_005()
		kgs_crit = 0.05
	else:
		kgs_crit = calc_leak_crit_gas()
		sec_crit = integrate_criteria(1, 0.01)
	
	kgs_test = calc_leak_rate_gas()
	kgs_real = find_real_leak()
#	print(find_real_leak2())
	sec_test = integrate_leak()
	
	$"%LeakRate".text = str(kgs_real)
	$"%CritLeak".text = str(kgs_crit)
	
	$"%CritLeakSec".text = str(sec_crit)
	$"%LeakSec".text = str(sec_test)
	init_trend()
	
	if kgs_real > kgs_crit:
		$"%LeakRate".get_stylebox("normal").bg_color = Color(0.583008, 0.04327, 0.04327)
	else:
		$"%LeakRate".get_stylebox("normal").bg_color = Color(0.141176, 0.396078, 0.078431)


# Klikkevent fra netrekkslisten
func _on_OptionButton_item_selected(index)->void:
	tag = $"%OptionButton".get_item_text(index)

func calc_leak_new(ori, pipe):
	var K = 273.15 + T
	var p1 = P1 * 100000.0
	var p2 = P2 * 100000.0
	var dP: float = p1 - p2
	print(dP)
	var C = 0.62
	var beta = ori / pipe
	var dg = (MW * p1) / (8314 * K * Z)
	print(dg)
	var e = 1.0
	var d2 = ori * ori
	var Qm = (C / sqrt(1 - pow(beta, 4))) * e * (PI / 4) * d2 * sqrt(2 * dg * dP)
	print(Qm)

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



func _on_Trend_resized():
	init_trend()
