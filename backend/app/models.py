from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Boolean, Index
from sqlalchemy.orm import relationship
from .database import Base
import datetime

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, nullable=False) 
    
    lotes_creados = relationship("Lote", back_populates="creador", foreign_keys="Lote.creador_id")
    lotes_bajo_custodia = relationship("Lote", back_populates="custodio", foreign_keys="Lote.custodio_id")
    mediciones_realizadas = relationship("Telemetria", back_populates="registrador")


class Lote(Base):
    __tablename__ = "lotes"
    id = Column(Integer, primary_key=True, index=True)
    codigo_lote = Column(String, unique=True, index=True, nullable=False)
    producto = Column(String, nullable=False)
    temp_min_ideal = Column(Float, nullable=False)
    temp_max_ideal = Column(Float, nullable=False)
    password_lote = Column(String, nullable=False) 
    estado_actual = Column(String, default="Esperando")
    entregado = Column(Boolean, default=False)
    fecha_creacion = Column(DateTime, default=datetime.datetime.utcnow, index=True) # Indexado para búsquedas rápidas en monitor
    
    creador_id = Column(Integer, ForeignKey("users.id"), nullable=False) 
    custodio_id = Column(Integer, ForeignKey("users.id"), nullable=True) 

    creador = relationship("User", back_populates="lotes_creados", foreign_keys=[creador_id])
    custodio = relationship("User", back_populates="lotes_bajo_custodia", foreign_keys=[custodio_id])
    
    telemetrias = relationship("Telemetria", back_populates="lote_perteneciente", cascade="all, delete-orphan")


class Telemetria(Base):
    __tablename__ = "telemetrias"
    id = Column(Integer, primary_key=True, index=True)
    lote_id = Column(Integer, ForeignKey("lotes.id"), nullable=False, index=True)
    usuario_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    temperatura = Column(Float, nullable=False)
    humedad = Column(Float, nullable=False)
    diagnostico = Column(String, nullable=True) 
    
    # Indexamos la fecha de registro para consultas de rango de tiempo ultra rápidas
    fecha_registro = Column(DateTime, default=datetime.datetime.utcnow, index=True)
    
    lote_perteneciente = relationship("Lote", back_populates="telemetrias")
    registrador = relationship("User", back_populates="mediciones_realizadas")

# ==========================================================================
# 🛑 ÍNDICES COMPUESTOS DE RENDIMIENTO INDUSTRIAL (NUEVO) 🛑
# ==========================================================================
# Este índice le permite a SQLite resolver la query de filtros de la pantalla de detalles
# buscando directamente por lote e intervalo de tiempo de forma combinada.
Index("idx_lote_fecha", Telemetria.lote_id, Telemetria.fecha_registro)