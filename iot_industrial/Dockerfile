# 1. Usamos la imagen ligera de Python que prefiere el profesor
FROM python:3.11-slim

# 2. Directorio de trabajo dentro del contenedor
WORKDIR /app

# 3. Instalar las librerías directamente ya que son pocas (paho-mqtt y requests)
RUN pip install --no-cache-dir paho-mqtt requests

# 4. Copiar el script real de simulación de tus sensores al contenedor
COPY sensor_sim.py .

# 5. Ejecutar el script como un daemon continuo
CMD ["python", "sensor_sim.py"]