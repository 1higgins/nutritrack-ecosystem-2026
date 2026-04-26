from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional
from datetime import datetime

# --- ESQUEMAS DE SEGURIDAD (JWT) ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class UserCreate(BaseModel):
    username: str
    password: str = Field(..., max_length=72)
    role: Optional[str] = "operario"
    
class UserRead(BaseModel):
    id: int
    username: str
    role: str
    model_config = ConfigDict(from_attributes=True)

# --- ESQUEMAS DE TELEMETRÍA ---
class TelemetriaBase(BaseModel):
    temperatura: float = Field(..., ge=-50.0, le=100.0) 
    humedad: float = Field(..., ge=0.0, le=100.0)

class TelemetriaCreate(TelemetriaBase):
    lote_id: int

class TelemetriaRead(TelemetriaBase):
    id: int
    lote_id: int # Añadido para trazabilidad explícita
    fecha_registro: datetime
    model_config = ConfigDict(from_attributes=True)

# --- ESQUEMAS DE LOTE ---
class LoteBase(BaseModel):
    codigo_lote: str = Field(..., min_length=3)
    producto: str
    temp_min_ideal: float
    temp_max_ideal: float

class LoteCreate(LoteBase):
    pass

class LoteRead(LoteBase):
    id: int
    estado_actual: str
    entregado: bool
    creador_id: Optional[int]
    # Usamos List[TelemetriaRead] para que el operario vea el historial en la App
    telemetrias: List[TelemetriaRead] = [] 
    model_config = ConfigDict(from_attributes=True)