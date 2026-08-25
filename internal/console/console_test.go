package console_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/console"
	"github.com/codeschool-ing/schooling/internal/tenant"
	"github.com/codeschool-ing/schooling/ui"
)

// THE ADDRESS IS BUILT FROM THE PLATFORM'S AND NOWHERE ELSE.
//
// A second environment variable for the console's host would be a second thing
// to get wrong on the day somebody moves the platform, and the two would be
// found to disagree by a 404 nobody could explain.
func TestTheConsolesAddressIsThePlatformsWithALabel(t *testing.T) {
	for platform, want := range map[string]string{
		"schooling.lab.aleogr.dev": "console.schooling.lab.aleogr.dev",
		"example.tld":              "console.example.tld",
		"  Example.TLD  ":          "console.example.tld",

		// Nothing to build one from is not "console." — an empty platform
		// domain is a misconfiguration, and a host of `console.` would match a
		// request nobody meant.
		"": "",
	} {
		if got := console.HostOf(platform); got != want {
			t.Errorf("HostOf(%q) = %q, want %q", platform, got, want)
		}
	}
}

// A HOST HEADER IS READ THE SAME WAY FOR THE CONSOLE AS FOR A SCHOOL.
//
// Two rules for reading one header is two chances to disagree about
// `CONSOLE.example.tld:8080`, and a disagreement would be a request that is
// neither a school's nor the console's — the fourth case the design says does
// not exist. So `tenant.Normalise` does both, passed in rather than imported.
func TestTheConsolesHostIsReadLikeASchools(t *testing.T) {
	is := console.Is(console.Settings{Host: console.HostOf("example.tld")}, tenant.Normalise)

	for host, want := range map[string]bool{
		"console.example.tld":       true,
		"CONSOLE.example.tld":       true, // host names are case-insensitive
		"console.example.tld:8099":  true, // the port is not part of the address
		"console.example.tld.":      true, // a fully qualified name is the same name
		"code.example.tld":          false,
		"example.tld":               false,
		"console.example.tld.evil":  false,
		"notconsole.example.tld":    false,
		"console.example.tld.other": false,
		"":                          false,
	} {
		req := httptest.NewRequest(http.MethodGet, "/console/api/v1/me", nil)
		req.Host = host
		if got := is(req); got != want {
			t.Errorf("Is(%q) = %v, want %v", host, got, want)
		}
	}
}

// AND WITH NO PLATFORM DOMAIN, NOTHING IS THE CONSOLE.
//
// The alternative is a host of `console.` matching whatever normalises to it,
// which would be the console appearing at an address nobody configured — the
// exact failure `tenant.Resolve` refuses to make for schools.
func TestWithNoPlatformDomainNothingIsTheConsole(t *testing.T) {
	is := console.Is(console.Settings{Host: console.HostOf("")}, tenant.Normalise)

	for _, host := range []string{"console.", "console", "", "console.example.tld"} {
		req := httptest.NewRequest(http.MethodGet, "/console/api/v1/me", nil)
		req.Host = host
		if is(req) {
			t.Errorf("Is(%q) said yes with no platform domain configured", host)
		}
	}
}

/* ---------- the screen ---------- */

// THE SHELL IS SERVED TO ANYBODY, and that is the fix for a console nobody can
// open without a role: it also cannot tell somebody they need one. What is
// behind the gate is the API; this is a page saying where to sign in.
func TestTheConsolesShellIsServedWithoutASession(t *testing.T) {
	rec := httptest.NewRecorder()
	console.Interface("v1.2.3").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("the shell answered %d, want 200", rec.Code)
	}
	if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "text/html") {
		t.Errorf("Content-Type %q, want html", ct)
	}
	body := rec.Body.String()
	for _, wanted := range []string{
		"/app/main.js",     // the console itself
		"/assets/base.css", // the shared identity
		"/assets/console.css",
		`id="rail"`, `id="stage"`, // the layout the rest of this organisation uses
	} {
		if !strings.Contains(body, wanted) {
			t.Errorf("the shell does not carry %s", wanted)
		}
	}
}

// THE STYLESHEET IS THE STUDY INTERFACE'S, byte for byte, out of its embed.
//
// It already exists three times across this organisation with a comment asking
// whoever edits one to copy it to the others. A fourth copy inside one binary
// would be indefensible, so this proves there is not one.
func TestTheConsoleServesTheSharedStylesheetAndNotACopy(t *testing.T) {
	rec := httptest.NewRecorder()
	console.Interface("v1.2.3").ServeHTTP(rec,
		httptest.NewRequest(http.MethodGet, "/assets/base.css", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("the stylesheet answered %d, want 200", rec.Code)
	}

	want, err := ui.Files.ReadFile("assets/base.css")
	if err != nil {
		t.Fatalf("reading the study interface's stylesheet: %v", err)
	}
	if rec.Body.String() != string(want) {
		t.Error("the console is serving a different stylesheet from the study interface — " +
			"which is the fourth copy this arrangement exists to avoid")
	}
}

// A STUDENT'S SCREENS ARE NOT THE CONSOLE'S TO SERVE. `assets/` is shared;
// `app/` is not, and the console's own `app/` must not become a window into it.
func TestTheConsoleDoesNotServeTheStudyInterfacesModules(t *testing.T) {
	for _, path := range []string{"/app/api.js", "/app/screens/practice.js", "/index.html/../app/api.js"} {
		rec := httptest.NewRecorder()
		console.Interface("").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
		if rec.Code == http.StatusOK {
			t.Errorf("%s answered 200 from the console", path)
		}
	}
}

// NO CATCH-ALL. A shell that rendered itself at any address leaves somebody
// staring at an empty screen wondering what they typed.
func TestTheConsoleHasNoCatchAll(t *testing.T) {
	rec := httptest.NewRecorder()
	console.Interface("").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/whatever", nil))
	if rec.Code != http.StatusNotFound {
		t.Errorf("an unknown path answered %d, want 404", rec.Code)
	}
}

// AN UNSTAMPED BUILD OFFERS NO VALIDATOR, because every unstamped build shares
// the same one — a browser would hold the first file it ever saw and
// revalidate it happily against every later one.
func TestAnUnstampedConsoleOffersNoETag(t *testing.T) {
	rec := httptest.NewRecorder()
	console.Interface("").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	if got := rec.Header().Get("ETag"); got != "" {
		t.Errorf("an unstamped build offered the ETag %q", got)
	}
	if got := rec.Header().Get("Cache-Control"); got != "no-store" {
		t.Errorf("Cache-Control %q, want no-store", got)
	}
}

/*
AND THE ICON IS THE CONSOLE'S OWN, WHICH IS THE OPPOSITE RULE.

	The stylesheet above is shared because two copies of a design token set is
	two chances to disagree. An icon is the other thing entirely: it is what
	somebody picks out of a row of twelve tabs, and a console that wore the
	study interface's mark would be indistinguishable from the school it
	administers — at exactly the moment when knowing which one you are looking
	at matters most.

	The console had NO icon at all until this test existed, which is how it went
	unnoticed: a tab with the browser's blank glyph reads as a tab that has not
	finished loading.
*/
func TestTheConsoleWearsItsOwnMark(t *testing.T) {
	rec := httptest.NewRecorder()
	console.Interface("v1.2.3").ServeHTTP(rec,
		httptest.NewRequest(http.MethodGet, "/assets/favicon.svg", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("the icon answered %d, want 200", rec.Code)
	}

	theirs, err := ui.Files.ReadFile("assets/favicon.svg")
	if err != nil {
		t.Fatalf("reading the study interface's mark: %v", err)
	}
	if rec.Body.String() == string(theirs) {
		t.Error("the console is wearing the study interface's mark, so a console tab and " +
			"a school tab are the same picture")
	}
}

// AND THE SHELL ASKS FOR IT. A file nobody links to is a file nobody sees, and
// the browser's fallback for a missing declaration is `/favicon.ico`, which
// this handler answers with a 404.
func TestTheConsoleShellDeclaresItsIcon(t *testing.T) {
	rec := httptest.NewRecorder()
	console.Interface("v1.2.3").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	if !strings.Contains(rec.Body.String(), `rel="icon"`) {
		t.Error("the console's shell declares no icon, so the tab shows the browser's " +
			"blank glyph — which reads as a page that never finished loading")
	}
}
