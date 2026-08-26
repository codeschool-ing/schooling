package ui_test

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/codeschool-ing/schooling/ui"
)

/* The platform's front door, as bytes over HTTP.

   WHAT THESE HOLD is the boundary between three trees that are served by one
   binary and must not be served for each other. What the page draws, and in
   which language, is `check-interface`'s and the browser suite's. */

func askFront(t *testing.T, path string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	ui.Front("v1.2.3").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	return rec
}

// The shell, at the root and at its own name. `http.FileServer` answers
// `index.html` with a 301 to `./`, which is one wasted round trip before
// anything renders — so the shell is written out rather than served as a file,
// exactly as the other two trees do it.
func TestTheFrontDoorServesItsShell(t *testing.T) {
	for _, path := range []string{"/", "/index.html"} {
		rec := askFront(t, path)
		if rec.Code != http.StatusOK {
			t.Fatalf("GET %s answered %d, want 200", path, rec.Code)
		}
		if got := rec.Header().Get("Content-Type"); got != "text/html; charset=utf-8" {
			t.Errorf("GET %s came back as %q", path, got)
		}
		if !bytes.Contains(rec.Body.Bytes(), []byte("/app/main.js")) {
			t.Errorf("GET %s did not carry the boot script", path)
		}
	}
}

/*
THE STYLESHEET IS THE STUDY INTERFACE'S, THE SAME BYTES.

	`assets/base.css` exists three times across this organisation already, with a
	comment at the top asking whoever edits one to copy it to the others. A
	fourth copy inside one binary would be indefensible, and a fifth more so.
*/
func TestTheFrontDoorFallsBackToTheSharedAssets(t *testing.T) {
	for _, path := range []string{"/assets/base.css", "/assets/i18n.js", "/assets/i18n-runtime.js"} {
		if got := askFront(t, path).Code; got != http.StatusOK {
			t.Errorf("GET %s answered %d, want 200 — the shared assets are not reachable "+
				"from the front door", path, got)
		}
	}
}

// AND ITS OWN COME FIRST. `front.css` and this address's Portuguese live in
// this tree; asking here before falling back is what lets neither side know
// which files the other has.
func TestTheFrontDoorPrefersItsOwnAssets(t *testing.T) {
	for _, path := range []string{"/assets/front.css", "/assets/i18n-pt.js"} {
		if got := askFront(t, path).Code; got != http.StatusOK {
			t.Errorf("GET %s answered %d, want 200", path, got)
		}
	}

	/* The dictionary is the one that matters: the study interface has a file at
	   exactly this path saying hundreds of other things, and serving THAT one
	   here would leave every string on this screen falling back to English with
	   nothing looking wrong. `my.` carries the same assertion for the same
	   reason. */
	mine := askFront(t, "/assets/i18n-pt.js").Body.Bytes()
	theirs, err := ui.Files.ReadFile("assets/i18n-pt.js")
	if err != nil {
		t.Fatalf("reading the study interface's dictionary: %v", err)
	}
	if bytes.Equal(mine, theirs) {
		t.Error("the dictionary served at the front door is the study interface's — " +
			"every string on this screen would fall back to English and nothing " +
			"would look wrong")
	}
}

/*
THE OTHER TWO TREES' SCREENS ARE NOT REACHABLE HERE.

	`app/` is served from this tree only. The study interface's screens assume a
	school and there is none at this address; the student's own place assumes a
	session and this address is the one place that asks for nothing. A module
	that exists over there and not here is a 404 rather than a screen that boots
	into nothing.
*/
func TestTheOtherScreensAreNotServedAtTheFrontDoor(t *testing.T) {
	if got := askFront(t, "/app/main.js").Code; got != http.StatusOK {
		t.Fatalf("this place's own boot answered %d", got)
	}
	for _, path := range []string{"/app/rail.js", "/app/screens/dashboard.js",
		"/app/source.js", "/app/queue.js"} {
		if got := askFront(t, path).Code; got != http.StatusNotFound {
			t.Errorf("GET %s answered %d at the front door, want 404 — that module "+
				"belongs to another address", path, got)
		}
	}
}

// NO CATCH-ALL, for the study interface's reason: a shell that rendered itself
// at any address leaves somebody staring at an empty screen wondering what they
// typed.
func TestAnUnknownPathAtTheFrontDoorIsNotTheShell(t *testing.T) {
	rec := askFront(t, "/whatever")
	if rec.Code != http.StatusNotFound {
		t.Errorf("an unknown path answered %d, want 404", rec.Code)
	}
	if bytes.Contains(rec.Body.Bytes(), []byte("/app/main.js")) {
		t.Error("an unknown path was answered with the shell")
	}
}

// THE ONE ADDRESS THAT ASKS TO BE FOUND. Every other interface here is either
// one person's, or staff software, or one school — and the door being indexable
// is the difference between a door and a wall. It is an easy line to lose in a
// copy-paste from `my.`, whose shell says the exact opposite.
func TestTheFrontDoorAsksToBeIndexed(t *testing.T) {
	shell := askFront(t, "/").Body.Bytes()

	if bytes.Contains(shell, []byte("noindex")) {
		t.Error("the front door tells crawlers to stay away, which is `my.`'s rule " +
			"and the opposite of this address's")
	}
	if !bytes.Contains(shell, []byte(`name="robots"`)) {
		t.Error("the front door says nothing to crawlers at all — the tag is written " +
			"out rather than left absent, so that reading it is not guesswork")
	}
}
