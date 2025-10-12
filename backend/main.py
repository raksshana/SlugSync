from fastapi import FastAPI, HTTPException, Query, status
from typing import List, Optional, Dict
from datetime import datetime
from pydantic import BaseModel, Field, model_validator, EmailStr
from uuid import uuid4
import os
from dotenv import load_dotenv
from sqlmodel import Field, Session, SQLModel, create_engine, select




app = FastAPI()
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL, echo=False)

# Create database tables
SQLModel.metadata.create_all(engine)

#necessary attributes of an event: name(str), organizer(str), contact email(str), location(str), date(str), description(str)
class EventIn(BaseModel):
    name: str = Field(..., min_length=1, max_length=120, description="Event title")
    starts_at: datetime = Field(..., description="Start time (ISO 8601, e.g. 2025-10-15T15:00:00-07:00)")
    ends_at: Optional[datetime] = Field(None, description="End time (ISO 8601)")
    location: str = Field(..., min_length=1, max_length=160, description="Where the event happens")
    description: str = Field(None, max_length=10000)
    host: str = Field(None, max_length=300)
    tags: List[str] = Field(default_factory=list, description="Freeform labels like ['career','tech']")
    
    
    #checks if datetimes are valid
    @model_validator(mode="after")
    def check_times(self):
        # This method runs AFTER Pydantic has parsed & type-checked all fields.
        if self.ends_at and self.ends_at <= self.starts_at:
            # Raising ValueError signals a validation failure for the whole model.
            raise ValueError("ends_at must be after starts_at")
        return self  # Must return the (possibly modified) model instance
    #could add a bunch of optional stuff i'll work it out later

class EventOut(EventIn):
    id: str
    created_at: datetime

class EventUpdate(BaseModel):   #everything optional incase something needs to be updated
    name: Optional[str] = None
    organizer: Optional[str] = None
    contact_email: Optional[EmailStr] = None
    location: Optional[str] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    description: Optional[str] = None
    tags: Optional[List[str]] = None

# Database model
class EventModel(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    starts_at: datetime
    ends_at: Optional[datetime] = None
    location: str
    description: Optional[str] = None
    host: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
#necessary routes for the app: default get for populating the fyp of the app, add_events, remove_events, search bar feature.


events_db: Dict[str, EventOut] = {}


#__________________________________________________________GET__________________________________________________________________________________________

#default view that just gets all the events and displays them
@app.get("/events", response_model=List[EventOut])
def list_events(
    q: Optional[str] = Query(None, min_length=3, description="Search term for name, description, location"),
    tag: Optional[str] = Query(None, description="Filter by a specific tag"),
    start_date: Optional[datetime] = Query(None, description="Find events starting after this date"),
    limit: int = Query(50, ge=1, le=500)
):
    with Session(engine) as session:
        # Get all events from database
        statement = select(EventModel)
        
        # Apply filters
        if start_date:
            statement = statement.where(EventModel.starts_at >= start_date)
        
        events = session.exec(statement).all()
        
        # Convert to EventOut format
        results = []
        for event in events:
            # Apply search filter if provided
            if q:
                q_lower = q.lower()
                if not (q_lower in event.name.lower() or
                       q_lower in (event.description or "").lower() or
                       q_lower in event.location.lower()):
                    continue
            
            # Apply tag filter if provided
            if tag:
                tag_lower = tag.lower()
                if tag_lower not in [t.lower() for t in event.tags]:
                    continue
            
            results.append(EventOut(
                id=str(event.id),
                name=event.name,
                starts_at=event.starts_at,
                ends_at=event.ends_at,
                location=event.location,
                description=event.description,
                host=event.host,
                tags=event.tags,
                created_at=event.created_at
            ))
        
        # Sort by start time (most recent first) and limit
        results.sort(key=lambda e: e.starts_at, reverse=True)
        return results[:limit]



#When user clicks on certain event, event details will be pulled with unique event_id
@app.get("/events/{event_id}", response_model = EventOut)
def get_event(event_id : str):
    if event_id not in events_db:
        raise HTTPException(status_code = 404, detail= "Event not found")
    return events_db[event_id]



#____________________________________________________________POST__________________________________________________________________________________________

@app.post("/events", response_model = EventOut, status_code = 201)    #create new event
def create_event(event_db: EventIn):
    with Session(engine) as session:
        # Create database record
        db_event = EventModel(
            name=event_db.name,
            starts_at=event_db.starts_at,
            ends_at=event_db.ends_at,
            location=event_db.location,
            description=event_db.description,
            host=event_db.host,
            tags=event_db.tags
        )
        session.add(db_event)
        session.commit()
        session.refresh(db_event)
        
        # Convert to EventOut format
        return EventOut(
            id=str(db_event.id),
            name=db_event.name,
            starts_at=db_event.starts_at,
            ends_at=db_event.ends_at,
            location=db_event.location,
            description=db_event.description,
            host=db_event.host,
            tags=db_event.tags,
            created_at=db_event.created_at
        )



#update event
@app.post("/events/{event_id}", response_model = EventOut)
def update_event(event_id : str, event_update: EventUpdate):
    if event_id not in events_db:
        raise HTTPException(status_code=404, detail="Event not found")
    # Get the existing event data
    stored_event = events_db[event_id]
    
    # Create a dictionary from the stored event Pydantic model
    update_data = event_update.model_dump(exclude_unset=True)  #Pydantic Model, event_update, is converted into a python dictionary with .model_dump. Exclude_unset includes only the fields sent by the client
    
    # Update the stored model with the new data
    updated_event = stored_event.model_copy(update=update_data)
    try:
        validated_event = EventOut(**updated_event.model_dump())
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
        
    events_db[event_id] = validated_event
    return validated_event
#_______________________________________________________DELETE__________________________________________________________________________________________

@app.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_event(event_id: str):
    with Session(engine) as session:
        # Find the event in database - handle both string and int IDs
        try:
            # Try to convert to int first (for database IDs)
            event_id_int = int(event_id)
            statement = select(EventModel).where(EventModel.id == event_id_int)
        except ValueError:
            # If conversion fails, treat as string ID (for UUIDs)
            statement = select(EventModel).where(EventModel.id == event_id)
        
        event = session.exec(statement).first()
        
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        
        # Delete the event
        session.delete(event)
        session.commit()
    
    return
