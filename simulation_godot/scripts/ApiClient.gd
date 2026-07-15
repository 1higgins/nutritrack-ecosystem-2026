extends Node
## ApiClient (Autoload / Singleton)
## Se conecta al Backend de NutriTrack (FastAPI) para:
##   1. Autenticarse vía /token (OAuth2PasswordRequestForm -> JWT)
##   2. Hacer polling periódico a /lotes/ con el Bearer Token
##   3. Emitir señales cuando cambia el estado térmico de un lote
##
## Cualquier nodo de la escena (el camión, el HUD) se suscribe a las señales
## de abajo, así todo queda desacoplado del backend real.

signal estado_actualizado(lote_id, temperatura, humedad, estado)
signal conexion_error(mensaje: String)
signal conexion_ok()

# --- CONFIGURACIÓN (edítala aquí o desde el Inspector si conviertes esto en escena) ---
@export var backend_url: String = "http://127.0.0.1:8000"
@export var username: String = "Epsilon"
@export var password: String = "a12345"
@export var poll_interval: float = 5.0          # mismo intervalo que mqtt_sender.py
@export var lote_id_objetivo: int = -1           # -1 = monitorea automáticamente el lote en peor estado

var _token: String = ""
var _reintentando_auth: bool = false

@onready var auth_request: HTTPRequest = $AuthRequest
@onready var lotes_request: HTTPRequest = $LotesRequest
@onready var _timer: Timer = $PollTimer


func _ready() -> void:
	auth_request.request_completed.connect(_on_auth_completed)
	lotes_request.request_completed.connect(_on_lotes_completed)
	_timer.wait_time = poll_interval
	_timer.timeout.connect(_poll)
	_autenticar()


func _autenticar() -> void:
	_reintentando_auth = true
	var body := "username=%s&password=%s" % [username.uri_encode(), password.uri_encode()]
	var headers := ["Content-Type: application/x-www-form-urlencoded"]
	var err := auth_request.request(backend_url + "/token", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		emit_signal("conexion_error", "No se pudo iniciar la petición de login (%s)" % err)


func _on_auth_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_reintentando_auth = false
	if response_code != 200:
		emit_signal("conexion_error", "Login rechazado por el backend (código %d)" % response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json is Dictionary and json.has("access_token"):
		_token = json["access_token"]
		emit_signal("conexion_ok")
		_timer.start()
		_poll()
	else:
		emit_signal("conexion_error", "Respuesta de /token inválida")


func _poll() -> void:
	if _token == "":
		if not _reintentando_auth:
			_autenticar()
		return

	var headers := ["Authorization: Bearer %s" % _token]
	var err := lotes_request.request(backend_url + "/lotes/", headers, HTTPClient.METHOD_GET)
	if err != OK:
		emit_signal("conexion_error", "No se pudo conectar con /lotes/ (%s)" % err)


func _on_lotes_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 401:
		# Token expirado (dura 240 min según auth.py) -> reautenticar
		_token = ""
		_autenticar()
		return

	if response_code != 200:
		emit_signal("conexion_error", "El backend respondió %d en /lotes/" % response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if typeof(json) != TYPE_ARRAY or json.is_empty():
		emit_signal("conexion_error", "Aún no hay lotes registrados en el backend")
		return

	var lote_elegido = _elegir_lote(json)
	if lote_elegido == null:
		return

	emit_signal(
		"conexion_ok"
	)
	emit_signal(
		"estado_actualizado",
		lote_elegido.get("id", -1),
		lote_elegido.get("ultima_temperatura", null),
		null,
		str(lote_elegido.get("estado_actual", "DESCONOCIDO"))
	)


func _elegir_lote(lotes: Array):
	# Si se pidió un lote específico, se busca ese.
	if lote_id_objetivo != -1:
		for lote in lotes:
			if int(lote.get("id", -1)) == lote_id_objetivo:
				return lote
		return null

	# Si no, se prioriza mostrar el lote más crítico (para que la simulación
	# siempre refleje la alerta más urgente del almacén).
	var mejor_critico = null
	var mejor_alerta = null
	for lote in lotes:
		var estado := _normalizar(str(lote.get("estado_actual", "")))
		if estado.find("CRIT") != -1:
			mejor_critico = lote
		elif estado.find("ALERT") != -1 and mejor_alerta == null:
			mejor_alerta = lote

	if mejor_critico != null:
		return mejor_critico
	if mejor_alerta != null:
		return mejor_alerta
	return lotes[0]


func _normalizar(texto: String) -> String:
	# Quita tildes básicas y pasa a mayúsculas para comparar estados sin
	# depender de si el backend manda "CRÍTICO", "CRITICO" o "critico".
	var t := texto.to_upper()
	t = t.replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U")
	return t
