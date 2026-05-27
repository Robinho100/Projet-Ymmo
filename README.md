# Projet Ymmo - Infrastructure & Plateforme Immobilière

## 📋 Vue d'ensemble

**Ymmo** est une plateforme de gestion immobilière distribuée avec architecture **Hub & Spoke** sécurisée :
- **Siège** : Aix-en-Provence (30 postes + 2 serveurs)
- **Agences** : 12 sites distants (5 postes chacun)
- **Connexion** : Tunnels VPN IPSec chiffrés (AES-256)
- **Services** : Active Directory, DB SQL, Site Web, Sauvegarde centralisée

## 🏗️ Architecture

```
SIÈGE (10.0.0.0/24)
├── Firewall/VPN Gateway (10.0.0.254)
├── Serveur AD/DNS/DHCP (10.0.0.1) 
└── Serveur Web/SQL (10.0.0.2)
       ↓
    [Tunnels VPN IPSec]
       ↓
AGENCES x12 (10.0.X.0/24)
├── Routeur VPN local
├── Switch + Postes (5 chacun)
└── Imprimante réseau
```

Voir `docs/Schema_Architecture.md` pour détails.

## 📂 Structure du Projet

```
Projet-Ymmo/
├── docs/                          # Documentation stratégique
│   ├── Schema_Architecture.md      # Topologie réseau visuelle
│   ├── Plan_Adressage_IP.md        # Subnetting 10.0.0.0/16
│   ├── Matrice_Droits_Acces.md     # AD + GPO + Permissions
│   ├── Budget_et_Cloud.md          # Budgétisation + alternatives cloud
│   ├── Plan_Sauvegarde_Supervision.md
│   └── Rapport_TP_Final.md
│
├── scripts/
│   ├── cloud/
│   │   └── init_cloud.sh           # Azure VM setup (Titouan)
│   ├── vpn/
│   │   ├── ipsec-config.sh         # IPSec tunnel init
│   │   └── vpn-failover-test.sh    # Tests de failover
│   ├── ad/
│   │   ├── create-groups.ps1       # GPO + Security Groups
│   │   └── gpo-policy.ps1          # Politique de sécurité
│   └── db/
│       └── init-db.sql             # Schema SQL initial
│
├── src/
│   ├── web/                        # Plateforme web (Stan)
│   │   ├── requirements.txt
│   │   ├── manage.py
│   │   └── ...
│   └── db/
│       ├── migrations/
│       └── schema.sql
│
├── docker/
│   ├── Dockerfile.web
│   ├── Dockerfile.db
│   └── docker-compose.yml
│
├── tests/
│   ├── vpn-connectivity-test.sh
│   ├── ad-integration-test.sh
│   └── load-testing.py
│
└── README.md (ce fichier)
```

## 🚀 Démarrage Rapide

### Prérequis

- **Azure Subscription** (pour VMs)
- **Windows Server 2022** (AD/DHCP)
- **Linux/WSL** (for VPN + automation)
- **Docker** (pour services)
- **Python 3.9+** (Django)

### Phase 1 : Initialisation Cloud (Titouan)

```bash
# 1. Clone et setup
git clone https://github.com/Robinho100/Projet-Ymmo.git
cd Projet-Ymmo

# 2. Lancer l'init Azure
chmod +x scripts/cloud/init_cloud.sh
./scripts/cloud/init_cloud.sh

# Paramètres attendus :
# - Azure Resource Group : ymmo-infra
# - VM Image : Windows Server 2022
# - Region : France Central
```

### Phase 2 : Configuration AD (Titouan)

```powershell
# Sur le Serveur AD (10.0.0.1)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
.\scripts\ad\create-groups.ps1
.\scripts\ad\gpo-policy.ps1
```

### Phase 3 : Tunnels VPN (Titouan)

```bash
# Sur le Firewall/Routeur siège
chmod +x scripts/vpn/ipsec-config.sh
./scripts/vpn/ipsec-config.sh --mode hub --subnet 10.0.0.0/16
```

### Phase 4 : Plateforme Web (Stan)

```bash
cd src/web
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Voir `DEPLOYMENT.md` pour guide détaillé.

## 📊 État des Tâches

| Composant | Lead | Statut | Notes |
|-----------|------|--------|-------|
| Docs stratégiques | Robin | ✅ Fait | Stockées dans `/docs` |
| Script init_cloud.sh | Titouan | 🟡 WIP | À tester sur Azure |
| Config AD/DNS/DHCP | Titouan | ❌ À faire | Post-phase1 |
| Tunnels VPN IPSec | Titouan | ❌ À faire | Dépend phase 1 |
| Site web (Django) | Stan | ❌ À faire | Django + PostgreSQL |
| DB SQL schema | Stan | ❌ À faire | Migrations Django |
| Docker setup | Stan | ❌ À faire | docker-compose.yml |
| Tests & validation | Titouan/Stan | ❌ À faire | Tunnels + Load test |

## 🔐 Sécurité

- **Chiffrement VPN** : AES-256 + IKEv2
- **AD Policy** : Mot de passe 12 chars (maj+chiffre+spécial), lockdown 10min
- **Droits d'accès** : Matrice NTFS par groupe (Direction, Commercial, etc.)
- **Sauvegarde** : NAS Synology centralisé au siège
- **Firewall** : UFW + FortiGate (peering)

Voir `docs/Matrice_Droits_Acces.md`.

## 📞 Support

- **Questions réseau ?** → Consultez `docs/Plan_Adressage_IP.md`
- **Erreur VPN ?** → Allez voir `tests/vpn-connectivity-test.sh`
- **Besoin de budgeter ?** → `docs/Budget_et_Cloud.md`
- **Sauvegardes ?** → `docs/Plan_Sauvegarde_Supervision.md`

## 🎯 Timeline

- **Sem 5** (cette semaine) : Phase 1 + 2 (Cloud + AD)
- **Sem 6** : Phase 3 (VPN) + Phase 4 (Web)
- **Sem 7** : Tests, failover, load testing
- **Sem 8** : Déploiement en prod

---

**Dernier commit** : Initial commit - Documentation et Architecture (Robin)  
**Prochaines étapes** : Attendre commits Titouan (init_cloud.sh) et Stan (site web)
