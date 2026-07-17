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
        print("[FALLO] El token no esta disponible.")
        return []

    try:
        response = requests.get(API_LOTES, headers=header, timeout=5)
        if response.status_code == 200:
            lotes = response.json()
            ids = [lote["id"] for lote in lotes]
            if ids:
                print(f"[EXITO] {len(ids)} lote(s) encontrados en la DB: {ids}")
            else:
                print("[INFO] Conexion OK, pero la DB no tiene lotes registrados todavia.")
            return ids
        else:
            print(f"[FALLO] El backend respondio con error {response.status_code}: {response.text}")
            return []
    except requests.exceptions.RequestException as e:
        print(f"[FALLO] No se pudo conectar con el backend ({e}).")
        return []


def crear_lote_demo(header):
    """
    Si la DB no tiene ningun lote, crea uno de prueba automaticamente
    (requiere que el usuario autenticado tenga rol 'admin' u 'OPA',
    como es el caso de Epsilon). Esto evita tener que ir a Swagger (/docs)
    a mano cada vez que se reinicia la base de datos.

    Ajusta los campos del payload si tu schemas.LoteCreate usa otros nombres.
    """
    payload = {
        "codigo_lote": f"DEMO-{random.randint(1000, 9999)}",
        "producto": "Lote de prueba (IoT sender)",
        "temp_min_ideal": -20.0,
        "temp_max_ideal": -10.0,
        "password_lote": "demo123"
    }
    try:
        print("[INFO] Intentando crear un lote demo automaticamente...")
        response = requests.post(API_LOTES, json=payload, headers=header, timeout=5)
        if response.status_code == 201:
            nuevo_id = response.json().get("id")
            print(f"[EXITO] Lote demo creado con ID {nuevo_id} (codigo: {payload['codigo_lote']})")
            return [nuevo_id]
        else:
            print(f"[FALLO] No se pudo crear el lote demo ({response.status_code}): {response.text}")
            print("        Revisa si schemas.LoteCreate pide campos distintos a los de este script,")
            print("        o crea un lote manualmente en http://127.0.0.1:8000/docs")
            return []
    except requests.exceptions.RequestException as e:
        print(f"[FALLO] Error de red al crear el lote demo ({e}).")
        return []

#PARAMETROS TÉRMICOS INICIALES
temp_actual = -15.0
hum_actual = 55.0

#INICIALIZACIÓN
token, header = autenticacion()

if not token:
    print("[FATAL] No se pudo autenticar contra el backend. Verifica que este corriendo en", API_REG)
    raise SystemExit(1)

list_lotes = obtener_lotes(token, header)
if not list_lotes:
    list_lotes = crear_lote_demo(header)

#Conexion al Broker MQTT
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2) 
client.connect(BROKER, PORT)
print("[MQTT] Conectado al BROKER con éxito.")
print("-" * 50)

#BUCLE DE ENVIO DE DATOS
while True:

    list_lotes = obtener_lotes(token, header)
    if not list_lotes:
        list_lotes = crear_lote_demo(header)
    if not list_lotes:
        print("[INFO] Aun sin lotes disponibles. Reintentando en 5s...")
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