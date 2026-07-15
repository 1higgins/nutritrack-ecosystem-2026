extends Sprite2D
## Camión / pallet refrigerado.
## Escucha al ApiClient y cambia de color según el estado_actual del lote:
##   OPTIMO / NORMAL -> azul (frío correcto)
##   ALERTA          -> ámbar (advertencia)
##   CRITICO         -> rojo parpadeante (ruptura de cadena de frío)

@export var color_normal: Color = Color(0.35, 0.62, 1.0)
@export var color_alerta: Color = Color(1.0, 0.65, 0.05)
@export var color_critico: Color = Color(1.0, 0.15, 0.15)
@export var blink_speed: float = 0.35
@export var bounce_height: float = 6.0
@export var bounce_speed: float = 4.0

var _estado_actual: String = "OPTIMO"
var _blink_on: bool = false
var _blink_timer: float = 0.0
var _t: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	_base_y = position.y
	modulate = color_normal
	ApiClient.estado_actualizado.connect(_on_estado_actualizado)


func _on_estado_actualizado(_lote_id, _temperatura, _humedad, estado: String) -> void:
	_estado_actual = _normalizar(estado)


func _process(delta: float) -> void:
	# Pequeño rebote constante para dar sensación de movimiento del vehículo
	# sobre el asfalto (el camión no se traslada, es la carretera la que
	# se desplaza, pero el rebote refuerza la ilusión de "transporte").
	_t += delta * bounce_speed
	position.y = _base_y + sin(_t) * (bounce_height * 0.1)

	if _estado_actual.find("CRIT") != -1:
		_blink_timer += delta
		if _blink_timer >= blink_speed:
			_blink_timer = 0.0
			_blink_on = not _blink_on
		modulate = color_critico if _blink_on else Color(1, 1, 1, 1)
	elif _estado_actual.find("ALERT") != -1:
		modulate = color_alerta
	else:
		modulate = color_normal


func _normalizar(texto: String) -> String:
	var t := texto.to_upper()
	t = t.replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")
	return t
