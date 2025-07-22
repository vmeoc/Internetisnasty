#!/bin/bash

# Update script for Internet is Nasty on Lightsail - Amazon Linux 2023
# Run this on the VM to update the code

echo "🔄 Updating Internet is Nasty..."

cd /home/ec2-user/Internetisnasty

# Stash local changes if necessary
git stash

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Restore local changes if necessary
git stash pop 2>/dev/null || true

# Update dependencies if necessary
echo "📚 Checking dependencies..."
source venv/bin/activate
pip install -r requirements.txt

# Create database backup if it exists
if [ -f "honeypot_attacks.db" ]; then
    echo "📦 Creating database backup..."
    cp honeypot_attacks.db "honeypot_attacks.db.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Set proper database permissions
echo "🔒 Setting database permissions..."
sudo chown ec2-user:ec2-user honeypot_attacks.db* 2>/dev/null || true
sudo chmod 664 honeypot_attacks.db* 2>/dev/null || true

# Restart the service
echo "🔄 Restarting service..."
sudo systemctl restart internet-is-nasty

# Check service status
echo "✅ Checking service status..."
sleep 2
sudo systemctl status internet-is-nasty --no-pager

echo "✅ Update completed!"
echo "📍 Database location: $(pwd)/honeypot_attacks.db"
echo "📋 View logs: sudo journalctl -u internet-is-nasty -f"
echo "🎯 Test attack logging: curl -s http://localhost/api/recent-attacks | head -20"
