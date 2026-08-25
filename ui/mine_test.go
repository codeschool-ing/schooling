package ui_test

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/codeschool-ing/schooling/ui"
)

/* The student's own place, as bytes over HTTP.

   WHAT THESE HOLD is the boundary between two trees that both belong to the
   student and must not be served for each other. Everything else about this
   screen — what it draws, and in which language — is `check-interface`'s and
   the browser suite's. */

func askMine(t *testing.T, path string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	ui.Mine("v1.2.3").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	return rec
}

// The shell, at the root and at its own name. `http.FileServer` answers
// `index.html` with a 301 to `./`, which is one wasted round trip before
// anything renders — so the shell is written out rather than served as a file,
// exactly as the study interface's is.
func TestTheStudentsOwnPlaceServesItsShell(t *testing.T) {
	for _, path := range []string{"/", "/index.html"} {
		rec := askMine(t, path)
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
	comment at the top asking whoever edits one to copy it to the others. A fourth
	copy inside one binary would be indefensible — and this is the assertion that
	makes the fallback a rule rather than an arrangement that happens to work
	today. It is the console's test, one address along.
*/
func TestTheSharedStylesheetIsNotACopy(t *testing.T) {
	rec := askMine(t, "/assets/base.css")
	if rec.Code != http.StatusOK {
		t.Fatalf("the shared stylesheet answered %d", rec.Code)
	}

	want, err := ui.Files.ReadFile("assets/base.css")
	if err != nil {
		t.Fatalf("reading the study interface's stylesheet: %v", err)
	}
	if !bytes.Equal(rec.Body.Bytes(), want) {
		t.Error("the stylesheet served at the student's own place is not the study " +
			"interface's bytes — which means there is a second copy of it in this binary")
	}
}

// AND THIS TREE'S OWN ASSETS WIN. `mine.css` and this place's dictionary are
// asked for here first; the fallback is what the study interface has and this
// one does not.
func TestThisPlacesOwnAssetsComeFirst(t *testing.T) {
	for _, path := range []string{"/assets/mine.css", "/assets/i18n-pt.js"} {
		rec := askMine(t, path)
		if rec.Code != http.StatusOK {
			t.Errorf("GET %s answered %d, want 200", path, rec.Code)
		}
	}

	/* `i18n-pt.js` EXISTS IN BOTH TREES AND THE ANSWER MUST BE THIS ONE. The
	   study interface's is five hundred entries for screens this address does
	   not have; served here it would leave every string on this screen falling
	   back to English while looking perfectly translated. */
	rec := askMine(t, "/assets/i18n-pt.js")
	theirs, err := ui.Files.ReadFile("assets/i18n-pt.js")
	if err != nil {
		t.Fatalf("reading the study interface's dictionary: %v", err)
	}
	if bytes.Equal(rec.Body.Bytes(), theirs) {
		t.Error("the dictionary served here is the study interface's — every string on " +
			"this screen would fall back to English and nothing would look wrong")
	}
}

/*
THE STUDY INTERFACE'S SCREENS ARE NOT REACHABLE HERE.

	They are the other half of the reason this tree exists: every one of them
	assumes a school, and there is none at this address. `app/` is served from
	this tree only, so a module that exists over there and not here is a 404
	rather than a screen that boots into nothing.
*/
func TestTheStudyInterfacesScreensAreNotServedHere(t *testing.T) {
	if got := askMine(t, "/app/queue.js").Code; got != http.StatusOK {
		t.Fatalf("this place's own screen answered %d", got)
	}
	for _, path := range []string{"/app/rail.js", "/app/screens/dashboard.js", "/app/source.js"} {
		if got := askMine(t, path).Code; got != http.StatusNotFound {
			t.Errorf("GET %s answered %d at the student's own place, want 404 — that module "+
				"assumes a school", path, got)
		}
	}
}

// NO CATCH-ALL, for the study interface's reason: a shell that rendered itself
// at any address leaves somebody staring at an empty screen wondering what they
// typed.
func TestAnUnknownPathIsNotTheShell(t *testing.T) {
	rec := askMine(t, "/whatever")
	if rec.Code != http.StatusNotFound {
		t.Errorf("an unknown path answered %d, want 404", rec.Code)
	}
}

/*
AN UNSTAMPED BUILD OFFERS NO VALIDATOR AT ALL.

	Every unstamped build calls itself `dev`, so caching against that string means
	a browser holds the first stylesheet it ever saw and revalidates it happily
	against every later one. That is not hypothetical — it is what the study
	interface's handler did on its first run, and the edit that fixed it was
	invisible until the cache was cleared.
*/
func TestAnUnstampedBuildDoesNotCache(t *testing.T) {
	rec := httptest.NewRecorder()
	ui.Mine("").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/assets/mine.css", nil))

	if got := rec.Header().Get("ETag"); got != "" {
		t.Errorf("an unstamped build offered the validator %q", got)
	}
	if got := rec.Header().Get("Cache-Control"); got != "no-store" {
		t.Errorf("an unstamped build answered Cache-Control %q, want no-store", got)
	}

	stamped := askMine(t, "/assets/mine.css")
	if got := stamped.Header().Get("ETag"); got != `"v1.2.3"` {
		t.Errorf("a released build offered the validator %q", got)
	}
}
