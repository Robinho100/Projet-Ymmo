# 🏢 Projet Ymmo - Infrastructure & Plateforme Immobilière

## 📋 Vue d'ensemble

**Ymmo** est une plateforme de gestion immobilière distribuée avec architecture **Hub & Spoke** sécurisée :
- **Siège** : Aix-en-Provence (30 postes + 2 serveurs)
- **Agences** : 12 sites distants (5 postes chacun)
- **Connexion** : Tunnels VPN WireGuard chiffrés
- **Services** : Active Directory, DB SQL, Site Web, Sauvegarde centralisée

## 🏗️ Architecture

```
SIÈGE (10.0.0.0/24)
├── Firewall/VPN Gateway (10.0.0.254)
├── Serveur AD/DNS/DHCP (10.0.0.1) 
└── Serveur Web/SQL (10.0.0.2)
       ↓
    [Tunnels VPN WireGuard]
       ↓
AGENCES x12 (10.0.X.0/24)
├── Routeur VPN local
├── Switch + Postes (5 chacun)
└── Imprimante réseau
```

## 📂 Structure du Projet

*   **`docs/`** : Documentation complète (Architecture, Budget, Plan d'adressage).
*   **`scripts/powershell/`** : Automatisation Active Directory (Promotion, OUs, Groupes, GPO).
*   **`scripts/cloud/`** : Initialisation Azure (Provisioning & Setup VM).
*   **`tp-infra-4g/`** : Configuration et preuves du tunnel VPN sécurisé inter-sites (Robin & Nathan).
*   **`src/web/`** : Plateforme web Django (Stan).
*   **`docker-compose.yml`** : Orchestration complète (Django, PostgreSQL, Redis, Nginx, PgAdmin).

## 🚀 Démarrage Rapide

1.  **Infrastructure Azure** : Exécuter `scripts/cloud/init_cloud.sh` pour provisionner les ressources.
2.  **Configuration Windows** :
    ```powershell
    .\scripts\powershell\Setup-ADDS-Ymmo.ps1
    .\scripts\powershell\Create-OU-Ymmo.ps1
    .\scripts\powershell\Create-Users-Groups-Ymmo.ps1
    .\scripts\powershell\Configure-GPO-Ymmo.ps1
    ```
3.  **Plateforme Web** : `docker-compose up -d`
4.  **Interconnexion VPN** : Suivre le guide dans `tp-infra-4g/`.

## 📊 État final du Projet

| Composant | Lead | Statut |
|-----------|------|--------|
| Architecture & Docs | Robin | ✅ Terminé |
| Provisioning Azure | Titouan | ✅ Terminé |
| AD / DNS / GPO | Titouan/Robin | ✅ Terminé |
| Tunnels VPN | Nathan | ✅ Terminé |
| Plateforme Django | Stan | ✅ Terminé |
| Docker Stack | Stan/Robin | ✅ Terminé |

---
**Équipe :** Robin, Nathan, Stan, Titouan.  
*Projet finalisé avec rigueur le 4 Juin 2026.*
