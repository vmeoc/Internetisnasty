# Project: Internet is Nasty 🛡️

## 1. Project Goal

The primary goal of this project is to create a compelling, educational, and visually engaging cybersecurity honeypot that demonstrates the constant, automated scanning and connection attempts that occur on internet-facing servers. The project adopts a "horror movie" aesthetic to make the cybersecurity experience memorable and impactful for educational purposes.

## 2. Core Features ✅ COMPLETED

*   **✅ Real-time Port Monitoring**: Backend listens on 17 common TCP ports (SSH, TELNET, SMTP, etc.)
*   **✅ Live Attack Visualization**: Frontend updates in real-time, displaying each connection attempt as it happens
*   **✅ Horror-Themed Dashboard**: Retro terminal aesthetic with dark theme, glitch effects, and cybersecurity fonts
*   **✅ SQLite Persistence**: Attack data stored with daily statistics and automatic midnight reset
*   **✅ Educational Interface**: Clear explanations of ports, services, and attack patterns
*   **✅ Production Deployment**: Fully deployed on AWS Lightsail with HTTPS support
*   **✅ Service Management**: systemd integration with automated startup and logging

## 3. Development Phases - PROJECT STATUS: ✅ V1.0 COMPLETED

### Phase 1: Project Scaffolding ✅ COMPLETED

*   [x] Define project goals and technology stack
*   [x] Create file structure (`app.py`, `templates/`, `static/`)
*   [x] Create comprehensive documentation (`README.md`, `Project.md`)
*   [x] Create `requirements.txt` with all dependencies
*   [x] Add deployment scripts (`deploy-lightsail.sh`, `update.sh`)

### Phase 2: Backend Development ✅ COMPLETED

*   [x] Flask server with Flask-SocketIO for real-time communication
*   [x] Multi-threaded port listening on 17 common ports
*   [x] SQLite database persistence for attack logging
*   [x] Daily statistics tracking with automatic midnight reset
*   [x] Comprehensive error handling and logging
*   [x] API endpoints for stats and recent attacks
*   [x] SSL/HTTPS support with Let's Encrypt integration

### Phase 3: Frontend Development ✅ COMPLETED

*   [x] Responsive dashboard layout with three-panel design
*   [x] Horror-themed UI with cybersecurity aesthetics
*   [x] Real-time attack feed with Socket.IO integration
*   [x] Port monitoring grid with connection counters
*   [x] Educational content explaining honeypot functionality
*   [x] Mobile-responsive design
*   [x] Favicon and branding elements

### Phase 4: Production Deployment ✅ COMPLETED

*   [x] AWS Lightsail deployment with automated scripts
*   [x] systemd service integration for reliability
*   [x] HTTPS/SSL certificate automation with Let's Encrypt
*   [x] Firewall configuration and security hardening
*   [x] Database backup and permission management
*   [x] Automated update and maintenance scripts
*   [x] Comprehensive troubleshooting documentation

### Phase 5: Future Enhancements 🚀 ROADMAP

TBD

## 4. Technical Architecture 🏢

### Current Production Stack

**Infrastructure:**
- **Platform**: AWS Lightsail (Amazon Linux 2023)
- **Domain**: Custom domain with Let's Encrypt SSL
- **Firewall**: Lightsail managed firewall (17+ ports open)

**Backend:**
- **Language**: Python 3.11+
- **Framework**: Flask + Flask-SocketIO
- **Database**: SQLite with daily rotation
- **Concurrency**: Multi-threading (1 thread per monitored port)
- **Logging**: systemd journalctl integration
- **SSL**: Let's Encrypt with auto-renewal

**Frontend:**
- **Architecture**: Single-page application (SPA)
- **Real-time**: Socket.IO WebSocket connections
- **Styling**: Custom CSS with horror theme
- **Responsive**: Mobile and desktop optimized
- **Performance**: Lightweight, no external dependencies

**Deployment:**
- **Service**: systemd daemon with auto-restart
- **Updates**: Automated update script with database backup
- **Monitoring**: Real-time logs and service status
- **Security**: Root privileges for privileged ports, secure database permissions

### Monitored Ports & Services

```
Port 22   - SSH (Secure Shell)
Port 23   - TELNET (Telnet Protocol)
Port 25   - SMTP (Email Server)
Port 53   - DNS (Domain Name System)
Port 110  - POP3 (Email Retrieval)
Port 135  - RPC (Windows RPC)
Port 139  - NetBIOS (Windows File Sharing)
Port 143  - IMAP (Email Access)
Port 445  - SMB (Windows File Sharing)
Port 993  - IMAPS (Secure Email Access)
Port 995  - POP3S (Secure Email Retrieval)
Port 1433 - MSSQL (MS SQL Server)
Port 3306 - MySQL (MySQL Database)
Port 3389 - RDP (Remote Desktop)
Port 5900 - VNC (Remote Control)
Port 8080 - HTTP-ALT (Alternate Web)
```

## 5. Current Status 📊

**✅ Version**: 1.0 Production Ready
**🌐 Live URL**: https://internetisnasty.vmcloud.fr
**📊 Uptime**: 24/7 monitoring active
**🔒 Security**: HTTPS with auto-renewing certificates
**💾 Data**: SQLite with daily reset at midnight (Paris time)
**📋 Logs**: Real-time via `sudo journalctl -u internet-is-nasty -f`

### Key Achievements

1. **🎯 Educational Impact**: Clear, non-technical explanations of cybersecurity concepts
2. **🚀 Performance**: Handles hundreds of concurrent attacks without issues
3. **🔒 Security**: Production-hardened with proper permissions and SSL
4. **📱 Accessibility**: Works on all devices and screen sizes
5. **🔧 Maintainability**: Automated deployment, updates, and monitoring
6. **🌐 Scalability**: Ready for increased traffic and additional features

The project successfully demonstrates real-world cybersecurity threats in an engaging, educational format suitable for both technical and non-technical audiences.
