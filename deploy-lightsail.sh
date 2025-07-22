#!/bin/bash

# Deployment script for AWS Lightsail - Amazon Linux 2023
# Run this ON the Lightsail VM after creation

echo "🚀 Deploying Internet is Nasty on AWS Lightsail (Amazon Linux 2023)..."

# System update
echo "📦 Updating system..."
sudo dnf update -y

# Install required packages
echo "🔧 Installing required packages..."
sudo dnf update -y
sudo dnf install -y python3 python3-pip git sqlite libcap

# Clone repository
echo "📥 Cloning repository..."
cd /home/ec2-user
git clone https://github.com/vmeoc/Internetisnasty.git
cd Internetisnasty

# Create virtual environment
echo "🔧 Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Configure permissions for privileged ports
echo "🔐 Configuring permissions..."
# For privileged ports, we'll use sudo in the systemd service
echo "Privileged ports will be managed via sudo in systemd service"

# Create systemd service
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/internet-is-nasty.service > /dev/null <<EOF
[Unit]
Description=Internet is Nasty Honeypot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/ec2-user/Internetisnasty
Environment=PATH=/home/ec2-user/Internetisnasty/venv/bin
Environment=LIGHTSAIL_PRODUCTION=true
Environment=PYTHONUNBUFFERED=1
ExecStart=/home/ec2-user/Internetisnasty/venv/bin/python app.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "🔄 Enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable internet-is-nasty
sudo systemctl start internet-is-nasty

# Firewall configuration
echo "🔥 Firewall configuration..."
echo "ℹ️  AWS Lightsail manages firewall at infrastructure level."
echo "🔧 Configure ports in Lightsail console:"
echo "   - Go to Lightsail Console > Your instance > Networking > Firewall"
echo "   - Add these ports: 80,22,23,25,53,110,135,139,143,445,993,995,1433,3306,3389,5900,8080"
echo "   - Type: TCP, Source: Anywhere (0.0.0.0/0)"
echo "✅ No local firewall needed on the VM!"

echo "✅ Deployment completed!"
echo "🌐 Your honeypot is accessible at: http://YOUR_LIGHTSAIL_IP"
echo "📊 Service status: sudo systemctl status internet-is-nasty"
echo "📋 Real-time logs: sudo journalctl -u internet-is-nasty -f"
echo ""
echo "✅ SSH CONFIGURATION:"
echo "   If you moved SSH to another port, the honeypot can now"
echo "   monitor port 22 and capture SSH intrusion attempts!"
