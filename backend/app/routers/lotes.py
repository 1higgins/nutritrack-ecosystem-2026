from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from .. import database, models, schemas
from .auth import get_current_user

router = APIRouter(prefix="/lotes", tags=["Logística e Inventario"])

@router.post("/", response_model=schemas.LoteRead, status_code=status.HTTP_201_CREATED)
def crear_lote(
    lote: schemas.LoteCreate, 
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(get_current_user)
):
    """Registra un nuevo lote en el sistema vinculado al operario actual."""
    db_lote = models.Lote(**lote.model_dump(), creador_id=current_user.id)
    db.add(db_lote)
    db.commit()
    db.refresh(db_lote)
    return db_lote

@router.get("/", response_model=List[schemas.LoteRead])
def listar_lotes(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user) # Seguridad añadida
):
    """Retorna la lista completa de lotes monitoreados."""
    return db.query(models.Lote).all()

@router.patch("/{lote_id}/entregar", response_model=schemas.LoteRead)
def marcar_como_entregado(
    lote_id: int, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Cierra el monitoreo de un lote (Validación Cruzada)."""
    lote = db.query(models.Lote).filter(models.Lote.id == lote_id).first()
    if not lote:
        raise HTTPException(status_code=404, detail="Lote no encontrado")
    lote.entregado = True
    db.commit()
    db.refresh(lote)
    return lote