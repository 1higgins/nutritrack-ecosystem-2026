# 1. Usamos Python 3.11-slim, ideal para las versiones de SQLAlchemy y FastAPI que manejan
FROM python:3.11-slim

# 2. Instalamos dependencias del sistema necesarias para compilar librerías de seguridad (como bcrypt o cryptography)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Directorio de trabajo dentro del contenedor
WORKDIR /app

# 4. Copiamos el requirements primero para aprovechar la caché de Docker
COPY requirements.txt .

# 5. Actualizamos pip e instalamos las dependencias
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 6. Copiamos todo el código del backend al contenedor
COPY . .

# 7. Exponemos el puerto estándar que configuraron para Uvicorn
EXPOSE 8000

# 8. Comando para arrancar la API con la recarga automática desactivada en producción/docker
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]