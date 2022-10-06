extends ColorRect


var test = []
var crit = []
var distance = 0
var seconds = 0


func _ready():
	$TrendLine.color = Color(1.0, 1.0, 1.0)
	$TrendLine2.color = Color(1.0 , 0.0, 0.0)


func calculate_point_distance() -> void:
	if crit.size() > test.size():
		distance = rect_size.x / (crit.size() -1)
	else:
		distance = rect_size.x / (test.size() -1)
	$TrendLine.distance = distance
	$TrendLine2.distance = distance
	print(seconds)
