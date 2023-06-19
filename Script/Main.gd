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
const K: float = 273.15

var P2_crit: Array = []			# Lagring av trend ved integrering av kriterie
var P2_test: Array = []			# Lagring av trend ved integrering av test

var search_box = preload("res://UI/ValveSelector.tscn")
var results_box = preload("res://UI/ResultsPage.tscn")


# Kalkulerer lekkasjekriterie i kg / s
func max_leak_gas(ori: float, d_p: float, p_out, mol_w, kelvin, comp_f)->float:
	var Pr: float = d_p / p_out
	var Do: float = ori
	var Yo: float = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg: float = (mol_w * p_out) / (0.08314 * kelvin * comp_f)
	var kg_h: float = Do * Do * Yo * 0.62 * 1.265 * pow((d_p * dg), 0.5)
	var kg_s: float = kg_h / 3600
	kg_s = abs(kg_s)
	return kg_s


# Kalkulerer (gjennimsnitt) lekkasje under test i kg / s
func avg_leak_gas(p_in, p_end, vol, time, kelvin, comp_f, mol_w)->float:
	var g_c = 100000 * vol * mol_w / (comp_f * R * kelvin)
	var m1: float = p_in * g_c
	var m2: float = p_end * g_c
	var kg_s: float = (m1 - m2) / time
#	var n: float = (m2 * 1000) / MW
#	var z: float = (PB * 100000 * volume) / (n * (R / 1000) * K)
	kg_s = abs(kg_s)
	return kg_s


# Kalkulering orifice diameter ved gitt lekkasje
func calc_orifice_gas(kg_s: float, p_out, p_in, mol_w, kelvin, comp_f)->float:
	var kg_h = kg_s * 3600
	var dP: float = p_out - p_in
	var Pr: float = dP / p_out
	var Yo: float = 1.008 - 0.338 * Pr
	if Pr < 0.29:
		Yo = 1 - 0.31 * Pr
	var dg: float = (mol_w * p_out) / (0.08314 * kelvin * comp_f)
	var orifice = sqrt(kg_h / (Yo * 0.62 * 1.265 * pow((dP * dg), 0.5)))
	return orifice


# Regner ut sekunder det vil ta å nå 0 dP i testsegmentet ved en gitt orifice
# og lagrer punkter for å lage trend til forventet trykkutvikling
func simulate_gas(type: String, ori: float, p_out, p_in, vol, mol_w, comp_f, kelvin)->float:
	var sec: float = 0.0
	var count: int = 15
	var step: float = 0.01
	var p1 = p_out
	var p2 = p_in
	var gas_const = 100000 * vol * mol_w / (comp_f * R * kelvin)
	if type == "Criteria":
		P2_crit.clear()
	else:
		P2_test.clear()
	if ori <= 0:
		return 0.0
	while p2 < p1:
		var m1: float = p2 * gas_const
		var leak = max_leak_gas(ori, p1 - p2, p_out, mol_w, kelvin, comp_f)
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


# Ekstra funksjon for test av optimalsiering
func find_real_leak_gas2(orifice, kg_s, p_out, p_in, p_end, time, vol, mol_w, comp_f, kelvin):
#	var numw = 0
#	var numf = 0
	var p0 = p_in								#Trykk før test
	var t0 := 0.0							#Klakulert test varighet
	var p = p_end								#Trykk etter test
	var ori_pre = kg_s / (p_out - p_in) * 25	#Predikerer en sikker økning av orifice før loopen
	var predicted_orifice = orifice + ori_pre #Orifice testraten tilsvarer
	var gas_const = 100000 * vol * mol_w / (comp_f * R * kelvin)
	var d_g = (mol_w * p_out) / (0.08314 * kelvin * comp_f)
	var ab = 0.62 * 1.265
	var m0 = p0 * gas_const			#Masse ved teststart
	var dt := 2.0 					#Tidsenhet
	if kg_s <= 0:
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
			var dP: float = p_out - p0
			var Pr: float = dP / p_out
			var Do : float = predicted_orifice
			var Yo: float = 1.008 - 0.338 * Pr
			if Pr < 0.29:
				Yo = 1 - 0.31 * Pr
			var dg: float = d_g
			var kg_h: float = Do * Do * Yo * ab * pow((dP * dg), 0.5)
			var kgs: float = kg_h / 3600
#			kg_s = abs(kg_s)
			m_0 += kgs * dt
			p0 = m_0 / gas_const
			t0 += dt
			
#			numw += 1
		
		if p0 > p + 0.0001:
			dt *= 0.5
		else:
			if t0 <= time:
#				print("Time: ", t0)
#				print("Actual: ", predicted_orifice)
#				print("End pressure: ", p0)
#				print("Number of for: ", numf)
#				print("Number of while: ", numw)
				return max_leak_gas(predicted_orifice, p0 - p_in, p_out, mol_w, kelvin, comp_f)


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


# Sender verdier til trend og starter tegning
func init_trend(p_out, p_in, sec_test = 0, sec_crit = 0)->void: # TODO: inverter trenden ved negativ trykktest
	$"%Trend".test = P2_test
	$"%Trend".crit = P2_crit
	if sec_test >= sec_crit:
		$"%Trend".seconds = sec_test
	else:
		$"%Trend".seconds = sec_crit
	$"%Trend".max_pressure = p_out - 1
	$"%Trend".min_pressure = p_in - 1
	$"%TrendLine".data_points = P2_test
	$"%TrendLine2".data_points = P2_crit


func run_trend():
	$"%Trend".calculate_point_distance()
	$"%Trend".place_sec_marks()
	$"%TrendLine".trend_run()
	$"%TrendLine2".trend_run()


# Klikkevent fra "kalkuler" knappen
func _run_calculations()->void:
	# Sett variabler fra testen
	var time = float($"%TestTime".text)
	var P_1 = float($"%PressureExternal".text) + 1
	var P_2 = float($"%PressureStart".text) + 1
	var P_B = float($"%PressureAfter".text) + 1
	var T_K = float($"%Temperatur".text) + K
	if P_2 > P_1: # Positiv dp? Flip trykkene
		P_1 = float($"%PressureStart".text) + 1
		P_2 = float($"%PressureExternal".text) + 1
		P_B = float($"%PressureStart".text) + 1
	
	var z := 0.0
	var M_W := 28.01
	var d_i := 0.0
	var density := 0.0
	var elast := 0.0
	
	var valve : Dictionary = VALVES.valves[tag]
	var test_volume = valve["volume"]
	if not medie == "Nitrogen":
		M_W = valve["MW"]
		z = valve["Z"]
	if valve["type"] == "check":
		d_i = valve["Di"]
	if valve.has("Dens"):
		density = valve["Dens"]
		elast = valve["K"]
	
	# Sjekk om det er fare for å lage et sort hull
	var zero_list := [P_2, P_1, P_B, T_K, time, P_1-P_2]
	for i in zero_list:
		if i <= 0:
			return
	
	# Variabler for testresultat
	var kgs_crit := 0.0
	var crit_orifice := 0.0
	var sec_crit := 0.0
	var kgs_test := 0.0
	var test_orifice := 0.0
	var kgs_real := 0.0
	var sec_test := 0.0
	
	# Kjør simulering
	if medie == "Gass" or medie == "Nitrogen":
		if type == "valve":
			kgs_crit = 0.05
			crit_orifice = calc_orifice_gas(kgs_crit, P_1, P_2, M_W, T_K, z)
		else:
			kgs_crit = max_leak_gas(d_i / 10, P_1 - P_2, P_1, M_W, T_K, z)
			crit_orifice = d_i / 10
		sec_crit = simulate_gas("Criteria", crit_orifice, P_1, P_2, test_volume, M_W, z, T_K)
		kgs_test = avg_leak_gas(P_2, P_B, test_volume, time, T_K, z, M_W)
		test_orifice = calc_orifice_gas(kgs_test, P_1, P_2, M_W, T_K, z)
	#	var time_start = OS.get_ticks_msec()
	#	find_real_leak_gas(test_orifice, kgs_test)
	#	print("Loop time: ",OS.get_ticks_msec() - time_start, " ms\n")
	#	time_start = OS.get_ticks_msec()
		kgs_real = find_real_leak_gas2(test_orifice, kgs_test, P_1, P_2, P_B, time, test_volume, M_W, z, T_K)
	#	print("Loop time: ",OS.get_ticks_msec() - time_start, " ms\n")
		test_orifice = calc_orifice_gas(kgs_real, P_1, P_2, M_W, T_K, z)
		sec_test = simulate_gas("Test", test_orifice, P_1, P_2, test_volume, M_W, z, T_K)
	else:
		print(avg_leak_liquid_test())
		print(avg_leak_liquid())
	
	$"%Trend".gc = 100000 * test_volume * M_W / (z* R * T_K)
	$"%Trend".p2 = P_2
	init_trend(P_1, P_2, sec_test, sec_crit)
	run_trend()
	
	# Vis resultatet av simuleringen
	var a = results_box.instance()
	a.kgs_crit = kgs_crit
	a.kgs_test = kgs_real
	a.sec_crit = sec_crit
	a.sec_test = sec_test
	a.ori_crit = crit_orifice
	a.ori_test = test_orifice
	a.tag = tag
	a.result = P2_test
	a.type = type
	add_child(a)


# Klikkevent fra netrekkslisten
func _set_valve(valve)->void:
	tag = valve
	type = VALVES.valves[tag]["type"]
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
	run_trend()


func _open_Valve_search():
	var a = search_box.instance()
	add_child(a)


func _on_Medie_item_selected(index):
	medie = $"%Medie".get_item_text(index)