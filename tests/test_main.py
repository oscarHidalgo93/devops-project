from main import app


def test_home_endpoint_returns_200():
    client = app.test_client()

    response = client.get("/")

    assert response.status_code == 200
    data = response.get_json()
    assert "message" in data
    assert "secret_loaded" in data


def test_counter_endpoint_increments(monkeypatch, tmp_path):
    counter_file = tmp_path / "counter.txt"
    monkeypatch.setenv("COUNTER_FILE", str(counter_file))

    client = app.test_client()

    first_response = client.get("/counter")
    second_response = client.get("/counter")

    assert first_response.status_code == 200
    assert second_response.status_code == 200

    first_data = first_response.get_json()
    second_data = second_response.get_json()

    assert first_data["counter"] == 1
    assert second_data["counter"] == 2
    assert second_data["file"] == str(counter_file)
    assert counter_file.read_text() == "2"