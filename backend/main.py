from fastapi import FastAPI, HTTPException, Query, status, Depends
from typing import List, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel, Field, model_validator, EmailStr
from dotenv import load_dotenv
import os
from jose import jwt
from jose.exceptions import JWTError
from sqlmodel import Field, Session, SQLModel, create_engine, select, Relationship
from passlib.context import CryptContext
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

# --- 1. App & DB Setup ---
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found in .env file")

app = FastAPI(title="SlugSync API")
engine = create_engine(DATABASE_URL, echo=False)

# --- 2. Security Setup ---
SECRET_KEY = os.getenv("SECRET_KEY", "lkasdjkjfadskljflpraneethkajf8923983")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 # 1 day

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- 3. Security Models ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# --- 4. User Models ---
# This base model is for API VALIDATION
class UserBase(SQLModel):
    email: EmailStr = Field(index=True, unique=True) # Use EmailStr for API validation

# This model is for API INPUT (Registration)
class UserCreate(UserBase):
    name: str = Field(..., min_length=1, max_length=100, description="User full name")
    password: str
    is_host: bool = Field(default=False) # Field to determine if user is a host

# This is the DATABASE TABLE model
# It does NOT inherit from UserBase to avoid the EmailStr problem
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(index=True, unique=True) # Use a simple str for DB storage
    name: str = Field(..., min_length=1, max_length=100)
    hashed_password: str
    is_host: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    # Corrected relationship to point to "EventModel"
    events: List["EventModel"] = Relationship(back_populates="owner")

# This is the API OUTPUT model
class UserRead(UserBase):
    id: int
    name: str
    is_host: bool # Show role in API response
    created_at: datetime

# --- 5. Event Models ---
# Database Table Model (Cleaned: no API validation here)
class EventModel(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    starts_at: datetime
    location: str
    ends_at: Optional[datetime] = Field(default=None)
    description: Optional[str] = Field(default=None)
    host: Optional[str] = Field(default=None) # Display name of host
    tags: Optional[str] = Field(default=None) # Stored as comma-separated string
    created_at: datetime = Field(default_factory=datetime.utcnow, nullable=False)
    owner_id: Optional[int] = Field(default=None, foreign_key="user.id", nullable=True, index=True)
    owner: Optional[User] = Relationship(back_populates="events") # Link back to User

# API Input Model for creating
class EventIn(SQLModel):
    name: str = Field(..., min_length=1, max_length=120, description="Event title")
    starts_at: datetime = Field(..., description="Start time (ISO 8601)")
    ends_at: Optional[datetime] = Field(None, description="End time (ISO 8601)")
    location: str = Field(..., min_length=1, max_length=160, description="Where the event happens")
    description: Optional[str] = Field(None, max_length=10000)
    host: Optional[str] = Field(None, max_length=300)
    tags: Optional[str] = Field(default=None, description="Comma-separated tags e.g. 'career,tech'")

    @model_validator(mode="after")
    def check_times(self):
        if self.ends_at and self.ends_at <= self.starts_at:
            raise ValueError("ends_at must be after starts_at")
        return self

# API Output Model
class EventOut(SQLModel):
    id: int
    name: str
    starts_at: datetime
    location: str
    ends_at: Optional[datetime] = None
    description: Optional[str] = None
    host: Optional[str] = None
    tags: Optional[str] = None
    created_at: datetime
    owner_id: Optional[int] = None

# API Update Model
class EventUpdate(SQLModel):
    name: Optional[str] = Field(None, min_length=1, max_length=120)
    location: Optional[str] = Field(None, min_length=1, max_length=160)
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    description: Optional[str] = Field(None, max_length=10000)
    host: Optional[str] = Field(None, max_length=300)
    tags: Optional[str] = Field(None) # Corrected type to Optional[str]

# --- 6. Database Setup ---
def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

# Dependency to get a database session
def get_session():
    with Session(engine) as session:
        yield session

# --- 7. Auth Utility Functions ---
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# --- 8. Auth Dependency ---
async def get_current_user(token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    
    user = session.exec(select(User).where(User.email == token_data.email)).first()
    if user is None:
        raise credentials_exception
    return user

# --- 9. Auth Endpoints ---
@app.post("/users/", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register_user(user_data: UserCreate, session: Session = Depends(get_session)):
    existing_user = session.exec(select(User).where(User.email == user_data.email)).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    hashed_password = get_password_hash(user_data.password)
    db_user = User(
        email=user_data.email,
        name=user_data.name,
        hashed_password=hashed_password,
        is_host=user_data.is_host # Correctly sets the user's role
    )
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user

# Alternative registration endpoint for compatibility with frontend
@app.post("/users/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register_user_alt(user_data: UserCreate, session: Session = Depends(get_session)):
    """Alternative registration endpoint that matches frontend expectations"""
    return register_user(user_data, session)

@app.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.email == form_data.username)).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# --- 10. Event Endpoints ---

# GET endpoints remain unprotected
@app.get("/events/", response_model=List[EventOut])
def list_events(
    session: Session = Depends(get_session),
    q: Optional[str] = Query(None, min_length=3),
    tag: Optional[str] = Query(None),
    start_date: Optional[datetime] = Query(None),
    limit: int = Query(50, ge=1, le=500)
):
    statement = select(EventModel)
    if start_date:
        statement = statement.where(EventModel.starts_at >= start_date)
    
    results = session.exec(statement).all()
    
    filtered_results = []
    for event in results:
        if q:
            q_lower = q.lower()
            if not (q_lower in event.name.lower() or
                    q_lower in (event.description or "").lower() or
                    q_lower in event.location.lower()):
                continue
        if tag:
            tag_lower = tag.lower()
            # Assumes tags is a comma-separated string
            event_tags = [t.strip().lower() for t in (event.tags or "").split(',') if t.strip()]
            if tag_lower not in event_tags:
                continue
        filtered_results.append(event)
    
    filtered_results.sort(key=lambda e: e.starts_at, reverse=True)
    
    # Convert EventModel to EventOut
    return [EventOut.model_validate(ev) for ev in filtered_results[:limit]]

@app.get("/events/{event_id}", response_model=EventOut)
def get_event(event_id: int, session: Session = Depends(get_session)):
    event = session.get(EventModel, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event # Automatic conversion by FastAPI

# POST /events/ requires login AND user must be a host
@app.post("/events/", response_model=EventOut, status_code=status.HTTP_201_CREATED)
def create_event(
    event_data: EventIn,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    if not current_user.is_host:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only event hosts can create events.")
    
    # model_validate creates a new EventModel from the EventIn data
    # and adds the owner_id from the current_user
    db_event = EventModel.model_validate(event_data, update={"owner_id": current_user.id})
    session.add(db_event)
    session.commit()
    session.refresh(db_event)
    # Return an EventOut model
    return EventOut.model_validate(db_event)

# PATCH /events/{event_id} requires login and ownership
@app.patch("/events/{event_id}", response_model=EventOut)
def update_event(
    event_id: int,
    event_update: EventUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    db_event = session.get(EventModel, event_id)
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")

    # --- AUTHORIZATION: Check ownership ---
    if db_event.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to modify this event")

    update_data = event_update.model_dump(exclude_unset=True)
    
    # Update the db_event object with new data
    db_event.sqlmodel_update(update_data)
    
    session.add(db_event)
    session.commit()
    session.refresh(db_event)
    return EventOut.model_validate(db_event)

# DELETE /events/{event_id} requires login and ownership
@app.delete("/events/{event_id}", status_code=status.HTTP_200_OK)
def delete_event(
    event_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    event = session.get(EventModel, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    # --- AUTHORIZATION: Check ownership ---
    if event.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this event")

    session.delete(event)
    session.commit()
    # Return a success message instead of nothing
    return {"message": "Event deleted successfully"}
