def test_register_and_login(client):
    # 1. Register User
    reg_payload = {
        "name": "Testing Guru",
        "identifier": "TEST12345",
        "email": "guru.test@komunitas.id",
        "password": "mypassword123",
        "role": "staff"
    }
    reg_resp = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_resp.status_code == 200, reg_resp.text
    user_data = reg_resp.json()
    assert user_data["identifier"] == "TEST12345"

    # 2. Login with device_id (Device Binding test)
    login_payload = {
        "identifier": "TEST12345",
        "password": "mypassword123",
        "device_id": "DEVICE_PHONE_UUID_001"
    }
    login_resp = client.post("/api/v1/auth/login", json=login_payload)
    assert login_resp.status_code == 200, login_resp.text
    token_data = login_resp.json()
    assert "access_token" in token_data

    # 3. Test Unauthorized device login
    bad_device_payload = {
        "identifier": "TEST12345",
        "password": "mypassword123",
        "device_id": "DIFFERENT_PHONE_XYZ"
    }
    bad_login_resp = client.post("/api/v1/auth/login", json=bad_device_payload)
    assert bad_login_resp.status_code == 403
