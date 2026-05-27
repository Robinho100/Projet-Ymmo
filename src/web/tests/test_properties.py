import pytest
from django.contrib.auth.models import User
from properties.models import Property, Favorite
from rest_framework.test import APIClient


@pytest.mark.django_db
class TestProperty:
    def setup_method(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='agent1', password='pass123')
        self.client.force_authenticate(user=self.user)

    def test_create_property(self):
        data = {
            'title': 'Maison Test',
            'description': 'Belle maison',
            'price': 250000,
            'address': '123 Rue Test',
            'city': 'Aix-en-Provence',
            'property_type': 'house',
            'bedrooms': 3,
        }
        response = self.client.post('/api/properties/', data)
        assert response.status_code == 201
        assert Property.objects.count() == 1

    def test_list_properties(self):
        Property.objects.create(
            title='Maison 1',
            price=200000,
            address='Test',
            city='Aix',
            property_type='house',
            agent=self.user
        )
        response = self.client.get('/api/properties/')
        assert response.status_code == 200
        assert len(response.data['results']) == 1

    def test_favorite_property(self):
        prop = Property.objects.create(
            title='Maison Test',
            price=200000,
            address='Test',
            city='Aix',
            property_type='house',
            agent=self.user
        )
        response = self.client.post(f'/api/properties/{prop.id}/favorite/')
        assert response.status_code == 201
        assert Favorite.objects.filter(user=self.user, property=prop).exists()
