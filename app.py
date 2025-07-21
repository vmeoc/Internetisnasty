import eventlet
# We must patch the standard library for eventlet to work correctly with sockets
eventlet.monkey_patch()

import threading
import socket
from datetime import datetime

from flask import Flask, render_template, jsonify
from flask_socketio import SocketIO

# --- Application Setup ---
app = Flask(__name__)
# Using a secret key is a security best practice for Flask applications
app.config['SECRET_KEY'] = 'secret!change_me_in_production'
# Initialize SocketIO with the Flask app, using eventlet for the async server
socketio = SocketIO(app, async_mode='eventlet')

# --- Port Monitoring Configuration ---
# Dictionary of ports to monitor with their descriptions
PORTS_TO_MONITOR = {
    23: {"name": "TELNET", "description": "Telnet Protocol"},
    25: {"name": "SMTP", "description": "Email Server"},
    53: {"name": "DNS", "description": "Domain Name System"},
    80: {"name": "HTTP", "description": "Web Server"},
    110: {"name": "POP3", "description": "Email Retrieval"},
    135: {"name": "RPC", "description": "Windows RPC"},
    139: {"name": "NetBIOS", "description": "Windows File Sharing"},
    143: {"name": "IMAP", "description": "Email Access"},
    445: {"name": "SMB", "description": "Windows File Sharing"},
    993: {"name": "IMAPS", "description": "Secure Email Access"},
    995: {"name": "POP3S", "description": "Secure Email Retrieval"},
    1433: {"name": "MSSQL", "description": "MS SQL Server"},
    3306: {"name": "MySQL", "description": "MySQL Database"},
    3389: {"name": "RDP", "description": "Remote Desktop"},
    5900: {"name": "VNC", "description": "Remote Control"},
    8080: {"name": "HTTP-ALT", "description": "Alternate Web"}
}

# --- Backend Logic ---

def listen_on_port(port):
    """
    This function creates a socket listener for a specific port.
    It creates a socket, listens for incoming connections, and emits the data.
    """
    try:
        # Create a new TCP/IP socket
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            # Set the socket to be reusable to avoid "Address already in use" errors
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            
            # Bind the socket to all available network interfaces ('0.0.0.0') on the specified port
            s.bind(('0.0.0.0', port))
            # Start listening for incoming connections
            s.listen()
            print(f"[*] Successfully listening on port {port}...")

            # Loop forever to accept all incoming connection attempts
            while True:
                try:
                    # Accept a new connection. This is a blocking call.
                    conn, addr = s.accept()
                    with conn:
                        # addr[0] is the IP address of the client
                        attacker_ip = addr[0]
                        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                        
                        print(f"[!] Connection attempt from {attacker_ip} on port {port}")

                        # Prepare the data to be sent to the frontend
                        data = {
                            'port': port,
                            'ip': attacker_ip,
                            'timestamp': timestamp
                        }
                        # Emit a 'new_connection' event over the WebSocket
                        socketio.emit('new_connection', data)
                except Exception as e:
                    print(f"[!] Error accepting connection on port {port}: {e}")
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"[!] Port {port} is already in use by another service - skipping")
        elif e.errno == 13:  # Permission denied
            print(f"[!] Permission denied for port {port} - need root privileges")
        else:
            print(f"[!] Failed to bind to port {port}: {e}")
    except Exception as e:
        print(f"[!] Unexpected error on port {port}: {e}")

# --- Web Server Routes ---

@app.route('/')
def index():
    """Serves the main HTML page."""
    # Flask will look for this file in the 'templates' folder
    return render_template('index.html', ports=PORTS_TO_MONITOR)

# --- Main Execution ---

if __name__ == '__main__':
    import os
    
    # Get port from environment variable (App Runner compatibility)
    port = int(os.environ.get('PORT', 5000))
    
    # Create and start a new thread for each port in our list
    threads = []
    for monitor_port in PORTS_TO_MONITOR.keys():
        thread = threading.Thread(target=listen_on_port, args=(monitor_port,))
        # A daemon thread will exit when the main program exits
        thread.daemon = True
        thread.start()
        threads.append(thread)
        print(f"[*] Started listener thread for port {monitor_port}")

    # Start the Flask-SocketIO server
    # We use socketio.run instead of app.run to enable WebSocket support
    # Disable use_reloader to prevent thread conflicts
    print(f"[*] Starting Flask-SocketIO server on port {port}...")
    # Use debug=True for local development, False for production
    is_production = os.environ.get('LIGHTSAIL_PRODUCTION', 'false').lower() == 'true'
    socketio.run(app, host='0.0.0.0', port=port, debug=not is_production, use_reloader=False)
