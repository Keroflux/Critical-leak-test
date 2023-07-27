extends Node2D


var data_points: Array = []
var distance: float
var new_dist_x: float = 0
var scale_y: float = 0
var max_value: float = 100
var min_value: float = 0
var pos: Vector2 = Vector2(0,0)
var trend: Array = [Vector2(0,0), Vector2(0,0)]
var color: Color = Color(1.0, 1.0, 1.0)
var parent: Node


func _ready() -> void:
	parent = get_parent()
#	calculate_point_distance()
	pos.x = 0
	pos.y = parent.size.y
	var minmax: float = max_value - min_value
	scale_y = parent.size.y / minmax


func _draw() -> void:
	draw_polyline(trend, color, 2.0)


func trend_run() -> void:
	redraw_trend()
	update()


func draw_trend() -> void:
	new_dist_x = 0
	trend.clear()
	for i in data_points:
		var a: float = (-i + min_value) * scale_y
		trend.append(Vector2(new_dist_x, parent.size.y + a))
		new_dist_x += distance



func redraw_trend() -> void:
	if data_points.size() > 1:
#		calculate_point_distance()
		find_max()
		draw_trend()


func calculate_point_distance() -> void:
	distance = parent.size.x / (data_points.size() -1)


func find_max():
	scale_y = 0
	max_value = -9999999
	min_value = 9999999
	for i in data_points:
		if i > max_value:
			max_value = i
		if i < min_value:
			min_value = i
	
	var minmax = max_value - min_value
	if minmax == 0:
		minmax = 1
	scale_y = parent.size.y / (minmax)
