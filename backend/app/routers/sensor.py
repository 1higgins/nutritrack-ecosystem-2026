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
    """
    RECEPCIÓN DE TELEMETRÍA CON VALIDACIÓN DE CUSTODIA (OPA/OPT):
    
    1. Verifica existencia del activo (Lote).
    2. Valida jurisdicción (Solo el Creador OPA o el Custodio OPT vinculado).
    3. Verifica integridad del estado (No permite datos en lotes finalizados).
    4. Procesa IA de Alertas y Diagnóstico.
    5. Registra con trazabilidad de usuario/sensor.
    """
    
    # --- 1. VALIDACIÓN DE EXISTENCIA Y ESTADO CENTRAL ---
    lote = db.query(models.Lote).filter(models.Lote.id == data.lote_id).first()
    
    if not lote:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"Lote ID {data.lote_id} no identificado en la base de datos central de NutriTrack."
        )

    if lote.entregado:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Operación rechazada: El lote '{lote.codigo_lote}' ya tiene cierre logístico (ENTREGADO)."
        )

    # --- 2. VALIDACIÓN DE JURISDICCIÓN INDUSTRIAL (RBAC) ---
    # Implementamos una lógica de 'handshake' digital.
    # El usuario que envía el dato debe tener permiso explícito sobre el activo.
    
    es_creador = (lote.creador_id == current_user.id)
    es_custodio = (lote.custodio_id == current_user.id)
    es_admin = (current_user.role == "admin")

    if not (es_creador or es_custodio or es_admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Violación de Seguridad: El usuario no posee la custodia activa de este lote. "
                "Los transportistas deben vincularse antes de reportar telemetría."
            )
        )

    # --- 3. INTELIGENCIA DE NEGOCIO Y EVALUACIÓN TÉRMICA ---
    # Delegamos la lógica de evaluación al servicio especializado 'alerts'
    
    nuevo_estado = alerts.evaluar_estado_lote(
        data.temperatura, 
        data.humedad,
        lote.temp_min_ideal, 
        lote.temp_max_ideal
    )
    
    mensaje_diagnostico = alerts.generar_diagnostico(
        data.temperatura,
        data.humedad,
        lote.temp_min_ideal,
        lote.temp_max_ideal
    )
    
    # Actualización atómica del estado del activo
    lote.estado_actual = nuevo_estado

    # --- 4. PERSISTENCIA Y TRAZABILIDAD (AUDIT LOG) ---
    try:
        nueva_lectura = models.Telemetria(
            lote_id=data.lote_id,
            usuario_id=current_user.id, # Vínculo directo con el responsable
            temperatura=data.temperatura,
            humedad=data.humedad,
            diagnostico=mensaje_diagnostico
        )
        
        db.add(nueva_lectura)
        db.commit()
        db.refresh(nueva_lectura)
        
        return nueva_lectura

    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error crítico de persistencia: No se pudo registrar la telemetría en el servidor."
        )