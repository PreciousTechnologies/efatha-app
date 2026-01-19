import requests
import json
from datetime import date

# Test registration endpoint with all fields
url = "http://10.146.127.233:8000/api/auth/register/"

# Prepare test data with ALL fields
test_data = {
    'username': 'testuser3@example.com',
    'email': 'testuser3@example.com',
    'password': 'TestPassword123!',
    'password_confirm': 'TestPassword123!',
    
    # Personal Information
    'first_name': 'John',
    'middle_name': 'Michael',
    'last_name': 'Doe',
    'gender': 'Male',
    'date_of_birth': '1990-05-15',
    'marital_status': 'Married',
    
    # Contact Information
    'phone_number': '+233501234567',
    'postal_address': 'P.O. Box 12345, Accra',
    
    # Location Information
    'country': 'Ghana',
    'region': 'Greater Accra',
    'city': 'Accra Metropolitan',
    'residence': 'East Legon',
    'street': 'Oxford Street',
    'house_number': 'H123',
    
    # Church Details
    'church_position': 'Deacon',
    'service_region': 'Central Region',
    'membership_number': 'MEM2024-001',
}

print("=" * 80)
print("Testing Registration with ALL Fields")
print("=" * 80)
print(f"\nSending POST request to: {url}")
print(f"\nTest Data:")
print(json.dumps(test_data, indent=2))

try:
    response = requests.post(url, json=test_data, timeout=10)
    
    print(f"\n{'=' * 80}")
    print(f"Response Status Code: {response.status_code}")
    print(f"{'=' * 80}")
    
    if response.status_code == 201:
        print("\n✅ SUCCESS! User registered successfully!")
        response_data = response.json()
        print(f"\nResponse Data:")
        print(json.dumps(response_data, indent=2))
        
        # Check which fields were saved
        if 'data' in response_data and 'user' in response_data['data']:
            user_data = response_data['data']['user']
            print(f"\n{'=' * 80}")
            print("VERIFICATION: Fields Saved in Database")
            print(f"{'=' * 80}")
            
            fields_to_check = [
                'first_name', 'middle_name', 'last_name',
                'gender', 'date_of_birth', 'marital_status',
                'phone_number', 'postal_address',
                'country', 'region', 'city',
                'residence', 'street', 'house_number',
                'church_position', 'service_region', 'membership_number'
            ]
            
            for field in fields_to_check:
                value = user_data.get(field, 'NOT FOUND')
                status = "✅" if value and value != 'NOT FOUND' else "❌"
                print(f"{status} {field}: {value}")
    else:
        print(f"\n❌ FAILED! Status Code: {response.status_code}")
        print(f"\nError Response:")
        print(json.dumps(response.json(), indent=2))
        
except requests.exceptions.ConnectionError:
    print("\n❌ ERROR: Could not connect to server.")
    print("Make sure Django server is running at http://10.146.127.233:8000")
except Exception as e:
    print(f"\n❌ ERROR: {str(e)}")

print(f"\n{'=' * 80}")
