from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import models, database
from .routers import auth, lotes, sensor # Conectamos los módulos 

# Inicialización de la persistencia de datos
# Aseguramos que todas las tablas existan al arrancar
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
    docs_url="/docs",  
    redoc_url="/redoc"  
)

# --- POLÍTICAS CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- REGISTRO DE RUTAS MODULARES (MIGRACIÓN DE LÓGICA) ---
app.include_router(auth.router)    # Gestión de Identidad y Seguridad
app.include_router(lotes.router)   # Control de Inventario y Trazabilidad
app.include_router(sensor.router)

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