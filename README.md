# SlugSync



The problem many UCSC students face, especially Freshmen, is finding events to connect with others to make friends/socialize. To find UCSC club events, students must research on Instagram by searching for each club and determining where/when the event is taking place. We have personally faced this problem, as we were unable to find some of the events we wanted to attend, and ended up missing out on a great opportunity. But now, with our app, students don't need to worry about any of this, as our app, SlugSync is a one-stop destination that centralizes all of the events into one place and gives a description about the event while showing the whereabouts of the event. 

As we briefly stated above, some major effects caused by this problem are missing out on great opportunities because students simply do not have the time to or do not know how to, find each club event on Instagram that they want to go to. Another effect of this problem is a lower turnout rate at the actual event, as many people may not be able to find the events on Instagram. With SlugSync, club owners/reps can also add their own events to the app so students can find them easily, leading to a higher turnout rate.                                

The target audience of our app is UCSC students. SlugSync is specifically designed for UCSC events to be posted on it for UCSC students to attend. 

Students would use SlugSync because of the easy-to-use UI/UX that we have, leading them to remember all of the events since they're all in one spot, which also reduces the amount of time students spend scrolling through multiple Instagram accounts. Through SlugSync, students can also find new clubs/events that they never knew about, since all of the events happening will be in one centralized spot. 

# Tech Stack

Frontend – Swift (iOS App):
We used Swift to build the IOS app, and it handles everything users see and interact with like buttons, event listings, and swiping features. By using Swift, we were able to make the app on IOS and make sure the users have a clear and easy-to-use interface.

Backend – FastAPI (Python):
The backend is powered by FastAPI, a modern and high-performance web framework for Python. It processes requests from the app, such as logging in users, fetching event data, and storing user preferences. FastAPI is known for being fast, easy to scale, and great for building APIs that communicate with mobile apps.

Database – SQL:
All the app’s data — like user accounts, events, and preferences — is stored in an SQL database. This ensures that data is organized, easily accessible, and secure. The backend connects to the database to read or update data whenever needed.

Deployment – Render:
The FastAPI backend and database are deployed on Render, a cloud platform that hosts web apps and APIs. Render keeps the backend running online 24/7, so the iOS app can connect to it anytime. It automatically manages scaling, updates, and uptime.


# Features 


- Event Feed: Browse upcoming UCSC club events in one centralized feed.

- Search & Filters: Find events by date, category, or club.

- Favorites: Save events you’re interested in.

- Club Submissions: Club reps can upload their own events directly through the app.

- Map Integration: View where events are happening across campus.


# User Flow 


- The user opens the app and signs in with their UCSC email.

- The home screen shows all upcoming events in a card-swiping format.

- Swiping right saves the event to their “Interested” list; swiping left skips it.

- Users can tap an event to view details, location, and club info.

- Club reps can log in through a special portal to post new events.


# App Flow

SlugSync App Workflow
1. User Opens the App (Frontend – Swift)

The user launches the SlugSync iOS app built in Swift.

The app displays a login or sign-up screen.

The user logs in using their UCSC email (authentication request sent to backend).

2. Backend Authenticates the User (FastAPI)

The FastAPI backend receives the login request.

It verifies the credentials against the SQL database.

If valid, the backend sends back an authentication token (session ID).

The user is redirected to the home screen.

3. Event Feed Loads (Frontend ↔ Backend ↔ Database)

The app sends a request to the backend:
GET /events

FastAPI fetches all current events from the SQL database (including event name, date, time, location, and description).

The backend sends the event data to the Swift app in JSON format.

The Swift app displays these events as swipeable cards in the UI.

4. User Interaction with Events (Frontend)

The user browses through events by swiping right (interested) or left (skip).

When swiping right, the app sends a request to the backend:
POST /favorites

FastAPI stores that user’s “liked” event in the SQL database under their profile.

The app updates the UI to show saved events in a “Favorites” or “Interested” section.

5. Event Details & Map View

If the user taps an event, the app requests detailed info:
GET /events/{event_id}

The backend retrieves the specific event’s full details from the database.

The app shows the event’s description, club info, and a map view (using MapKit) of where the event is happening.

6. Club Representatives Add Events

Club reps can log in using a “club” account type.

They fill out a form in the app to post an event (title, description, date, time, location).

The app sends a request:
POST /events

FastAPI validates and saves this event in the SQL database.

The event immediately becomes visible to all users on the feed.

7. Continuous Sync & Updates

Every time a new event is added, updated, or deleted, the backend updates the database.

The next time users refresh or open the app, they receive the latest events automatically.

8. Deployment & Hosting

The FastAPI backend and SQL database are hosted on Render.

This keeps the API accessible 24/7 so that the Swift app can always fetch or update event data.

When users interact with the app, all communication happens securely over HTTPS.
