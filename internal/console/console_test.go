package console_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/codeschool-ing/schooling/internal/console"
	"github.com/codeschool-ing/schooling/internal/tenant"
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
