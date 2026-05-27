# Ymmo Project - Quick Start Guide

**Status**: Ready for Phase 1 (Sem 5)  
**Created**: 2026-05-27 23:30 UTC  
**For**: Robin, Titouan, Stan

---

## 🚀 5-Minute Setup (Local Development)

### Prerequisites
- Docker & Docker Compose installed
- Bash/PowerShell
- Git

### Step 1: Clone & Configure
```bash
cd Projet-Ymmo
cp .env.example .env
# .env is already prepared in .env.local for quick testing
```

### Step 2: Start Services
```bash
docker-compose up -d
```

**Expected output:**
```
✓ Creating db container
✓ Creating redis container
✓ Creating web container
✓ Creating nginx container
✓ Creating pgadmin container
```

### Step 3: Verify Everything Works
```bash
# Check containers running
docker-compose ps

# Access web app
curl http://localhost:8000/health
# Expected: "healthy"

# Access admin panel
# http://localhost:8000/admin (user: admin, pass: admin123)

# Access PgAdmin
# http://localhost:5050 (user: admin@ymmo.local, pass: pgadmin-dev-password)
```

**All up?** ✅ You're ready for Phase 1!

---

## 📋 Phase 1 Checklist (Sem 5 - Titouan)

### Monday (May 27)
- [ ] Read `DEPLOYMENT.md#Phase-1`
- [ ] Verify Docker setup works locally
- [ ] Prepare Azure credentials

### Tuesday-Wednesday (May 28-29)
- [ ] Run `scripts/cloud/init_cloud.sh` (creates Azure VMs)
- [ ] Verify VMs appear in Azure portal
- [ ] RDP into `ymmo-hq-vm` (10.0.0.1)

### Thursday-Friday (May 30-31)
- [ ] On `ymmo-hq-vm`, run `scripts/ad/create-groups.ps1`
- [ ] Verify Active Directory is online
- [ ] Commit progress to branch (push when Robin adds you)

---

## 📋 Phase 2 Prep Checklist (Sem 6 - Stan)

### Monday (June 3)
- [ ] Read `src/web/README.md`
- [ ] Verify `requirements.txt` installs locally
- [ ] Create Django project structure

### Tuesday-Wednesday (June 4-5)
- [ ] Define models (Property, Agent, Transaction)
- [ ] Create initial views + templates
- [ ] Run migrations on local PostgreSQL
- [ ] Test admin panel

### Thursday-Friday (June 6-7)
- [ ] Implement property search/filter
- [ ] Add basic API endpoints
- [ ] Write unit tests
- [ ] Deploy to Docker + test

---

## 🔧 Common Commands

### Django
```bash
# Create admin user
docker-compose exec web python manage.py createsuperuser

# Run migrations
docker-compose exec web python manage.py migrate

# Create test data
docker-compose exec web python manage.py shell
# >>> from django.contrib.auth.models import User
# >>> User.objects.create_superuser('admin', 'admin@ymmo.local', 'admin123')

# Run tests
docker-compose exec web python manage.py test
```

### PostgreSQL
```bash
# Connect to database
docker-compose exec db psql -U ymmo_user -d ymmo_db

# List tables
\dt

# Query properties
SELECT * FROM properties LIMIT 5;
```

### Docker
```bash
# View logs
docker-compose logs -f web

# Rebuild image
docker-compose build web

# Stop all services
docker-compose down

# Clean everything (careful!)
docker-compose down -v
```

### Scripts
```bash
# Make scripts executable
chmod +x scripts/cloud/init_cloud.sh
chmod +x scripts/vpn/ipsec-config.sh
chmod +x tests/vpn-connectivity-test.sh

# Run tests
./tests/vpn-connectivity-test.sh
```

---

## 📞 Quick Links

| Document | Purpose |
|----------|---------|
| `README.md` | Main project overview |
| `DEPLOYMENT.md` | Detailed 4-phase plan |
| `src/web/README.md` | Django app specification |
| `QUICK_START.md` | This file |

---

## 🆘 Troubleshooting

### "docker: command not found"
→ Install Docker Desktop from https://www.docker.com/products/docker-desktop

### "PostgreSQL container fails to start"
```bash
# Check logs
docker-compose logs db

# Reset database
docker-compose down -v
docker-compose up -d
```

### "Web server won't connect to database"
```bash
# Check connection
docker-compose exec web python manage.py dbshell

# If failed, rebuild
docker-compose down
docker-compose up --build
```

### "Azure CLI not found"
```bash
# Install Azure CLI
# https://docs.microsoft.com/cli/azure/install-azure-cli

# Then login
az login
```

### "Permission denied on scripts"
```bash
# Fix on Linux/Mac
chmod +x scripts/**/*.sh

# On Windows, use PowerShell (scripts are .ps1)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
```

---

## 📌 Important Notes

1. **Never commit `.env`** - It contains secrets. Use `.env.example` as template.

2. **Database persistence**: PostgreSQL data is stored in Docker volume `db_data`. Use `docker-compose down -v` to reset.

3. **Timeouts**: Initial docker-compose up might take 2-3 minutes. Be patient.

4. **Port conflicts**: If ports 80, 443, 5432, 8000 are in use, edit `docker-compose.yml` to use different ports.

5. **Windows line endings**: If shell scripts fail, convert LF:
   ```bash
   dos2unix scripts/**/*.sh
   # Or in Git:
   git config core.autocrlf true
   ```

---

## 🎯 Next Steps After Local Setup

1. **Titouan**: Start Phase 1 Azure setup (see `DEPLOYMENT.md#Phase-1`)
2. **Stan**: Begin Django project setup (see `src/web/README.md`)
3. **Robin**: Review progress, add team to GitHub repo permissions

**Target**: Both have code commits by end of week → Ready for Phase 2 integration in Sem 6.

---

**Last Updated**: 2026-05-27 23:30 UTC  
**Created by**: Claude Code  
**For questions**: Post in #infra Slack channel
