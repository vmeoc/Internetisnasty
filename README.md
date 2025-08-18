# Internet is Nasty 🛡️

A horror-themed cybersecurity honeypot that visualizes real-time connection attempts and attacks on common network ports.

## 🎯 Overview

This project creates an educational cybersecurity demonstration showing how internet-facing servers are constantly under attack. It consists of:

1. **Python Backend**: Flask-based honeypot listening on multiple ports (22, 23, 25, 53, 80, 110, etc.)
2. **Web Dashboard**: Real-time visualization of attacks with horror-themed UI
3. **SQLite Persistence**: Attack logging with daily statistics and reset functionality

## 🛠️ Tech Stack

- **Backend**: Python, Flask, Flask-SocketIO, SQLite
- **Frontend**: HTML5, CSS3, JavaScript, Socket.IO
- **Deployment**: AWS Lightsail, systemd service
- **Monitoring**: journalctl logging

## 🚀 AWS Lightsail Deployment

### Prerequisites
- AWS Lightsail instance (Ubuntu 20.04+ or Amazon Linux 2023)
- SSH access to your instance
- Domain/IP for public access

### Step 1: Create Lightsail Instance
1. Go to [AWS Lightsail Console](https://lightsail.aws.amazon.com/)
2. Create instance:
   - **Platform**: Linux/Unix
   - **Blueprint**: Amazon Linux 2023 or Ubuntu 20.04+
   - **Instance plan**: $5/month minimum (1GB RAM)
   - **Instance name**: `internet-is-nasty-honeypot`

### Step 2: Configure Networking
1. In Lightsail console, go to **Networking** tab
2. Add firewall rules for these ports:
   ```
   HTTP (80) - TCP - Anywhere (0.0.0.0/0)
   SSH (22) - TCP - Your IP only (for management)
   Custom (23,25,53,110,135,139,143,445,993,995,1433,3306,3389,5900,8080) - TCP - Anywhere
   ```

### Step 3: Deploy Application
1. **SSH into your instance:**
   ```bash
   ssh -i your-key.pem ec2-user@YOUR_LIGHTSAIL_IP
   ```

2. **Run deployment script:**
   ```bash
   curl -sSL https://raw.githubusercontent.com/vmeoc/Internetisnasty/main/deploy-lightsail.sh | bash
   ```

3. **Verify deployment:**
   ```bash
   sudo systemctl status internet-is-nasty
   ```

### Step 4: Access Your Honeypot
- **Web Interface**: `http://YOUR_LIGHTSAIL_IP`
- **Service Management**: `sudo systemctl restart internet-is-nasty`
- **Live Logs**: `sudo journalctl -u internet-is-nasty -f`

### Step 5: Enable HTTPS (Optional)
1. **Configure Lightsail Firewall:**
   - Add rule: `HTTPS (443) - TCP - Anywhere (0.0.0.0/0)`
   - Keep `HTTP (80)` open for SSL certificate renewal

2. **Enable SSL with Let's Encrypt:**
   ```bash
   chmod +x enable-https.sh
   ./enable-https.sh your-domain.com
   ```

3. **Access with HTTPS:**
   - **Secure Interface**: `https://your-domain.com`
   - **Auto-renewal**: Certificates renew automatically daily at 3 AM

## 🔧 Management Commands

### Service Control
```bash
# Restart the application
sudo systemctl restart internet-is-nasty

# Check service status
sudo systemctl status internet-is-nasty

# View real-time logs
sudo journalctl -u internet-is-nasty -f

# Stop the service
sudo systemctl stop internet-is-nasty
```

### Updates
```bash
# Update to latest version
cd /home/ec2-user/Internetisnasty
./update.sh
```

## 🔍 Local Development

### Setup
```bash
# Clone repository
git clone https://github.com/vmeoc/Internetisnasty.git
cd Internetisnasty

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Run locally (development mode)
python app.py
```

### Local Testing
- Access: `http://localhost:5000`
- Limited port access (no privileged ports < 1024)
- SQLite database: `honeypot_attacks.db`

## 📊 Features

### Real-time Monitoring
- **Port Scanning Detection**: Monitors 17+ common ports
- **Live Attack Feed**: Real-time display of connection attempts
- **Geographic Tracking**: Shows attacker IP addresses
- **Service Identification**: Identifies targeted services (SSH, HTTP, etc.)

### Data Persistence
- **SQLite Database**: Stores all attack data
- **Daily Statistics**: Tracks daily attack counts
- **Automatic Reset**: Daily counter reset at midnight (Paris time)
- **Attack History**: Recent attacks with timestamps

### Dashboard Features
- **Port Grid**: Visual representation of monitored ports
- **Connection Counters**: Shows attempts per port since midnight
- **Live Feed**: Scrolling list of recent attacks
- **Educational Content**: Explains what users are seeing

## 🔒 Security Notes

- **Honeypot Nature**: Designed to attract and log attacks
- **No Data Execution**: Only logs connection attempts
- **Secure Database**: SQLite with proper file permissions
- **Firewall Ready**: Works with AWS Lightsail firewall
- **Root Privileges**: Required for privileged ports (< 1024)

## 🐛 Troubleshooting

### Common Issues
```bash
# Service won't start
sudo journalctl -u internet-is-nasty -n 50

# Port conflicts
sudo netstat -tulpn | grep :80

# Permission errors
sudo chown ec2-user:ec2-user /home/ec2-user/Internetisnasty/honeypot_attacks.db
sudo chmod 600 /home/ec2-user/Internetisnasty/honeypot_attacks.db

# Database issues
sudo systemctl restart internet-is-nasty
```

### Log Analysis
```bash
# Real-time monitoring
sudo journalctl -u internet-is-nasty -f

# Recent errors
sudo journalctl -u internet-is-nasty -p err -n 20

# Service restart history
sudo journalctl -u internet-is-nasty --since "1 hour ago"
```

## 📝 File Structure
```
Internetisnasty/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── deploy-lightsail.sh    # Deployment script
├── update.sh             # Update script
├── templates/
│   └── index.html        # Web dashboard
├── static/
│   ├── css/style.css     # Styling
│   └── js/script.js      # Frontend logic
└── honeypot_attacks.db   # SQLite database (created on first run)
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.
