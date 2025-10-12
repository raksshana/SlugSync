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
    # Start with all events, sorted by start time (most recent first)
    # Using list() creates a copy so we don't modify the original values
    results = sorted(list(events_db.values()), key=lambda e: e.starts_at, reverse=True)

    # Apply search query if provided
    if q:
        q_lower = q.lower()
        results = [
            event for event in results 
            if q_lower in event.name.lower() or 
               (event.description and q_lower in event.description.lower()) or
               q_lower in event.location.lower()
        ]

    # Apply tag filter if provided
    if tag:
        tag_lower = tag.lower()
        # Ensure tags are compared case-insensitively
        results = [event for event in results if tag_lower in [t.lower() for t in event.tags]]

    # Apply date filter if provided
    if start_date:
        results = [event for event in results if event.starts_at >= start_date]

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
    saved = EventOut(
        **event_db.model_dump(),
        id=str(uuid4()),                 # server-generated
        created_at=datetime.utcnow(),    # server-generated
    )
    events_db[saved.id] = saved
    return saved



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
    if event_id not in events_db:
        raise HTTPException(status_code = 404, detail= "Event not found")
    del events_db[event_id]
    return
















# (Your models go here)

# --- DATABASE (IN-MEMORY) ---
# --- API ENDPOINTS ---

