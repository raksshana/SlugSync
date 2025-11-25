from fastapi import FastAPI, HTTPException, Query, status, Depends, Request
from fastapi.responses import RedirectResponse
from typing import List, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel, Field, model_validator, EmailStr
from dotenv import load_dotenv
import os
from jose import jwt
from jose.exceptions import JWTError
from sqlmodel import Field, Session, SQLModel, create_engine, select, Relationship
from fastapi.security import OAuth2PasswordBearer
import httpx

# --- 1. App & DB Setup ---
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")
GOOGLE_REDIRECT_URI = os.getenv("GOOGLE_REDIRECT_URI", "https://slugsync-1.onrender.com/auth/google/callback")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found in .env file")
if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
    raise RuntimeError("Google OAuth credentials not found in .env file")

app = FastAPI(title="SlugSync API")
engine = create_engine(DATABASE_URL, echo=False)

# --- 2. Security Setup ---
SECRET_KEY = os.getenv("SECRET_KEY", "lkasdjkjfadskljflpraneethkajf8923983")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 1 week

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token", auto_error=False)

# --- 3. Security Models ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# --- 4. User Models ---
class UserBase(SQLModel):
    email: EmailStr = Field(index=True, unique=True)
    name: str = Field(min_length=1, max_length=100)

class UserCreate(BaseModel):
    email: EmailStr
    name: str
    is_host: bool = False

# Database table
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True)
    name: str
    google_id: Optional[str] = Field(default=None, unique=True, index=True)
    is_host: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    events: List["EventModel"] = Relationship(back_populates="owner")

# API Output
class UserRead(BaseModel):
    id: int
    email: str
    name: str
    is_host: bool
    created_at: datetime

# --- 5. Event Models ---
class EventModel(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    starts_at: datetime
    location: str
    ends_at: Optional[datetime]
    description: Optional[str]
    host: Optional[str]
    tags: Optional[str]
    created_at: datetime = Field(default_factory=datetime.utcnow)
    owner_id: Optional[int] = Field(default=None, foreign_key="user.id")
    owner: Optional[User] = Relationship(back_populates="events")

class EventIn(BaseModel):
    name: str
    starts_at: datetime
    ends_at: Optional[datetime]
    location: str
    description: Optional[str]
    host: Optional[str]
    tags: Optional[str]

    @model_validator(mode="after")
    def check_times(self):
        if self.ends_at and self.ends_at <= self.starts_at:
            raise ValueError("ends_at must be after starts_at")
        return self

class EventOut(BaseModel):
    id: int
    name: str
    starts_at: datetime
    location: str
    ends_at: Optional[datetime]
    description: Optional[str]
    host: Optional[str]
    tags: Optional[str]
    created_at: datetime
    owner_id: Optional[int]

class EventUpdate(SQLModel):
    name: Optional[str] = Field(None, min_length=1, max_length=120)
    location: Optional[str] = Field(None, min_length=1, max_length=160)
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    description: Optional[str] = Field(None, max_length=10000)
    host: Optional[str] = Field(None, max_length=300)
    tags: Optional[str] = Field(None)

# --- 6. Database Setup ---
def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

def get_session():
    with Session(engine) as session:
        yield session

# --- 7. Auth Utility Functions ---
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_ucsc_email(email: str) -> bool:
    """Verify that the email is from UCSC (@ucsc.edu)"""
    return email.lower().endswith("@ucsc.edu")

# --- 8. Auth Dependency ---
async def get_current_user(
    token: str = Depends(oauth2_scheme), 
    session: Session = Depends(get_session)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    if not token:
        raise credentials_exception
    
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

# --- 9. Google OAuth Endpoints ---
@app.get("/auth/google/login")
async def google_login():
    """Initiate Google OAuth login"""
    google_auth_url = (
        "https://accounts.google.com/o/oauth2/v2/auth?"
        f"client_id={GOOGLE_CLIENT_ID}&"
        f"redirect_uri={GOOGLE_REDIRECT_URI}&"
        "response_type=code&"
        "scope=openid email profile&"
        "access_type=offline&"
        "prompt=consent"
    )
    return RedirectResponse(url=google_auth_url)

@app.get("/auth/google/callback")
async def google_callback(code: str, session: Session = Depends(get_session)):
    """Handle Google OAuth callback"""
    
    # Exchange authorization code for access token
    token_url = "https://oauth2.googleapis.com/token"
    token_data = {
        "code": code,
        "client_id": GOOGLE_CLIENT_ID,
        "client_secret": GOOGLE_CLIENT_SECRET,
        "redirect_uri": GOOGLE_REDIRECT_URI,
        "grant_type": "authorization_code",
    }
    
    async with httpx.AsyncClient() as client:
        token_response = await client.post(token_url, data=token_data)
        token_json = token_response.json()
        
        if "error" in token_json:
            raise HTTPException(status_code=400, detail=token_json["error"])
        
        access_token = token_json.get("access_token")
        
        # Get user info from Google
        userinfo_url = "https://www.googleapis.com/oauth2/v2/userinfo"
        headers = {"Authorization": f"Bearer {access_token}"}
        userinfo_response = await client.get(userinfo_url, headers=headers)
        user_info = userinfo_response.json()
    
    email = user_info.get("email")
    google_id = user_info.get("id")
    name = user_info.get("name", email.split("@")[0])
    
    # Verify UCSC email
    if not verify_ucsc_email(email):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only @ucsc.edu emails are allowed to access SlugSync"
        )
    
    # Check if user exists, if not create them
    user = session.exec(select(User).where(User.email == email)).first()
    
    if not user:
        # Create new user
        user = User(
            email=email,
            name=name,
            google_id=google_id,
            is_host=False
        )
        session.add(user)
        session.commit()
        session.refresh(user)
    else:
        # Update google_id if it wasn't set
        if not user.google_id:
            user.google_id = google_id
            session.add(user)
            session.commit()
            session.refresh(user)
    
    # Create JWT token for our app
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    jwt_token = create_access_token(
        data={"sub": user.email}, 
        expires_delta=access_token_expires
    )
    
    # Redirect to frontend with token
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")
    return RedirectResponse(url=f"{frontend_url}/auth/callback?token={jwt_token}")

@app.post("/token", response_model=Token)
async def create_token_from_google(google_token: str, session: Session = Depends(get_session)):
    """
    Alternative endpoint: Accept Google ID token directly from frontend
    This is useful if you want to handle OAuth on the frontend
    """
    async with httpx.AsyncClient() as client:
        # Verify Google token
        verify_url = f"https://oauth2.googleapis.com/tokeninfo?id_token={google_token}"
        response = await client.get(verify_url)
        
        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Google token"
            )
        
        user_info = response.json()
        
        email = user_info.get("email")
        google_id = user_info.get("sub")
        name = user_info.get("name", email.split("@")[0])
        
        # Verify UCSC email
        if not verify_ucsc_email(email):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only @ucsc.edu emails are allowed"
            )
        
        # Get or create user
        user = session.exec(select(User).where(User.email == email)).first()
        
        if not user:
            user = User(
                email=email,
                name=name,
                google_id=google_id,
                is_host=False
            )
            session.add(user)
            session.commit()
            session.refresh(user)
        
        # Create our JWT token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.email}, 
            expires_delta=access_token_expires
        )
        
        return {"access_token": access_token, "token_type": "bearer"}

# --- 10. User Endpoints ---
@app.get("/users/me", response_model=UserRead, tags=["users"])
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get the current logged-in user's information"""
    return UserRead(
        id=current_user.id,
        email=current_user.email,
        name=current_user.name,
        is_host=current_user.is_host,
        created_at=current_user.created_at
    )

@app.patch("/users/me/host-status", response_model=UserRead, tags=["users"])
async def update_host_status(
    is_host: bool,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session)
):
    """Allow users to become event hosts"""
    current_user.is_host = is_host
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    
    return UserRead(
        id=current_user.id,
        email=current_user.email,
        name=current_user.name,
        is_host=current_user.is_host,
        created_at=current_user.created_at
    )

# --- 11. Event Endpoints ---
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
            event_tags = [t.strip().lower() for t in (event.tags or "").split(',') if t.strip()]
            if tag_lower not in event_tags:
                continue
        filtered_results.append(event)
    
    filtered_results.sort(key=lambda e: e.starts_at, reverse=True)
    
    return [EventOut.model_validate(ev) for ev in filtered_results[:limit]]

@app.get("/events/{event_id}", response_model=EventOut)
def get_event(event_id: int, session: Session = Depends(get_session)):
    event = session.get(EventModel, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event

@app.post("/events/", response_model=EventOut, status_code=status.HTTP_201_CREATED)
def create_event(
    event_data: EventIn,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    if not current_user.is_host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Only event hosts can create events."
        )
    
    db_event = EventModel.model_validate(event_data, update={"owner_id": current_user.id})
    session.add(db_event)
    session.commit()
    session.refresh(db_event)
    return EventOut.model_validate(db_event)

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

    if db_event.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to modify this event"
        )

    update_data = event_update.model_dump(exclude_unset=True)
    db_event.sqlmodel_update(update_data)
    
    session.add(db_event)
    session.commit()
    session.refresh(db_event)
    return EventOut.model_validate(db_event)

@app.delete("/events/{event_id}", status_code=status.HTTP_200_OK)
def delete_event(
    event_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    event = session.get(EventModel, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    if event.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Not authorized to delete this event"
        )

    session.delete(event)
    session.commit()
    return {"message": "Event deleted successfully"}

# --- 12. Health Check ---
@app.get("/")
def health_check():
    return {"status": "healthy", "message": "SlugSync API is running"}
