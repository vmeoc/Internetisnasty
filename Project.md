# Project: Internet is Nasty

## 1. Project Goal

The primary goal of this project is to create a compelling, educational, and visually engaging web application that demonstrates the constant, automated scanning and connection attempts that occur on internet-facing servers. The project will adopt a "horror movie" aesthetic to make the experience memorable and impactful.

## 2. Core Features

*   **Real-time Port Monitoring**: The backend will listen on a configurable list of common TCP ports.
*   **Live Visualization**: The frontend will update in real-time, displaying each connection attempt as it happens.
*   **Horror-Themed UI**: The user interface will be designed to look like a retro or horror-style computer terminal, using a dark theme, glitch effects, and unsettling fonts.
*   **Client-Server Architecture**: A clear separation between the Python/Flask backend (the server) and the HTML/CSS/JS frontend (the client).
*   **Easy Deployment**: The project will be structured for easy deployment to cloud services like AWS.

## 3. Development Phases

### Phase 1: Project Scaffolding (Current Phase)

*   [x] Define project goals and technology stack.
*   [x] Create the basic file and directory structure (`app.py`, `templates/`, `static/`).
*   [x] Create documentation (`README.md`, `Project.md`).
*   [x] Create the `requirements.txt` file with initial dependencies.

### Phase 2: Backend Development

*   [x] Set up a basic Flask server in `app.py`.
*   [x] Integrate Flask-SocketIO for real-time communication.
*   [x] Implement the port listening logic using Python's `socket` library.
*   [x] Create a separate thread for each port listener to avoid blocking the main application.
*   [x] When a connection is detected, emit a WebSocket event with details (e.g., timestamp, port number, attacker's IP address).

### Phase 3: Frontend Development

*   [x] Create the basic HTML structure in `index.html`.
*   [x] Style the page using `style.css` to achieve the horror movie terminal look.
*   [x] In `script.js`, connect to the backend using the Socket.IO client library.
*   [x] Write a JavaScript function to handle incoming WebSocket events.
*   [x] Dynamically add new entries to the display when a connection attempt is reported by the server.

### Phase 4: Refinement and Deployment

*   [ ] Refine the UI/UX with animations or sound effects.
*   [ ] Ensure the application is stable.
*   [ ] Follow the deployment guide in `README.md` to deploy the application to a public server.
