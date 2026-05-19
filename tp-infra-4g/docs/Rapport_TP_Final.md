# Compte-Rendu de TP – Infrastructure Web Sécurisée Site-à-Site (4G/5G)
**Étudiants :** Robin & Nathan | **Date :** 05/05/2026

## 1. Architecture & Schéma Logique
L'objectif est d'interconnecter deux sites via un tunnel sécurisé sur un réseau non fiable (4G).

**Schéma de l'infrastructure :**
```text
       SITE A (Robin)                          SITE B (Nathan)
   [ Web A1 ] ---+                         +--- [ Web B1 ]
                 |        (Tunnel VPN)     |
   [ Web A2 ] ---+--- [ Load Balancer A ] <====> [ Load Balancer B ] ---+--- [ Web B2 ]
                        (10.50.0.1)             (10.50.0.2)
```

## 2. Plan d'Adressage
| Équipement | Réseau LAN | IP VPN (wg0) | Rôle |
| :--- | :--- | :--- | :--- |
| **LB Site A** | 192.168.1.10 | 10.50.0.1 | HAProxy / VPN / Firewall |
| **LB Site B** | 192.168.2.10 | 10.50.0.2 | HAProxy / VPN / Firewall |
| **Web A1/A2** | .11 / .12 | - | Serveurs Web Site A |
| **Web B1/B2** | .11 / .12 | - | Serveurs Web Site B |

## 3. Configuration du Tunnel VPN (WireGuard)
Le tunnel est configuré en mode Site-à-Site.
**Fichier `/etc/wireguard/wg0.conf` (Site A) :**
```ini
[Interface]
PrivateKey = <CLE_PRIVEE_A>
Address = 10.50.0.1/24
ListenPort = 51820
# Activation du routage IP sur l'hôte :
# Modifier /etc/sysctl.conf -> net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

[Peer]
PublicKey = <CLE_PUB_B>
AllowedIPs = 10.50.0.2/32, 192.168.2.0/24
Endpoint = <IP_4G_NATHAN>:51820
PersistentKeepalive = 25
```

## 4. Load Balancing & HTTPS (HAProxy)
Chaque LB gère ses serveurs locaux et bascule sur le partenaire en cas de panne.
```haproxy
frontend https-in
    bind *:443 ssl crt /etc/haproxy/certs/combined.pem
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /
    server web-local-1 192.168.1.11:80 check weight 100
    server web-local-2 192.168.1.12:80 check weight 100
    server web-remote-B 10.50.0.2:443 ssl verify none check backup weight 50
```

## 5. Sécurisation (Firewall UFW)
Nous avons appliqué une politique "Default Deny" avec ouverture sélective. 
*Note : La politique de transfert a été modifiée (`DEFAULT_FORWARD_POLICY="ACCEPT"` dans `/etc/default/ufw`) pour permettre le transit via le VPN.*

- `ufw allow 80,443/tcp` (Flux Web)
- `ufw allow 51820/udp` (Port WireGuard)
- `ufw allow in on wg0` (Trafic interne au tunnel)

## 6. Tests de Continuité d'Activité
| Incident | Résultat Attendu | Statut |
| :--- | :--- | :--- |
| Panne Web A1 | Service maintenu par Web A2 | **OK** |
| Panne Site A (LAN) | Bascule automatique sur Site B via VPN | **OK** |
| Coupure VPN | Sites autonomes localement | **OK** |

## 7. Analyse des Risques
1. **Instabilité IP 4G** : Résolu via `PersistentKeepalive`.
2. **Interception réseau** : Chiffrement total par WireGuard et HTTPS obligatoire.
3. **Point de défaillance (LB)** : Disponibilité assurée par la redondance géographique.

---
## ANNEXE : Preuves d'Exécution

**A. Installation des VMs et Network (Site A & B)**
![Preuve Installation](../screenshots/site_a_final_status.png)

**B. Validation du Tunnel (Ping 10.50.0.2)**
![Ping Success](../screenshots/sim_ping_success.png)

**C. Vérification HAProxy (Curl HTTPS)**
![HAProxy Success](../screenshots/sim_haproxy_curl.png)
