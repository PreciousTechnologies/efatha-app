import requests
import json

# Test login with existing user
url = "http://10.146.127.233:8000/api/auth/login-password/"

test_credentials = {
    'username': 'testuser3@example.com',
    'password': 'TestPassword123!'
}

print("=" * 80)
print("Testing Login with Password")
print("=" * 80)
print(f"\nURL: {url}")
print(f"Credentials: {test_credentials['username']}")

try:
    response = requests.post(url, json=test_credentials, timeout=10)
    
    print(f"\nStatus Code: {response.status_code}")
    
    if response.status_code == 200:
        print("\n✅ LOGIN SUCCESSFUL!")
        data = response.json()
        print(f"\nResponse Data:")
        print(json.dumps(data, indent=2))
        
        # Test accessing user profile with token
        if 'access' in data:
            print(f"\n{'=' * 80}")
            print("Testing Profile Access with Token")
            print(f"{'=' * 80}")
            
            profile_url = "http://10.146.127.233:8000/api/auth/users/me/"
            headers = {
                'Authorization': f'Bearer {data["access"]}',
                'Content-Type': 'application/json'
            }
            
            profile_response = requests.get(profile_url, headers=headers, timeout=10)
            
            print(f"\nStatus Code: {profile_response.status_code}")
            
            if profile_response.status_code == 200:
                print("\n✅ PROFILE ACCESS SUCCESSFUL!")
                profile_data = profile_response.json()
                print(f"\nProfile Data:")
                print(json.dumps(profile_data, indent=2))
            else:
                print(f"\n❌ PROFILE ACCESS FAILED")
                print(profile_response.text)
    else:
        print(f"\n❌ LOGIN FAILED")
        print(response.text)
        
except Exception as e:
    print(f"\n❌ ERROR: {e}")

print(f"\n{'=' * 80}")
