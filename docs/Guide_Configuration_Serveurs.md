# Guide de Configuration des Serveurs - Projet Ymmo

Ce guide fournit les paramètres techniques pour la mise en place des serveurs critiques du groupe Ymmo.

## 🏢 1. Serveur Contrôleur de Domaine (AD-YMMO)
*   **Système** : Windows Server 2022
*   **IP** : 10.0.0.1 / 24
*   **Rôle** : AD DS, DNS, DHCP
*   **Nom de domaine** : `ymmo.local`
*   **OUs à créer** :
    *   `YMMO_Siège` (Direction, Marketing, IT, Administratif)
    *   `YMMO_Agences` (Commercial)

## 💻 2. Serveur Web & Base de Données (WEB-YMMO)
*   **Système** : Ubuntu 24.04 LTS (via Docker)
*   **IP** : 10.0.0.2 / 24
*   **Rôle** : Serveur Apache/Nginx, MySQL/PostgreSQL
*   **Configuration SQL** :
    *   Base : `ymmo_db`
    *   Utilisateur : `stan_admin`
    *   Permissions : Droits complets sur `ymmo_db`, accès restreint via l'API.

## 🛡️ 3. Serveur VPN / Passerelle (FW-YMMO)
*   **Système** : Ubuntu Server ou FortiGate (Virtuel)
*   **IP LAN** : 10.0.0.254 / 24
*   **IP WAN** : Adresse IP Publique (Azure)
*   **Protocole VPN** : IPSec IKEv2
*   **Configuration** :
    *   Phase 1 : Encryption AES-256, DH Group 14.
    *   Phase 2 : ESP, AES-256, HMAC-SHA256.

## 📁 4. Serveur de Fichiers (FILE-YMMO)
*   **Système** : Windows Server (Partage SMB)
*   **Partage Racine** : `\\AD-YMMO\Partages`
*   **Droits NTFS** : Appliquer strictement la `Matrice_Droits_Acces.md`.
*   **Shadow Copies** : Activer pour permettre aux utilisateurs de restaurer des versions précédentes.

---
*Livrable généré par Robin (Lead Archi) pour l'équipe Projet Ymmo*
