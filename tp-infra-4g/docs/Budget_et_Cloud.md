# Budgétisation Matérielle et Proposition Cloud - Projet Ymmo

## 1. Budget Matériel (Infrastructure On-Premise)
Estimation pour le siège et les 12 agences avec du matériel professionnel garanti 3 ans.

| Équipement | Modèle (Exemple) | Quantité | Prix Unitaire (Est.) | Total (Est.) |
| :--- | :--- | :---: | :---: | :---: |
| **Serveurs (Siège)** | Dell PowerEdge R450 (32GB RAM, 2TB SSD RAID) | 2 | 3 500 € | 7 000 € |
| **Switch Cœur (Siège)** | Cisco Catalyst 9200L (24 ports GigE) | 1 | 1 800 € | 1 800 € |
| **Firewall/VPN (Siège)** | FortiGate 60F | 1 | 900 € | 900 € |
| **Switchs (Agences)** | Cisco Business 250 (8 ports) | 12 | 250 € | 3 000 € |
| **Routeurs/VPN (Agences)** | Ubiquiti EdgeRouter 4 | 12 | 200 € | 2 400 € |
| **Onduleur (Siège)** | APC Smart-UPS 1500VA | 1 | 600 € | 600 € |
| **NAS Sauvegarde** | Synology DS423+ (4x4TB HDD) | 1 | 1 000 € | 1 000 € |
| **TOTAL ESTIMÉ HT** | | | | **16 700 €** |

## 2. Proposition de Solution Cloud (Alternative)
Pour plus de scalabilité et moins de maintenance matérielle, une migration vers le Cloud est envisageable.

### Modèle Hybride (Recommandé)
*   **Active Directory & Fichiers** : Migration vers **Azure AD** et **SharePoint/OneDrive**.
*   **Serveur Web & SQL** : Hébergement sur des instances **Azure SQL** et **App Services**.
*   **Avantages** :
    *   Pas d'investissement matériel initial (CAPEX réduit).
    *   Haute disponibilité native (99.9%).
    *   Sécurité renforcée (Microsoft Defender).
*   **Coût estimatif** : Abonnement mensuel d'environ 450 € / mois (OPEX).

## 3. Guide de Déploiement (Résumé)
1.  **Phase 1** : Pré-configuration des serveurs et du firewall au siège.
2.  **Phase 2** : Envoi des routeurs pré-configurés dans les 12 agences.
3.  **Phase 3** : Montage des tunnels VPN et jointure au domaine des postes agences.
4.  **Phase 4** : Tests de montée en charge et validation du plan de sauvegarde.

---
*Document généré pour la partie Stratégie - Robin*
