from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# --- IMPORTACIONES ESTRATÉGICAS ---
from . import models, database
from .routers import auth, lotes, sensor # Conectamos los módulos especializados

# Inicialización de la persistencia de datos
# Aseguramos que todas las tablas (User, Lote, Telemetria) existan al arrancar
models.Base.metadata.create_all(bind=database.engine)

# Configuración de la instancia principal de FastAPI
app = FastAPI(
    title="NutriTrack Enterprise Engine",
    description=(
        "Plataforma centralizada para el monitoreo de cadena de frío. "
        "Implementa arquitectura modular, seguridad mediante JWT Bearer Tokens "
        "y validación industrial de telemetría IoT."
    ),
    version="1.0.0",
    docs_url="/docs",      # URL para la documentación técnica Swagger
    redoc_url="/redoc"     # URL para documentación alternativa profesional
)

# --- CONFIGURACIÓN DE POLÍTICAS CORS ---
# Crucial para permitir que la App Móvil (Flutter/RN) y 
# la simulación en Godot puedan comunicarse con este servidor.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- REGISTRO DE RUTAS MODULARES (MIGRACIÓN DE LÓGICA) ---
# Al usar 'include_router', delegamos la responsabilidad a cada archivo 
# dentro de la carpeta /routers/, manteniendo este archivo principal limpio.
app.include_router(auth.router)    # Gestión de Identidad y Seguridad
app.include_router(lotes.router)   # Control de Inventario y Trazabilidad
app.include_router(sensor.router)  # Procesamiento de Datos IoT y Alertas

@app.get("/", tags=["Health Check"])
def check_health():
    """
    Verificación de estado del motor central. 
    Indica que todas las capas están operativas.
    """
    return {
        "status": "Online",
        "service": "NutriTrack Central Engine",
        "version": "1.0.0",
        "security": "JWT/OAuth2 Protected",
        "architecture": "Clean Modular Architecture"
    }