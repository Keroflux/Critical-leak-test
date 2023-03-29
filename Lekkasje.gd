extends Control

var tag : String = "A-VC23-0263"
var type : String = "Valve"

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

var P2_crit: Array = []		# Lagring av trend ved integrering av kriterie
var P2_test: Array = []		# Lagring av trend ved integrering av test

var search_box = preload("res://ValveSelector.tscn")
var results_box = preload("res://ResultsPage.tscn")


# Kalkulerer lekkasjekriterie i kg / s
func calc_leak_crit_gas(ori: float, dp: float)->float:
	var K: float = 273.15 + T
	var dP: float = dp
	if P1 == 0:
		P1 = 1
	var Pr: float = dP / P1
	var Do: float = ori
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
#	var n: float = (m2 * 1000) / MW
#	var z: float = (PB * 100000 * volume) / (n * (R / 1000) * K)
	kg_s = abs(kg_s)
	return kg_s


func calc_leak_rate_trend(pb, time, p2 = 1)->float:
	var K: float = 273.15 + T
	var m1: float = p2 * 100000 * volume * MW / (Z * R * K)
	var m2: float = pb * 100000 * volume * MW / (Z * R * K)
	if time == 0:
		return 0.0
	var kg_s: float = (m1 - m2) / time
	kg_s = abs(kg_s)
	return kg_s


# Kalkulering orifice diameter ved gitt lekkasje
func calc_orifice(kgs: float)->float:
	var kgh = kgs * 3600
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


# Regner ut sekunder det vil ta å nå 0 dP i testsegmentet ved en gitt orifice
# og lagrer punkter for å lage trend til forventet trykkutvikling
func simulate_pressure_buildup(type: String, ori: float)->float:
	var sec: float = 0.0
	var count: int = 15
	var step: float = 0.01
	var K: float = 273.15 + T
	var p1 = P1
	var p2 = P2
	var gas_const = 100000 * volume * MW / (Z * R * K)
	if type == "Criteria":
		P2_crit.clear()
	else:
		P2_test.clear()
	while p2 < p1:
		var m1: float = p2 * gas_const
		var leak = calc_leak_crit_gas(ori, p1 - p2)
		m1 += leak * step
		p2 = m1 / gas_const
		sec += step
		if count == 15:
			if type == "Criteria":
				P2_crit.append(p2)
			else:
				P2_test.append(p2)
			count = 0
		count += 1
	return sec


# Kalkulerer den høyeste (første) lekkasjeraten under testen fra gjennomsnittet
func find_real_leak(orifice, kgs):
	var numw = 0
	var numf = 0
	var p0 = P2								#Trykk før test
	var t0 := 0.0							#Klakulert test varighet
	var t = test_time						#Test varighet
	var p = PB								#Trykk etter test
	var ori_pre = kgs / (P1 - P2) * 25	#Predikerer en sikker økning av orifice før loopen
	var predicted_orifice = orifice + ori_pre #Orifice testraten tilsvarer
	var K = T + 273.15
	var gas_const = 100000 * volume * MW / (Z * R * K)
	var d_g = (MW * P1) / (0.08314 * K * Z)
	var ab = 0.62 * 1.265
	var m0 = p0 * gas_const			#Masse ved teststart
	var dt := 0.02 					#Tidsenhet
	print("Average: ",orifice)
	print("Predicted: ",predicted_orifice)
#	Loop som øker størrelsen på orificen for hver ieterasjon og simulerer trykkoppbygging.
#	Når simulert sluttrykk (p0) når testens sluttrykk (p) og simulert testvarighet (t0)
#	er større eller lik testvarighet (test_time) returneres lekkasjeraten for tilsvarende orifice
	for i in range (1000):
		numf += 1
		predicted_orifice += 0.01
		t0 = 0
		p0 = P2
		var m_0 = m0
		while p0 < p and t0 <= test_time:
			var dP: float = P1 - p0
			if P1 == 0:
				P1 = 1
			var Pr: float = dP / P1
			var Do : float = predicted_orifice
			var Yo: float = 1.008 - 0.338 * Pr
			if Pr < 0.29:
				Yo = 1 - 0.31 * Pr
			var dg: float = d_g
			var kg_h: float = Do * Do * Yo * ab * pow((dP * dg), 0.5)
			var kg_s: float = kg_h / 3600
#			kg_s = abs(kg_s)
			m_0 += kg_s * dt
			p0 = m_0 / gas_const
			t0 += dt
			
			numw += 1
			
		if t0 <= test_time:
			print("Actual: ", predicted_orifice)
			print("End pressure: ", p0)
			print("Number of for: ", numf)
			print("Number of while: ", numw)
			return calc_leak_crit_gas(predicted_orifice, p0 - P2)

# Ekstra funksjon for test av optimalsiering
func find_real_leak2(orifice, kgs):
	var numw = 0
	var numf = 0
	var p0 = P2								#Trykk før test
	var t0 := 0.0							#Klakulert test varighet
	var t = test_time						#Test varighet
	var p = PB								#Trykk etter test
	var ori_pre = kgs / (P1 - P2) * 25	#Predikerer en sikker økning av orifice før loopen
	var predicted_orifice = orifice + ori_pre #Orifice testraten tilsvarer
	var K = T + 273.15
	var gas_const = 100000 * volume * MW / (Z * R * K)
	var d_g = (MW * P1) / (0.08314 * K * Z)
	var ab = 0.62 * 1.265
	var m0 = p0 * gas_const			#Masse ved teststart
	var dt := 2.0 					#Tidsenhet
	print("Average: ",orifice)
	print("Predicted: ",predicted_orifice)
#	Loop som øker størrelsen på orificen for hver ieterasjon og simulerer trykkoppbygging.
#	Når simulert sluttrykk (p0) når testens sluttrykk (p) og simulert testvarighet (t0)
#	er større eller lik testvarighet (test_time) returneres lekkasjeraten for tilsvarende orifice
	for i in range (1000):
		numf += 1
		predicted_orifice += 0.01
		t0 = 0
		p0 = P2
		var m_0 = m0
		while p0 < p:
			var dP: float = P1 - p0
			if P1 == 0:
				P1 = 1
			var Pr: float = dP / P1
			var Do : float = predicted_orifice
			var Yo: float = 1.008 - 0.338 * Pr
			if Pr < 0.29:
				Yo = 1 - 0.31 * Pr
			var dg: float = d_g
			var kg_h: float = Do * Do * Yo * ab * pow((dP * dg), 0.5)
			var kg_s: float = kg_h / 3600
#			kg_s = abs(kg_s)
			m_0 += kg_s * dt
			p0 = m_0 / gas_const
			t0 += dt
			
			numw += 1
		
		if p0 > p + 0.0001:
			dt *= 0.5
		else:
			if t0 <= test_time:
				print("Time: ", t0)
				print("Actual: ", predicted_orifice)
				print("End pressure: ", p0)
				print("Number of for: ", numf)
				print("Number of while: ", numw)
				return calc_leak_crit_gas(predicted_orifice, p0 - P2)


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
		type = "Valve"
	else:
		type = "Check"
		Di = valve["Di"]
		volume = valve["volume"]
	
	P2 = float($"%PressureStart".text) + 1
	P1 = float($"%PressureExternal".text) + 1
	PB = float($"%PressureAfter".text) + 1
	T = float($"%Temperatur".text)
	if P2 > P1:
		P1 = float($"%PressureStart".text) + 1
		P2 = float($"%PressureExternal".text) + 1
		PB = float($"%PressureStart".text) + 1
	test_time = float($"%TestTime".text)


# Sender verdier til trend og starter tegning
func init_trend(sec_test = 0, sec_crit = 0)->void: # TODO: inverter trenden ved negativ trykktest
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
func _run_calculations()->void:
	set_test_variables()
	var kgs_crit
	var crit_orifice
	if type == "Valve":
		kgs_crit = 0.05
		print(kgs_crit)
		crit_orifice = calc_orifice(kgs_crit)
	else:
		kgs_crit = calc_leak_crit_gas(Di / 10, P1 - P2)
		crit_orifice = Di / 10
	var sec_crit = simulate_pressure_buildup("Criteria", crit_orifice)
	var kgs_test = calc_leak_rate_gas()
	var test_orifice = calc_orifice(kgs_test)
	var time_start = OS.get_ticks_msec()
	find_real_leak(test_orifice, kgs_test)
	print("Loop time: ",OS.get_ticks_msec() - time_start, " ms\n")
	time_start = OS.get_ticks_msec()
	var kgs_real = find_real_leak2(test_orifice, kgs_test)
	print("Loop time: ",OS.get_ticks_msec() - time_start, " ms\n")
	test_orifice = calc_orifice(kgs_real)
	var sec_test = simulate_pressure_buildup("Test", test_orifice)
	init_trend(sec_test, sec_crit)
	
	var a = results_box.instance()
	a.kgs_crit = kgs_crit
	a.kgs_test = kgs_real
	a.sec_crit = sec_crit
	a.sec_test = sec_test
	a.ori_crit = crit_orifice
	a.ori_test = test_orifice
	a.tag = tag
	add_child(a)


# Klikkevent fra netrekkslisten
func _set_valve(valve)->void:
	tag = valve
	$"%ValveSearch".text = tag


func calc_leak_new(ori, pipe):
	var K = 273.15 + T
	var p1 = P1 * 100000.0
	var p2 = P2 * 100000.0
	var dP: float = p1 - p2
	var C = 0.62
	var beta = ori / pipe
	var dg = (MW * p1) / (8314 * K * Z)
	var e = 1.0
	var d2 = ori * ori
	var Qm = (C / sqrt(1 - pow(beta, 4))) * e * (PI / 4) * d2 * sqrt(2 * dg * dP)
	print(Qm)


func _on_Trend_resized():
	init_trend()


func _open_Valve_search():
	var a = search_box.instance()
	add_child(a)
