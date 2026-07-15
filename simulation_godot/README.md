# NutriTrack — Digital Twin del Transporte (Godot 4.x)

Simulación 2D: un camión refrigerado se queda fijo en pantalla mientras la
carretera se desplaza en bucle infinito (parallax), dando la ilusión de que
el vehículo transporta el lote sin parar. El color del camión cambia según
el estado térmico que reporta tu Backend (que a su vez recibe los datos del
IoT vía MQTT):

| Estado del lote (`estado_actual`) | Color del camión         |
|---|---|
| `OPTIMO` / `NORMAL`               | 🔵 Azul (fijo)            |
| `ALERTA`                          | 🟠 Ámbar (fijo)           |
| `CRITICO`                         | 🔴 Rojo parpadeante + panel de alerta en pantalla |

## 1. Cómo abrir el proyecto

1. Abre **Godot Engine 4.x**.
2. "Import" → selecciona la carpeta `simulation_godot/` (el archivo
   `project.godot`).
3. Dale a Play (▶). La escena `Main.tscn` es la escena de inicio.

## 2. Cómo se conecta al Backend

Todo vive en `scripts/ApiClient.gd` (autoload, corre siempre en segundo
plano, sin necesidad de estar en ninguna escena visible):

1. Al arrancar, hace `POST {backend_url}/token` con `username`/`password`
   (form-urlencoded, igual que `mqtt_sender.py` y `mqtt_bridge.py`) y guarda
   el JWT.
2. Cada `poll_interval` segundos (por defecto 5s, igual que tu
   `mqtt_sender.py`) hace `GET {backend_url}/lotes/` con el header
   `Authorization: Bearer <token>`.
3. De la lista de lotes, si `estado_actual` de alguno contiene `"CRITICO"`
   se prioriza ese; si no, se busca `"ALERTA"`; si no hay ninguno en
   problemas, se muestra el primer lote de la lista.
4. Emite la señal `estado_actualizado(lote_id, temperatura, humedad, estado)`
   que escuchan el camión (`Truck.gd`) y el HUD (`Main.gd`).
5. Si el token expira (dura 240 min según tu `auth.py`) o el backend
   responde 401, se reautentica automáticamente.

### Variables que probablemente quieras tocar

En `scripts/ApiClient.gd`, arriba del todo:

```gdscript
@export var backend_url: String = "http://127.0.0.1:8000"
@export var username: String = "Epsilon"
@export var password: String = "a12345"
@export var poll_interval: float = 5.0
@export var lote_id_objetivo: int = -1   # -1 = auto (el más crítico); o pon un ID fijo, ej: 3
```

Como son `@export`, si conviertes `ApiClient.tscn` en editable puedes
cambiarlos desde el Inspector de Godot sin tocar código.

> ⚠️ **Importante:** el backend debe estar corriendo (`uvicorn ...`) *antes*
> de darle Play en Godot, y con al menos un usuario (`Epsilon` / `a12345`
> ya existe por el "usuario semilla" de tu `auth.py`) y al menos un lote
> creado, o el HUD se quedará en "conectando...".

## 3. Flujo completo para probar la demo (como lo evaluará el profesor)

```
1. Backend (FastAPI)      -> uvicorn app.main:app --reload
2. mqtt_bridge.py         -> escucha MQTT y guarda telemetría en la DB
3. mqtt_sender.py         -> simula el sensor y publica temperatura por MQTT
4. Godot (Play ▶)         -> hace polling a /lotes/ y pinta el camión
```

Cuando `mqtt_sender.py` mande una temperatura fuera de rango, tu backend
(`alerts.evaluar_estado_lote`) debe recalcular `estado_actual` a algo que
contenga "CRITICO" o "ALERTA" — el camión en Godot lo reflejará en el
siguiente ciclo de polling (máx. 5s de delay).

## 4. Si tus valores de `estado_actual` son distintos

Si en tu `alerts.py` el enum usa otras palabras (por ejemplo
`"FUERA_DE_RANGO"` en vez de `"CRITICO"`), solo tienes que ajustar el
`.find(...)` en dos archivos:

- `scripts/ApiClient.gd` → función `_elegir_lote()`
- `scripts/Truck.gd` y `scripts/Main.gd` → función `_process()` / `_on_estado_actualizado()`

## 5. Estructura de archivos

```
simulation_godot/
├── project.godot
├── icon.svg
├── assets/
│   ├── truck.png          # tu imagen (fondo removido)
│   └── background.png     # tu imagen de referencia (fondo/paisaje)
├── scenes/
│   ├── Main.tscn           # escena principal (fondo + carretera + camión + HUD)
│   └── ApiClient.tscn       # autoload: conexión con el backend
├── scripts/
│   ├── Main.gd              # controla el HUD
│   ├── ApiClient.gd         # login + polling al backend
│   ├── Truck.gd             # cambia de color según estado_actual
│   └── RoadScroll.gd        # genera y desplaza las líneas de la carretera
└── README.md
```

## 6. Criterio de aceptación cubierto

> *"Interoperabilidad: El sensor detecta calor → El Backend genera alerta →
> Godot muestra el pallet en rojo."*

Este proyecto cumple ese flujo exacto: Godot no simula el estado por su
cuenta, siempre lo lee en vivo del Backend real.
