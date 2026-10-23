import pytest

from app import app
from settings import ADMIN_TOKEN


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setattr("app.DATABASE", str(tmp_path / "test.db"))
    return app.test_client()


def test_create_needs_the_token(client):
    assert client.post("/links", data={"url": "https://example.org"}).status_code == 401


def test_a_link_redirects(client):
    made = client.post("/links", data={"url": "https://example.org/a"},
                       headers={"X-Token": ADMIN_TOKEN})
    assert made.status_code == 201
    code = made.get_json()["code"]
    followed = client.get(f"/{code}")
    assert followed.status_code == 302
    assert followed.headers["Location"] == "https://example.org/a"


def test_search_finds_a_link(client):
    client.post("/links", data={"url": "https://example.org/docs"},
                headers={"X-Token": ADMIN_TOKEN})
    page = client.get("/search?q=docs")
    assert page.status_code == 200
    assert b"https://example.org/docs" in page.data


def test_search_survives_a_quote(client):
    client.post("/links", data={"url": "https://example.org/it's-here"},
                headers={"X-Token": ADMIN_TOKEN})
    page = client.get("/search?q=it's")
    assert page.status_code == 200
    assert b"it&#39;s-here" in page.data
