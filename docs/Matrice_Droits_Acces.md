# Matrice des Droits d'Accès et Structure Active Directory - Projet Ymmo

## 1. Structure des Groupes de Sécurité (Active Directory)
Pour gérer les accès de manière centralisée, nous allons créer les groupes suivants dans l'OU (Organizational Unit) "Utilisateurs" :

*   **GS_Direction** : Membres de la direction.
*   **GS_Commercial** : Agents commerciaux des agences et du siège.
*   **GS_Marketing** : Équipe Communication & Marketing.
*   **GS_Administratif** : RH, Juridique et Administratif.
*   **GS_IT_Support** : Équipe technique et support.

## 2. Arborescence des Dossiers Partagés
Le serveur de fichiers (10.0.0.1) hébergera un partage racine nommé `\\SERVEUR-YMMO\Partages` contenant les sous-dossiers suivants :

1.  `01_Direction`
2.  `02_Commercial`
3.  `03_Marketing`
4.  `04_Administratif`
5.  `05_IT_Support`

## 3. Matrice des Permissions (NTFS / Partage)

Conformément au brief client, voici les droits appliqués (L = Lecture seule, L/E = Lecture et Écriture, X = Accès interdit) :

| Dossier \ Groupe | GS_Direction | GS_Commercial | GS_Marketing | GS_Administratif | GS_IT_Support |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **01_Direction** | **L/E** | L | L | L | L |
| **02_Commercial** | X | **L/E** | L | X | X |
| **03_Marketing** | X | L | **L/E** | X | X |
| **04_Administratif** | X | L | L | **L/E** | X |
| **05_IT_Support** | X | L | L | L | **L/E** |

## 4. Politique de Sécurité (GPO)
Pour renforcer la sécurité, les stratégies suivantes seront appliquées via GPO :
*   **Mappage auto** : Montage automatique des lecteurs réseaux selon le groupe d'appartenance.
*   **Complexité des mots de passe** : 12 caractères minimum, majuscule, chiffre et caractère spécial.
*   **Verrouillage de session** : Automatique après 10 minutes d'inactivité.

---
*Document généré pour la partie Sécurité - Robin*
