# Plan de Sauvegarde et de Supervision - Projet Ymmo

## 1. Stratégie de Sauvegarde (Backup)
Pour garantir la sécurité des données immobilières et des configurations AD, nous appliquons la règle du **3-2-1**.

### Fréquence et Rétention
*   **Sauvegarde Complète** : Chaque week-end (samedi soir).
*   **Sauvegarde Incrémentale** : Chaque soir (du lundi au vendredi).
*   **Rétention** : Conservation des sauvegardes sur 30 jours glissants.

### Détails Techniques
*   **Données à sauvegarder** : Base de données SQL (Ymmo Web), Partages de fichiers (Matrice des droits), État du système (Active Directory).
*   **Support de stockage** : 
    1.  **Local** : NAS situé au siège (VLAN dédié).
    2.  **Externalisé** : Stockage Cloud sécurisé (Azure Blob Storage ou AWS S3) pour la protection contre les sinistres physiques (incendie, vol).
*   **Outil préconisé** : Veeam Backup & Replication ou Windows Server Backup.

### Objectifs de Continuité
*   **RPO (Recovery Point Objective)** : 24 heures (perte de données maximale autorisée).
*   **RTO (Recovery Time Objective)** : 4 heures (temps maximum pour rétablir les services critiques).

## 2. Plan de Supervision (Monitoring)
L'objectif est d'être alerté **avant** que les utilisateurs ne constatent une panne.

### Éléments supervisés
*   **Serveurs** : Charge CPU, utilisation RAM, espace disque disponible (Alerte à 85% d'occupation).
*   **Réseau** : État des tunnels VPN IPSec avec les 12 agences (Up/Down).
*   **Services** : État des services critiques (DNS, DHCP, Active Directory, Serveur Web Apache/IIS).
*   **Sécurité** : Tentatives de connexion infructueuses (Brute force detection).

### Outils de supervision
*   **Zabbix** ou **PRTG** : Pour une vue d'ensemble du parc avec un tableau de bord (Dashboard).
*   **Alerting** : Envoi de notifications par Email ou Slack en cas d'incident critique.

---
*Document généré pour la partie Stratégie - Robin*
