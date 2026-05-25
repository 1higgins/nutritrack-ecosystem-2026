"""
NutriTrack - Enterprise Logic Service: Alerts (v2.0 - State Memory)
"""

STATUS_OPTIMO = "OPTIMO"
STATUS_ALERTA = "ALERTA"
STATUS_CRITICO = "CRITICO"
STATUS_ESPERANDO = "ESPERANDO" # <-- Añadimos el nuevo estado

MARGEN_CRITICO_TEMP = 3.0  
HUMEDAD_MIN_ACEPTABLE = 20.0 
HUMEDAD_MAX_ACEPTABLE = 65.0

def evaluar_estado_lote(temp: float, hum: float, t_min: float, t_max: float, estado_anterior: str) -> str:
    """
    LÓGICA DE ESTADOS CON ESTADO INICIAL NEUTRO:
    Si el estado es ESPERANDO, la primera temperatura define el estado real sin restricciones.
    """
    # 0. Manejo de seguridad para nulos
    if temp is None: 
        return estado_anterior if estado_anterior else STATUS_ESPERANDO

    # 1. ¿Está en Zona Óptima? (Verde)
    if t_min <= temp <= t_max:
        return STATUS_OPTIMO

    # 2. Rango de Alerta (Margen de 3 grados)
    esta_en_margen_alerta = (temp < t_min and temp >= (t_min - MARGEN_CRITICO_TEMP)) or \
                            (temp > t_max and temp <= (t_max + MARGEN_CRITICO_TEMP))

    if esta_en_margen_alerta:
        # LÓGICA DE TRANSICIÓN:
        # SOLO permitimos ALERTA si veníamos estrictamente de ÓPTIMO (empeoramiento)
        if estado_anterior == STATUS_OPTIMO:
            return STATUS_ALERTA
        else:
            # Si venía de CRÍTICO (recuperación) o si es el PRIMER dato (ESPERANDO), se considera CRÍTICO
            return STATUS_CRITICO

    # 3. Fuera de todo margen (Rojo)
    return STATUS_CRITICO

def generar_diagnostico(temp: float, hum: float, t_min: float, t_max: float, estado_actual: str) -> str:
    avisos = []
    
    # 1. Evaluamos avisos térmicos basados en el estado calculado por el sistema
    if estado_actual == STATUS_ALERTA:
        # Solo entra aquí si venía de ÓPTIMO y cruzó el límite (Transición/Empeoramiento)
        if temp > t_max:
            avisos.append("Alerta: Temperatura por encima del límite")
        elif temp < t_min:
            avisos.append("Alerta: Temperatura por debajo del límite")

    elif estado_actual == STATUS_CRITICO:
        # A. Extremos (Superaron el margen de los 3 grados)
        if temp > (t_max + MARGEN_CRITICO_TEMP):
            avisos.append("CRÍTICO: Sobrecalentamiento extremo")
        elif temp < (t_min - MARGEN_CRITICO_TEMP):
            avisos.append("CRÍTICO: Congelación severa")
        
        # B. Moderados (Están dentro de los 3 grados pero clasificaron como CRÍTICO)
        # Ya sea porque el primer dato nació aquí, o porque viene recuperándose desde un extremo
        elif t_max < temp <= (t_max + MARGEN_CRITICO_TEMP):
            avisos.append("CRÍTICO: Temperatura por encima del límite operativo")
        elif (t_min - MARGEN_CRITICO_TEMP) <= temp < t_min:
            avisos.append("CRÍTICO: Temperatura por debajo del límite operativo")
    
    # 2. Evaluación de Humedad (Se mantiene intacta)
    if hum > HUMEDAD_MAX_ACEPTABLE: 
        avisos.append("Humedad Alta")
    elif hum < HUMEDAD_MIN_ACEPTABLE: 
        avisos.append("Humedad Baja")

    return " | ".join(avisos) if avisos else "Sistema operando en parámetros ideales"