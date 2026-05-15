from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from .. import database, models, schemas
from .auth import get_current_user

router = APIRouter(prefix="/lotes", tags=["Logística e Inventario"])

# ==========================================================================
# --- ESCRITURA: CREACIÓN DE LOTES ---
# ==========================================================================

@router.post("/", response_model=schemas.LoteRead, status_code=status.HTTP_201_CREATED)
def crear_lote(
    lote_in: schemas.LoteCreate, 
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(get_current_user)
):
    """
    POLÍTICA OPA: Solo personal de almacén puede iniciar el ciclo de vida de un lote.
    """
    # 1. Verificación de Rol (OPA o Admin)
    if current_user.role not in ["OPA", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: Los transportistas (OPT) no tienen permisos para crear lotes."
        )

    # 2. Verificación de duplicidad global
    db_lote = db.query(models.Lote).filter(models.Lote.codigo_lote == lote_in.codigo_lote).first()
    if db_lote:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El código '{lote_in.codigo_lote}' ya está registrado en el sistema."
        )

    # 3. Persistencia con Password de Lote
    try:
        new_lote = models.Lote(
            **lote_in.model_dump(), 
            creador_id=current_user.id,
            entregado=False 
        )
        db.add(new_lote)
        db.commit()
        db.refresh(new_lote)
        return new_lote

    except IntegrityError:
        # Volvemos a la precisión original: Error de concurrencia o duplicidad
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Error de consistencia: El lote ya fue registrado por otro proceso simultáneo o el código está duplicado."
        )
    except Exception as e:
        # Error genérico para cualquier otra cosa que falle en el servidor
        db.rollback()
        raise HTTPException(
            status_code=500, 
            detail=f"Error interno no controlado: {str(e)}"
        )

@router.post("/vincular", response_model=schemas.LoteRead)
def vincular_lote_a_transporte(
    datos_vinculo: schemas.LoteVincular,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    PROTOCOLO DE VÍNCULO (OPT): Validación por Usuario OPA + Código + Password.
    """
    # 1. Solo un OPT puede solicitar la custodia de un lote
    if current_user.role != "OPT":
        raise HTTPException(status_code=403, detail="Esta función es exclusiva para Operarios de Transporte.")

    # 2. Búsqueda por triple validación
    lote = db.query(models.Lote).join(models.User, models.Lote.creador_id == models.User.id).filter(
        models.User.username == datos_vinculo.nombre_opa,
        models.Lote.codigo_lote == datos_vinculo.codigo_lote,
        models.Lote.password_lote == datos_vinculo.password_lote
    ).first()

    if not lote:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales de lote inválidas: Verifique Usuario OPA, Código y Password."
        )
    
    if lote.entregado:
        raise HTTPException(status_code=400, detail="Este lote ya ha sido finalizado y entregado.")

    # 3. Asignación de custodia al transportista actual
    lote.custodio_id = current_user.id
    db.commit()
    db.refresh(lote)
    return lote
# ==========================================================================
# --- LECTURA: JERARQUÍA DE ACCESO ---
# ==========================================================================

@router.get("/", response_model=List[schemas.LoteRead])
def listar_lotes(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Los Admins ven todo. OPA ve lo que creó. OPT ve lo que tiene asignado.
    """
    query = db.query(models.Lote)
    
    if current_user.role == "admin":
        pass # Admin / Epsilon ven todo
    elif current_user.role == "OPA":
        query = query.filter(models.Lote.creador_id == current_user.id)
    elif current_user.role == "OPT":
        query = query.filter(models.Lote.custodio_id == current_user.id)
    
    return query.order_by(models.Lote.id.desc()).all()

@router.get("/{lote_id}", response_model=schemas.LoteDetail)
def obtener_detalle_lote(
    lote_id: int, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Obtiene el detalle completo del lote y su telemetría.
    ACCESO PERMITIDO A:
    1. OPA: Si es el creador original.
    2. OPT: Si es el custodio actual (vinculado).
    3. Admin/Epsilon: Siempre.
    """
    lote = db.query(models.Lote).filter(models.Lote.id == lote_id).first()
    
    if not lote:
        raise HTTPException(status_code=404, detail="Lote no encontrado.")

    # --- NUEVA LÓGICA DE PRIVILEGIOS ---
    is_admin = current_user.role == "admin"
    is_creador = lote.creador_id == current_user.id
    is_custodio = lote.custodio_id == current_user.id # El OPT vinculado

    # Si no cumple ninguna de las 3, "Security by Obscurity"
    if not (is_admin or is_creador or is_custodio):
        raise HTTPException(status_code=404, detail="Lote no encontrado en su jurisdicción.")
        
    return lote

# ==========================================================================
# --- ACTUALIZACIÓN: CONTROL DE ESTADO ---
# ==========================================================================

@router.post("/entregar", response_model=schemas.LoteRead)
def marcar_como_entregado(
    datos_entrega: schemas.LoteEntregar, # <--- Nuevo esquema de validación
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    CIERRE DE CUSTODIA CON HANDSHAKE: 
    Requiere validación de OPA, Código y Password para finalizar el flujo.
    """
    # 1. Búsqueda exhaustiva con validación de seguridad
    # Búsqueda optimizada y más segura
    lote = db.query(models.Lote).filter(models.Lote.codigo_lote == datos_entrega.codigo_lote).first()
    
    if not lote:
        raise HTTPException(status_code=404, detail="Lote no encontrado.")

    # Validamos que el password sea correcto Y que el OPA coincida
    creador = db.query(models.User).filter(models.User.id == lote.creador_id).first()
    
    if not creador or creador.username != datos_entrega.nombre_opa or lote.password_lote != datos_entrega.password_lote:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales de seguridad inválidas para este lote."
        )

    # 2. Verificación de permisos de usuario
    # El OPA NO PUEDE entregar. Solo el que lo tiene vinculado (OPT) o el Admin.
    es_custodio = lote.custodio_id == current_user.id
    es_admin = current_user.role == "admin"

    if not (es_custodio or es_admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seguridad: Solo el transportista a cargo (vínculo activo) o un Administrador pueden finalizar este lote."
        )

    if lote.entregado:
        raise HTTPException(status_code=400, detail="Operación redundante: El lote ya figura como entregado.")
        
    # 3. Ejecución del cierre
    lote.entregado = True
    db.commit()
    db.refresh(lote)
    return lote