"""
NutriTrack - Logic Service: Alerts
Este módulo centraliza las reglas de negocio para la cadena de frío.
"""

def evaluar_estado_lote(temperatura: float, temp_min: float, temp_max: float) -> str:
    """
    Analiza la telemetría y determina el estado de seguridad.
    Retorna: 'OPTIMO', 'ALERTA' o 'CRITICO'.
    """
    # Si se sale del rango por más de 5 grados, es CRÍTICO
    if temperatura > (temp_max + 5) or temperatura < (temp_min - 5):
        return "CRITICO"
    
    # Si se sale del rango normal pero no es extremo, es ALERTA
    if temperatura > temp_max or temperatura < temp_min:
        return "ALERTA"
    
    # Si todo está bien
    return "OPTIMO"