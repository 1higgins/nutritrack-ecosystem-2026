"""
NutriTrack - Enterprise Logic Service: Alerts
Motor de decisiones con tolerancia a fallos y auditoría diagnóstica.
"""

# alerts.py

STATUS_OPTIMO = "OPTIMO"
STATUS_ALERTA = "ADVERTENCIA"
STATUS_CRITICO = "CRITICO"
<<<<<<< Updated upstream
=======
STATUS_ESPERANDO = "ESPERANDO" 
>>>>>>> Stashed changes

MARGEN_CRITICO_TEMP = 3.0  
HUMEDAD_MIN_ACEPTABLE = 20.0 
HUMEDAD_MAX_ACEPTABLE = 80.0

def evaluar_estado_lote(temp: float, hum: float, t_min: float, t_max: float) -> str:
    """
    DETERMINISMO TÉRMICO: El estado visual de la App se rige SOLO por la temperatura.
    Esto garantiza que si el punto está en la zona verde, el estado sea OPTIMO.
    """
    if temp is None: return STATUS_ALERTA

    # 1. ESTADO CRÍTICO (Rojo en App)
    if temp > (t_max + MARGEN_CRITICO_TEMP) or temp < (t_min - MARGEN_CRITICO_TEMP):
        return STATUS_CRITICO

    # 2. ESTADO ADVERTENCIA (Naranja en App)
    if temp > t_max or temp < t_min:
        return STATUS_ALERTA

    # 3. ESTADO ÓPTIMO (Verde en App)
    return STATUS_OPTIMO

def generar_diagnostico(temp: float, hum: float, t_min: float, t_max: float) -> str:
    """
    DIAGNÓSTICO MULTI-VARIABLE: Informa sobre todo, pero con coherencia.
    Si la temperatura es óptima pero la humedad no, lo dice sin cambiar el color del sistema.
    """
    avisos = []

    # Prioridad 1: Temperaturas Críticas
    if temp > (t_max + MARGEN_CRITICO_TEMP):
        avisos.append(f"CRÍTICO: Sobrecalentamiento extremo (+{round(temp - t_max, 2)}°C)")
    elif temp < (t_min - MARGEN_CRITICO_TEMP):
        avisos.append(f"CRÍTICO: Congelación no programada (-{round(t_min - temp, 2)}°C)")
    
    # Prioridad 2: Advertencias Térmicas
    elif temp > t_max:
        avisos.append("Advertencia: Temperatura ligeramente alta")
    elif temp < t_min:
        avisos.append("Advertencia: Temperatura bajo el nivel ideal")
    
    # Prioridad 3: Humedad (Se añade como información adicional)
    if hum > HUMEDAD_MAX_ACEPTABLE:
        avisos.append("Aviso: Humedad Elevada")
    elif hum < HUMEDAD_MIN_ACEPTABLE:
        avisos.append("Aviso: Ambiente Seco")

    # Salida Profesional
    if not avisos:
        return "Sistema operando en parámetros ideales."
    
    return " | ".join(avisos)