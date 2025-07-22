import eventlet
# We must patch the standard library for eventlet to work correctly with sockets
eventlet.monkey_patch()

import threading
import socket
import logging
import sys
import sqlite3
import schedule
import time
import os
from datetime import datetime, timezone
import pytz

from flask import Flask, render_template, jsonify
from flask_socketio import SocketIO

# --- Logging Configuration ---
# Configure logging to work with systemd
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Force stdout to be unbuffered for immediate log visibility
sys.stdout.reconfigure(line_buffering=True)

# --- Application Setup ---
app = Flask(__name__)
# Using a secret key is a security best practice for Flask applications
app.config['SECRET_KEY'] = 'secret!change_me_in_production'
# Initialize SocketIO with the Flask app, using eventlet for the async server
socketio = SocketIO(app, async_mode='eventlet')

# --- Port Monitoring Configuration ---
# Dictionary of ports to monitor with their descriptions
PORTS_TO_MONITOR = {
    22: {"name": "SSH", "description": "Secure Shell"},
    23: {"name": "TELNET", "description": "Telnet Protocol"},
    25: {"name": "SMTP", "description": "Email Server"},
    53: {"name": "DNS", "description": "Domain Name System"},
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

# --- Database Configuration ---
DB_PATH = 'honeypot_attacks.db'
PARIS_TZ = pytz.timezone('Europe/Paris')

def init_database():
    """Initialize SQLite database with required tables"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Table for individual attacks
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS attacks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            port INTEGER NOT NULL,
            ip_address TEXT NOT NULL,
            timestamp DATETIME NOT NULL,
            date_only DATE NOT NULL
        )
    ''')
    
    # Table for daily statistics
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS daily_stats (
            date DATE NOT NULL,
            port INTEGER NOT NULL,
            attack_count INTEGER DEFAULT 0,
            PRIMARY KEY (date, port)
        )
    ''')
    
    conn.commit()
    conn.close()
    logger.info("Database initialized successfully")

def log_attack_to_db(port, ip_address):
    """Log an attack to the database"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Get current time in Paris timezone
        now_paris = datetime.now(PARIS_TZ)
        date_only = now_paris.date()
        
        # Insert attack record
        cursor.execute('''
            INSERT INTO attacks (port, ip_address, timestamp, date_only)
            VALUES (?, ?, ?, ?)
        ''', (port, ip_address, now_paris, date_only))
        
        # Update daily stats
        cursor.execute('''
            INSERT OR REPLACE INTO daily_stats (date, port, attack_count)
            VALUES (?, ?, COALESCE((SELECT attack_count FROM daily_stats WHERE date=? AND port=?), 0) + 1)
        ''', (date_only, port, date_only, port))
        
        conn.commit()
        conn.close()
        
    except Exception as e:
        logger.error(f"Error logging attack to database: {e}")

def get_daily_stats():
    """Get today's attack statistics"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        today = datetime.now(PARIS_TZ).date()
        
        cursor.execute('''
            SELECT port, attack_count FROM daily_stats 
            WHERE date = ?
            ORDER BY port
        ''', (today,))
        
        stats = {}
        for port, count in cursor.fetchall():
            stats[port] = count
            
        conn.close()
        return stats
        
    except Exception as e:
        logger.error(f"Error getting daily stats: {e}")
        return {}

def get_recent_attacks(limit=50):
    """Get recent attacks for display"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT port, ip_address, timestamp FROM attacks 
            ORDER BY timestamp DESC 
            LIMIT ?
        ''', (limit,))
        
        attacks = []
        for port, ip, timestamp in cursor.fetchall():
            # Convert timestamp to UTC ISO format for consistent client-side handling
            try:
                # Parse the timestamp from database (Paris timezone)
                if isinstance(timestamp, str):
                    # If it's a string, parse it assuming Paris timezone
                    dt_paris = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                    if dt_paris.tzinfo is None:
                        dt_paris = PARIS_TZ.localize(dt_paris)
                else:
                    # If it's already a datetime object
                    dt_paris = timestamp
                    if dt_paris.tzinfo is None:
                        dt_paris = PARIS_TZ.localize(dt_paris)
                
                # Convert to UTC and format as ISO
                dt_utc = dt_paris.astimezone(pytz.UTC)
                timestamp_iso = dt_utc.isoformat().replace('+00:00', 'Z')
            except Exception as e:
                logger.warning(f"Error converting timestamp {timestamp}: {e}")
                # Fallback to original timestamp
                timestamp_iso = str(timestamp)
            
            attacks.append({
                'port': port,
                'ip': ip,
                'timestamp': timestamp_iso,
                'port_name': PORTS_TO_MONITOR.get(port, {}).get('name', 'Unknown')
            })
            
        conn.close()
        return attacks
        
    except Exception as e:
        logger.error(f"Error getting recent attacks: {e}")
        return []

def reset_daily_counters():
    """Reset daily counters at midnight (called by scheduler)"""
    try:
        logger.info("Performing daily reset of attack counters (midnight Paris time)")
        
        # Archive yesterday's data and prepare for new day
        today = datetime.now(PARIS_TZ).date()
        logger.info(f"Daily reset completed for {today}")
        
        # Optional: Clean up old data (keep last 30 days)
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            DELETE FROM attacks 
            WHERE date_only < date('now', '-30 days')
        ''')
        
        cursor.execute('''
            DELETE FROM daily_stats 
            WHERE date < date('now', '-30 days')
        ''')
        
        conn.commit()
        conn.close()
        
        logger.info("Old data cleanup completed (kept last 30 days)")
        
    except Exception as e:
        logger.error(f"Error during daily reset: {e}")

def run_scheduler():
    """Run the scheduler in a separate thread"""
    while True:
        schedule.run_pending()
        time.sleep(60)  # Check every minute

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
            logger.info(f"Successfully listening on port {port} ({PORTS_TO_MONITOR[port]['name']})")

            # Loop forever to accept all incoming connection attempts
            while True:
                try:
                    # Accept a new connection. This is a blocking call.
                    conn, addr = s.accept()
                    with conn:
                        # addr[0] is the IP address of the client
                        attacker_ip = addr[0]
                        # Use UTC timestamp in ISO format for proper client-side conversion
                        timestamp = datetime.utcnow().isoformat() + 'Z'
                        
                        logger.warning(f"THREAT DETECTED: Connection from {attacker_ip} on port {port} ({PORTS_TO_MONITOR[port]['name']})")

                        # Log attack to database
                        log_attack_to_db(port, attacker_ip)

                        # Prepare the data to be sent to the frontend
                        data = {
                            'port': port,
                            'ip': attacker_ip,
                            'timestamp': timestamp
                        }
                        # Emit a 'new_connection' event over the WebSocket
                        socketio.emit('new_connection', data)
                except Exception as e:
                    logger.error(f"Error accepting connection on port {port}: {e}")
    except OSError as e:
        if e.errno == 98:  # Address already in use
            if port == 22:
                logger.warning(f"Port 22 (SSH) is already in use by another service")
                logger.info(f"If you moved SSH to another port, this conflict should not occur")
            else:
                logger.warning(f"Port {port} is already in use by another service - skipping")
        elif e.errno == 13:  # Permission denied
            logger.error(f"Permission denied for port {port} - need root privileges")
        else:
            logger.error(f"Failed to bind to port {port}: {e}")
    except Exception as e:
        logger.error(f"Unexpected error on port {port}: {e}")

# --- Web Server Routes ---

@app.route('/')
def index():
    """Serves the main HTML page."""
    # Get current daily stats to initialize the interface
    daily_stats = get_daily_stats()
    return render_template('index.html', ports=PORTS_TO_MONITOR, daily_stats=daily_stats)

@app.route('/api/stats')
def api_stats():
    """API endpoint for current daily statistics"""
    return jsonify(get_daily_stats())

@app.route('/api/recent-attacks')
def api_recent_attacks():
    """API endpoint for recent attacks"""
    return jsonify(get_recent_attacks(100))

# --- Main Execution ---

if __name__ == '__main__':
    import os
    
    # Get port from environment variable (default to 80 for web interface)
    port = int(os.environ.get('PORT', 80))
    
    logger.info("=== INTERNET IS NASTY HONEYPOT STARTING ===")
    logger.info(f"Web interface will be available on port {port}")
    logger.info(f"Monitoring {len(PORTS_TO_MONITOR)} ports for intrusion attempts")
    
    # Initialize database
    init_database()
    
    # Setup daily reset scheduler (midnight Paris time)
    schedule.every().day.at("00:00").do(reset_daily_counters)
    logger.info("Scheduled daily reset at midnight (Paris time)")
    
    # Start scheduler thread
    scheduler_thread = threading.Thread(target=run_scheduler)
    scheduler_thread.daemon = True
    scheduler_thread.start()
    logger.info("Scheduler thread started")
    
    # Create and start a new thread for each port in our list
    threads = []
    for monitor_port in PORTS_TO_MONITOR.keys():
        thread = threading.Thread(target=listen_on_port, args=(monitor_port,))
        # A daemon thread will exit when the main program exits
        thread.daemon = True
        thread.start()
        threads.append(thread)
        logger.info(f"Started monitoring thread for port {monitor_port} ({PORTS_TO_MONITOR[monitor_port]['name']})")

    # Start the Flask-SocketIO server
    # We use socketio.run instead of app.run to enable WebSocket support
    # Disable use_reloader to prevent thread conflicts
    logger.info(f"Starting Flask-SocketIO web server on port {port}")
    logger.info("Honeypot is now active and monitoring for threats!")
    
    # Use debug=True for local development, False for production
    is_production = os.environ.get('LIGHTSAIL_PRODUCTION', 'false').lower() == 'true'
    
    # Check for SSL configuration
    ssl_cert_path = os.environ.get('SSL_CERT_PATH')
    ssl_key_path = os.environ.get('SSL_KEY_PATH')
    
    if ssl_cert_path and ssl_key_path:
        # HTTPS mode with SSL certificates
        logger.info(f"Starting HTTPS server with SSL certificates")
        logger.info(f"SSL Certificate: {ssl_cert_path}")
        logger.info(f"SSL Key: {ssl_key_path}")
        socketio.run(app, host='0.0.0.0', port=port, debug=not is_production, use_reloader=False,
                    certfile=ssl_cert_path, keyfile=ssl_key_path)
    else:
        # HTTP mode (default)
        logger.info(f"Starting HTTP server (no SSL)")
        socketio.run(app, host='0.0.0.0', port=port, debug=not is_production, use_reloader=False)
