import requests
import time
import random
import sys
from datetime import datetime

# --- CONFIGURACIÓN DE ALTA DISPONIBILIDAD ---
API_BASE_URL = "http://127.0.0.1:8000"
FRECUENCIA_BASE = 5  # Segundos entre lecturas exitosas

class NutriTrackIndustrialSensor:
    def __init__(self, user, password, code):
        self.username = user
        self.password = password
        self.codigo_lote = code
        
        self.token = None
        self.lote_id = None
        self.headers = {}
        
        # Parámetros térmicos iniciales
        self.temp_actual = -15.0
        self.hum_actual = 55.0

    def autenticar(self):
        """Protocolo OAuth2 con bloqueo hasta éxito en caso de caída del servidor."""
        while True:
            try:
                print(f"🔑 [AUTH] Autenticando usuario: {self.username}...")
                data = {"username": self.username, "password": self.password}
                res = requests.post(f"{API_BASE_URL}/token", data=data, timeout=10)
                
                if res.status_code == 200:
                    self.token = res.json()["access_token"]
                    self.headers = {"Authorization": f"Bearer {self.token}"}
                    print("✅ [AUTH] Sesión establecida correctamente.")
                    return True
                else:
                    print(f"❌ [AUTH] Credenciales rechazadas, verifique sus datos")
                    return False
            except requests.exceptions.RequestException:
                print("⚠️ [RED] Backend no responde. Entrando en modo espera (10s)...")
                time.sleep(10)

    def inicializar_lote(self):
        """
        MODO PROFESIONAL: Solo busca lotes existentes donde el usuario tiene 
        permisos (Creados por OPA o Vinculados por OPT). 
        Se elimina la creación automática para respetar la jerarquía de roles.
        """
        while True:
            try:
                # 1. INTENTO DE VINCULACIÓN (Solo lectura de lo autorizado)
                print(f"🔍 [LOTE] Buscando acceso autorizado para '{self.codigo_lote}'...")
                res_get = requests.get(f"{API_BASE_URL}/lotes/", headers=self.headers)
                
                if res_get.status_code == 200:
                    lotes_en_sistema = res_get.json()
                    # Buscamos nuestro código en la lista que nos dio la API (filtrada por el backend)
                    for lote in lotes_en_sistema:
                        if lote["codigo_lote"] == self.codigo_lote:
                            self.lote_id = lote["id"]
                            print(f"🔗 [VINCULACIÓN] Acceso confirmado. ID Sistema: {self.lote_id}")
                            return True
                    
                    # Si el bucle termina sin encontrar el lote:
                    print(f"\n❌ [ERROR] Lote '{self.codigo_lote}' no disponible para este usuario.")
                    print("─" * 60)
                    print("📌 OPA: Asegúrese de haber creado el lote primero.")
                    print("📌 OPT: El lote debe aparecer en su lista de la App (requiere vínculo previo).")
                    print("─" * 60)
                    return False

                elif res_get.status_code == 401:
                    print("🔑 [RE-AUTH] Sesión expirada durante la búsqueda...")
                    if not self.autenticar(): return False
                else:
                    print(f"❌ [ERROR] Error de servidor inesperado: {res_get.status_code}")
                    return False

            except requests.exceptions.RequestException:
                print("⚠️ [RED] Backend no responde. Reintentando búsqueda en 5s...")
                time.sleep(5)

    def aplicar_logica_termica(self):
        """Genera fluctuaciones realistas."""
        salto = random.uniform(-4.0, 6.0)
        self.temp_actual += salto
        # Seguridad de simulación: si se sale de rango lógico, reseteamos
        if self.temp_actual > 20 or self.temp_actual < -30:
            self.temp_actual = -15.0
        
        self.hum_actual = max(30, min(95, self.hum_actual + random.uniform(-3, 3)))
        return round(self.temp_actual, 2), round(self.hum_actual, 2)

    def ejecutar(self):
        """Bucle de Transmisión Crítica: Flujo Lineal Profesional."""
        
        # 1. PASO CRÍTICO: Autenticación
        # No podemos preguntar el lote sin saber si el usuario es válido.
        if not self.autenticar(): 
            return # Detenemos la ejecución si las credenciales fallan

        # 2. SELECCIÓN DE RECURSO
        # Solo después de un 200 OK del servidor, pedimos el lote.
        print("\n✅ Acceso Concedido.")
        self.codigo_lote = input("📦 Lote a monitorear: ") 

        # 3. VINCULACIÓN Y PERMISOS
        # Aquí inicializar_lote usará el nombre que acabamos de escribir.
        if not self.inicializar_lote(): 
            print("❌ No se pudo vincular el lote. Finalizando...")
            return

        # 4. CONFIRMACIÓN DE ESTADO
        # Ahora que self.codigo_lote TIENE un valor, lo imprimimos.
        print(f"\n📡 [IOT] Transmisión iniciada para {self.username} en {self.codigo_lote}")
        print("-" * 75)

        while True:
            # 1. Generamos el dato
            temp, hum = self.aplicar_logica_termica()
            payload = {"lote_id": self.lote_id, "temperatura": temp, "humedad": hum}
            
            envio_exitoso = False
            while not envio_exitoso:
                try:
                    start_time = time.time()
                    res = requests.post(f"{API_BASE_URL}/telemetria/", json=payload, headers=self.headers, timeout=10)
                    latency = round((time.time() - start_time) * 1000, 1)

                    if res.status_code == 201:
                        diag = res.json().get('diagnostico', 'OK')
                        ts = datetime.now().strftime("%H:%M:%S")
                        print(f"[{ts}] {self.username} | {self.codigo_lote} | {temp:6}°C | {diag:10} | {latency}ms")
                        envio_exitoso = True 
                    
                    elif res.status_code == 401:
                        print("🔑 [RE-AUTH] Sesión expirada. Renovando llave...")
                        self.autenticar()

                    # --- NUEVA LÓGICA DE DETECCIÓN DE CIERRE (ERROR 400) ---
                    elif res.status_code == 400:
                        detalle = res.json().get('detail', 'Error de validación.')
                        print(f"\n🚫 [BLOQUEO] {detalle}")
                        print("🏁 El ciclo de este lote ha terminado. Sensor en reposo.")
                        return # Salimos de toda la ejecución del sensor

                    else:
                        print(f"❌ [HTTP] Error inesperado {res.status_code}. Reintentando...")
                        time.sleep(2)

                except requests.exceptions.RequestException:
                    print("⚠️ [ALERTA] Servidor desconectado. Reintentando...")
                    time.sleep(10)

            time.sleep(FRECUENCIA_BASE)

def mostrar_menu():
    print("\n" + "═"*50)
    print("      NUTRITRACK INDUSTRIAL - AGENTE IOT v2.0")
    print("═"*50)
    user = input("👤 Usuario: ") or "Epsilon"
    pw = input("🔑 Contraseña: ") or "a12345"
    print("═"*50)
    return user, pw,

if __name__ == "__main__":
    try:
        u, p = mostrar_menu()
        sensor = NutriTrackIndustrialSensor(u, p, "")
        sensor.ejecutar()
    except KeyboardInterrupt:
        print("\n🛑 [SISTEMA] Sensor apagado por el usuario")
        sys.exit()