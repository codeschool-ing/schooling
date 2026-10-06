package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestBooksAnswersWithTheCatalogue(t *testing.T) {
	rec := httptest.NewRecorder()
	routes(memory(builtIn)).ServeHTTP(rec, httptest.NewRequest("GET", "/books", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("status %d, want 200", rec.Code)
	}
	var got []book
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatal(err)
	}
	if len(got) != len(builtIn) {
		t.Fatalf("%d books, want %d", len(got), len(builtIn))
	}
}

func TestHealthIsOK(t *testing.T) {
	rec := httptest.NewRecorder()
	routes(memory(nil)).ServeHTTP(rec, httptest.NewRequest("GET", "/health", nil))
	if rec.Code != http.StatusOK || rec.Body.String() != "ok\n" {
		t.Fatalf("got %d %q", rec.Code, rec.Body.String())
	}
}
