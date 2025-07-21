#!/bin/bash

# Script de déploiement automatique pour Internet is Nasty
# Usage: ./deploy.sh

echo "🚀 Déploiement d'Internet is Nasty sur AWS..."

# Vérifier si EB CLI est installé
if ! command -v eb &> /dev/null; then
    echo "❌ EB CLI n'est pas installé. Installation..."
    pip install awsebcli
fi

# Vérifier si l'application EB existe
if [ ! -f .elasticbeanstalk/config.yml ]; then
    echo "🔧 Initialisation d'Elastic Beanstalk..."
    eb init --platform python-3.9 --region eu-west-1 internet-is-nasty
fi

# Créer l'environnement s'il n'existe pas
echo "🏗️  Création/Mise à jour de l'environnement..."
eb create internet-is-nasty-prod --single-instance || eb deploy

echo "🌐 Ouverture de l'application..."
eb open

echo "✅ Déploiement terminé !"
echo "📊 Pour voir les logs: eb logs"
echo "🔧 Pour mettre à jour: eb deploy"
