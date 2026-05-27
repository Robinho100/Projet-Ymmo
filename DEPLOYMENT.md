# Ymmo Deployment Guide

## Phase Overview

This guide walks through the complete deployment of the Ymmo infrastructure in 4 phases over 4 weeks.

```
Phase 1 (Sem 5): Cloud Setup + AD Configuration
Phase 2 (Sem 6): VPN Tunnels + Web Application
Phase 3 (Sem 7): Testing & Failover Validation
Phase 4 (Sem 8): Production Deployment
```

---

## Phase 1: Cloud & Active Directory Setup (Week 1)

**Lead**: Titouan  
**Duration**: Days 1-5  
**Deliverable**: HQ VMs + Active Directory online

### Step 1.1: Azure Infrastructure (Days 1-2)

```bash
# Prerequisites
az login
az account set --subscription <subscription-id>

# Run cloud init script
chmod +x scripts/cloud/init_cloud.sh
./scripts/cloud/init_cloud.sh

# Verify VMs created
az vm list -g ymmo-infra --query "[].{Name:name, IP:publicIps}"

# Expected output:
# Name           IP
# ymmo-hq-vm     203.0.113.10
# ymmo-fw-vm     203.0.113.20
```

### Step 1.2: Active Directory Setup (Days 2-3)

```powershell
# RDP into ymmo-hq-vm (10.0.0.1)
mstsc /v:203.0.113.10

# Promote server to Domain Controller
Add-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Install AD Forest
Install-ADDSForest -DomainName ymmo.local `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS"

# Run AD setup script
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
.\scripts\ad\create-groups.ps1 -DomainName "ymmo.local"

# Create file share
New-SMBShare -Name "Partages" `
    -Path "C:\Partages" `
    -FullAccess "ymmo.local\GS_Direction" `
    -ChangeAccess "Everyone"

# Verify AD health
dcdiag
```

### Step 1.3: DNS & DHCP Configuration (Day 3-4)

```powershell
# Add DHCP role
Add-WindowsFeature -Name DHCP -IncludeManagementTools

# Create DHCP scope for Siège (10.0.0.0/24)
Add-DhcpServerv4Scope -Name "Siege-Scope" `
    -StartRange 10.0.0.11 `
    -EndRange 10.0.0.250 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 8:00:00

# Set DHCP options
Set-DhcpServerv4OptionValue -OptionID 3 -Value 10.0.0.254  # Router
Set-DhcpServerv4OptionValue -OptionID 6 -Value 10.0.0.1    # DNS

# Authorize DHCP in AD
Add-DhcpServerInDC -DnsName "ymmo-hq-vm.ymmo.local"

# Verify DHCP
Get-DhcpServerv4Scope
```

### Step 1.4: Firewall Configuration (Day 4-5)

```bash
# RDP into ymmo-fw-vm (10.0.0.254)
mstsc /v:203.0.113.20

# Install UFW and configure
apt-get update
apt-get install -y ufw

# Allow internal traffic
ufw allow from 10.0.0.0/16

# Allow management
ufw allow 22/tcp   # SSH
ufw allow 3389/tcp # RDP
ufw allow 5985/tcp # WinRM
ufw allow 5986/tcp # WinRM SSL

# Allow VPN
ufw allow 500/udp  # IPSec IKE
ufw allow 4500/udp # IPSec NAT-T

# Allow web
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw enable

# Verify
ufw status
```

### Phase 1 Checklist

- [ ] Azure VMs created (ymmo-hq-vm, ymmo-fw-vm)
- [ ] Active Directory Forest online
- [ ] Security Groups created (5 groups)
- [ ] File shares mounted (\Partages\01_Direction, etc.)
- [ ] DHCP scopes configured
- [ ] DNS resolves ymmo.local
- [ ] Firewall rules in place
- [ ] All systems can ping each other (10.0.0.x)

---

## Phase 2: VPN Tunnels & Web Application (Week 2)

**Lead**: Titouan (VPN) + Stan (Web)  
**Duration**: Days 6-10  
**Deliverable**: VPN tunnels up + Django site running

### Step 2.1: IPSec Tunnel Configuration (Days 6-7)

```bash
# On HQ Firewall (ymmo-fw-vm)
chmod +x scripts/vpn/ipsec-config.sh

# Configure HUB mode
./scripts/vpn/ipsec-config.sh --mode hub --subnet 10.0.0.0/16

# Verify tunnel status
ipsec status

# Expected: "no active IPSec tunnels" (normal until branch connects)
```

**For each Branch** (configure post-phase 2):

```bash
# On branch firewall
./scripts/vpn/ipsec-config.sh --mode spoke --branch 1 --hq-ip 203.0.113.20

# Test tunnel
ping 10.0.0.1  # Should work via tunnel
```

### Step 2.2: Web Application Deployment (Days 7-10)

**Titouan**: Prepare the HQ environment

```bash
# On ymmo-hq-vm
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Clone repo
git clone https://github.com/Robinho100/Projet-Ymmo.git
cd Projet-Ymmo

# Configure environment
cp .env.example .env
# Edit .env with real credentials

# Start services
docker-compose up -d

# Verify containers running
docker-compose ps
```

**Stan**: Develop the Django application

```bash
# Create Django project (if not already done)
django-admin startproject config .
django-admin startapp properties

# Create models, views, templates
# See src/web/README.md for detailed instructions

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Run tests
python manage.py test
```

### Step 2.3: Load Balancing Setup (Day 10)

```bash
# On HQ, configure HAProxy (in Docker or native)
apt-get install -y haproxy

# Edit /etc/haproxy/haproxy.cfg
# Configure backend servers for web + failover

# Verify HAProxy
systemctl restart haproxy
systemctl status haproxy

# Test load balancing
curl http://10.0.0.2/health
```

### Phase 2 Checklist

- [ ] IPSec tunnel configured (HUB mode on FW)
- [ ] Strongswan service running
- [ ] Docker/Kubernetes environment ready
- [ ] Django application deployed
- [ ] PostgreSQL database online
- [ ] Static files served correctly
- [ ] Web app accessible via HTTP/HTTPS
- [ ] Admin panel login works
- [ ] HAProxy load balancer configured

---

## Phase 3: Testing & Failover Validation (Week 3)

**Lead**: Titouan + Stan  
**Duration**: Days 11-15  
**Deliverable**: All systems validated, failover tested

### Step 3.1: Connectivity Testing

```bash
# Run comprehensive test suite
chmod +x tests/vpn-connectivity-test.sh
./tests/vpn-connectivity-test.sh

# Expected results
# [PASS] HQ Firewall reachable
# [PASS] VPN Tunnel status
# [PASS] AD/DNS resolution
# [PASS] Branch connectivity
# [PASS] Web server accessibility
```

### Step 3.2: Failover Simulation

```bash
# Test 1: Database failover
# 1. Stop PostgreSQL container
docker-compose stop db

# 2. Measure downtime
# 3. Restart container
docker-compose start db

# 4. Verify data integrity
python manage.py dbshell "SELECT COUNT(*) FROM properties;"

# Test 2: Web server failover
# 1. Stop web container
docker-compose stop web

# 2. Verify HAProxy routes to backup
curl http://10.0.0.2/health

# 3. Restart web container
docker-compose start web

# Test 3: VPN tunnel failover
# 1. Bring down IPSec tunnel
systemctl stop strongswan

# 2. Test rerouting (if configured)
# 3. Restart IPSec
systemctl start strongswan

# 4. Verify tunnel re-establishes
ipsec status
```

### Step 3.3: Load Testing

```bash
# Install Apache Bench
apt-get install -y apache2-utils

# Run load test
ab -n 1000 -c 100 http://10.0.0.2/

# Expected: <500ms response time under 100 concurrent users

# For sustained load:
apt-get install -y iperf3

# Test VPN bandwidth
# On HQ: iperf3 -s -B 10.0.0.254
# On Branch: iperf3 -c 10.0.0.254 -t 60

# Expected: >80 Mbps throughput
```

### Step 3.4: Security Validation

```powershell
# On AD Server, verify GPO applied
gpresult /h c:\gpreport.html

# Check password complexity
secedit /export /cfg c:\security-policy.inf

# Verify NTFS permissions
icacls C:\Partages\01_Direction

# Expected:
# YMMO\GS_Direction:(OI)(CI)(M)
# YMMO\GS_Commercial:(OI)(CI)(RX)
```

### Phase 3 Checklist

- [ ] All connectivity tests pass
- [ ] Database failover working
- [ ] Web server failover working
- [ ] VPN tunnel failover tested
- [ ] Load testing shows acceptable performance
- [ ] Security policies applied correctly
- [ ] Backup routine validated
- [ ] Log aggregation working
- [ ] Monitoring alerts configured

---

## Phase 4: Production Deployment (Week 4)

**Lead**: All  
**Duration**: Days 16-20  
**Deliverable**: Live production environment

### Step 4.1: Pre-Production Sign-Off

```bash
# Final checklist
chmod +x tests/*.sh

# Run all tests
./tests/vpn-connectivity-test.sh
./tests/ad-integration-test.sh
python tests/load-testing.py --duration 300

# Review logs
docker-compose logs --tail 100
```

### Step 4.2: DNS Cutover

```powershell
# Update external DNS to point to HQ public IP
# On your DNS provider:
# ymmo.local -> 203.0.113.10 (A record)
# *.ymmo.local -> 203.0.113.10 (wildcard)

# Verify DNS propagation
nslookup ymmo.local
nslookup www.ymmo.local

# Expected: Both resolve to 203.0.113.10
```

### Step 4.3: Branch Rollout

For each of the 12 branch offices:

```bash
# 1. Ship pre-configured router/firewall to branch
# 2. On-site installation
# 3. Run IPSec spoke configuration

./scripts/vpn/ipsec-config.sh --mode spoke --branch <N> --hq-ip 203.0.113.20

# 4. Test connectivity
ping 10.0.0.1
ping 10.0.0.2
nslookup ymmo.local

# 5. Verify file share access
net use X: \\10.0.0.2\Partages\02_Commercial

# 6. Sign-off
```

### Step 4.4: User Training & Go-Live

```
- Train users on new system (1 day)
- Enable monitoring/alerts
- Activate support desk
- Monitor for 48 hours continuously
- Gradual traffic migration if cutover from old system
```

### Phase 4 Checklist

- [ ] All pre-prod tests passed
- [ ] External DNS configured
- [ ] SSL certificates valid
- [ ] Backups automated and tested
- [ ] Monitoring/alerting live
- [ ] Support team trained
- [ ] Branch VPN tunnels online (all 12)
- [ ] Users can access files + web app
- [ ] Performance SLA met (< 500ms response)
- [ ] No security issues detected

---

## Rollback Plan

If critical issues occur:

```bash
# Immediate rollback
docker-compose down
docker-compose up -d --build

# If database corrupted, restore from backup
pg_restore -d ymmo_db < backup-2026-05-27.sql

# If VPN broken, revert IPSec config
systemctl stop strongswan
# Edit /etc/ipsec.conf to previous version
systemctl start strongswan

# Communication
# 1. Notify stakeholders
# 2. Document issue
# 3. Post-mortem review
# 4. Root cause analysis
```

---

## Monitoring & Maintenance

### Daily Checks

```bash
# Service health
docker-compose ps
ipsec status
systemctl status strongswan postgresql

# Disk usage
df -h /
du -sh /data/*

# Network
netstat -tulpn | grep -E ':80|:443|:5432'
```

### Weekly Tasks

- Review logs for errors
- Run connectivity tests
- Backup verification
- Update packages (apt-get update && apt-get upgrade)

### Monthly Tasks

- Performance report
- Security audit
- Disaster recovery drill
- Certificate expiration check

---

## Support & Troubleshooting

See README.md for common issues and solutions.

**Contact**:
- **Network Issues**: Titouan (titouan@ymmo.local)
- **Web Application**: Stan (stan@ymmo.local)
- **Operations**: Robin (robin@ymmo.local)
