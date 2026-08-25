// Package geo answers which country a request came from, and is the only place
// in this repository that reads the caller's address.
//
// # THE ADDRESS IS READ HERE AND NOWHERE ELSE
//
// That is the whole design, and it is what makes the promise checkable. The
// published privacy policy says, in these words, that we do not store the IP
// address and that the country is derived from the request and the address
// itself is discarded (K-05). A promise like that is not kept by everyone
// remembering it: it is kept by there being one function that touches the
// address, and a test that fails when a second one appears.
//
// So `netip.Addr` never leaves this package. What leaves is a country — two
// letters, or "unknown" — put into the request's context for whoever needs it.
// Nothing here logs an address, and nothing here returns one.
//
// # WHICH ENTRY OF `X-Forwarded-For` IS THE CALLER
//
// Every proxy appends the address it saw, so the header is a trail and the
// right end of it is the one OUR OWN infrastructure wrote. Everything to the
// left of that was written by somebody we do not control — including, on a
// forged request, by the caller.
//
// Reading the leftmost entry is therefore reading a value the caller chose, and
// it is the classic version of this mistake: it works perfectly in every test,
// because in every test nobody is lying.
//
// `Hops` is how many entries our infrastructure appends, and the caller is the
// one that many from the end. It is a number about the deployment and not about
// the request, which is why it is configuration rather than a guess made per
// call.
//
// # AND THE ALARM IS THAT THE ADDRESS IS NOT A PUBLIC ONE
//
// A wrong `Hops` does not fail. It picks a neighbouring entry, resolves a
// country for it, and every report downstream then looks exactly as plausible
// as it would if the number were right — which is the failure this repository
// keeps finding: an answer nobody can tell from the truth.
//
// What a wrong `Hops` does produce is an address that has no business being a
// caller: a private one, a loopback, or something the caller invented. So that
// is what is watched. It cannot fire in normal operation — a request that
// crossed the internet arrives from a public address — and it fires on the
// first request of a deployment whose shape is not what was configured.
//
// It is also the alarm for a change nobody announced. These domains are on
// Cloudflare in DNS-only mode; turning the proxy on puts one more hop in front
// of this process, and every country in the platform would quietly become
// whichever one that proxy answers from.
package geo

import (
	"context"
	"log/slog"
	"net/http"
	"net/netip"
	"strings"
)

// Unknown is a country nobody could work out, and it is a value rather than an
// empty string because the columns it lands in refuse an empty one: a report
// can then tell "we do not know" from "we lost it".
const Unknown = "unknown"

// Resolve turns an address into an ISO 3166-1 alpha-2 country code, lowercased,
// or an empty string when it does not know.
//
// IT IS A FUNCTION TYPE AND NOTHING SATISFIES IT YET. The database that will —
// a few megabytes of it, embedded — is a decision about a licence and a
// repository's size, and it is deliberately not this change. What is this
// change is everywhere the country has to reach, which is the half with all the
// ways to be wrong in it.
//
// Wired with nil, every country is `Unknown`, which is exactly what the columns
// already hold. So this ships without changing a single number, and the day the
// database arrives it changes one line in `cmd/api`.
type Resolve func(netip.Addr) string

// Settings are what this package cannot work out for itself.
type Settings struct {
	// Hops is how many entries our own infrastructure appends to
	// `X-Forwarded-For`. On Cloud Run behind a domain mapping this is 1: the
	// front end appends the address it saw, and anything the caller sent stays
	// to the left of it.
	//
	// ZERO MEANS THERE IS NO PROXY, which is what a laptop is. The header is
	// then not read at all — trusting it on a direct connection is trusting the
	// caller — and the address comes off the connection itself.
	Hops int

	// Resolve is the database. Nil is a deployment that has none.
	Resolve Resolve
}

type ctxKey int

const ctxCountry ctxKey = iota

// FromContext answers the country this request came from.
//
// IT NEVER ANSWERS EMPTY. A handler reached without the middleware in front of
// it gets `Unknown`, which is true — nothing worked it out — rather than an
// empty string that would fail a constraint three layers down, in an INSERT
// whose message says nothing about a middleware.
func FromContext(ctx context.Context) string {
	if country, ok := ctx.Value(ctxCountry).(string); ok && country != "" {
		return country
	}
	return Unknown
}

// Country resolves the caller's country once per request and puts it in the
// context.
//
// ONCE, AND NOT WHERE IT IS USED. Four places want this — the first touch, the
// arrival, a sign-up and every student event — and resolving it in each would
// be four readings of the address instead of one, which is four places for the
// rule to be different. It also makes the promise above a thing a test can
// check by counting.
func Country(s Settings, log *slog.Logger) func(http.Handler) http.Handler {
	if log == nil {
		log = slog.Default()
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			country := s.countryOf(r, log)
			next.ServeHTTP(w, r.WithContext(
				context.WithValue(r.Context(), ctxCountry, country)))
		})
	}
}

func (s Settings) countryOf(r *http.Request, log *slog.Logger) string {
	addr, ok := s.callerOf(r, log)
	if !ok || s.Resolve == nil {
		return Unknown
	}
	if country := strings.ToLower(strings.TrimSpace(s.Resolve(addr))); country != "" {
		return country
	}
	return Unknown
}

// callerOf is the one function in this repository that produces the caller's
// address, and it hands it straight to the resolver.
func (s Settings) callerOf(r *http.Request, log *slog.Logger) (netip.Addr, bool) {
	/* THE SHAPE ALARM. See the package comment: a wrong `Hops` is silent in
	   every other way, and these two are the only symptoms it cannot hide —
	   either there is no entry where one was expected, or the entry there is
	   an address no caller could have crossed the internet from.

	   NOTHING ABOUT THE ADDRESS IS LOGGED. The count, the setting and the
	   reason are the whole line: the address is the thing this system promised
	   not to keep, and a log is somewhere it would be kept. The line
	   complaining about an address is the easiest place in the world to leak
	   one. */
	addr, ok := s.pick(r)
	switch {
	case !ok:
		s.alarm(log, r, "there is no address where one was expected")
		return netip.Addr{}, false
	case !addr.IsValid() || !addr.IsGlobalUnicast() || addr.IsPrivate():
		s.alarm(log, r, "the address is not a public one")
		return netip.Addr{}, false
	}
	return addr, true
}

// alarm says the shape is not what was configured — and says nothing at all on
// a deployment with no proxy in front of it.
//
// A LAPTOP IS CALLED FROM `127.0.0.1` AND THAT IS NORMAL. Warning about it
// would put a line on every request of every development run and every browser
// test, and an alarm that fires constantly in the one place people read logs
// closely is an alarm nobody reads in the place it matters. There is nothing to
// be wrong about when `Hops` is zero: no proxy is claimed, so none can be
// missing.
func (s Settings) alarm(log *slog.Logger, r *http.Request, reason string) {
	if s.Hops <= 0 {
		return
	}
	log.Warn("the country of a request cannot be trusted — the number of proxies in "+
		"front of this process is probably not what is configured",
		"reason", reason,
		"hops_configured", s.Hops,
		"entries_seen", len(forwarded(r)))
}

func (s Settings) pick(r *http.Request) (netip.Addr, bool) {
	/* NO PROXY MEANS THE HEADER IS NOT READ. A laptop serving directly has
	   nothing in front of it that could have written one, so anything arriving
	   under that name is the caller's own — and reading it would make the
	   country a field the caller fills in. */
	if s.Hops <= 0 {
		return parse(hostOf(r.RemoteAddr))
	}

	trail := forwarded(r)
	if len(trail) < s.Hops {
		return netip.Addr{}, false
	}
	return parse(trail[len(trail)-s.Hops])
}

// forwarded is the trail, oldest first, exactly as the header spells it.
func forwarded(r *http.Request) []string {
	header := r.Header.Get("X-Forwarded-For")
	if strings.TrimSpace(header) == "" {
		return nil
	}
	trail := strings.Split(header, ",")
	for i := range trail {
		trail[i] = strings.TrimSpace(trail[i])
	}
	return trail
}

// parse reads one entry of the trail.
//
// IT TAKES THE ZONE OFF AN IPv6 ADDRESS and drops a port if one is there.
// Neither is wrong of a caller to send, and both make `netip.ParseAddr` refuse
// a string that is otherwise a perfectly good address — which would be read as
// a broken deployment by the alarm above.
func parse(entry string) (netip.Addr, bool) {
	entry = strings.TrimSpace(entry)
	if entry == "" {
		return netip.Addr{}, false
	}
	if withPort, err := netip.ParseAddrPort(entry); err == nil {
		return withPort.Addr().Unmap().WithZone(""), true
	}
	addr, err := netip.ParseAddr(entry)
	if err != nil {
		return netip.Addr{}, false
	}
	return addr.Unmap().WithZone(""), true
}

// hostOf takes the address off a `RemoteAddr`, which carries a port.
func hostOf(remote string) string {
	remote = strings.TrimSpace(remote)
	if remote == "" {
		return ""
	}
	if _, err := netip.ParseAddr(remote); err == nil {
		return remote
	}
	if i := strings.LastIndex(remote, ":"); i >= 0 {
		return strings.Trim(remote[:i], "[]")
	}
	return remote
}
