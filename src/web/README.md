# Ymmo Web Application - Django

**Status**: 🟡 WIP (Awaiting Stan's implementation)

This is the Django-based web platform for Ymmo real estate management.

## 📋 Project Structure

```
src/web/
├── manage.py               # Django management script
├── requirements.txt        # Python dependencies
├── config/                 # Django project settings
│   ├── settings.py        # Main settings
│   ├── urls.py            # URL routing
│   └── wsgi.py            # WSGI app
├── properties/            # Main app (to be created)
│   ├── models.py          # Property, Agent, Transaction models
│   ├── views.py           # Views for listing/detail
│   ├── forms.py           # Forms for property input
│   ├── urls.py            # App-level routing
│   └── templates/
│       ├── base.html
│       ├── property_list.html
│       └── property_detail.html
├── users/                 # Authentication app (to be created)
│   ├── models.py
│   ├── views.py
│   └── forms.py
├── analytics/             # Data analysis app (to be created)
│   ├── models.py
│   └── views.py
└── static/                # CSS, JS, images
    └── css/
```

## 🚀 Quick Start

### Prerequisites

- Python 3.9+
- PostgreSQL 13+
- Virtual environment

### Setup

```bash
cd src/web

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Apply migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

Access the app at `http://localhost:8000`

## 🗄️ Database Models

### Property

```python
class Property(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    price = models.DecimalField(max_digits=12, decimal_places=2)
    location = models.CharField(max_length=255)
    bedrooms = models.IntegerField()
    bathrooms = models.IntegerField()
    square_feet = models.IntegerField()
    property_type = models.CharField(
        max_length=20,
        choices=[('house', 'House'), ('apt', 'Apartment'), ('land', 'Land')]
    )
    agent = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_available = models.BooleanField(default=True)
```

### Agent

```python
class Agent(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone = models.CharField(max_length=20)
    agency = models.CharField(max_length=255)
    license_number = models.CharField(max_length=100, unique=True)
    years_experience = models.IntegerField()
    properties = models.ManyToManyField(Property)
```

### Transaction

```python
class Transaction(models.Model):
    property = models.ForeignKey(Property, on_delete=models.PROTECT)
    buyer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    agent = models.ForeignKey(Agent, on_delete=models.SET_NULL, null=True)
    sale_price = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_date = models.DateTimeField()
    status = models.CharField(
        max_length=20,
        choices=[('pending', 'Pending'), ('completed', 'Completed'), ('cancelled', 'Cancelled')]
    )
```

## 🔧 Key Features to Implement

### Phase 1: MVP (Week 2)

- [x] User authentication (login/register)
- [x] Property listing (browse all properties)
- [x] Property detail (view single property with images)
- [x] Search & filter (by location, price, type)
- [x] Contact form (buyer inquiries)

### Phase 2: Enhancement (Week 3)

- [ ] Saved favorites (wishlist)
- [ ] Agent profiles (contact + history)
- [ ] Buyer profiles (purchase history)
- [ ] Image gallery (multiple photos per property)
- [ ] Map integration (property location)

### Phase 3: Analytics (Week 4)

- [ ] Sales dashboard (monthly trends)
- [ ] Agent performance (commissions, deals)
- [ ] Market analysis (price trends by location)
- [ ] Reports (PDF export)

## 🧪 Testing

```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test properties

# With coverage
pip install coverage
coverage run --source='.' manage.py test
coverage report
```

## 📦 Dependencies

See `requirements.txt` for full list. Key packages:

- **Django 4.2**: Web framework
- **djangorestframework**: REST API (if needed)
- **psycopg2**: PostgreSQL adapter
- **Pillow**: Image handling
- **celery**: Async tasks (optional)
- **django-filter**: Advanced filtering
- **django-cors-headers**: CORS support (if frontend separate)

## 🔐 Security Checklist

- [ ] SECRET_KEY randomized per environment
- [ ] ALLOWED_HOSTS configured
- [ ] DEBUG=False in production
- [ ] HTTPS enforced
- [ ] CSRF protection enabled
- [ ] SQL injection protection (use ORM)
- [ ] XSS protection (template auto-escaping)
- [ ] Input validation on all forms
- [ ] Rate limiting on APIs
- [ ] User authentication strong (12+ chars)

## 📄 API Endpoints (Future)

```
GET  /api/properties/                  # List all properties
GET  /api/properties/{id}/             # Get single property
POST /api/properties/                  # Create new (agents only)
PUT  /api/properties/{id}/             # Update (owner only)
DELETE /api/properties/{id}/           # Delete (owner only)

GET  /api/agents/                      # List agents
GET  /api/agents/{id}/                 # Get agent details

POST /api/inquiries/                   # Submit buyer inquiry
GET  /api/inquiries/{id}/              # Get inquiry details
```

## 🚀 Deployment

See `DEPLOYMENT.md` for Docker deployment instructions.

```bash
# Build Docker image
docker build -f docker/Dockerfile.web -t ymmo-web:latest .

# Run with docker-compose
docker-compose up -d web

# View logs
docker-compose logs -f web
```

## 📞 Support

**Issues with Django setup?** Check:

1. `python manage.py check` - validates project structure
2. `python manage.py migrate --plan` - shows pending migrations
3. `python manage.py shell` - interactive Python with Django models

**Database issues?** 

```bash
# Connect to PostgreSQL
psql -U ymmo_user -d ymmo_db -h localhost

# In psql:
\dt          # List tables
\d properties # Describe properties table
SELECT * FROM properties LIMIT 5;
```

## 🎯 Next Steps for Stan

1. Create Django project structure
2. Define models (Property, Agent, Transaction, User)
3. Build views & templates for MVP
4. Configure PostgreSQL connection
5. Implement authentication
6. Create REST API endpoints
7. Write tests
8. Containerize with Docker

**Timeline**: Complete by end of Week 2 for Phase 2 integration.

---

**Last Updated**: 2026-05-27  
**Lead Developer**: Stan (stan@ymmo.local)
