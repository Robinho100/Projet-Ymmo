# Architecture Réseau et Plan d'Adressage IP - Projet Ymmo

## 1. Topologie Réseau
L'infrastructure repose sur un modèle "Hub and Spoke" :
*   **Hub (Siège - Aix-en-Provence) :** Centralise les ressources (Serveurs, AD, Web, SQL).
*   **Spokes (12 Agences) :** Connectées au siège via des tunnels VPN/IPSec sécurisés.

## 2. Plan d'Adressage IP (IPv4)
Nous utiliserons la plage privée **10.0.0.0/8** pour permettre une scalabilité maximale.

### Réseau Global
*   **Plage globale :** 10.0.0.0/16
*   **Masque par défaut :** 255.255.255.0 (/24) pour chaque site.

### Détail des Sous-réseaux

| Site | Plage IP | Masque | Passerelle (Routeur) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Siège (Aix)** | 10.0.0.0/24 | 255.255.255.0 | 10.0.0.254 | 30 postes + 2 serveurs + 1 Imp |
| **Agence 1** | 10.0.1.0/24 | 255.255.255.0 | 10.0.1.254 | 5 postes + 1 Imp |
| **Agence 2** | 10.0.2.0/24 | 255.255.255.0 | 10.0.2.254 | 5 postes + 1 Imp |
| ... | ... | ... | ... | ... |
| **Agence 12** | 10.0.12.0/24 | 255.255.255.0 | 10.0.12.254 | 5 postes + 1 Imp |

### Adressage Statique (Siège)
*   **Serveur AD/DNS/DHCP :** 10.0.0.1
*   **Serveur Web/SQL :** 10.0.0.2
*   **Imprimante Siège :** 10.0.0.10
*   **Routeur/Firewall :** 10.0.0.254

## 3. Configuration des Tunnels VPN
*   **Protocole :** IPsec IKEv2
*   **Chiffrement :** AES-256
*   **Authentification :** Certificats ou Pre-shared Key (PSK)
*   **Objectif :** Permettre aux agences d'accéder aux serveurs du siège et à l'Active Directory.

---
*Document généré pour la partie Architecture - Robin*
