#!/bin/bash

# Script de déploiement pour AWS Lightsail - Amazon Linux 2023
# À exécuter SUR la VM Lightsail après création

echo "🚀 Déploiement d'Internet is Nasty sur AWS Lightsail (Amazon Linux 2023)..."

# Mise à jour du système
echo "📦 Mise à jour du système..."
sudo dnf update -y

# Installation de Python et pip
echo "[*] Installing required packages..."
sudo dnf update -y
sudo dnf install -y python3 python3-pip git sqlite libcap

# Clonage du repository
echo "📥 Clonage du repository..."
cd /home/ec2-user
git clone https://github.com/vmeoc/Internetisnasty.git
cd Internetisnasty

# Création de l'environnement virtuel
echo "🔧 Configuration de l'environnement Python..."
python3 -m venv venv
source venv/bin/activate

# Installation des dépendances
echo "📚 Installation des dépendances..."
pip install -r requirements.txt

# Configuration des permissions pour les ports privilégiés
echo "🔐 Configuration des permissions..."
# Pour les ports privilégiés, on utilisera sudo dans le service systemd
echo "Les ports privilégiés seront gérés via sudo dans le service systemd"

# Création du service systemd
echo "⚙️ Création du service systemd..."
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

# Activation et démarrage du service
echo "🔄 Activation du service..."
sudo systemctl daemon-reload
sudo systemctl enable internet-is-nasty
sudo systemctl start internet-is-nasty

# Configuration du firewall
echo "🔥 Configuration du firewall..."
echo "ℹ️  AWS Lightsail gère le firewall au niveau infrastructure."
echo "🔧 Configurez les ports dans la console Lightsail :"
echo "   - Allez dans Lightsail Console > Votre instance > Networking > Firewall"
echo "   - Ajoutez ces ports : 80,22,23,25,53,110,135,139,143,445,993,995,1433,3306,3389,5900,8080"
echo "   - Type: TCP, Source: Anywhere (0.0.0.0/0)"
echo "✅ Pas de firewall local nécessaire sur la VM !"

echo "✅ Déploiement terminé !"
echo "🌐 Votre honeypot est accessible sur : http://VOTRE_IP_LIGHTSAIL"
echo "📊 Status du service : sudo systemctl status internet-is-nasty"
echo "📋 Logs en temps réel : sudo journalctl -u internet-is-nasty -f"
echo ""
echo "✅ CONFIGURATION SSH :"
echo "   Si vous avez déplacé SSH sur un autre port, le honeypot peut maintenant"
echo "   surveiller le port 22 et capturer les tentatives d'intrusion SSH !"
