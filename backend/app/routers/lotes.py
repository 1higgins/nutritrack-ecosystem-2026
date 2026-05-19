from sqlalchemy import func
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from .. import database, models, schemas
from .auth import get_current_user
from datetime import datetime, timedelta
from typing import List, Optional

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
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Error de consistencia: El lote ya fue registrado por otro proceso simultáneo o el código está duplicado."
        )
    except Exception as e:
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

    # ==========================================================================
    # 👇 CONTROL DE SEGURIDAD ANTIDUPLICADO DE CUSTODIA 👇
    # ==========================================================================
    if lote.custodio_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Conflicto logístico: Este lote ya cuenta con un transportista (OPT) bajo custodia asignado."
        )

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
    username: Optional[str] = None,
    rango_fecha: Optional[str] = "24h", # 24 horas por defecto para evitar saturación
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Jerarquía de acceso optimizada con filtros avanzados cruzados para Administradores.
    Coincidencia estricta y exacta por Username del OPA.
    Por defecto, limita la carga a las últimas 24 horas.
    """
    query = db.query(models.Lote)
    
    # ==========================================================================
    # 1. RESTRICCIÓN DE PRIVILEGIOS POR ROL
    # ==========================================================================
    if current_user.role == "admin":
        # El administrador tiene acceso al universo completo.
        # Condición Corregida: El username debe ser EXACTO carácter por carácter.
        if username and username.strip():
            query = query.join(models.User, models.Lote.creador_id == models.User.id).filter(
                models.User.username == username.strip()
            )
    elif current_user.role == "OPA":
        # OPA solo ve lo que él mismo creó
        query = query.filter(models.Lote.creador_id == current_user.id)
    elif current_user.role == "OPT":
        # OPT solo ve lo que tiene bajo custodia asignado
        query = query.filter(models.Lote.custodio_id == current_user.id)

    # ==========================================================================
    # 2. EMBUDO TEMPORAL (RANGOS DE FECHA)
    # ==========================================================================
    ahora = datetime.utcnow()

    if rango_fecha == "24h":
        fecha_limite = ahora - timedelta(hours=24)
        query = query.filter(models.Lote.fecha_creacion >= fecha_limite)
    elif rango_fecha == "semana":
        fecha_limite = ahora - timedelta(days=7)
        query = query.filter(models.Lote.fecha_creacion >= fecha_limite)
    elif rango_fecha == "mes":
        fecha_limite = ahora - timedelta(days=30)
        query = query.filter(models.Lote.fecha_creacion >= fecha_limite)
    elif rango_fecha == "3meses":
        fecha_limite = ahora - timedelta(days=90)
        query = query.filter(models.Lote.fecha_creacion >= fecha_limite)
    elif rango_fecha == "6meses":
        fecha_limite = ahora - timedelta(days=180)
        query = query.filter(models.Lote.fecha_creacion >= fecha_limite)
    elif rango_fecha == "todo":
        pass

    # ==========================================================================
    # 3. EXTRACCIÓN GENERAL E INYECCIÓN DE DATOS EN TIEMPO REAL
    # ==========================================================================
    lotes = query.order_by(models.Lote.id.desc()).all()

    for lote in lotes:
        ultima_t = db.query(models.Telemetria).filter(
            models.Telemetria.lote_id == lote.id
        ).order_by(models.Telemetria.id.desc()).first()
        
        lote.ultima_temperatura = ultima_t.temperatura if ultima_t else None

        if lote.custodio_id:
            transportista = db.query(models.User).filter(models.User.id == lote.custodio_id).first()
            lote.custodio_username = transportista.username if transportista else None
        else:
            lote.custodio_username = None

    return lotes
    

@router.get("/{lote_id}", response_model=schemas.LoteAuditoriaDetail)
def obtener_detalle_lote(
    lote_id: int, 
    rango_fecha: Optional[str] = "24h", # Por defecto según requerimiento
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Obtiene la auditoría térmica de un lote específico con cálculo de promedio
    e historial parametrizado por fecha para la gráfica industrial de la app móvil.
    """
    # 1. Búsqueda y existencia del lote
    lote = db.query(models.Lote).filter(models.Lote.id == lote_id).first()
    if not lote:
        raise HTTPException(status_code=404, detail="Lote no encontrado.")

    # 2. Validación jerárquica de seguridad por jurisdicción
    is_admin = current_user.role == "admin"
    is_creador = lote.creador_id == current_user.id
    is_custodio = lote.custodio_id == current_user.id 

    if not (is_admin or is_creador or is_custodio):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Acceso denegado: El lote no se encuentra bajo su jurisdicción operativa."
        )

    # 3. Determinación del embudo temporal para la telemetría
    ahora = datetime.utcnow()
    query_telemetria = db.query(models.Telemetria).filter(models.Telemetria.lote_id == lote.id)

    if rango_fecha == "24h":
        query_telemetria = query_telemetria.filter(models.Telemetria.fecha_registro >= ahora - timedelta(hours=24))
    elif rango_fecha == "3dias":
        query_telemetria = query_telemetria.filter(models.Telemetria.fecha_registro >= ahora - timedelta(days=3))
    elif rango_fecha == "semana":
        query_telemetria = query_telemetria.filter(models.Telemetria.fecha_registro >= ahora - timedelta(days=7))
    elif rango_fecha == "mes":
        query_telemetria = query_telemetria.filter(models.Telemetria.fecha_registro >= ahora - timedelta(days=30))
    elif rango_fecha == "todo":
        pass
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Parámetro de rango '{rango_fecha}' inválido. Use: 24h, 3dias, semana, mes o todo."
        )

    # 4. Extracción cronológica ordenada para la gráfica
    lecturas = query_telemetria.order_by(models.Telemetria.fecha_registro.asc()).all()

    # 5. Cálculo de métricas: Temperatura Actual (Último registro histórico global)
    ultima_t = db.query(models.Telemetria.temperatura).filter(
        models.Telemetria.lote_id == lote.id
    ).order_by(models.Telemetria.id.desc()).first()
    
    temp_actual = ultima_t[0] if ultima_t else None

    # 6. Cálculo de métricas: Temperatura Promedio del rango seleccionado
    # Ejecutamos la consulta escalar con func.avg sobre el query ya filtrado por tiempo
    promedio_t = query_telemetria.with_entities(func.avg(models.Telemetria.temperatura)).scalar()
    
    # Redondeamos a 2 decimales si el valor existe para mantener la consistencia industrial
    temp_promedio = round(promedio_t, 2) if promedio_t is not None else None

    # 7. Resolución del username del transportista vinculado
    custodio_username = None
    if lote.custodio_id:
        transportista = db.query(models.User.username).filter(models.User.id == lote.custodio_id).first()
        if transportista:
            custodio_username = transportista[0]

    # 8. Mapeo explícito y seguro al nuevo esquema de salida
    return schemas.LoteAuditoriaDetail(
        id=lote.id,
        codigo_lote=lote.codigo_lote,
        producto=lote.producto,
        temp_min_ideal=lote.temp_min_ideal,
        temp_max_ideal=lote.temp_max_ideal,
        estado_actual=lote.estado_actual,
        entregado=lote.entregado,
        custodio_username=custodio_username,
        temperatura_actual=temp_actual,
        temperatura_promedio=temp_promedio,
        historial_lecturas=lecturas
    )

# ==========================================================================
# --- ACTUALIZACIÓN: CONTROL DE ESTADO ---
# ==========================================================================

@router.post("/entregar", response_model=schemas.LoteRead)
def marcar_como_entregado(
    datos_entrega: schemas.LoteEntregar, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    CIERRE DE CUSTODIA CON HANDSHAKE: 
    Requiere validación de OPA, Código y Password para finalizar el flujo.
    """
    # 1. Búsqueda exhaustiva con validación de seguridad
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