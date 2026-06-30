import time
import random
import json
import paho.mqtt.client as mqtt
import requests

API_LOTES = "http://127.0.0.1:8000/lotes/"
API_REG = "http://127.0.0.1:8000/token"
BROKER = "broker.hivemq.com"
PORT = 1883

def autenticacion():
    try:
        data = {"username": "Epsilon", "password": "a12345"}
        response = requests.post(API_REG, data=data, timeout=5)

        if response.status_code == 200:
            token = response.json()["access_token"]
            header = {"Authorization": f"Bearer {token}"}
            return token, header
        else:
            print(f"[Fallo] Credenciales incorrectas: {response.status_code}")
            return None, None
    except requests.exceptions.RequestException:
        print("[Fallo] El backend no responde correctamente")
        return None, None

def obtener_lotes(token, header):
    if not token:
        print("El token no esta disponible.")
        return [1]
    
    try:
        print("Conectando con la base de datos para obtener la lista de lotes..")
        response = requests.get(API_LOTES, headers=header, timeout=5)
        if response.status_code == 200:
            lotes = response.json() 
            ids = [lote["id"] for lote in lotes]
            print("[EXITO] Lotes encontrados en la DB")
            return ids
        else:
            print(f"Error del servidor: {response.status_code}.")
            return [1]
    except requests.exceptions.RequestException as e:
        print(f"No se pudo conectar con el backend ({e}).")
        return [1]

#PARAMETROS TÉRMICOS INICIALES
temp_actual = -15.0
hum_actual = 55.0

#INICIALIZACIÓN
token, header = autenticacion()
list_lotes = obtener_lotes(token, header)

#Conexion al Broker MQTT
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2) 
client.connect(BROKER, PORT)
print("[MQTT] Conectado al BROKER con éxito.")
print("-" * 50)

#BUCLE DE ENVIO DE DATOS
while True:

    list_lotes = obtener_lotes(token, header)
    if not list_lotes:
        print("No se encontraron lotes registrados. Reintentando en 5s...")
        time.sleep(5)
        continue

    lote_actual = random.choice(list_lotes)

    #Logica termica
    salto = random.uniform(-4.0, 6.0)
    temp_actual += salto
    
    #Seguridad de simulación
    if temp_actual > 20 or temp_actual < -30:
        temp_actual = -15.0
    
    hum_actual = max(30, min(95, hum_actual + random.uniform(-3, 3)))

    #Redondeamos para el envío limpio
    temperatura = round(temp_actual, 2)
    humedad = round(hum_actual, 2) 


    payload = {
        "temperatura": temperatura,
        "humedad": humedad
    }

    TOPIC = f"fisi/nutritrack/lotes/{lote_actual}/telemetria"

    try:
        #PUBLICAMOS AL BRIDGE A TRAVÉS DEL BROKER
        client.publish(TOPIC, json.dumps(payload))
        print(f"[ENVIADO] Lote ID: {lote_actual} | Temp: {temperatura:6}°C | Hum: {humedad:6}%")
    except Exception as e:
        print(f"Error al enviar mensaje por MQTT: {e}")

    time.sleep(5)