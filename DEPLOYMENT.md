# Guide de Déploiement AWS - Internet is Nasty

## 🚀 Meilleures Options de Déploiement

### Option 1: AWS Elastic Beanstalk (RECOMMANDÉE)
**✅ La plus simple et rapide**

**Avantages:**
- Déploiement automatique depuis GitHub
- Gestion automatique de l'infrastructure
- Scaling automatique
- Load balancing intégré
- Monitoring inclus

**Étapes de déploiement:**

1. **Préparer le repository GitHub**
   ```bash
   git add .
   git commit -m "Ready for AWS deployment"
   git push origin main
   ```

2. **Créer l'application Elastic Beanstalk**
   - Aller sur AWS Console → Elastic Beanstalk
   - Cliquer "Create Application"
   - Nom: `internet-is-nasty`
   - Platform: Python 3.9+
   - Source: "Connect to GitHub"

3. **Configuration automatique**
   - Elastic Beanstalk détectera automatiquement `requirements.txt`
   - L'application sera accessible sur un domaine AWS

**Coût estimé:** 10-20€/mois

---

### Option 2: AWS App Runner (MODERNE)
**✅ Serverless et pay-per-use**

**Avantages:**
- Pas de gestion d'infrastructure
- Scaling automatique à zéro
- Paiement à l'usage uniquement
- Déploiement direct depuis GitHub

**Étapes:**
1. AWS Console → App Runner
2. "Create service"
3. Source: GitHub repository
4. Build settings: Automatic (détecte Python)

**Coût estimé:** 5-15€/mois (selon le trafic)

---

### Option 3: EC2 + GitHub Actions (CONTRÔLE MAXIMUM)
**✅ Pour les utilisateurs avancés**

**Avantages:**
- Contrôle total de l'infrastructure
- Moins cher pour un usage constant
- Possibilité d'optimisation fine

**Inconvénients:**
- Plus complexe à configurer
- Gestion manuelle des mises à jour

---

## 🔧 Configuration Spéciale pour les Ports Privilégiés

**⚠️ IMPORTANT:** L'application écoute maintenant sur des ports privilégiés (22, 80, 443, etc.)

### Sur AWS, vous devez:

1. **Configurer les Security Groups**
   ```
   Inbound Rules:
   - Port 5000 (Flask app): 0.0.0.0/0
   - Ports 22,23,25,53,80,110,135,139,143,443,445,993,995,1433,3306,3389,5900,8080: 0.0.0.0/0
   ```

2. **Permissions root requises**
   - L'application doit tourner avec des privilèges élevés
   - Sur Elastic Beanstalk, ajouter dans `.ebextensions/01_permissions.config`:

```yaml
commands:
  01_run_as_root:
    command: "sudo python3 application.py"
    leader_only: true
```

---

## 📝 Fichiers de Configuration AWS

### 1. Créer `.ebextensions/python.config`
```yaml
option_settings:
  aws:elasticbeanstalk:container:python:
    WSGIPath: app.py
  aws:elasticbeanstalk:application:environment:
    PYTHONPATH: /var/app/current
```

### 2. Créer `Procfile` (pour App Runner)
```
web: python app.py
```

---

## 🛡️ Sécurité et Monitoring

### Recommandations:
1. **CloudWatch Logs**: Activer pour surveiller les tentatives d'intrusion
2. **AWS WAF**: Optionnel, pour filtrer le trafic malveillant
3. **Elastic IP**: Pour une IP fixe (Elastic Beanstalk)
4. **SSL Certificate**: Gratuit avec AWS Certificate Manager

---

## 🚀 Déploiement Rapide (Elastic Beanstalk)

```bash
# 1. Installer EB CLI
pip install awsebcli

# 2. Initialiser
eb init

# 3. Créer l'environnement
eb create internet-is-nasty-prod

# 4. Déployer
eb deploy

# 5. Ouvrir l'application
eb open
```

---

## 💰 Estimation des Coûts

| Service | Coût/mois | Avantages |
|---------|-----------|-----------|
| Elastic Beanstalk | 15-25€ | Simple, robuste |
| App Runner | 8-20€ | Serverless, moderne |
| EC2 t3.micro | 8-12€ | Maximum de contrôle |

**Recommandation:** Commencer avec **Elastic Beanstalk** pour la simplicité.
