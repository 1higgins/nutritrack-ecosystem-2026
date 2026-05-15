from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from . import models, database
from .routers import auth, lotes, sensor
from .database import engine, SessionLocal

# Inicialización de persistencia
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="NutriTrack Enterprise Engine",
    description="Motor central de monitoreo de cadena de frío con seguridad JWT.",
    version="1.0.0"
)

@app.on_event("startup")
def startup_event():
    """Al encender el servidor, sembramos el usuario maestro."""
    db = SessionLocal()
    try:
        # Llamamos a una función que crearemos en auth.py
        auth.asegurar_usuario_semilla(db)
    finally:
        db.close()

# --- CONFIGURACIÓN PROFESIONAL DE CORS ---
# Permitimos localhost en distintos puertos para cubrir Flutter Web (Chrome)
# y entornos de desarrollo locales.
origins = [
    "http://localhost",
    "http://127.0.0.1",
    "http://localhost:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Cambiar a 'origins' en despliegue de producción
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"]
)

# Registro de rutas
app.include_router(auth.router)
app.include_router(lotes.router)
app.include_router(sensor.router)

@app.get("/", tags=["Health Check"])
def check_health():
    return {
        "status": "Online",
        "environment": "Development/Hybrid",
        "security": "JWT/OAuth2 Active"
    }