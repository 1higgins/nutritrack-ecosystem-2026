import time
import json
import requests
import paho.mqtt.client as mqtt

API_TELEMETRIA = "http://127.0.0.1:8000/telemetria/" 
API_REG = "http://127.0.0.1:8000/token"
BROKER = "broker.hivemq.com"
PORT = 1883

TOPIC_SUSCRIPCION = "fisi/nutritrack/lotes/+/telemetria"

#AUTENTICACIÓN 
def autenticacion_bridge():
    try:
        print("[BRIDGE] Autenticando con el Backend para obtener permisos de escritura...")
        data = {"username": "Epsilon", "password": "a12345"}
        response = requests.post(API_REG, data=data, timeout=5)

        if response.status_code == 200:
            token = response.json()["access_token"]
            header = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
            print("[ÉXITO BRIDGE] Token JWT obtenido correctamente.")
            return header
        else:
            print(f"[FALLO BRIDGE] Credenciales incorrectas: {response.status_code}")
            return {}
    except requests.exceptions.RequestException:
        print("[FALLO BRIDGE] El backend no responde.")
        return {}


def on_connect(client, userdata, flags, rc, properties=None):
    print(f"\n[BRIDGE] Conectado exitosamente al Broker MQTT.")
    # Nos suscribimos al canal masivo de lotes
    client.subscribe(TOPIC_SUSCRIPCION)
    print(f"[BRIDGE] Suscrito al tópico: {TOPIC_SUSCRIPCION}")
    print("=" * 60)

def on_message(client, userdata, msg):
    """Se ejecuta cada vez que el Sender envía un mensaje y el Broker nos lo pasa."""
    try:
        #Extraer el ID del lote desde la estructura del topico recibido
        partes_del_topico = msg.topic.split('/')
        lote_id = int(partes_del_topico[3])

        #Decodificar el JSON plano que envió el Sender
        payload_recibido = json.loads(msg.payload.decode())
        temp = payload_recibido.get("temperatura")
        hum = payload_recibido.get("humedad")

        print(f"\n[MQTT RECIBIDO] Lote ID: {lote_id} | Temp: {temp}°C | Hum: {hum}%")

        #Preparar el Payload estructurado para el backend
        payload_para_backend = {
            "temperatura": temp,
            "humedad": hum,
            "lote_id": lote_id

        }

        #Enviar el dato mediante HTTP POST hacia la base de datos 
        print(f"[HTTP POST] Enviando datos del Lote {lote_id} hacia la DB")
        response = requests.post(API_TELEMETRIA, json=payload_para_backend, headers=header_global, timeout=5)

        if response.status_code == 201 or response.status_code == 200:
            print(f"[DB GUARDADO] Telemetría registrada con éxito para el Lote {lote_id}.")
        else:
            print(f"[HTTP ERROR {response.status_code}] El Backend rechazó los datos: {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"[FALLO DE RED] No se pudo conectar con FastAPI. ¿El backend está encendido? ({e})")
    except Exception as e:
        print(f"[ERROR GENERAL] Error procesando el mensaje: {e}")

#Flujo del BRIDGE

#Obtenemos las cabeceras de autenticación globales para el Bridge
header_global = autenticacion_bridge()

bridge_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)

#Asignamos las funciones callback que definimos arriba
bridge_client.on_connect = on_connect
bridge_client.on_message = on_message

#Nos conectamos al Broker
bridge_client.connect(BROKER, PORT)

#Iniciamos el bucle permanente de escucha de MQTT
print("[BRIDGE] Iniciando bucle persistente de escucha...")
try:
    bridge_client.loop_forever()
except KeyboardInterrupt:
    print("\n[SISTEMA] Bridge apagado por el usuario.")