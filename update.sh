#!/bin/bash

# Script de mise à jour pour Internet is Nasty sur Lightsail - Amazon Linux 2023
# À exécuter sur la VM pour mettre à jour le code

echo "🔄 Mise à jour d'Internet is Nasty..."

cd /home/ec2-user/Internetisnasty

# Sauvegarder les changements locaux si nécessaire
git stash

# Récupérer les dernières modifications
echo "📥 Récupération des dernières modifications..."
git pull origin main

# Restaurer les changements locaux si nécessaire
git stash pop 2>/dev/null || true

# Mettre à jour les dépendances si nécessaire
echo "📚 Vérification des dépendances..."
source venv/bin/activate
pip install -r requirements.txt

# Redémarrer le service
echo "🔄 Redémarrage du service..."
sudo systemctl restart internet-is-nasty

# Vérifier le statut
echo "✅ Vérification du statut..."
sleep 2
sudo systemctl status internet-is-nasty --no-pager

echo "🎉 Mise à jour terminée !"
echo "📊 Logs en temps réel : sudo journalctl -u internet-is-nasty -f"
