# NutriTrack Ecosystem 2026

**Universidad Nacional Mayor de San Marcos (UNMSM)** — Facultad de Ingeniería de Sistemas e Informática — Desarrollo Basado en Plataformas, Ciclo 2026-I.

---

## Descripción y Arquitectura

NutriTrack Ecosystem es un sistema distribuido de monitoreo en tiempo real diseñado para garantizar la integridad térmica de la cadena de frío alimentaria. El ecosistema se compone de cuatro plataformas autónomas que intercambian datos mediante contratos HTTP protegidos con autenticación JWT/OAuth2.

**Backend (FastAPI + SQLite).** Núcleo central del ecosistema, ubicado en `backend/`. Implementado en Python 3.10+ con FastAPI como framework ASGI, SQLAlchemy 2.0 como ORM y SQLite con WAL como motor de persistencia. Recibe telemetría de los sensores IoT, ejecuta un motor de diagnóstico basado en máquina de estados finitos para clasificar cada lote como OPTIMO, ALERTA o CRITICO, y expone los datos a las demás plataformas mediante endpoints REST. Los archivos `.db`, `.db-shm` y `.db-wal` están excluidos del repositorio vía `.gitignore`; la base de datos se genera automáticamente en el primer arranque del servidor junto con un usuario semilla `Epsilon` (rol `admin`, contraseña `a12345`).

**Mobile (Flutter/Dart).** Interfaz de operación en campo ubicada en `mobile/`. Construida con Flutter SDK 3.0+ y Material Design 3, soporta despliegue en Web, Android, iOS y Desktop. Permite a los operarios (roles OPA y OPT) crear lotes con rangos térmicos, vincular custodias mediante handshake con contraseña, visualizar alertas térmicas con gráficas de serie temporal (Syncfusion Charts) y cerrar formalmente la custodia logística.

**IoT Industrial (Python).** Capa de sensores simulados ubicada en `iot_industrial/`. El script principal `sensor_sim.py` implementa un agente autónomo que se autentica contra el backend, obtiene un JWT, y transmite lecturas de temperatura y humedad cada 5 segundos con fluctuaciones aleatorias que simulan picos de calor. Incluye re-autenticación automática ante expiración del token y detección de cierre de lote. Complementariamente, `mqtt_sender.py` y `mqtt_bridge.py` soportan una topología distribuida mediante MQTT con el broker público `broker.hivemq.com`.

**Gemelo Digital (Godot Engine 4.x).** Simulador 3D de almacén logístico ubicado en `simulation_godot/`. Los archivos de escenas, scripts GDScript y assets 3D se encuentran en proceso de subida al repositorio. Su función final consiste en hacer polling HTTP al backend y, cuando un lote alcanza el estado CRITICO, renderizar el pallet correspondiente con una animación de parpadeo en rojo, proporcionando una señal visual inmediata para supervisores de planta.

---

## Roles del Equipo

**Backend Lead.** Diseña e implementa la API REST, el modelo de datos relacional, el motor de alertas con máquina de estados, la seguridad JWT/RBAC y la persistencia SQLite.

**Mobile Dev.** Desarrolla la interfaz Flutter para operarios, la integración HTTP con el backend, las gráficas térmicas, el flujo de login persistente y la navegación por roles.

**IoT Engineer.** Implementa los agentes de telemetría simulada, la lógica de reconexión resiliente, el puente MQTT-HTTP y el protocolo de autenticación Bearer Token.

**Sim Manager.** Modela el entorno 3D del almacén en Godot, programa las entidades pallet con interpolación de color y la integración HTTP para polling de estados.

---

## Instrucciones de Ejecución

Prerrequisitos: Python 3.10+, Flutter SDK 3.0+, Godot Engine 4.x.

### Levantar el Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Verificar accediendo a `http://127.0.0.1:8000/docs` para la documentación Swagger. En el primer arranque se crea la base de datos y el usuario `Epsilon` (admin / `a12345`).

### Ejecutar la App Mobile

```bash
cd mobile
flutter pub get
flutter run -d web-server
```

Acceder a la URL que Flutter indica en la terminal. La app se conecta por defecto a `http://127.0.0.1:8000`.

### Ejecutar los Sensores IoT

Requiere que el backend esté corriendo previamente.

```bash
cd iot_industrial
python sensor_sim.py
```

El agente solicita usuario y contraseña, autentica contra el backend, pide el código del lote y comienza la transmisión de telemetría cada 5 segundos.

---

## Contratos de API

Todos los endpoints están protegidos por JWT/OAuth2 excepto `POST /token`. Las solicitudes autenticadas requieren el header `Authorization: Bearer <access_token>`. Por convención del proyecto, todas las respuestas JSON utilizan listas `[]` en lugar de sets `{}` para garantizar secuenciación predecible y compatibilidad con `List<T>` de Dart y `Array` de GDScript.

### POST /token

Autenticación OAuth2 que emite un JWT con validez de 240 minutos. Se envía como `application/x-www-form-urlencoded` con los campos `username` y `password`. No requiere autenticación previa.

Respuesta exitosa (200):

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "role": "admin",
  "username": "Epsilon"
}
```

Respuesta de error (401):

```json
{
  "detail": "Credenciales incorrectas"
}
```

### POST /telemetria/

Registro de lecturas de sensores IoT. Requiere autenticación Bearer JWT. Se envía como `application/json` con los campos `lote_id` (int, ID existente), `temperatura` (float, rango -50.0 a 100.0) y `humedad` (float, rango 0.0 a 100.0). El backend ejecuta la máquina de estados de alerta y persiste el resultado con diagnóstico textual.

Ejemplo de request:

```json
{
  "lote_id": 1,
  "temperatura": -12.5,
  "humedad": 58.3
}
```

Respuesta exitosa (201):

```json
{
  "id": 42,
  "temperatura": -12.5,
  "humedad": 58.3,
  "diagnostico": "Sistema operando en parámetros ideales",
  "usuario_id": 1,
  "fecha_registro": "2026-07-07T06:30:00.000000"
}
```

Códigos de error: 400 si el lote está cerrado, 401 si el JWT es inválido o ausente, 403 si el usuario no tiene custodia activa, 404 si el lote no existe, 500 por error interno de persistencia.

Los estados de diagnóstico son OPTIMO (temperatura dentro de rango ideal), ALERTA (fuera de rango por margen menor o igual a 3°C, viniendo de OPTIMO) y CRITICO (fuera de rango por más de 3°C, o primera lectura fuera de rango).

---

## Interoperabilidad

El sensor IoT detecta una anomalía térmica y envía la lectura mediante `POST /telemetria/` con su Bearer Token JWT; el backend recibe el POST, valida la firma JWT (HS256), verifica la jurisdicción RBAC del usuario, ejecuta la máquina de estados finitos que transiciona el lote al estado correspondiente (OPTIMO, ALERTA o CRITICO), genera un diagnóstico textual, persiste la lectura en SQLite y retorna el resultado con código 201; finalmente, el gemelo digital en Godot realiza polling HTTP periódico al backend y, al detectar que un lote alcanzó el estado CRITICO, renderiza el pallet asociado con una animación de parpadeo en rojo que alerta visualmente al supervisor de planta.

---

*NutriTrack Ecosystem 2026 — UNMSM · Facultad de Ingeniería de Sistemas e Informática*
