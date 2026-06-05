# Guide de Déploiement - Projet Ymmo

Ce document détaille les étapes nécessaires au déploiement complet de l'infrastructure et de la plateforme web pour le groupe Ymmo.

## 🚀 Étape 1 : Initialisation de l'Infrastructure Cloud
Avant de configurer les services, la VM Azure doit être préparée.
1. Se connecter à la VM via SSH.
2. Cloner le dépôt : `git clone https://github.com/Robinho100/Projet-Ymmo`
3. Exécuter le script d'initialisation :
   ```bash
   chmod +x Projet-Ymmo/scripts/cloud/init_cloud.sh
   ./Projet-Ymmo/scripts/cloud/init_cloud.sh
   ```

## 🏗️ Étape 2 : Configuration du Cœur de Réseau (Siège)
*Responsable : Titouan & Robin*
1. **Active Directory** : Promouvoir le serveur Windows en tant que contrôleur de domaine principal.
   ```powershell
   .\scripts\powershell\Setup-ADDS-Ymmo.ps1
   ```
2. **Structure & Groupes** : Créer les OUs et les groupes de sécurité.
   ```powershell
   .\scripts\powershell\Create-OU-Ymmo.ps1
   .\scripts\powershell\Create-Users-Groups-Ymmo.ps1
   ```
3. **DNS & DHCP** : Configurer les zones et les plages d'adresses selon le `Plan_Adressage_IP.md`.

## 🔐 Étape 3 : Interconnexion des Agences (VPN)
*Responsable : Titouan*
1. Configurer le tunnel WireGuard entre le siège et les agences en utilisant les scripts du dossier `tp-infra-4g/scripts/`.
2. Vérifier la connectivité : chaque agence doit pouvoir `ping 10.0.0.1` (Serveur AD).

## 🌐 Étape 4 : Déploiement de la Plateforme Web
*Responsable : Stan*
1. Configurer la base de données PostgreSQL selon la `Matrice_Droits_Acces.md`.
2. Déployer l'application web via Docker Compose.
   ```bash
   docker-compose up -d
   ```
3. Vérifier l'accès au site sur `http://localhost`.

## 🛡️ Étape 5 : Validation et Sécurité
1. Appliquer les GPO de sécurité (Verrouillage session, mots de passe).
2. Tester le plan de sauvegarde (Veeam).
3. Effectuer un scan de ports pour valider le firewall.

---
*Livrable généré par Robin (Lead Archi) pour l'équipe Projet Ymmo*
