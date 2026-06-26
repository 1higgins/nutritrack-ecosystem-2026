from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from .database import Base
import datetime

# models.py

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    # Cambiamos el default a OPA por seguridad (o dejarlo sin default)
    role = Column(String, nullable=False) 
    
    lotes_creados = relationship("Lote", back_populates="creador", foreign_keys="Lote.creador_id")
    # Relación para los lotes que un OPT tiene asignados
    lotes_bajo_custodia = relationship("Lote", back_populates="custodio", foreign_keys="Lote.custodio_id")
    mediciones_realizadas = relationship("Telemetria", back_populates="registrador")

class Lote(Base):
    __tablename__ = "lotes"
    id = Column(Integer, primary_key=True, index=True)
    codigo_lote = Column(String, unique=True, index=True, nullable=False)
    producto = Column(String, nullable=False)
    temp_min_ideal = Column(Float, nullable=False)
    temp_max_ideal = Column(Float, nullable=False)
    cantidad = Column(Integer, nullable=False)
    
    # --- NUEVO: Seguridad de Acceso ---
    password_lote = Column(String, nullable=False) 
    
    estado_actual = Column(String, default="OPTIMO") 
    entregado = Column(Boolean, default=False)
    fecha_creacion = Column(DateTime, default=datetime.datetime.utcnow)
    
    # Dueño original (OPA)
    creador_id = Column(Integer, ForeignKey("users.id"), nullable=False) 
    # Custodio actual (OPT) - Puede ser nulo al inicio hasta que el OPT se vincule
    custodio_id = Column(Integer, ForeignKey("users.id"), nullable=True) 

    creador = relationship("User", back_populates="lotes_creados", foreign_keys=[creador_id])
    custodio = relationship("User", back_populates="lotes_bajo_custodia", foreign_keys=[custodio_id])
    
    telemetrias = relationship("Telemetria", back_populates="lote_perteneciente", cascade="all, delete-orphan")

class Telemetria(Base):
    __tablename__ = "telemetrias"
    id = Column(Integer, primary_key=True, index=True)
    lote_id = Column(Integer, ForeignKey("lotes.id"), nullable=False)
    
    # AUDITORÍA: ¿Qué usuario o sensor autenticado envió este dato?
    usuario_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    temperatura = Column(Float, nullable=False)
    humedad = Column(Float, nullable=False)
    
    # INTELIGENCIA: El mensaje de diagnóstico generado por alerts.py
    diagnostico = Column(String, nullable=True) 
    
    fecha_registro = Column(DateTime, default=datetime.datetime.utcnow)
    
    lote_perteneciente = relationship("Lote", back_populates="telemetrias")
<<<<<<< Updated upstream
    registrador = relationship("User", back_populates="mediciones_realizadas")
=======
    registrador = relationship("User", back_populates="mediciones_realizadas")

# Este índice le permite a SQLite resolver la query de filtros de la pantalla de detalles
# buscando directamente por lote e intervalo de tiempo de forma combinada.
Index("idx_lote_fecha", Telemetria.lote_id, Telemetria.fecha_registro)
>>>>>>> Stashed changes
