extends Control

var tag : String = "A-VC23-0263"
var type : String = "Check"
var medie : String = "Gass"

# Variabler til bruk i kalkulering av lekkasjerater
# Blir satt av bruker
var P1: float = 2.0 			# Trykk utenfor testvolum
var P2: float = 1.0 			# Trykk i testvolum før test
var PB: float = 1.0 			# Trykk i testvolum etter test
var T: float = 288.15 			# Temperatur test medie i Kelvin
var test_time: float = 900.0	# Testvarighet i sekunder
var volume: float = 0.11876		# Testvolumet i m3
# Blir satt av valgt ventil
var MW: float = 28.01 			# MOL vekt for test medie
var Di: float= 372.0 			# Indre rør diameter
var Z: float = 0.98 			# Kompressabilitet til testmedie
var dens: float = 847			# Densitet i g / l
var elasticity: float = 15000	# Elastisitet...

const R: float = 8314.5			# Gasskonstanten

var P2_crit: Array = []			# Lagring av trend ved integrering av kriterie
var P2_test: Array = []			# Lagring av trend ved integrering av test

var search_box = preload("res://ValveSelector.tscn")
var results_box = preload("res://ResultsPage.tscn")


# Kalkulerer lekkasjekriterie i kg / s
func max_leak_gas(ori: float, dp: float)->float:
	var dP: float = dp
	if P1 == 0:
		P1 = 1
	var Pr: float = dP / P1
	var Do: float = ori
	var Yo: float = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg: float = (MW * P1) / (0.08314 * T * Z)
	var kg_h: float = Do * Do * Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)
	var kg_s: float = kg_h / 3600
	kg_s = abs(kg_s)
	return kg_s


# Kalkulerer (gjennimsnitt) lekkasje under test i kg / s
func avg_leak_gas()->float:
	var m1: float = P2 * 100000 * volume * MW / (Z * R * T)
	var m2: float = PB * 100000 * volume * MW / (Z * R * T)
	var kg_s: float = (m1 - m2) / test_time
#	var n: float = (m2 * 1000) / MW
#	var z: float = (PB * 100000 * volume) / (n * (R / 1000) * K)
	kg_s = abs(kg_s)
	return kg_s


func calc_leak_rate_trend(pb, time, p2 = 1)->float:
	var m1: float = p2 * 100000 * volume * MW / (Z * R * T)
	var m2: float = pb * 100000 * volume * MW / (Z * R * T)
	if time == 0:
		return 0.0
	var kg_s: float = (m1 - m2) / time
	kg_s = abs(kg_s)
	return kg_s


# Kalkulering orifice diameter ved gitt lekkasje
func calc_orifice_gas(kgs: float)->float:
	var kgh = kgs * 3600
	var dP: float = P1 - P2
	if P1 == 0:
		P1 = 1
	var Pr: float = dP / P1
	var Yo: float = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg: float = (MW * P1) / (0.08314 * T * Z)
	var orifice = sqrt(kgh / (Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)))
	return orifice


# Regner ut sekunder det vil ta å nå 0 dP i testsegmentet ved en gitt orifice
# og lagrer punkter for å lage trend til forventet trykkutvikling
func simulate_gas(type: String, ori: float)->float:
	var sec: float = 0.0
	var count: int = 15
	var step: float = 0.01
	var p1 = P1
	var p2 = P2
	var gas_const = 100000 * volume * MW / (Z * R * T)
	if type == "Criteria":
		P2_crit.clear()
	else:
		P2_test.clear()
	if ori <= 0:
		return 0.0
	while p2 < p1:
		var m1: float = p2 * gas_const
		var leak = max_leak_gas(ori, p1 - p2)
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
func find_real_leak_gas(orifice, kgs):
	var numw = 0
	var numf = 0
	var p0 = P2								#Trykk før test
	var t0 := 0.0							#Klakulert test varighet
	var t = test_time						#Test varighet
	var p = PB								#Trykk etter test
	var ori_pre = kgs / (P1 - P2) * 25	#Predikerer en sikker økning av orifice før loopen
	var predicted_orifice = orifice + ori_pre #Orifice testraten tilsvarer
	var gas_const = 100000 * volume * MW / (Z * R * T)
	var d_g = (MW * P1) / (0.08314 * T * Z)
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
			return max_leak_gas(predicted_orifice, p0 - P2)

# Ekstra funksjon for test av optimalsiering
func find_real_leak_gas2(orifice, kgs):
#	var numw = 0
#	var numf = 0
	var p0 = P2								#Trykk før test
	var t0 := 0.0							#Klakulert test varighet
	var t = test_time						#Test varighet
	var p = PB								#Trykk etter test
	var ori_pre = kgs / (P1 - P2) * 25	#Predikerer en sikker økning av orifice før loopen
	var predicted_orifice = orifice + ori_pre #Orifice testraten tilsvarer
	var gas_const = 100000 * volume * MW / (Z * R * T)
	var d_g = (MW * P1) / (0.08314 * T * Z)
	var ab = 0.62 * 1.265
	var m0 = p0 * gas_const			#Masse ved teststart
	var dt := 2.0 					#Tidsenhet
	if kgs <= 0:
		return 0.0
#	print("Average: ",orifice)
#	print("Predicted: ",predicted_orifice)
#	Loop som øker størrelsen på orificen for hver ieterasjon og simulerer trykkoppbygging.
#	Når simulert sluttrykk (p0) når testens sluttrykk (p) og simulert testvarighet (t0)
#	er større eller lik testvarighet (test_time) returneres lekkasjeraten for tilsvarende orifice
	for i in range (1000):
#		numf += 1
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
			
#			numw += 1
		
		if p0 > p + 0.0001:
			dt *= 0.5
		else:
			if t0 <= test_time:
#				print("Time: ", t0)
#				print("Actual: ", predicted_orifice)
#				print("End pressure: ", p0)
#				print("Number of for: ", numf)
#				print("Number of while: ", numw)
				return max_leak_gas(predicted_orifice, p0 - P2)


func avg_leak_liquid_test():
	var t = [0, 10]
	var p = [0.5, 1.0]
	var k = 15000
	var d = []
	var q = []
	for i in p.size():
		if i == 0:
			d.append(847)
		else:
			var dn = (((p[i] - p[i-1]) / k) + 1) * d[i-1]
			d.append(dn)
			print(k)
	for i in d.size():
		if i > 0:
			var qn = ((d[i] - d[i-1]) / (t[i] - t[i-1])) * 0.03664
			q.append(qn)
	return q


func avg_leak_liquid():
	var t = test_time
	var dP = PB - P2
	var K = elasticity
	var d = dens
	var v = volume
	var dn = ((dP / K) + 1) * d
	print(K)
	var q = ((dn - d) / test_time) * v
	return q


func calc_orifice_liquid(kgs: float):
	var dis_coef = 0.6
	var ori = kgs / (dis_coef * 847 * sqrt(2 * P1 - P2 / 847))
	return ori


# Setter verdier for testmedie og ventil
func set_test_variables()->void:
	var valve : Dictionary = VALVES.valves[tag]
	volume = valve["volume"]
	
	if medie == "Nitrogen":
		MW = 28.01
		Z = 0.98
	else:
		MW = valve["MW"]
		Z = valve["Z"]
	
	if valve["type"] == "Valve":
		type = "Valve"
	else:
		type = "Check"
		Di = valve["Di"]
	
	if valve.has("Dens"):
		dens = valve["Dens"]
		elasticity = valve["K"]
	
	P2 = float($"%PressureStart".text) + 1
	P1 = float($"%PressureExternal".text) + 1
	PB = float($"%PressureAfter".text) + 1
	T = float($"%Temperatur".text) + 273.15
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
	
	var kgs_crit := 0.0
	var crit_orifice := 0.0
	var sec_crit := 0.0
	var kgs_test := 0.0
	var test_orifice := 0.0
	var kgs_real := 0.0
	var sec_test := 0.0
	
	if medie == "Gass" or medie == "Nitrogen":
		if type == "Valve":
			kgs_crit = 0.05
			crit_orifice = calc_orifice_gas(kgs_crit)
		else:
			kgs_crit = max_leak_gas(Di / 10, P1 - P2)
			crit_orifice = Di / 10
		sec_crit = simulate_gas("Criteria", crit_orifice)
		kgs_test = avg_leak_gas()
		test_orifice = calc_orifice_gas(kgs_test)
	#	var time_start = OS.get_ticks_msec()
	#	find_real_leak_gas(test_orifice, kgs_test)
	#	print("Loop time: ",OS.get_ticks_msec() - time_start, " ms\n")
	#	time_start = OS.get_ticks_msec()
		kgs_real = find_real_leak_gas2(test_orifice, kgs_test)
	#	print("Loop time: ",OS.get_ticks_msec() - time_start, " ms\n")
		test_orifice = calc_orifice_gas(kgs_real)
		sec_test = simulate_gas("Test", test_orifice)
	else:
		print(avg_leak_liquid_test())
		print(avg_leak_liquid())
	init_trend(sec_test, sec_crit)
	
	var a = results_box.instance()
	a.kgs_crit = kgs_crit
	a.kgs_test = kgs_real
	a.sec_crit = sec_crit
	a.sec_test = sec_test
	a.ori_crit = crit_orifice
	a.ori_test = test_orifice
	a.tag = tag
	a.result = P2_test
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


func _on_Medie_item_selected(index):
	medie = $"%Medie".get_item_text(index)
