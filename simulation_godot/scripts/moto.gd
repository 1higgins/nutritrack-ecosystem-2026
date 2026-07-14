extends CharacterBody2D

# Referencias a los nodos
@onready var mqtt_client = $MQTT 
@onready var sprite_moto = $Sprite2D

const VELOCIDAD = 100.0
const INTERVALO_ENVIO = 5.0 
var tiempo_acumulado = 0.0

# NUEVO: Bloqueo de seguridad
var esta_conectado = false 

func _ready():
	# 1. Conectamos las señales
	mqtt_client.broker_connected.connect(_on_broker_conectado)
	mqtt_client.received_message.connect(_on_mensaje_recibido)
	
	# 2. Conectar al broker (Añadido tcp:// por seguridad del plugin)
	print("Intentando conectar a HiveMQ...")
	mqtt_client.connect_to_broker("ws://broker.hivemq.com:8000/mqtt")

func _on_broker_conectado():
	print("¡Éxito! Godot conectado al broker MQTT. Suscribiendo...")
	
	# Usamos "#" para escuchar todo el tráfico de nutritrack y evitar bugs del plugin
	mqtt_client.subscribe("fisi/nutritrack/#")
	
	esta_conectado = true 

func _physics_process(delta):
	var direccion_x = Input.get_axis("ui_left", "ui_right")
	var direccion_y = Input.get_axis("ui_up", "ui_down")
	
	velocity.x = direccion_x * VELOCIDAD
	velocity.y = direccion_y * VELOCIDAD
	
	move_and_slide()

func _process(delta):
	# NUEVO: Si no estamos conectados, no hacemos nada más
	if not esta_conectado:
		return
		
	# Control de envío cada 5 segundos
	tiempo_acumulado += delta
	if tiempo_acumulado >= INTERVALO_ENVIO:
		enviar_datos()
		tiempo_acumulado = 0.0

func enviar_datos():
	var mensaje = {
		"moto_id": "moto_01",
		"posicion": {"x": position.x, "y": position.y}
	}
	var json_string = JSON.stringify(mensaje)
	mqtt_client.publish("sensores/moto", json_string)

# --- LÓGICA DE RECEPCIÓN Y COLOR ---

func _on_mensaje_recibido(topic, message):
	# Verificamos si el tópico empieza con la ruta base de telemetría
	if topic.begins_with("fisi/nutritrack/lotes/") and topic.ends_with("/telemetria"):
		var json = JSON.parse_string(message)
		
		if json != null and json.has("temperatura"):
			var temp = float(json["temperatura"])
			actualizar_color(temp)

func actualizar_color(temp):
	print("Temperatura recibida: ", temp, " °C - Cambiando color...")
	
	if temp <= -15.0:
		sprite_moto.modulate = Color(0, 0, 1) # Azul (Frío)
	elif temp > -10.0 and temp <= 15.0:
		sprite_moto.modulate = Color(0, 1, 0) # Verde (Normal)
	else:
		sprite_moto.modulate = Color(1, 0, 0) # Rojo (Caliente)
