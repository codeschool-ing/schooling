package dbip_test

import (
	"net/netip"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/geo/dbip"
)

func open(t *testing.T) *dbip.Database {
	t.Helper()
	d, err := dbip.Open()
	if err != nil {
		t.Fatalf("opening the embedded database: %v", err)
	}
	t.Cleanup(func() {
		if err := d.Close(); err != nil {
			t.Errorf("closing the database: %v", err)
		}
	})
	return d
}

/*
THE ADDRESSES HERE ARE PICKED FOR NOT MOVING.

	Pinning an address to a country is a test that a database update can break,
	and that is the point rather than the risk: each of these belongs to an
	organisation whose whole identity is the country it is in, and a new
	database that stopped saying so would be a broken update rather than a
	stale test.

	`200.160.0.0/20` is NIC.br's own block, in São Paulo. `8.8.8.8` is Google
	Public DNS, announced from the United States. Neither is going anywhere,
	and if one does, this failing is the correct outcome.
*/
func TestTheDatabaseKnowsWhereTheseAre(t *testing.T) {
	d := open(t)

	for address, want := range map[string]string{
		"200.160.2.3": "br", // NIC.br, São Paulo
		"8.8.8.8":     "us", // Google Public DNS
	} {
		if got := d.Country(netip.MustParseAddr(address)); got != want {
			t.Errorf("Country(%s) = %q, want %q", address, got, want)
		}
	}
}

// AND `unknown` IS A REAL ANSWER, not a failure to be papered over. These are
// addresses no country was ever assigned, and a database that produced two
// letters for one of them would be inventing them.
func TestAnAddressInNoCountryAnswersNothing(t *testing.T) {
	d := open(t)

	for _, address := range []string{
		"203.0.113.9", // TEST-NET-3, reserved for documentation
		"10.1.2.3",    // private
		"127.0.0.1",   // loopback
	} {
		if got := d.Country(netip.MustParseAddr(address)); got != "" {
			t.Errorf("Country(%s) = %q, want nothing at all — that address is in no "+
				"country, and two letters here would be invented", address, got)
		}
	}
}

// IPv6 IS NOT A SEPARATE DATABASE and must not be a separate outcome. A reader
// that quietly answered nothing for every IPv6 address would show as a country
// distribution that is missing a growing slice of the world, with nothing
// anywhere saying so.
func TestIPv6IsAnsweredToo(t *testing.T) {
	d := open(t)

	if got := d.Country(netip.MustParseAddr("2001:4860:4860::8888")); got == "" {
		t.Error("an IPv6 address in an assigned block got no country at all")
	}
}

// A ZERO VALUE IS NOT AN ADDRESS. It reaches here from a parse that failed
// upstream, and looking one up is the kind of thing that works until the day
// the library's behaviour changes underneath it.
func TestAnInvalidAddressIsNotLookedUp(t *testing.T) {
	if got := open(t).Country(netip.Addr{}); got != "" {
		t.Errorf("the zero address answered %q", got)
	}
}

/*
AND THE DATABASE IS NOT ALLOWED TO GET OLD IN SILENCE.

	This is the failure the whole arrangement is exposed to: a country database
	from three years ago answers every query, instantly, confidently and
	sometimes wrongly. Nothing else in this system can tell a stale answer from
	a right one — that is what makes it the same shape as a rollup nobody
	noticed had stopped running, and as a threshold a screen kept its own copy
	of.

	TWELVE MONTHS AND NOT THREE. The cadence is quarterly, so a bound at three
	months would fail every time a quarter ticked over and would be silenced by
	somebody within a week. What this catches is the real failure — that nobody
	has updated it in a YEAR — and it leaves three quarters of slack so that
	the only way to meet it is to have genuinely stopped.

	IT FAILS ON ITS OWN ONE DAY, WITH NO COMMIT TO BLAME, and that is intended:
	the thing that went wrong is the passage of time, and there is nothing else
	that would ever report it.
*/
func TestTheDatabaseIsNotTooOldToBelieve(t *testing.T) {
	const tooOld = 365 * 24 * time.Hour

	built := open(t).Built()
	if built.IsZero() {
		t.Fatal("the database does not say when it was built, so its age cannot be " +
			"checked at all — which is worse than it being old")
	}

	if age := time.Since(built); age > tooOld {
		t.Errorf("the country database was built on %s, which is %d days ago.\n\n"+
			"Replace internal/platform/geo/dbip/dbip-country-lite.mmdb with a current\n"+
			"one from https://db-ip.com/db/download/ip-to-country-lite — it answers\n"+
			"every query either way, which is exactly why nothing else would tell you.",
			built.Format(time.DateOnly), int(age.Hours()/24))
	}

	// A database from the future is a clock problem or a corrupt file, and
	// either way the age above proves nothing.
	if built.After(time.Now().Add(24 * time.Hour)) {
		t.Errorf("the database says it was built on %s, which has not happened yet",
			built.Format(time.DateOnly))
	}
}
