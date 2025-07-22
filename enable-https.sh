#!/bin/bash

# Simple HTTPS Setup for Internet is Nasty (Flask Direct)
# No Nginx complexity - just Flask + SSL certificates

echo "🔒 Setting up HTTPS for Internet is Nasty (Simple Method)..."

# Check if domain is provided
if [ -z "$1" ]; then
    echo "❌ Usage: ./enable-https.sh your-domain.com"
    echo "Example: ./enable-https.sh honeypot.example.com"
    exit 1
fi

DOMAIN=$1
echo "🌐 Domain: $DOMAIN"

# Install Certbot only (no Nginx needed)
echo "📦 Installing Certbot..."
sudo dnf install -y certbot

# Stop Flask app to free port 80 for certificate validation
echo "⏸️ Stopping Flask app temporarily..."
sudo systemctl stop internet-is-nasty

# Get SSL certificate using standalone mode
echo "🔒 Obtaining SSL certificate from Let's Encrypt..."
sudo certbot certonly --standalone \
    -d $DOMAIN \
    --non-interactive \
    --agree-tos \
    --email admin@$DOMAIN

if [ $? -ne 0 ]; then
    echo "❌ Certificate generation failed!"
    echo "Please check:"
    echo "1. Domain $DOMAIN points to this server's IP"
    echo "2. Port 80 is open and not used by other services"
    sudo systemctl start internet-is-nasty
    exit 1
fi

# Update systemd service to use HTTPS
echo "🔧 Updating service configuration for HTTPS..."
sudo tee /etc/systemd/system/internet-is-nasty.service > /dev/null <<EOF
[Unit]
Description=Internet is Nasty Honeypot (HTTPS)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/ec2-user/Internetisnasty
Environment=PATH=/home/ec2-user/Internetisnasty/venv/bin
Environment=LIGHTSAIL_PRODUCTION=true
Environment=PYTHONUNBUFFERED=1
Environment=PORT=443
Environment=SSL_CERT_PATH=/etc/letsencrypt/live/$DOMAIN/fullchain.pem
Environment=SSL_KEY_PATH=/etc/letsencrypt/live/$DOMAIN/privkey.pem
ExecStart=/home/ec2-user/Internetisnasty/venv/bin/python app.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Set up automatic certificate renewal
echo "🔄 Setting up automatic certificate renewal..."
sudo tee /etc/systemd/system/certbot-renew.service > /dev/null <<EOF
[Unit]
Description=Certbot Renewal

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --post-hook "systemctl restart internet-is-nasty"
EOF

sudo tee /etc/systemd/system/certbot-renew.timer > /dev/null <<EOF
[Unit]
Description=Run certbot renewal daily at 3 AM

[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the renewal timer
sudo systemctl daemon-reload
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer

# Restart Flask app with HTTPS
echo "🚀 Starting Flask app with HTTPS..."
sudo systemctl daemon-reload
sudo systemctl start internet-is-nasty

# Wait and check status
sleep 5
sudo systemctl status internet-is-nasty --no-pager

echo ""
echo "✅ HTTPS Setup Complete!"
echo "🌐 Your honeypot is now available at: https://$DOMAIN"
echo "🔒 Certificate auto-renewal: Daily at 3 AM (only if < 30 days remaining)"
echo "📊 Service status: sudo systemctl status internet-is-nasty"
echo "📋 Logs: sudo journalctl -u internet-is-nasty -f"
echo "🔒 Certificate status: sudo certbot certificates"
echo ""
echo "🎯 Architecture: Browser ──HTTPS──▶ Flask (Direct, no proxy)"
