from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Estándar profesional: Nombre de DB descriptivo
SQLALCHEMY_DATABASE_URL = "sqlite:///./nutritrack.db"

# Engine: El motor de comunicación. 
# check_same_thread=False es vital para que FastAPI (asíncrono) trabaje con SQLite.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

# Sesión: La interfaz para hacer consultas
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base: Clase maestra para que SQLAlchemy reconozca nuestros modelos
Base = declarative_base()

# Inyección de dependencia: Garantiza que la sesión se cierre tras cada uso,
# evitando fugas de memoria y bloqueos de DB.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()