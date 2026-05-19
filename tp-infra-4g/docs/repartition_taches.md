# Répartition des Tâches - TP Infrastructure Web Sécurisée

## Équipe : Robin & Nathan

### 🧑‍💻 Robin (Prestataire Site A - Principal)
**Responsabilités :**
1. **Réseau Site A :** Configuration du LB A en mode Bridge sur connexion 4G.
2. **Tunnel VPN :** Initialisation du tunnel WireGuard (IP 10.50.0.1).
3. **Routage :** Configuration des routes vers le Site B (10.50.0.2).
4. **Load Balancing :** Configuration HAProxy avec priorité aux serveurs du Site A.
5. **Sécurité :** Mise en place du Firewall (UFW) et HTTPS sur le Site A.

### 🧑‍💻 Nathan (Prestataire Site B - PRA)
**Responsabilités :**
1. **Réseau Site B :** Configuration du LB B en mode Bridge sur connexion 4G.
2. **Tunnel VPN :** Connexion au tunnel WireGuard (IP 10.50.0.2).
3. **Routage :** Configuration des routes vers le Site A (10.50.0.1).
4. **Load Balancing :** Configuration HAProxy (Miroir ou Backup du Site A).
5. **Sécurité :** Mise en place du Firewall (UFW) et HTTPS sur le Site B.

---

## 📊 Plan d'Adressage Logique

| Élément | Réseau Interne (LAN) | IP Tunnel (VPN) | Rôle |
| :--- | :--- | :--- | :--- |
| **LB Site A** | 192.168.1.10/24 | 10.50.0.1/24 | Passerelle / VPN / HAProxy |
| **Web A1** | 192.168.1.11/24 | - | Serveur Web Local |
| **Web A2** | 192.168.1.12/24 | - | Serveur Web Local |
| **LB Site B** | 192.168.2.10/24 | 10.50.0.2/24 | Passerelle / VPN / HAProxy |
| **Web B1** | 192.168.2.11/24 | - | Serveur Web PRA |
| **Web B2** | 192.168.2.12/24 | - | Serveur Web PRA |

---

## 🛠️ Ordre de Marche (Rigoureux)
1. **Phase 1 :** Connectivité 4G + Bridge + Ping IP Publiques.
2. **Phase 2 :** Installation WireGuard + Échange de clés publiques.
3. **Phase 3 :** Activation du tunnel + Ping 10.50.0.X.
4. **Phase 4 :** Configuration des routes statiques.
5. **Phase 5 :** Installation HAProxy + Certificats SSL.
6. **Phase 6 :** Tests de panne (Coupure services/VPN).
