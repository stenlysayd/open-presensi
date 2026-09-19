from app.services.attendance_service import calculate_haversine_distance
from app.services.card_generator_service import generate_printable_card_grid_pdf

def test_haversine_distance_calculation():
    # Distance between two nearby coordinates in Sikumana, Kupang
    lat1, lon1 = -10.180430, 123.605320
    lat2, lon2 = -10.180500, 123.605400

    dist = calculate_haversine_distance(lat1, lon1, lat2, lon2)
    assert 10.0 < dist < 25.0  # Approx 11-15 meters

def test_card_generator_pdf():
    # Verify generation of 4-column printable A4 card grid
    sample_members = [
        {"name": f"Siswa {i}", "registration_number": f"NISN00{i}", "group_name": "Kelas X-1", "qr_token": f"TOKEN-{i}"}
        for i in range(1, 9)
    ]
    pdf_bytes = generate_printable_card_grid_pdf("SMA Nusantara", sample_members)
    assert isinstance(pdf_bytes, bytes)
    assert pdf_bytes.startswith(b"%PDF")  # Valid PDF signature

def test_root_status(client):
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "online"
    assert data["version"] == "0.1.0"

def test_healthcheck(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "healthy"
