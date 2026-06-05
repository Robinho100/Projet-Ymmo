# 🏢 Projet Ymmo - Infrastructure & Plateforme Immobilière

## 📋 Vue d'ensemble
Le projet **Ymmo** consiste à déployer une infrastructure sécurisée et une plateforme web pour un groupe immobilier national. L'architecture repose sur un modèle **Hub & Spoke** (Siège + 12 agences).

## 👥 Équipe & Répartition (Binôme)
- **Robin** : Architecture réseau, Plan d'adressage, Budgétisation, **Base de données (SQL) & Orchestration Docker**.
- **Titouan** : Infrastructure Cloud (Azure), Active Directory, DNS, **Déploiement de la plateforme Web & Sécurité (GPO)**.

## 🏗️ Architecture Technique
- **Cloud** : Instances Azure (Windows Server & Ubuntu).
- **Réseau** : Tunnels VPN IPSec entre le siège et les agences.
- **Identités** : Domaine `ymmo.local`, 5 groupes de sécurité, OUs segmentées.
- **Web Stack** : Django, PostgreSQL, Redis, Nginx (Reverse Proxy).

## 📂 Structure du Repo
*   **`docs/`** : Architecture, Budget, Sécurité, Sauvegarde.
*   **`scripts/ad/`** : Automatisation Active Directory (Titouan).
*   **`scripts/cloud/`** : Provisioning Azure (Titouan).
*   **`scripts/vpn/`** : Configuration des tunnels IPSec.
*   **`src/web/`** : Application Django (Stan).
*   **`docker/`** : Configuration Docker & Nginx.
*   **`tp-infra-4g/`** : Rapport de TP sur l'infrastructure 4G (Robin & Nathan).

## 🚀 Déploiement
1. Provisionner l'infra : `scripts/cloud/init_cloud.sh`
2. Configurer l'AD : `scripts/ad/create-groups.ps1`
3. Lancer le Web : `docker-compose up -d`

---
*Projet finalisé pour la soutenance du 4 Juin 2026.*
