# Guide de Validation et Preuves de Tests (TP 4G/5G)

## 1. Connectivité Initiale (Partie 1)
- **Test :** `ping <IP_PUBLIQUE_4G_PARTENAIRE>`
- **Résultat attendu :** Réponse du ping.
- **Preuve :** Screenshot du terminal montrant les pings réussis entre les deux hôtes via l'interface 4G.

## 2. Tunnel WireGuard (Partie 2)
- **Test :** `ping 10.50.0.1` (depuis Nathan) ou `ping 10.50.0.2` (depuis Robin).
- **Test :** `wg show`
- **Résultat attendu :** Ping OK via IP tunnel. `wg show` doit afficher le "handshake" récent et le transfert de données.
- **Preuve :** Output de la commande `wg show`.

## 3. Routage Inter-Site (Partie 3)
- **Test :** `ping 192.168.2.11` (depuis Site A vers Web B1).
- **Test :** `curl -I 10.50.0.2` (depuis Site A).
- **Résultat attendu :** Les serveurs web internes répondent à travers le tunnel.
- **Preuve :** Screenshot d'un `traceroute` montrant le passage par 10.50.0.x.

## 4. Sécurité (Partie 5 & 6)
- **Test :** `nmap <IP_PUBLIQUE_4G>`
- **Résultat attendu :** Seuls 80, 443, 53, 51820 et SSH (si autorisé) sont ouverts.
- **Test :** `curl -v http://<IP_LB>`
- **Résultat attendu :** Redirection 301 vers HTTPS.
- **Preuve :** Output `nmap` et headers HTTP `Location: https://...`.

## 5. Continuité d'Activité (Partie 7)
| Scénario | Action | Test | Résultat |
| :--- | :--- | :--- | :--- |
| **Web A1 HS** | `systemctl stop apache2` sur Web A1 | Rafraîchir page Web | Toujours accessible via Web A2 |
| **Site A HS** | `systemctl stop apache2` sur Web A1 et A2 | Rafraîchir page Web | Accessible via Site B (lentement via VPN) |
| **VPN HS** | `systemctl stop wg-quick@wg0` | Accès distant | Erreur sur le distant, local OK |
