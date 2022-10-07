extends ColorRect


var test = []
var crit = []
var distance = 0
var seconds = 0
var max_pressure = 0
var min_pressure = 0
var sec_mark = preload("res://SecondsMarker.tscn")
var pres_mark = preload("res://PressureMark.tscn")


func _ready():
	$TrendLine.color = Color(1.0, 1.0, 1.0)
	$TrendLine2.color = Color(1.0 , 0.0, 0.0)
	place_sec_marks()


func calculate_point_distance() -> void:
	if crit.size() > test.size():
		distance = rect_size.x / (crit.size() -1)
	else:
		distance = rect_size.x / (test.size() -1)
	$TrendLine.distance = distance
	$TrendLine2.distance = distance


func place_sec_marks():
	var sec = seconds / 5
	var pres = max_pressure / 5
	var x = rect_size.x / 5
	var y = rect_size.y / 5
	
	for child in $Marks.get_children():
		child.queue_free()
	
	for i in 4:
		var a = sec_mark.instance()
		a.rect_position.x = x * (i + 1) - a.rect_size.x / 2
		a.rect_position.y = rect_size.y
		a.rect_size.y = rect_size.y
		a.get_child(0).text = str(stepify(sec * (i + 1), 0.01))
		$Marks.add_child(a)
	
	for i in 4:
		var a = pres_mark.instance()
		a.rect_position.y = (-y * (i + 1)) + rect_size.y
		a.rect_size.x = rect_size.x
		a.get_child(0).text = str(stepify(pres * (i + 1), 0.01))
		$Marks.add_child(a)
	
	$MinPressure.text = str(min_pressure)
	$MaxPressure.text = str(max_pressure)
	$MinSeconds.text = str(0)
	$MaxSeconds.text = str(seconds)



