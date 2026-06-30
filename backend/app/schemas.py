from pydantic import BaseModel, ConfigDict, Field, model_validator
from typing import List, Optional
from datetime import datetime
from enum import Enum
# ==========================================================================
# --- ENTIDAD: USUARIOS (NUEVO) ---
# ==========================================================================

class UserRole(str, Enum):
    admin = "admin"
    opa = "OPA"
    opt = "OPT"

class UserBase(BaseModel):
    username: str = Field(..., min_length=4, max_length=20, pattern="^[a-zA-Z0-9_]+$")
    role: UserRole

class UserCreate(UserBase):
    """Estructura para recibir datos en el registro (POST /register)"""
    password: str = Field(..., min_length=6)

class UserRead(UserBase):
    """Estructura de salida segura (No incluye el hash de la contraseña)"""
    id: int
    model_config = ConfigDict(from_attributes=True)


# ==========================================================================
# --- SEGURIDAD JWT ---
# ==========================================================================

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str

class TokenData(BaseModel):
    username: Optional[str] = None


# ==========================================================================
# --- TELEMETRÍA ---
# ==========================================================================

class TelemetriaBase(BaseModel):
    temperatura: float = Field(..., ge=-50.0, le=100.0) 
    humedad: float = Field(..., ge=0.0, le=100.0)

class TelemetriaCreate(TelemetriaBase):
    lote_id: int

class TelemetriaRead(TelemetriaBase):
    id: int
    fecha_registro: datetime
    diagnostico: Optional[str] = None 
    usuario_id: int 
    model_config = ConfigDict(from_attributes=True)


# ==========================================================================
# --- LOTES ---
# ==========================================================================

# schemas.py

class LoteBase(BaseModel):
    # Field(...) con min_length asegura que no sea un string vacío
    codigo_lote: str = Field(..., min_length=3, description="Código único del lote")
    producto: str = Field(..., min_length=1, description="Nombre del producto")
    temp_min_ideal: float = Field(..., description="Límite térmico inferior")
    temp_max_ideal: float = Field(..., description="Límite térmico superior")

    @model_validator(mode='after')
    def validar_datos_lote(self) -> 'LoteBase':
        """
        VALIDACIÓN INDUSTRIAL CRÍTICA:
        1. Previene rangos nulos (Min == Max).
        2. Previene rangos invertidos (Min > Max).
        3. Valida que 'producto' no contenga solo espacios.
        """
        # 1. Validación de campos obligatorios (Strings no vacíos)
        if not self.producto.strip():
            raise ValueError("El nombre del producto es obligatorio y no puede estar vacío.")

        min_t = self.temp_min_ideal
        max_t = self.temp_max_ideal

        # 2. Validación de coherencia térmica (Separada por precisión)
        if min_t > max_t:
            raise ValueError(
                f"Error de rango: El límite mínimo ({min_t}°C) no puede ser mayor "
                f"al máximo ({max_t}°C)."
            )
        
        if min_t == max_t:
            raise ValueError(
                f"Error de precisión: Los límites no pueden ser iguales ({min_t}°C). "
                "Debe existir un rango operativo para los sensores."
            )

        return self

class LoteCreate(LoteBase):
    """
    OPA usa esto para crear. Hereda la validación de temperatura
    y añade la obligatoriedad de la contraseña del lote.
    """
    password_lote: str = Field(..., min_length=4)

class LoteRead(LoteBase):
    id: int
    estado_actual: str
    entregado: bool
    creador_id: int
    custodio_id: Optional[int] = None # Para saber qué OPT lo tiene vinculado
    custodio_username: Optional[str] = None
    ultima_temperatura: Optional[float] = None
    model_config = ConfigDict(from_attributes=True)

# --- NUEVO: Esquema para el 'Handshake' de seguridad del OPT ---
class LoteVincular(BaseModel):
    nombre_opa: str       # El transportista debe saber quién le dio la carga
    codigo_lote: str      # El nombre del lote (Ej: EPSILKI)
    password_lote: str    # La clave secreta que el OPA puso al crear

class LoteDetail(LoteRead):
    telemetrias: List[TelemetriaRead] = []

# --- NUEVO: Esquema para el cierre de custodia ---
class LoteEntregar(BaseModel):
    nombre_opa: str       # Validación del origen
    codigo_lote: str      # Validación del activo
    password_lote: str    # Validación de seguridad

# ==========================================================================
# --- DETALLE DE AUDITORÍA TÉRMICA (NUEVO) ---
# ==========================================================================

class LoteAuditoriaDetail(BaseModel):
    """
    Contrato de datos optimizado para la pantalla lote_detail_screen.dart.
    Entrega métricas digeridas y la telemetría necesaria para la gráfica propia.
    """
    id: int
    codigo_lote: str = Field(..., description="Código único del lote")
    producto: str = Field(..., description="Nombre del producto")
    temp_min_ideal: float
    temp_max_ideal: float
    estado_actual: str
    entregado: bool
    custodio_username: Optional[str] = None
    
    # Métricas calculadas en Backend
    temperatura_actual: Optional[float] = None
    temperatura_promedio: Optional[float] = None
    
    # Dataset filtrado cronológicamente para la gráfica del Mobile
    historial_lecturas: List[TelemetriaRead] = []

    model_config = ConfigDict(from_attributes=True)