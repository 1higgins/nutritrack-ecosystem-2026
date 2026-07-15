extends Node2D

# Referencias a los nodos de la escena actual
@onready var mqtt_client = $Truck/MQTT 
@onready var truck_sprite = $Truck # Si el Truck ya tiene el sprite, usa solo $Truck. Si tiene un hijo llamado Sprite2D, usa $Truck/Sprite2D
@onready var label_temp = $CanvasLayer/HUD/PanelInfo/VBoxInfo/LabelTemp
@onready var label_estado = $CanvasLayer/HUD/PanelInfo/VBoxInfo/LabelEstado

var esta_conectado = false

func _ready():
	# Conectamos las señales del nodo MQTT que está en Truck
	mqtt_client.broker_connected.connect(_on_broker_conectado)
	mqtt_client.received_message.connect(_on_mensaje_recibido)
	
	print("Intentando conectar a HiveMQ...")
	mqtt_client.connect_to_broker("wss://broker.hivemq.com:8884/mqtt")

func _on_broker_conectado():
	print("¡Éxito! Conectado al broker MQTT.")
	mqtt_client.subscribe("fisi/nutritrack/#")
	esta_conectado = true 

func _on_mensaje_recibido(topic, message):
	var json = JSON.parse_string(message)
	if json != null and json.has("temperatura"):
		var temp = float(json["temperatura"])
		actualizar_interfaz(temp)

func actualizar_interfaz(temp):
	# Actualizar texto del HUD
	label_temp.text = "Temp: " + str(temp) + " °C"
	
	# Lógica de colores (Camión y texto)
	if temp <= -15.0:
		label_estado.text = "Estado: OK (Congelado)"
		truck_sprite.modulate = Color(0, 0, 1) # Azul
	elif temp > -15.0 and temp <= 0.0:
		label_estado.text = "Estado: ADVERTENCIA"
		truck_sprite.modulate = Color(0, 1, 0) # Verde
	else:
		label_estado.text = "Estado: CRÍTICO"
		truck_sprite.modulate = Color(1, 0, 0) # Rojo
