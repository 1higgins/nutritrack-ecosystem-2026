extends Node2D
## Genera marcas de carril y las desplaza de derecha a izquierda en bucle
## infinito. Como el camión se queda fijo en pantalla, esto crea la ilusión
## de que el vehículo avanza por la carretera sin parar.

@export var scroll_speed: float = 320.0
@export var dash_width: float = 60.0
@export var dash_height: float = 8.0
@export var gap: float = 50.0
@export var road_width: float = 1280.0

var _dashes: Array[ColorRect] = []
var _step: float = 0.0


func _ready() -> void:
	_step = dash_width + gap
	var count := int(road_width / _step) + 2
	for i in range(count):
		var dash := ColorRect.new()
		dash.color = Color(1, 1, 1, 0.9)
		dash.size = Vector2(dash_width, dash_height)
		dash.position = Vector2(i * _step, -dash_height / 2.0)
		add_child(dash)
		_dashes.append(dash)


func _process(delta: float) -> void:
	var total_width := _step * _dashes.size()
	for dash in _dashes:
		dash.position.x -= scroll_speed * delta
		if dash.position.x <= -dash_width:
			dash.position.x += total_width
