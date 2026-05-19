# Schéma d'Architecture Réseau - Projet Ymmo

Ce schéma représente la topologie **Hub & Spoke** sécurisée entre le siège social (Aix) et les agences distantes.

## 1. Schéma Visuel (Mermaid)

```mermaid
graph TD
    subgraph "SIÈGE SOCIAL (AIX-EN-PROVENCE)"
        direction TB
        FW1[Firewall/Routeur VPN]
        SW1[Switch Cœur de Réseau]
        
        subgraph "Zone Serveurs (VLAN 10)"
            SRV_AD[Serveur AD/DNS/DHCP]
            SRV_WEB[Serveur Web/SQL/Fichiers]
        end
        
        subgraph "Zone Utilisateurs (VLAN 20)"
            POSTES_SIEGE[30x Postes de travail]
            IMP_SIEGE[Imprimante Réseau]
        end
        
        FW1 --- SW1
        SW1 --- SRV_AD
        SW1 --- SRV_WEB
        SW1 --- POSTES_SIEGE
        SW1 --- IMP_SIEGE
    end

    subgraph "INTERNET / WAN"
        CLOUD((Nuage Internet))
    end

    subgraph "AGENCES (x12)"
        FW_AG[Routeur VPN Agence]
        SW_AG[Switch Local]
        POSTES_AG[5x Postes Commerciaux]
        IMP_AG[Imprimante Agence]
        
        FW_AG --- SW_AG
        SW_AG --- POSTES_AG
        SW_AG --- IMP_AG
    end

    %% Tunnels VPN
    FW1 <== "Tunnel VPN IPSec (Chiffré)" ==> CLOUD
    CLOUD <== "Tunnel VPN IPSec (Chiffré)" ==> FW_AG

    %% Styles
    style FW1 fill:#f96,stroke:#333,stroke-width:2px
    style FW_AG fill:#f96,stroke:#333,stroke-width:2px
    style SRV_AD fill:#9cf,stroke:#333,stroke-width:2px
    style SRV_WEB fill:#9cf,stroke:#333,stroke-width:2px
    style CLOUD fill:#fff,stroke:#333,stroke-dasharray: 5 5
```

## 2. Légende technique
*   **Ligne Double (==) :** Tunnel VPN IPSec sécurisé.
*   **Ligne Simple (--) :** Connexion Ethernet LAN (GigaBit).
*   **Firewall :** Gère la sécurité périmétrique et le routage inter-VLAN.
*   **Serveurs :** Centralisés au siège pour faciliter la maintenance et les sauvegardes.

---
*Document généré pour la partie Architecture - Robin*
