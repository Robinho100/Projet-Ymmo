import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient


@pytest.mark.django_db
class TestUser:
    def setup_method(self):
        self.client = APIClient()

    def test_register_user(self):
        data = {
            'username': 'testuser',
            'email': 'test@ymmo.local',
            'password': 'TestPassword123',
        }
        response = self.client.post('/api/users/register/', data)
        assert response.status_code == 201
        assert User.objects.count() == 1
        assert 'token' in response.data

    def test_get_user_profile(self):
        user = User.objects.create_user(username='testuser', password='pass123')
        self.client.force_authenticate(user=user)
        response = self.client.get('/api/users/profile/')
        assert response.status_code == 200
        assert response.data['username'] == 'testuser'
