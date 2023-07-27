extends ColorRect

var root
var test = []
var crit = []
var distance = 0
var seconds = 0
var max_pressure = 0
var min_pressure = 0
var show_marker := false
var sec_mark = preload("res://UI/SecondsMarker.tscn")
var pres_mark = preload("res://UI/PressureMark.tscn")
var marker_label = preload("res://UI/MarkerLabel.tscn")

var marker_s : Label
var marker_p : Label
var marker_kgs : Label

var p_start : float
var gc : float


func _ready():
	set_process(false)
	root = get_tree().get_root().get_node("Main")
	$TrendLine.color = Color(1.0, 1.0, 1.0)
	$TrendLine2.color = Color(1.0 , 0.0, 0.0)
	place_sec_marks()


func _process(_delta):
	queue_redraw()


func _draw():
	if show_marker:
		var mouse = get_local_mouse_position()
		var mouse_norm_x = mouse.x / size.x
		var mouse_norm_y = 1 - mouse.y / size.y
		var sec = mouse_norm_x * seconds
		var pres = (mouse_norm_y * (max_pressure - min_pressure) + min_pressure)
		var kgs = calc_leak_rate_trend(pres+1, sec, gc, p_start)
		
		draw_line(Vector2(mouse.x, 0), Vector2(mouse.x, size.y), Color(0.094118, 0.513726, 0.917647))
		draw_line(Vector2(0, mouse.y), Vector2(size.x, mouse.y), Color(0.094118, 0.513726, 0.917647))
		
		marker_s.position = Vector2(mouse.x - (marker_s.size.x / 2), size.y)
		marker_s.text = str(snapped(sec, 0.01))
		marker_p.position = Vector2(0 - marker_p.size.x, mouse.y - (marker_p.size.y / 2))
		marker_p.text = str(snapped(pres, 0.1))
		marker_kgs.position = Vector2(mouse.x - (marker_kgs.size.x / 2), -marker_kgs.size.y)
		marker_kgs.text = str(snapped(kgs, 0.001))


func calc_leak_rate_trend(p_end, time, gas_c, p_start = 1)->float:
	var m1: float = p_start * gas_c
	var m2: float = p_end * gas_c
	if time == 0:
		return 0.0
	var kg_s: float = (m1 - m2) / time
	kg_s = abs(kg_s)
	return kg_s


func calculate_point_distance() -> void:
	if crit.size() > test.size():
		distance = size.x / (crit.size() -1)
	else:
		distance = size.x / (test.size() -1)
	$TrendLine.distance = distance
	$TrendLine2.distance = distance


func place_sec_marks():
	var sec = seconds / 5
	var pres = (max_pressure - min_pressure) / 5
	var x = size.x / 5
	var y = size.y / 5
	
	for child in $Marks.get_children():
		child.queue_free()
	
	for i in 4:
		var a = sec_mark.instantiate()
		a.position.x = x * (i + 1) - a.size.x / 2 + 2
		a.position.y = size.y + 10
		a.size.y = size.y
		a.get_child(0).text = str(snappedf(sec * (i + 1.0), 0.01))
		$Marks.add_child(a)
	
	for i in 4:
		var a = pres_mark.instantiate()
		a.position.y = (-y * (i + 1)) + size.y + 8
		a.size.x = size.x
		a.get_child(0).text = str(snappedf(pres * (i + 1.0) + min_pressure, 0.01))
		$Marks.add_child(a)
	
	$MinPressure.text = str(min_pressure)
	$MaxPressure.text = str(snappedf(max_pressure, 0.01))
	$MinSeconds.text = str(0)
	$MaxSeconds.text = str(snappedf(seconds, 0.01))


func _on_Trend_mouse_entered():
	set_process(true)
	show_marker = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	marker_s = marker_label.instantiate()
	add_child(marker_s)
	marker_p = marker_label.instantiate()
	add_child(marker_p)
	marker_kgs = marker_label.instantiate()
	add_child(marker_kgs)


func _on_Trend_mouse_exited():
	set_process(false)
	show_marker = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	marker_s.queue_free()
	marker_p.queue_free()
	marker_kgs.queue_free()


func _on_Trend_resized():
	place_sec_marks()
	$"%TrendLine".trend_run()
	$"%TrendLine2".trend_run()
