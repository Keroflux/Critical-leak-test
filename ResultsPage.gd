extends Control


var kgs_crit = 0
var kgs_test = 0
var sec_crit = 0
var sec_test = 0
var ori_test = 0
var ori_crit = 0
var tag = ""


func _ready():
	$"%Tag/Result".text = " " + tag
	$"%CriteriaKGS/Result".text = " " + str(kgs_crit) + " kg / s"
	$"%TestKGS/Result".text = " " + str(kgs_test) + " kg / s"
	$"%CriteriaTime/Result".text = " " + str(sec_crit) + " Sekunder"
	$"%TestTime/Result".text = " " + str(sec_test) + " Sekunder"
	$"%CriteriaOri/Result".text = " " + str(ori_crit) + " mm"
	$"%TestOri/Result".text = " " + str(ori_test) + " mm"
	if kgs_test > kgs_crit:
		$"%Accepted/Result".text = " Underkjent"


func _on_Close_pressed():
	queue_free()
