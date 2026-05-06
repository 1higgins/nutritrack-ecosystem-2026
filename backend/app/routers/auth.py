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

# Configuración de Seguridad
SECRET_KEY = "NutriTrack_Secret_Key_2026_Secure" 
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 120

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# FUNCIONES DE APOYO
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def asegurar_usuario_admin(db: Session):
    admin_username = "admin_nutritrack"
    user = db.query(models.User).filter(models.User.username == admin_username).first()
    
    if not user:
        print(f"🛠️ [SISTEMA] Creando usuario maestro: {admin_username}...")
        hashed_pw = get_password_hash("nutritrack2026")
        new_admin = models.User(
            username=admin_username,
            hashed_password=hashed_pw,
            role="admin"
        )
        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)
        return new_admin
    return user

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido, expirado o usuario no registrado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = schemas.TokenData(username=username)
    except JWTError:
        raise credentials_exception
    
    user = db.query(models.User).filter(models.User.username == token_data.username).first()
    
    if user is None and token_data.username == "admin_nutritrack":
        user = asegurar_usuario_admin(db)
        
    if user is None:
        raise credentials_exception
    return user

# --- ENDPOINT DE REGISTRO ---
@router.post("/register", response_model=schemas.UserRead)
def registrar_usuario(usuario: schemas.UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.username == usuario.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="El usuario ya existe")
    
    hashed_pw = get_password_hash(usuario.password)
    nuevo_usuario = models.User(
        username = usuario.username,
        hashed_password = hashed_pw,
        role = usuario.role
    )
    
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    
    return nuevo_usuario
    
# --- ENDPOINT DE LOGIN ---
@router.post("/login", response_model=schemas.Token)
def login_para_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    
    if not user and form_data.username == "admin_nutritrack":
        user = asegurar_usuario_admin(db)
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    access_token = create_access_token(
        data={"sub": user.username}, 
    )
    return {"access_token": access_token, "token_type": "bearer"}