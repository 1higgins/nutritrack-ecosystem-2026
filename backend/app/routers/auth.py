from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status, APIRouter
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from .. import database, models, schemas
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter(tags=["Seguridad"])

# --- CONFIGURACIÓN DE SEGURIDAD INDUSTRIAL ---
SECRET_KEY = "NutriTrack_Secret_Key_2026_Secure" 
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 240

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- FUNCIONES DE APOYO (Hashing & Tokens) ---
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(
    token: str = Depends(oauth2_scheme), 
    db: Session = Depends(database.get_db)
) -> models.User:
    """
    Interpela el Token JWT, valida la firma y recupera el objeto User de la DB.
    Esta es la barrera principal para endpoints protegidos.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Sesión inválida o expirada. Por favor, reautentíquese.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(models.User).filter(models.User.username == username).first()
    if user is None:
        raise credentials_exception
        
    return user


@router.post("/register", response_model=schemas.UserRead, status_code=status.HTTP_201_CREATED)
def registrar_usuario(
    user_in: schemas.UserCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    SISTEMA DE CONTROL DE ACCESO JERÁRQUICO (RBAC):
    1. OPA/OPT: Tienen prohibido el acceso a este endpoint (403).
    2. Admin: Solo puede crear OPA o OPT. Intentar crear otro Admin resulta en 403.
    3. Epsilon: Único usuario con bypass para crear Administradores.
    """
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operación prohibida. Su rol no tiene permisos de gestión de usuarios."
        )

   
    if user_in.role == schemas.UserRole.admin:
        if current_user.username != "Epsilon":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Seguridad Crítica: Solo el Fundador (Epsilon) puede autorizar nuevos Administradores."
            )
        

    exist_user = db.query(models.User).filter(models.User.username == user_in.username).first()
    if exist_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Error de registro: El nombre de usuario ya está ocupado."
        )

    new_user = models.User(
        username=user_in.username,
        hashed_password=get_password_hash(user_in.password),
        role=user_in.role.value  # Guardamos 'admin', 'OPA' o 'OPT'
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

def asegurar_usuario_semilla(db: Session):
    """Garantiza la existencia del administrador inicial 'Epsilon' con rol admin."""
    username_epsilon = "Epsilon"
    user = db.query(models.User).filter(models.User.username == username_epsilon).first()
    
    if not user:
        print(f"[SISTEMA] 🔐 Inicializando Usuario Maestro: {username_epsilon}...")
        new_user = models.User(
            username=username_epsilon,
            hashed_password=get_password_hash("a12345"), 
            role="admin" 
        )
        db.add(new_user)
        db.commit()

@router.post("/token", response_model=schemas.Token)
def login_para_access_token(
    db: Session = Depends(database.get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(
        data={
            "sub": user.username,
            "role": user.role
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "username": user.username 
    }