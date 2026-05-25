from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import database, models, schemas
from ..services import alerts
from .auth import get_current_user

router = APIRouter(prefix="/telemetria", tags=["IoT / Sensores Industrial"])

@router.post("/", status_code=status.HTTP_201_CREATED, response_model=schemas.TelemetriaRead)
def registrar_medicion(
    data: schemas.TelemetriaCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user) 
):
    # --- 1. VALIDACIÓN DE EXISTENCIA ---
    lote = db.query(models.Lote).filter(models.Lote.id == data.lote_id).first()
    
    if not lote:
        raise HTTPException(status_code=404, detail="Lote no encontrado")

    if lote.entregado:
        raise HTTPException(status_code=400, detail="El lote ya está cerrado (ENTREGADO)")

    # --- 2. VALIDACIÓN DE JURISDICCIÓN (RBAC) ---
    es_creador = (lote.creador_id == current_user.id)
    es_custodio = (lote.custodio_id == current_user.id)
    es_admin = (current_user.role == "admin")

    if not (es_creador or es_custodio or es_admin):
        raise HTTPException(status_code=403, detail="Sin custodia activa sobre el lote")

    # --- 3. PROCESAMIENTO DE ESTADO CON MEMORIA ---
    # Capturamos el estado antes de la actualización
    estado_previo = lote.estado_actual 

    nuevo_estado = alerts.evaluar_estado_lote(
        temp=data.temperatura, 
        hum=data.humedad,
        t_min=lote.temp_min_ideal, 
        t_max=lote.temp_max_ideal,
        estado_anterior=estado_previo # <--- PASADO
    )
    
    mensaje_diagnostico = alerts.generar_diagnostico(
        data.temperatura, data.humedad,
        lote.temp_min_ideal, lote.temp_max_ideal,
        nuevo_estado # <--- ✅ CAMBIO CRÍTICO OBLIGATORIOaquí
    )
    
    # Actualización del activo (Atomic Update)
    lote.estado_actual = nuevo_estado

    # --- 4. PERSISTENCIA ---
    try:
        nueva_lectura = models.Telemetria(
            lote_id=data.lote_id,
            usuario_id=current_user.id,
            temperatura=data.temperatura,
            humedad=data.humedad,
            diagnostico=mensaje_diagnostico
        )
        
        db.add(nueva_lectura)
        db.commit()
        db.refresh(nueva_lectura)
        
        return nueva_lectura

    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Error de persistencia en base de datos")