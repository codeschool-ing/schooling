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

	for _, path := range []string{"/", "/assets/base.css", "/app/main.js"} {
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

	/* THE LIST IS READ OUT OF THE DOCUMENT, and it used to be typed here.

	   The comment above this test always said it asked for what the shell names
	   "rather than for a list somebody has to keep up to date" — and underneath
	   it was exactly such a list. It went stale the day the interface was
	   replaced, and what it then reported was five files that no longer exist
	   rather than anything wrong with the ones that do.

	   Reading the document means the test cannot be out of date: a script added
	   to the shell is checked from the moment it is added, and one removed stops
	   being checked without anybody editing this file. */
	wanted := localAssets(shell)
	if len(wanted) < 5 {
		t.Fatalf("the shell names %d local files, which cannot be right — it is a whole "+
			"interface: %v", len(wanted), wanted)
	}

	for _, asset := range wanted {
		got := httptest.NewRecorder()
		handler.ServeHTTP(got, httptest.NewRequest(http.MethodGet, asset, nil))
		if got.Code != http.StatusOK {
			t.Errorf("%s answered %d — it is embedded by a pattern, and a pattern that stops "+
				"matching says nothing at all", asset, got.Code)
		}
	}
}

// Every same-origin file the document loads: `src` and `href`, absolute paths
// only. An address with a scheme belongs to somebody else and is the subject of
// the test below rather than this one.
func localAssets(shell string) []string {
	var out []string
	seen := map[string]bool{}

	for _, attr := range []string{`src="`, `href="`} {
		rest := shell
		for {
			i := strings.Index(rest, attr)
			if i < 0 {
				break
			}
			rest = rest[i+len(attr):]
			end := strings.Index(rest, `"`)
			if end < 0 {
				break
			}
			path := rest[:end]
			rest = rest[end:]

			// A fragment route, a scheme, or the favicon's data — none of them
			// is a file this server has to answer for.
			if !strings.HasPrefix(path, "/") || strings.HasPrefix(path, "//") {
				continue
			}
			if seen[path] {
				continue
			}
			seen[path] = true
			out = append(out, path)
		}
	}
	return out
}

// THE SHELL ASKS NOBODY ELSE FOR ANYTHING.
//
// It used to ask fonts.googleapis.com for three families, which told a third
// party which school a student was reading before the page had rendered, left
// the offline bundle with no way to look like the site, and made two machines
// measure different cards — the graph test failed on the build machine at two
// window sizes and on none in the sandbox, because one of them could reach the
// CDN and the other could not.
//
// The faces are served from this origin now. This is the check that keeps them
// there, because the way that decision gets undone is one convenient `<link>`
// in a hurry, and nothing else in the repository would notice.
func TestTheShellAsksNobodyElseForAnything(t *testing.T) {
	recorder := httptest.NewRecorder()
	ui.Handler("v1.2.3").ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/", nil))

	// Every scheme-relative or absolute address in an attribute. Deliberately
	// blunt: it reads the whole document rather than the attributes it expects
	// to find, so a `<script src>` somebody adds next year is caught by the
	// same line as today's `<link href>`.
	for _, prefix := range []string{`="http://`, `="https://`, `="//`} {
		if at := strings.Index(recorder.Body.String(), prefix); at >= 0 {
			t.Errorf("the shell loads something from another origin: %q\n"+
				"Serve it from here instead — see tools/fonts for how the type got here.",
				excerpt(recorder.Body.String(), at))
		}
	}
}

// THE TYPE IS ACTUALLY THERE. `fonts.css` is generated, so the list of files it
// names is not one anybody maintains — which is exactly why nobody would notice
// it going stale. This asks the handler for each face the stylesheet asks a
// browser for.
func TestEveryFaceTheStylesheetNamesIsServed(t *testing.T) {
	handler := ui.Handler("v1.2.3")

	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/assets/fonts/fonts.css", nil))
	if recorder.Code != http.StatusOK {
		t.Fatalf("the font stylesheet answered %d — run `go run ./tools/fonts`", recorder.Code)
	}

	faces := 0
	for _, line := range strings.Split(recorder.Body.String(), "\n") {
		_, after, found := strings.Cut(line, "src: url('")
		if !found {
			continue
		}
		name, _, _ := strings.Cut(after, "'")
		faces++

		got := httptest.NewRecorder()
		handler.ServeHTTP(got, httptest.NewRequest(http.MethodGet, "/assets/fonts/"+name, nil))
		if got.Code != http.StatusOK {
			t.Errorf("%s answered %d — the stylesheet names a file that is not here", name, got.Code)
			continue
		}
		// woff2 begins "wOF2". A truncated or html-error-page download would
		// otherwise pass as a two hundred with a body.
		if !strings.HasPrefix(got.Body.String(), "wOF2") {
			t.Errorf("%s is served but is not a woff2", name)
		}
	}

	if faces == 0 {
		t.Error("the font stylesheet names no face at all")
	}
}

func excerpt(document string, at int) string {
	start := max(at-60, 0)
	end := min(at+60, len(document))
	return document[start:end]
}
