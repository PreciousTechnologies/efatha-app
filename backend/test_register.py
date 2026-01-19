import requests
import json

url = 'http://10.146.127.233:8000/api/auth/register/'

data = {
    'username': 'testuser@test.com',
    'email': 'testuser@test.com',
    'password': 'testpass123',
    'password_confirm': 'testpass123',
    'first_name': 'Test',
    'last_name': 'User',
    'phone_number': '+255123456789',
    'church_position': 'Muumini',
    'registration_number': 'REG001',
    'country': 'Tanzania',
    'region': 'Dar es Salaam',
    'service_region': 'Kinondoni',
    'city': 'Kinondoni'
}

headers = {
    'Content-Type': 'application/json'
}

print("Testing registration endpoint...")
print(f"URL: {url}")
print(f"Data: {json.dumps(data, indent=2)}")

try:
    response = requests.post(url, json=data, headers=headers)
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"\nError: {e}")
    if hasattr(response, 'text'):
        print(f"Response Text: {response.text}")
