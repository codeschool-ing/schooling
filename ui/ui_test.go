package ui_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/ui"
)

// THE ONE THAT MATTERS.
//
// The interface is mounted at the root and the API above it, which means the
// two are one registration order apart from swapping. If the shell ever answers
// a path under `/api/v1/`, a client asking for a route that does not exist gets
// a page — two hundred, with HTML in it — and every fetch in the browser fails
// while parsing JSON rather than saying what went wrong. That is a whole
// afternoon of debugging the wrong thing.
//
// It is asserted here, over this handler alone, because that is what makes it a
// property of the handler rather than of one arrangement in cmd/api.
func TestTheShellNeverAnswersForTheAPI(t *testing.T) {
	handler := ui.Handler("v1.2.3")

	for _, path := range []string{
		"/api/v1/courses", "/api/v1/", "/api/v1/nothing/here", "/readyz", "/version",
	} {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))

		if recorder.Code != http.StatusNotFound {
			t.Errorf("%s answered %d — the shell is claiming a path that belongs to something "+
				"else, and a client asking for JSON is getting a page", path, recorder.Code)
		}
	}
}

// An address nobody wrote is a 404, not the shell. There is no catch-all here
// on purpose: the routes are fragments, so a path that is not one of the two
// this package serves is a typo, and rendering the interface at it leaves
// somebody looking at an empty screen wondering what they got wrong.
func TestAnUnknownPathIsNotFound(t *testing.T) {
	handler := ui.Handler("v1.2.3")

	for _, path := range []string{"/course/web-fundamentals", "/dashboard", "/nowhere"} {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))

		if recorder.Code != http.StatusNotFound {
			t.Errorf("%s answered %d, want 404", path, recorder.Code)
		}
	}
}

// The address printed on a certificate. It is a real path rather than a
// fragment because it is read off paper and typed, and it is the shell that
// answers because the code after it is for the interface to read.
func TestTheVerificationAddressIsServedTheShell(t *testing.T) {
	handler := ui.Handler("v1.2.3")

	for _, path := range []string{"/", "/index.html", "/verify/G0950CQY8PEN3CGK", "/verify/anything"} {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))

		if recorder.Code != http.StatusOK {
			t.Fatalf("%s answered %d, want the shell", path, recorder.Code)
		}
		if !strings.Contains(recorder.Body.String(), "<title>") {
			t.Errorf("%s did not answer with the document", path)
		}
		if got := recorder.Header().Get("Content-Type"); !strings.HasPrefix(got, "text/html") {
			t.Errorf("%s answered with %q", path, got)
		}
	}
}

// A released build offers its version as the validator for every file, so one
// deploy invalidates all of them together and no cache can hold a stylesheet
// from before it beside a script from after.
func TestAReleasedBuildRevalidatesEverythingAgainstItself(t *testing.T) {
	handler := ui.Handler("v1.2.3")

	for _, path := range []string{"/", "/assets/app.css", "/assets/app.js"} {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))

		if got := recorder.Header().Get("ETag"); got != `"v1.2.3"` {
			t.Errorf("%s carries ETag %q, want the build", path, got)
		}
		if got := recorder.Header().Get("Cache-Control"); got != "no-cache" {
			t.Errorf("%s carries Cache-Control %q, want no-cache — which means revalidate, "+
				"not do not store", path, got)
		}

		// And the second request, the way a browser makes it.
		again := httptest.NewRecorder()
		request := httptest.NewRequest(http.MethodGet, path, nil)
		request.Header.Set("If-None-Match", `"v1.2.3"`)
		handler.ServeHTTP(again, request)

		if again.Code != http.StatusNotModified {
			t.Errorf("%s answered %d to a revalidation, want 304", path, again.Code)
		}
	}
}

// AND THE ONE THAT WAS A REAL DEFECT.
//
// Every unstamped build calls itself the same thing, so caching against that
// string means a browser keeps the first stylesheet it ever saw and revalidates
// it happily against every later build. It is not a development annoyance: it
// is a validator that claims two different files are the same file.
//
// A build that cannot say which build it is has nothing honest to offer, so it
// offers nothing. This test is the version of that sentence that cannot rot.
func TestAnUnstampedBuildPromisesNothing(t *testing.T) {
	handler := ui.Handler("")

	for _, path := range []string{"/", "/assets/app.css"} {
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))

		if got := recorder.Header().Get("ETag"); got != "" {
			t.Errorf("%s offers the validator %q from a build that cannot name itself", path, got)
		}
		if got := recorder.Header().Get("Cache-Control"); got != "no-store" {
			t.Errorf("%s carries Cache-Control %q, want no-store", path, got)
		}

		// A browser holding an old validator must not be told it is still good.
		again := httptest.NewRecorder()
		request := httptest.NewRequest(http.MethodGet, path, nil)
		request.Header.Set("If-None-Match", `"dev"`)
		handler.ServeHTTP(again, request)

		if again.Code == http.StatusNotModified {
			t.Errorf("%s answered 304 to a stale validator, which is how an edit becomes "+
				"invisible until somebody clears their cache", path)
		}
	}
}

// The interface is served, whole. A missing asset is a 404 in a browser and a
// blank screen for a student, and it is the failure a `//go:embed` pattern that
// stopped matching produces — silently, at build time.
func TestEveryAssetTheShellAsksForIsThere(t *testing.T) {
	handler := ui.Handler("v1.2.3")

	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/", nil))
	shell := recorder.Body.String()

	// The shell names them; this asks for each one rather than for a list
	// somebody has to keep up to date.
	for _, asset := range []string{
		"/assets/app.css", "/assets/app.js", "/assets/api.js",
		"/assets/i18n.js", "/assets/i18n-pt.js", "/assets/markdown.js",
		"/assets/favicon.svg",
	} {
		got := httptest.NewRecorder()
		handler.ServeHTTP(got, httptest.NewRequest(http.MethodGet, asset, nil))
		if got.Code != http.StatusOK {
			t.Errorf("%s answered %d — it is embedded by a pattern, and a pattern that stops "+
				"matching says nothing at all", asset, got.Code)
		}
	}

	// The two the document itself loads directly, so that a rename in the HTML
	// with no matching file fails here rather than in a browser.
	for _, named := range []string{"/assets/i18n-pt.js", "/assets/app.js", "/assets/app.css"} {
		if !strings.Contains(shell, named) {
			t.Errorf("the document no longer loads %s — either it moved, or this list is stale", named)
		}
	}
}
