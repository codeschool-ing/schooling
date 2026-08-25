package geo_test

import (
	"bytes"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/geo"
)

// resolver records what it was asked about, which is the only way to check the
// thing that matters: not that a country came out, but that the address that
// went in was the caller's and not somebody else's choice.
func resolver(answer string) (geo.Resolve, *[]netip.Addr) {
	var asked []netip.Addr
	return func(addr netip.Addr) string {
		asked = append(asked, addr)
		return answer
	}, &asked
}

func request(header, remote string) *http.Request {
	r := httptest.NewRequest(http.MethodGet, "/api/v1/anything", nil)
	r.RemoteAddr = remote
	if header != "" {
		r.Header.Set("X-Forwarded-For", header)
	}
	return r
}

// through runs the middleware and answers what reached the handler, along with
// whatever was logged on the way.
func through(t *testing.T, s geo.Settings, r *http.Request) (country string, logged string) {
	t.Helper()

	var buffer bytes.Buffer
	log := slog.New(slog.NewTextHandler(&buffer, &slog.HandlerOptions{Level: slog.LevelDebug}))

	handler := geo.Country(s, log)(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		country = geo.FromContext(r.Context())
	}))
	handler.ServeHTTP(httptest.NewRecorder(), r)

	return country, buffer.String()
}

/* ---------- which entry is the caller ---------- */

// THE ONE THAT MATTERS. A caller who sends their own `X-Forwarded-For` is
// choosing what the leftmost entry says, and a reader that takes the leftmost
// takes it from them — silently, and correctly in every test where nobody
// lies.
func TestAForgedHeaderDoesNotChooseTheCountry(t *testing.T) {
	resolve, asked := resolver("BR")
	s := geo.Settings{Hops: 1, Resolve: resolve}

	country, _ := through(t, s, request("198.51.100.7, 203.0.113.9", "10.0.0.1:1234"))

	if country != "br" {
		t.Errorf("country = %q, want %q", country, "br")
	}
	if len(*asked) != 1 {
		t.Fatalf("the address was read %d times, want once — it is read in one place "+
			"on purpose", len(*asked))
	}
	if got := (*asked)[0].String(); got != "203.0.113.9" {
		t.Errorf("resolved the country of %s, which is an entry the CALLER wrote — "+
			"the caller is the last entry, the one our own infrastructure appended", got)
	}
}

func TestTheCallerIsCountedFromTheEnd(t *testing.T) {
	for _, c := range []struct {
		name   string
		hops   int
		header string
		remote string
		want   string
	}{
		{"one proxy, nothing forged", 1, "203.0.113.9", "10.0.0.1:1234", "203.0.113.9"},
		{"one proxy, two forged in front", 1,
			"10.1.2.3, 198.51.100.7, 203.0.113.9", "10.0.0.1:1234", "203.0.113.9"},
		{"two proxies", 2, "203.0.113.9, 198.51.100.7", "10.0.0.1:1234", "203.0.113.9"},
		{"two proxies, one forged in front", 2,
			"192.0.2.5, 203.0.113.9, 198.51.100.7", "10.0.0.1:1234", "203.0.113.9"},

		// NO PROXY READS NO HEADER. On a laptop nothing in front could have
		// written one, so a header that arrives anyway is the caller's own.
		{"no proxy, header ignored", 0, "10.1.2.3", "203.0.113.9:1234", "203.0.113.9"},

		// Neither of these is wrong of a caller to send, and both make
		// `ParseAddr` refuse a string that is a perfectly good address.
		{"an entry with a port", 1, "203.0.113.9:51234", "10.0.0.1:1234", "203.0.113.9"},
		{"IPv6", 1, "2001:db8::1", "10.0.0.1:1234", "2001:db8::1"},
		{"IPv6 with a zone", 1, "2001:db8::1%eth0", "10.0.0.1:1234", "2001:db8::1"},
		{"IPv6 in brackets with a port", 1, "[2001:db8::1]:443", "10.0.0.1:1234", "2001:db8::1"},

		// Spacing is the header's own convention and two writers disagree
		// about it.
		{"no space after the comma", 1, "198.51.100.7,203.0.113.9", "10.0.0.1:1234", "203.0.113.9"},
	} {
		t.Run(c.name, func(t *testing.T) {
			resolve, asked := resolver("br")
			through(t, geo.Settings{Hops: c.hops, Resolve: resolve},
				request(c.header, c.remote))

			if len(*asked) != 1 {
				t.Fatalf("the resolver was asked %d times, want once", len(*asked))
			}
			if got := (*asked)[0].String(); got != c.want {
				t.Errorf("read %s as the caller, want %s", got, c.want)
			}
		})
	}
}

/* ---------- the alarm ---------- */

// A WRONG `Hops` IS SILENT IN EVERY OTHER WAY. It picks a neighbouring entry
// and produces a country as plausible as the right one, which is the failure
// this repository keeps finding. The one symptom it cannot hide is that the
// address it picked has no business being a caller.
func TestAnAddressThatCannotBeACallerRefusesToBeACountry(t *testing.T) {
	for _, c := range []struct {
		name   string
		hops   int
		header string
		remote string
		reason string
	}{
		{"the trail is shorter than the deployment says", 3, "203.0.113.9", "10.0.0.1:1234",
			"there is no address where one was expected"},
		{"no header at all where there should be one", 1, "", "10.0.0.1:1234",
			"there is no address where one was expected"},
		{"not an address", 1, "somebody's laptop", "10.0.0.1:1234",
			"there is no address where one was expected"},
		{"one hop too few, so a private address is picked", 1, "203.0.113.9, 10.1.2.3",
			"10.0.0.1:1234", "the address is not a public one"},
		{"loopback", 1, "127.0.0.1", "10.0.0.1:1234", "the address is not a public one"},
	} {
		t.Run(c.name, func(t *testing.T) {
			resolve, asked := resolver("br")
			country, logged := through(t, geo.Settings{Hops: c.hops, Resolve: resolve},
				request(c.header, c.remote))

			if country != geo.Unknown {
				t.Errorf("country = %q, want %q — an address that cannot be a caller "+
					"must not produce a country, because a country is what every "+
					"report downstream believes", country, geo.Unknown)
			}
			if len(*asked) != 0 {
				t.Errorf("the resolver was asked about %v, which is not a caller", *asked)
			}
			if !strings.Contains(logged, "cannot be trusted") {
				t.Errorf("nothing was logged about a shape that cannot be right:\n%s", logged)
			}
			if !strings.Contains(logged, c.reason) {
				t.Errorf("the alarm does not say %q, which is what tells somebody "+
					"which half is wrong:\n%s", c.reason, logged)
			}
		})
	}
}

// AND THE ALARM DOES NOT CARRY THE ADDRESS. A log is somewhere a thing is
// kept, and the address is the one thing this system promised not to keep —
// including in the line complaining about it, which is the easiest place in
// the world to leak one.
func TestTheAlarmNeverCarriesTheAddress(t *testing.T) {
	resolve, _ := resolver("br")
	_, logged := through(t, geo.Settings{Hops: 1, Resolve: resolve},
		request("203.0.113.9, 10.11.12.13", "192.168.5.5:1234"))

	for _, secret := range []string{"10.11.12.13", "192.168.5.5", "203.0.113.9"} {
		if strings.Contains(logged, secret) {
			t.Errorf("the log carries %s:\n%s", secret, logged)
		}
	}

	// What it does carry is the two numbers somebody needs to fix the setting.
	for _, wanted := range []string{"hops_configured=1", "entries_seen=2"} {
		if !strings.Contains(logged, wanted) {
			t.Errorf("the log does not say %s, which is what it is for:\n%s", wanted, logged)
		}
	}
}

// AND A LAPTOP DOES NOT SET IT OFF. `127.0.0.1` is where a development run is
// called from, every time, and an alarm on every request of every browser test
// is an alarm nobody reads on the day it means something.
func TestADeploymentWithNoProxyRaisesNoAlarm(t *testing.T) {
	resolve, _ := resolver("br")
	country, logged := through(t, geo.Settings{Hops: 0, Resolve: resolve},
		request("", "127.0.0.1:54321"))

	if country != geo.Unknown {
		t.Errorf("country = %q, want %q", country, geo.Unknown)
	}
	if logged != "" {
		t.Errorf("a laptop was warned about its own address:\n%s", logged)
	}
}

/* ---------- the database that is not here yet ---------- */

// A DEPLOYMENT WITH NO DATABASE ANSWERS `unknown`, AND THAT IS THE POINT. This
// change ships wired to nil, so every country is exactly what the columns
// already hold and not one number moves. The alternative — holding the
// plumbing back until a licence is decided — is how the address ends up read
// in four places on the day it finally is.
func TestNoDatabaseIsNotAWrongCountry(t *testing.T) {
	country, logged := through(t, geo.Settings{Hops: 1},
		request("203.0.113.9", "10.0.0.1:1234"))

	if country != geo.Unknown {
		t.Errorf("country = %q, want %q", country, geo.Unknown)
	}
	// It is not an alarm: the address was fine and nothing is misconfigured.
	if strings.Contains(logged, "cannot be trusted") {
		t.Errorf("a deployment with no database complained about its proxies:\n%s", logged)
	}
}

func TestADatabaseThatDoesNotKnowIsNotAnEmptyString(t *testing.T) {
	// The columns this lands in refuse an empty string, and the INSERT that
	// would fail is three layers from here.
	resolve, _ := resolver("")
	country, _ := through(t, geo.Settings{Hops: 1, Resolve: resolve},
		request("203.0.113.9", "10.0.0.1:1234"))

	if country != geo.Unknown {
		t.Errorf("country = %q, want %q", country, geo.Unknown)
	}
}

func TestTheCountryIsLowercasedAndTrimmed(t *testing.T) {
	// A database answering `BR` and one answering `br` must not become two
	// countries in a GROUP BY.
	resolve, _ := resolver("  BR \n")
	country, _ := through(t, geo.Settings{Hops: 1, Resolve: resolve},
		request("203.0.113.9", "10.0.0.1:1234"))

	if country != "br" {
		t.Errorf("country = %q, want %q", country, "br")
	}
}

/* ---------- the context ---------- */

// A HANDLER REACHED WITHOUT THE MIDDLEWARE GETS AN ANSWER, not an empty
// string. The empty string is refused by a CHECK constraint whose message
// mentions no middleware at all.
func TestWithoutTheMiddlewareTheCountryIsUnknown(t *testing.T) {
	if got := geo.FromContext(t.Context()); got != geo.Unknown {
		t.Errorf("FromContext of a bare context = %q, want %q", got, geo.Unknown)
	}
}
