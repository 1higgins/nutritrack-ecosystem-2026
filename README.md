# NutriTrack Ecosystem

**Universidad Nacional Mayor de San Marcos** — Facultad de Ingeniería de Sistemas e Informática — Desarrollo Basado en Plataformas.

Presentado por el **Grupo 10**:

- **Alvarez Chancafe, Fabian Matias**
- **Flores Quispe, Cristhian Alexi**
- **Gomez Huallanca, Jhonatan Jesus**
- **Gomez Levano, Enrique Guillermo**

Monorepo del ecosistema NutriTrack: plataforma de monitoreo de cadena de frío para transporte de productos perecibles.

---

## Descripción del Proyecto

El monorepo se organiza en cuatro módulos independientes que se comunican entre sí para conformar un sistema de monitoreo de cadena de frío de extremo a extremo.

### `backend/`

API REST construida con **FastAPI**. Gestiona la persistencia de datos en **SQLite** (los archivos `.db`, `.db-shm` y `.db-wal` no se suben al repositorio) y protege todos los endpoints mediante autenticación **JWT** con OAuth2. Implementa un modelo RBAC con tres roles (`admin`, `OPA`, `OPT`) y una máquina de estados que clasifica cada lectura de telemetría en `OPTIMO`, `ALERTA` o `CRITICO`. Al arrancar, siembra automáticamente el usuario administrador maestro `Epsilon`.

### `mobile/`

Aplicación móvil desarrollada en **Flutter**. Proporciona la interfaz de operario para que los usuarios con rol OPA (Operador de Almacén) y OPT (Operador de Transporte) gestionen lotes, vinculen custodias de carga y visualicen el historial de telemetría con gráficas en tiempo real. Se puede ejecutar como aplicación web durante el desarrollo.

### `iot_industrial/`

Red distribuida basada en el protocolo **MQTT**. Contiene dos componentes:

- **`mqtt_sender.py`**: Simula un sensor embebido en el camión de transporte. Se autentica contra el backend para obtener la lista de lotes activos y publica lecturas de temperatura y humedad en el broker MQTT público (`broker.hivemq.com`) bajo el tópico `fisi/nutritrack/lotes/{id}/telemetria`, con un intervalo de 5 segundos.
- **`mqtt_bridge.py`**: Middleware que se suscribe al broker MQTT, captura cada mensaje publicado por el sender, se autentica contra el backend para obtener un token JWT y reenvía la telemetría al endpoint `POST /telemetria/` del backend mediante HTTP.

### `simulation_godot/`

Simulación en **Godot Engine** (2D). Renderiza un mapa top-down con el trayecto de un vehículo de transporte. El gemelo digital realiza polling al backend y cambia dinámicamente el color del vehículo según el estado de la carga térmica: verde para `OPTIMO`, amarillo para `ALERTA` y rojo para `CRITICO`.

---

## Guía de Inicio Rápido

Se requieren **cuatro terminales** ejecutándose de forma simultánea. Todas las rutas son relativas a la raíz del monorepo.

### Terminal 1 — Backend (FastAPI)

```bash
cd backend
venv\Scripts\activate
uvicorn app.main:app --reload
```

El servidor estará disponible en `http://127.0.0.1:8000`. La documentación interactiva de la API se genera automáticamente en `http://127.0.0.1:8000/docs`.

### Terminal 2 — Mobile (Flutter)

```bash
cd mobile
flutter run -d web-server
```

Flutter compilará la aplicación y la servirá en un puerto local accesible desde el navegador.

### Terminal 3 — IoT Bridge (MQTT Middleware)

```bash
cd iot_industrial
venv\Scripts\activate
python mqtt_bridge.py
```

El bridge se autenticará contra el backend, se conectará al broker MQTT y quedará en escucha permanente del tópico `fisi/nutritrack/lotes/+/telemetria`.

### Terminal 4 — IoT Sender (Simulador de Sensor)

```bash
cd iot_industrial
venv\Scripts\activate
python mqtt_sender.py
```

El sender se autenticará contra el backend, consultará los lotes disponibles y comenzará a publicar lecturas simuladas de temperatura y humedad cada 5 segundos.

---

## Contratos de API

Base URL: `http://127.0.0.1:8000`

### `POST /token`

Autentica a un usuario y devuelve un token JWT. Utiliza el estándar OAuth2 con `application/x-www-form-urlencoded`.

**Request**

| Campo      | Tipo   | Requerido | Descripción              |
|------------|--------|-----------|--------------------------|
| `username` | string | Sí        | Nombre de usuario.       |
| `password` | string | Sí        | Contraseña en texto plano. |

```bash
curl -X POST http://127.0.0.1:8000/token \
  -d "username=Epsilon&password=a12345"
```

**Response `200 OK`**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "role": "admin"
}
```

---

### `POST /telemetria/`

Registra una lectura de telemetría para un lote. Requiere autenticación JWT (header `Authorization: Bearer <token>`). El backend ejecuta la máquina de estados para determinar el diagnóstico y el nuevo estado del lote.

**Request**

| Campo         | Tipo  | Requerido | Restricción          | Descripción                    |
|---------------|-------|-----------|----------------------|--------------------------------|
| `temperatura` | float | Sí        | `-50.0` a `100.0`    | Temperatura en grados Celsius. |
| `humedad`     | float | Sí        | `0.0` a `100.0`      | Humedad relativa en porcentaje.|
| `lote_id`     | int   | Sí        | ID existente en la DB | Identificador del lote.        |

```bash
curl -X POST http://127.0.0.1:8000/telemetria/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"temperatura": -18.5, "humedad": 55.0, "lote_id": 1}'
```

**Response `201 Created`**

```json
{
  "id": 42,
  "temperatura": -18.5,
  "humedad": 55.0,
  "fecha_registro": "2026-07-12T21:00:00.000000",
  "diagnostico": "Sistema operando en parámetros ideales",
  "usuario_id": 1
}
```

---

### Códigos de Error

| Código | Significado                | Contexto                                                                                           |
|--------|----------------------------|----------------------------------------------------------------------------------------------------|
| `400`  | Bad Request                | Datos de entrada inválidos o el lote ya fue marcado como entregado.                               |
| `401`  | Unauthorized               | Token JWT ausente, expirado o con firma inválida.                                                 |
| `403`  | Forbidden                  | El usuario autenticado no tiene custodia activa sobre el lote o su rol no permite la operación.   |
| `404`  | Not Found                  | El `lote_id` proporcionado no existe en la base de datos.                                         |
| `500`  | Internal Server Error      | Error de persistencia en la base de datos. Se ejecuta rollback automático.                        |

---

### Estados de la Máquina de Estados Térmicos

| Estado     | Condición                                                                                                                                          |
|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `OPTIMO`   | La temperatura se encuentra dentro del rango `[temp_min_ideal, temp_max_ideal]` definido para el lote.                                             |
| `ALERTA`   | La temperatura excedió el rango ideal pero permanece dentro del margen de tolerancia de 3 °C. Solo se asigna si el estado anterior era `OPTIMO`.   |
| `CRITICO`  | La temperatura superó el margen de tolerancia, o bien se encuentra en zona de alerta pero el estado anterior no era `OPTIMO` (recuperación parcial o primera lectura). |

---

## Interoperabilidad

El sensor simulado (`mqtt_sender.py`) genera lecturas de temperatura y humedad y las publica como mensaje JSON en el broker MQTT público `broker.hivemq.com` bajo el tópico `fisi/nutritrack/lotes/{lote_id}/telemetria`. El middleware (`mqtt_bridge.py`), que permanece suscrito a ese mismo broker, captura cada mensaje entrante, extrae el identificador del lote desde la estructura del tópico, se autentica contra el backend para obtener un token JWT válido y ejecuta un `POST /telemetria/` con la carga útil estructurada. El backend recibe la petición, valida la jurisdicción del usuario sobre el lote mediante RBAC, ejecuta la máquina de estados térmicos para clasificar la lectura como `OPTIMO`, `ALERTA` o `CRITICO`, genera un diagnóstico textual y persiste el registro completo en SQLite. Finalmente, el gemelo digital implementado en Godot realiza polling periódico al backend, obtiene el estado actualizado del lote y renderiza el vehículo en el mapa 2D cambiando su color a rojo cuando el estado transiciona a `CRITICO`.
