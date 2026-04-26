from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from .database import Base
import datetime

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="operario") 
    
    # Trazabilidad: Lotes creados por este usuario
    lotes_creados = relationship("Lote", back_populates="creador")

class Lote(Base):
    __tablename__ = "lotes"
    id = Column(Integer, primary_key=True, index=True)
    codigo_lote = Column(String, unique=True, index=True, nullable=False)
    producto = Column(String, nullable=False)
    temp_min_ideal = Column(Float, nullable=False)
    temp_max_ideal = Column(Float, nullable=False)
    estado_actual = Column(String, default="OPTIMO") 
    
    # --- MEJORAS INDUSTRIALES ---
    entregado = Column(Boolean, default=False) # Si es True, el sensor ya no puede escribir
    fecha_creacion = Column(DateTime, default=datetime.datetime.utcnow)
    creador_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Quién registró el lote
    
    creador = relationship("User", back_populates="lotes_creados")
    telemetrias = relationship("Telemetria", back_populates="lote_perteneciente")

class Telemetria(Base):
    __tablename__ = "telemetrias"
    id = Column(Integer, primary_key=True, index=True)
    lote_id = Column(Integer, ForeignKey("lotes.id"), nullable=False)
    temperatura = Column(Float, nullable=False)
    humedad = Column(Float, nullable=False)
    fecha_registro = Column(DateTime, default=datetime.datetime.utcnow)
    
    lote_perteneciente = relationship("Lote", back_populates="telemetrias")