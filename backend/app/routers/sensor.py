from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import database, models, schemas
from ..services import alerts
from .auth import get_current_user 

router = APIRouter(prefix="/telemetria", tags=["IoT / Sensores"])

@router.post("/", status_code=status.HTTP_201_CREATED)
def registrar_medicion(
    data: schemas.TelemetriaCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user) 
):
    """
    Recibe y procesa telemetría.
    """
    # 1. Validación de existencia del Lote
    lote = db.query(models.Lote).filter(models.Lote.id == data.lote_id).first()
    if not lote:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"Lote ID {data.lote_id} no existe en el inventario."
        )

    # 2. VALIDACIÓN CRUZADA: ¿El lote ya fue entregado?
    if lote.entregado:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Error: Este lote ya ha sido entregado. No se permiten más registros."
        )

    # 3. Motor de Reglas (Alertas)
    nuevo_estado = alerts.evaluar_estado_lote(
        data.temperatura, 
        lote.temp_min_ideal, 
        lote.temp_max_ideal
    )
    
    # Actualizamos el estado del lote en "caliente" 
    lote.estado_actual = nuevo_estado

    # 4. Persistencia 
    nueva_lectura = models.Telemetria(**data.model_dump())
    db.add(nueva_lectura)
    db.commit()
    db.refresh(nueva_lectura)
    
    # Al final de registrar_medicion, cambia "lote_estado" por "lote_status"
    return {
        "status": "success",
        "timestamp": nueva_lectura.fecha_registro,
        "lote_id": data.lote_id,
        "lote_status": nuevo_estado,  #Cambia 'estado' por 'status'
        "data": {"temp": data.temperatura, "hum": data.humedad}
    }