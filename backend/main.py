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
from sqlalchemy import text
from fastapi.security import OAuth2PasswordBearer
import httpx

# --- 1. App & DB Setup ---
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")  # iOS OAuth Client ID
ADMIN_EMAILS = os.getenv("ADMIN_EMAILS", "").split(",")  # Comma-separated admin emails

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found in .env file")
if not GOOGLE_CLIENT_ID:
    raise RuntimeError("GOOGLE_CLIENT_ID not found in .env file")

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

class GoogleAuthRequest(BaseModel):
    id_token: str

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
    hashed_password: Optional[str] = Field(default=None)  # Optional for Google OAuth users
    # google_id is optional - will be added via migration if needed
    # google_id: Optional[str] = Field(default=None, unique=True, index=True)
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

async def get_current_admin(current_user: User = Depends(get_current_user)) -> User:
    """Verify that the current user is an admin"""
    if current_user.email not in ADMIN_EMAILS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user

# --- 9. Auth Endpoint for iOS ---
@app.post("/auth/google", response_model=Token, tags=["auth"])
async def authenticate_with_google(
    auth_request: GoogleAuthRequest,
    session: Session = Depends(get_session)
):
    """
    Accept Google ID token from iOS app, verify it, and return JWT token.
    iOS app uses Google Sign-In SDK to get the ID token, then sends it here.
    """
    try:
        async with httpx.AsyncClient() as client:
            # Verify Google ID token
            verify_url = f"https://oauth2.googleapis.com/tokeninfo?id_token={auth_request.id_token}"
            response = await client.get(verify_url)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid Google token"
                )
            
            user_info = response.json()
            
            # Verify the token is for our app
            if user_info.get("aud") != GOOGLE_CLIENT_ID:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token was not issued for this application"
                )
            
            email = user_info.get("email")
            google_id = user_info.get("sub")
            name = user_info.get("name", email.split("@")[0] if email else "User")
            
            if not email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email not provided by Google"
                )
            
            # Verify UCSC email
            if not verify_ucsc_email(email):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only @ucsc.edu emails are allowed to access SlugSync"
                )
            
            # Get or create user
            try:
                user = session.exec(select(User).where(User.email == email)).first()
                
                if not user:
                    # Create new user (without password for Google OAuth users)
                    user = User(
                        email=email,
                        name=name,
                        hashed_password=None,  # Google users don't have passwords
                        is_host=False
                    )
                    session.add(user)
                    session.commit()
                    session.refresh(user)
                    print(f"✅ Created new user: {user.email}")
                else:
                    print(f"✅ Found existing user: {user.email}")
            except Exception as db_error:
                session.rollback()
                error_msg = str(db_error)
                print(f"❌ Database error in Google auth: {error_msg}")
                import traceback
                traceback.print_exc()
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Database error: {error_msg}. Please check backend logs."
                )
            
            # Create our JWT token
            access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
            access_token = create_access_token(
                data={"sub": user.email}, 
                expires_delta=access_token_expires
            )
            
            return {"access_token": access_token, "token_type": "bearer"}
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in Google authentication: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error: {str(e)}"
        )

# --- 9.5. Migration Endpoints (TEMPORARY - Remove after running once) ---
@app.post("/migrate/fix-database", tags=["migration"])
def migrate_fix_database():
    """
    TEMPORARY: Fix database schema for Google OAuth support.
    - Makes hashed_password nullable
    - Adds google_id column if it doesn't exist
    Run this once, then remove this endpoint.
    Call: POST https://your-backend.onrender.com/migrate/fix-database
    """
    try:
        with engine.connect() as conn:
            results = []
            
            # 1. Make hashed_password nullable
            try:
                conn.execute(text('ALTER TABLE "user" ALTER COLUMN hashed_password DROP NOT NULL'))
                conn.commit()
                results.append("✅ Made hashed_password nullable")
            except Exception as e:
                results.append(f"⚠️ hashed_password: {str(e)}")
            
            # 2. Add google_id column if it doesn't exist
            try:
                result = conn.execute(text("""
                    SELECT column_name 
                    FROM information_schema.columns 
                    WHERE table_name='user' AND column_name='google_id'
                """))
                
                if not result.fetchone():
                    conn.execute(text('ALTER TABLE "user" ADD COLUMN google_id VARCHAR(255)'))
                    conn.execute(text('CREATE INDEX IF NOT EXISTS ix_user_google_id ON "user"(google_id)'))
                    conn.commit()
                    results.append("✅ Added google_id column")
                else:
                    results.append("✅ google_id column already exists")
            except Exception as e:
                results.append(f"⚠️ google_id: {str(e)}")
            
            return {"status": "success", "messages": results}
    except Exception as e:
        return {"status": "error", "message": str(e)}

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

# REMOVED: Self-service host status endpoint
# Users can no longer make themselves hosts
# Admin approval is now required via /admin/users/{user_id}/approve-host

# --- 11. Admin Endpoints ---
@app.get("/admin/users", response_model=List[UserRead], tags=["admin"])
async def list_all_users(
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session),
    is_host: Optional[bool] = Query(None, description="Filter by host status")
):
    """List all users (admin only)"""
    statement = select(User)
    if is_host is not None:
        statement = statement.where(User.is_host == is_host)
    users = session.exec(statement).all()
    return [UserRead(
        id=user.id,
        email=user.email,
        name=user.name,
        is_host=user.is_host,
        created_at=user.created_at
    ) for user in users]

@app.patch("/admin/users/{user_id}/approve-host", response_model=UserRead, tags=["admin"])
async def approve_host_status(
    user_id: int,
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session)
):
    """Approve a user to become an event host (admin only)"""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.is_host:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already a host"
        )

    user.is_host = True
    session.add(user)
    session.commit()
    session.refresh(user)

    return UserRead(
        id=user.id,
        email=user.email,
        name=user.name,
        is_host=user.is_host,
        created_at=user.created_at
    )

@app.patch("/admin/users/{user_id}/revoke-host", response_model=UserRead, tags=["admin"])
async def revoke_host_status(
    user_id: int,
    admin: User = Depends(get_current_admin),
    session: Session = Depends(get_session)
):
    """Revoke a user's event host status (admin only)"""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not user.is_host:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a host"
        )

    user.is_host = False
    session.add(user)
    session.commit()
    session.refresh(user)

    return UserRead(
        id=user.id,
        email=user.email,
        name=user.name,
        is_host=user.is_host,
        created_at=user.created_at
    )

# --- 12. Event Endpoints ---
@app.get("/events/", response_model=List[EventOut], tags=["events"])
def list_events(
    session: Session = Depends(get_session),
    q: Optional[str] = Query(None, min_length=3),
    tag: Optional[str] = Query(None),
    start_date: Optional[datetime] = Query(None),
    limit: int = Query(50, ge=1, le=500)
):
    """List all events with optional filtering"""
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

@app.get("/events/{event_id}", response_model=EventOut, tags=["events"])
def get_event(event_id: int, session: Session = Depends(get_session)):
    """Get a specific event by ID"""
    event = session.get(EventModel, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event

@app.post("/events/", response_model=EventOut, status_code=status.HTTP_201_CREATED, tags=["events"])
def create_event(
    event_data: EventIn,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Create a new event (requires host status)"""
    if not current_user.is_host:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Only event hosts can create events. Update your profile to become a host."
        )
    
    db_event = EventModel.model_validate(event_data, update={"owner_id": current_user.id})
    session.add(db_event)
    session.commit()
    session.refresh(db_event)
    return EventOut.model_validate(db_event)

@app.patch("/events/{event_id}", response_model=EventOut, tags=["events"])
def update_event(
    event_id: int,
    event_update: EventUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Update an existing event (requires ownership)"""
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

@app.delete("/events/{event_id}", status_code=status.HTTP_200_OK, tags=["events"])
def delete_event(
    event_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Delete an event (requires ownership)"""
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
@app.get("/", tags=["health"])
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy", 
        "message": "SlugSync API is running",
        "version": "1.0.0"
    }
