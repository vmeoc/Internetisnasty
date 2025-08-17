#!/bin/bash

# 🛡️ Script de Sécurisation SSL pour Internet is Nasty
# Migration vers nginx + Let's Encrypt avec sécurité renforcée
# Compatible Amazon Linux 2023

set -e  # Arrêt en cas d'erreur

echo "🛡️ Démarrage de la sécurisation SSL pour Internet is Nasty..."
echo "🖥️  Système détecté: Amazon Linux 2023"
echo ""

# Vérification des paramètres
if [ -z "$1" ]; then
    echo "❌ Usage: ./secure-ssl.sh votre-domaine.com [email@exemple.com]"
    echo "Exemple: ./secure-ssl.sh honeypot.exemple.com admin@exemple.com"
    echo ""
    echo "📧 Si aucun email n'est fourni, un email générique sera utilisé"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-"admin-ssl-$(date +%s)@gmail.com"}  # Email générique si non fourni
FLASK_PORT=5000  # Port interne pour Flask
NGINX_USER="nginx"
APP_USER="ec2-user"
APP_DIR="/home/$APP_USER/Internetisnasty"

echo "🌐 Domaine: $DOMAIN"
echo "📧 Email: $EMAIL"
echo "🔧 Port Flask interne: $FLASK_PORT"
echo ""

# Fonction de logging avec timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction de vérification des erreurs
check_error() {
    if [ $? -ne 0 ]; then
        log "❌ ERREUR: $1"
        exit 1
    fi
}

# 1. INSTALLATION DES DÉPENDANCES
log "📦 Installation de nginx et certbot..."
sudo dnf update -y
sudo dnf install -y nginx certbot python3-certbot-nginx
check_error "Installation des paquets"

# 2. ARRÊT DU SERVICE FLASK ACTUEL
log "⏸️  Arrêt du service Flask actuel..."
sudo systemctl stop internet-is-nasty 2>/dev/null || true
sudo systemctl disable internet-is-nasty 2>/dev/null || true

# 3. CONFIGURATION DE NGINX
log "🔧 Configuration de nginx..."

# Sauvegarde de la configuration nginx par défaut
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%s)

# Configuration nginx principale avec sécurité renforcée
sudo tee /etc/nginx/nginx.conf > /dev/null <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

# Sécurité: Masquer la version nginx
server_tokens off;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # Types MIME et encodage
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    charset utf-8;

    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Sécurité Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Limites de sécurité
    client_max_body_size 10M;
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # Configuration du site
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Configuration spécifique pour le honeypot
sudo tee /etc/nginx/conf.d/internet-is-nasty.conf > /dev/null <<EOF
# Configuration SSL pour Internet is Nasty Honeypot
server {
    listen 80;
    server_name $DOMAIN;
    
    # Redirection HTTPS forcée (sauf pour Let's Encrypt)
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # Configuration SSL (sera mise à jour par certbot)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    # Sécurité SSL renforcée
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Headers de sécurité spécifiques
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self' wss: ws:;" always;
    
    # Configuration du reverse proxy vers Flask
    location / {
        proxy_pass http://127.0.0.1:$FLASK_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Support WebSocket pour Socket.IO
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Fichiers statiques (performance)
    location /static/ {
        alias $APP_DIR/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Sécurité: Bloquer les fichiers sensibles
    location ~ /\\.ht {
        deny all;
    }
    
    location ~ /\\.(git|env|config) {
        deny all;
    }
}
EOF

# 4. CRÉATION DU RÉPERTOIRE POUR LET'S ENCRYPT
log "📁 Création du répertoire web pour Let's Encrypt..."
sudo mkdir -p /var/www/html
sudo chown -R $NGINX_USER:$NGINX_USER /var/www/html

# 5. DÉMARRAGE DE NGINX
log "🚀 Démarrage de nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx
check_error "Démarrage de nginx"

# 6. OBTENTION DU CERTIFICAT SSL
log "🔒 Obtention du certificat SSL Let's Encrypt..."
sudo certbot --nginx \
    -d $DOMAIN \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --redirect
check_error "Obtention du certificat SSL"

# 7. MISE À JOUR DU SERVICE FLASK
log "🔧 Mise à jour du service Flask pour fonctionner avec nginx..."

# Nouveau service systemd pour Flask (port interne seulement)
sudo tee /etc/systemd/system/internet-is-nasty.service > /dev/null <<EOF
[Unit]
Description=Internet is Nasty Honeypot (Flask Backend)
After=network.target
Requires=nginx.service

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
Environment=LIGHTSAIL_PRODUCTION=true
Environment=PYTHONUNBUFFERED=1
Environment=PORT=$FLASK_PORT
Environment=FLASK_ENV=production
Environment=BEHIND_PROXY=true
ExecStart=$APP_DIR/venv/bin/python app.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

# Sécurité du service
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$APP_DIR

[Install]
WantedBy=multi-user.target
EOF

# 8. CONFIGURATION DU RENOUVELLEMENT AUTOMATIQUE
log "🔄 Configuration du renouvellement automatique SSL..."

# Service de renouvellement
sudo tee /etc/systemd/system/certbot-renew.service > /dev/null <<EOF
[Unit]
Description=Certbot SSL Certificate Renewal
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"
User=root
EOF

# Timer pour le renouvellement (2 fois par jour)
sudo tee /etc/systemd/system/certbot-renew.timer > /dev/null <<EOF
[Unit]
Description=Run certbot renewal twice daily
Requires=certbot-renew.service

[Timer]
OnCalendar=*-*-* 00,12:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 9. ACTIVATION DES SERVICES
log "🚀 Activation des services..."
sudo systemctl daemon-reload
sudo systemctl enable internet-is-nasty
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer
sudo systemctl start internet-is-nasty

# 10. CONFIGURATION DU FIREWALL (si ufw est installé)
log "🔥 Configuration du firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 'Nginx Full'
    sudo ufw allow OpenSSH
    log "✅ Firewall UFW configuré"
else
    log "ℹ️  UFW non installé - Configuration manuelle du firewall Lightsail requise"
fi

# 11. VÉRIFICATIONS FINALES
log "🔍 Vérifications finales..."
sleep 5

# Vérification nginx
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx: Actif"
else
    log "❌ Nginx: Problème détecté"
fi

# Vérification Flask
if sudo systemctl is-active --quiet internet-is-nasty; then
    log "✅ Flask: Actif"
else
    log "❌ Flask: Problème détecté"
fi

# Vérification SSL
if sudo certbot certificates | grep -q "$DOMAIN"; then
    log "✅ Certificat SSL: Installé"
else
    log "❌ Certificat SSL: Problème détecté"
fi

# 12. RAPPORT FINAL
echo ""
echo "🎉 =================================="
echo "🛡️  SÉCURISATION SSL TERMINÉE !"
echo "🎉 =================================="
echo ""
echo "🌐 Votre honeypot est maintenant sécurisé:"
echo "   ➤ HTTPS: https://$DOMAIN"
echo "   ➤ Redirection HTTP → HTTPS automatique"
echo ""
echo "🏗️  Architecture mise à jour:"
echo "   Internet ──HTTPS──▶ Nginx ──HTTP──▶ Flask"
echo ""
echo "🔒 Sécurité implémentée:"
echo "   ✅ Certificat SSL Let's Encrypt"
echo "   ✅ TLS 1.2/1.3 uniquement"
echo "   ✅ Headers de sécurité (HSTS, CSP, etc.)"
echo "   ✅ Renouvellement automatique (2x/jour)"
echo "   ✅ Reverse proxy nginx sécurisé"
echo ""
echo "🔧 Commandes de gestion:"
echo "   📊 Status services: sudo systemctl status nginx internet-is-nasty"
echo "   📋 Logs nginx: sudo tail -f /var/log/nginx/access.log"
echo "   📋 Logs Flask: sudo journalctl -u internet-is-nasty -f"
echo "   🔒 Status SSL: sudo certbot certificates"
echo "   🔄 Test renouvellement: sudo certbot renew --dry-run"
echo ""
echo "🔥 IMPORTANT - Configuration Lightsail:"
echo "   1. Ouvrir le port 443 (HTTPS) dans le firewall Lightsail"
echo "   2. Garder le port 80 (HTTP) ouvert pour le renouvellement SSL"
echo "   3. Le port 22 (SSH) doit rester accessible pour la gestion"
echo ""
echo "🎯 Test de sécurité:"
echo "   🌐 Accédez à: https://$DOMAIN"
echo "   🔒 Vérifiez le cadenas SSL dans votre navigateur"
echo "   📱 Testez la redirection: http://$DOMAIN → https://$DOMAIN"
echo ""

# Sauvegarde des informations dans un fichier de log
LOG_FILE="$APP_DIR/ssl-setup-$(date +%Y%m%d-%H%M%S).log"
{
    echo "SSL Setup completed on $(date)"
    echo "Domain: $DOMAIN"
    echo "Email: $EMAIL"
    echo "Flask Port: $FLASK_PORT"
    echo "Nginx Config: /etc/nginx/conf.d/internet-is-nasty.conf"
    echo "SSL Cert Path: /etc/letsencrypt/live/$DOMAIN/"
} > "$LOG_FILE"

log "📝 Informations sauvegardées dans: $LOG_FILE"
echo ""
echo "🚀 Votre honeypot cybersécurisé est maintenant prêt et sécurisé !"
