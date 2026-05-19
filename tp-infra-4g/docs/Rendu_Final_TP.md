# Compte-Rendu de TP – Infrastructure Web Sécurisée (4G/5G)
**Étudiants :** Robin & Nathan | **Date :** 05/05/2026

## 1. Plan d'Adressage & Architecture
L'infrastructure relie deux sites via un tunnel WireGuard sur réseau 4G. Chaque site possède un Load Balancer (LB) gérant le trafic local et le débordement vers le partenaire.

| Équipement | LAN (Eth0) | Tunnel (wg0) | Rôle |
| :--- | :--- | :--- | :--- |
| **LB Site A (Robin)** | 192.168.1.10 | 10.50.0.1 | Master / HAProxy / VPN |
| **LB Site B (Nathan)** | 192.168.2.10 | 10.50.0.2 | PRA / HAProxy / VPN |
| **Web A1/A2** | .11 / .12 | - | Backend Site A |
| **Web B1/B2** | .11 / .12 | - | Backend Site B |

## 2. Interconnexion Sécurisée (WireGuard)
Nous avons mis en place un tunnel chiffré entre les deux LBs. 
**Extrait /etc/wireguard/wg0.conf (Site A) :**
```ini
[Interface]
Address = 10.50.0.1/24
ListenPort = 51820
PrivateKey = <PRIV_KEY_A>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
[Peer]
PublicKey = <PUB_KEY_B>
AllowedIPs = 10.50.0.2/32, 192.168.2.0/24
Endpoint = <IP_4G_B>:51820
```

## 3. Load Balancing & HTTPS (HAProxy)
Le LB force le HTTPS et redirige vers le site partenaire si les serveurs locaux sont HS.
**Config HAProxy (Site A) :**
```haproxy
frontend https-in
    bind *:443 ssl crt /etc/haproxy/certs/combined.pem
    default_backend web_servers
backend web_servers
    balance roundrobin
    option httpchk GET /
    server web-local-1 192.168.1.11:80 check weight 100
    server web-remote-B 10.50.0.2:443 ssl verify none check backup weight 50
```

## 4. Sécurisation (Firewall)
Filtrage strict via UFW pour ne laisser passer que le flux Web, VPN et SSH (limité au partenaire).
```bash
ufw default deny incoming
ufw allow 80,443/tcp
ufw allow 51820/udp
ufw allow in on wg0
ufw allow from <IP_PARTENAIRE> to any port 22 proto tcp
```

## 5. Validation & Tests de Continuité
| Incident | Test | Résultat |
| :--- | :--- | :--- |
| Perte Web A1 | `systemctl stop apache2` | Toujours OK (via Web A2) |
| Perte Site A complet | Arrêt A1 + A2 | Toujours OK (Bascule via VPN vers Site B) |
| VPN Coupé | `wg-quick down wg0` | Sites isolés mais fonctionnels localement |

**Traces de validation :**
- `ping 10.50.0.2` : **OK** (Latence 42ms)
- `curl -I https://localhost` : **200 OK** (Certificat SSL actif)

## 6. Analyse des Risques
Le principal risque est la variation de l'IP 4G. Mitigation : `PersistentKeepalive` et scripts de mise à jour d'Endpoint. La sécurité est assurée par le chiffrement de bout en bout (Tunnel + HTTPS).
