package visitor

import (
	"context"
	"encoding/base64"
	"errors"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/geo"
)

// CookieName is the identity itself. One name, on the parent domain, so a
// person who reads about the platform and then opens a school is one visitor
// rather than two.
const CookieName = "schooling_visitor"

// How long the identity lasts. Two years, because the question it answers is
// "how many of the people who arrived became students" and people take months
// to decide. A session cookie would reset the funnel every time a browser
// closed, which is to say most of the time.
const cookieLifetime = 2 * 365 * 24 * time.Hour

// SchoolOf answers which school a request is for, if any.
//
// IT IS A FUNCTION AND NOT AN IMPORT. This package must not reach into the one
// that resolves schools — modules talk through what the consumer defines, wired
// together in cmd/, and a test enforces it. The shape is small enough to say
// out loud, so it is said here rather than imported.
type SchoolOf func(ctx context.Context) (id uuid.UUID, slug string, ok bool)

// Settings are what the middleware cannot work out for itself.
type Settings struct {
	// The parent domain the cookie is scoped to — the platform's, not a
	// school's. Empty means host-only, which is what local development wants.
	Domain string

	// Off in development, because a Secure cookie is not stored over plain
	// http and the identity would be reissued on every request without one
	// word of explanation.
	Secure bool
}

type ctxKey int

const ctxVisitor ctxKey = iota

// FromContext answers the visitor this request belongs to.
func FromContext(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(ctxVisitor).(uuid.UUID)
	return id, ok
}

// Arrived is emitted the first time a browser is seen, and is the first step of
// the funnel.
//
// IT IS A CALLBACK BECAUSE THIS MODULE MAY NOT IMPORT THE ONE THAT COUNTS, and
// it takes the visitor explicitly because at this moment there is not yet one on
// the request — this middleware is what puts it there.
type Arrived func(ctx context.Context, visitorID uuid.UUID)

// Identify puts a visitor on every request that has proved it keeps cookies.
//
// IT NEVER FAILS A REQUEST. A database that cannot issue an identity is a
// reason to serve the page anyway and count nothing — refusing to show a
// prospective student the catalogue because analytics is down would be the
// funnel destroying the thing it exists to measure.
//
// # A ROW IS FOR SOMEBODY WHO CAME BACK
//
// The first version wrote a row on any request that arrived without a cookie.
// A browser does that once and then carries the cookie; ANYTHING THAT DOES NOT
// KEEP COOKIES DOES IT ON EVERY REQUEST — a crawler, a scanner, `curl`. Within
// a day of this site having a public address there were three hundred and
// sixty-five of them, on a site nobody had been told about.
//
// Two things were wrong with that, and the first is the worse one:
//
//   - THE FUNNEL'S DENOMINATOR. This table exists to answer "how many of the
//     people who arrived became students" (K-10). Crawlers in the denominator
//     make that answer wrong in a way that looks entirely plausible, which is
//     the kind of wrong nobody catches by reading the number.
//   - A WRITE PER REQUEST, CHOSEN BY WHOEVER IS CALLING. `Seen` is coarse to an
//     hour precisely so that a read path does not become a write path. `Create`
//     had no such guard, and the disk it grows autoresizes and never shrinks.
//
// So the first request is OFFERED an identity and nothing is written. It
// becomes a row on the request that hands the offer back — because handing a
// cookie back is what a browser does and what a crawler does not.
//
// IT DOES NOT STOP A DETERMINED CALLER. Anybody willing to echo a cookie can
// still have a row per request, and the answer to that is a rate limit rather
// than this. What this stops is the unmalicious majority: everything that
// ignores Set-Cookie because it was never a browser.
//
// # THE ARRIVAL IS EMITTED HERE OR NOWHERE
//
// "Of the people who arrived, how many signed up" is the question the visitor
// identity exists for (K-10), and the arrival is the one step of the funnel
// that CANNOT BE RECONSTRUCTED AFTERWARDS. By the time somebody signs up, the
// visit that brought them is over; by the time anybody notices the event is
// missing, every earlier period is permanently unanswerable.
//
// It fires on the request that writes the row and on no other, which is what
// makes it "arrived" rather than "came back".
func Identify(store *Store, schoolOf SchoolOf, settings Settings, arrived Arrived) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			who := resolve(r, store, schoolOf, settings)

			if who.offer != nil {
				http.SetCookie(w, who.offer)
			}
			if who.id == uuid.Nil {
				next.ServeHTTP(w, r) // counted nothing; still serving
				return
			}

			ctx := context.WithValue(r.Context(), ctxVisitor, who.id)
			if who.accepted {
				http.SetCookie(w, cookie(who.id, settings))
			}
			if who.inserted && arrived != nil {
				// With the visitor already in the context, so the event
				// carries it the same way every other event does.
				arrived(ctx, who.id)
			}
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// outcome is what one request turned out to be.
//
// ACCEPTED AND INSERTED ARE TWO THINGS. Four parallel requests can hand back
// the same offer; all four are accepted and get the identity cookie, and
// exactly one of them writes the row. The arrival belongs to that one, or a
// single visit is counted four times.
type outcome struct {
	id       uuid.UUID
	accepted bool         // the offer was taken up here: replace the cookie
	inserted bool         // and this is the request that wrote the row
	offer    *http.Cookie // or there is no identity yet, and here is one
}

// resolve answers what this request is.
//
//	a known visitor       → the id, nothing to write
//	an offer handed back  → the id, the cookie replaced, maybe the row written
//	anything else         → no id, and an offer
func resolve(r *http.Request, store *Store, schoolOf SchoolOf, settings Settings) outcome {
	c, err := r.Cookie(CookieName)
	if err != nil {
		return outcome{offer: offer(r, schoolOf, settings)}
	}

	if id, err := uuid.Parse(c.Value); err == nil {
		switch err := store.Seen(r.Context(), id); {
		case err == nil:
			return outcome{id: id}
		case errors.Is(err, ErrUnknown):
			// A cookie that outlived its row: after an erasure, or after a
			// restore. Offer a new identity rather than carrying an id that
			// joins to nothing.
			return outcome{offer: offer(r, schoolOf, settings)}
		default:
			// The database is unreachable. Serve, count nothing, and offer
			// nothing — an offer taken up once it is back would be a second
			// identity for somebody who already has a perfectly good one.
			return outcome{}
		}
	}

	offered, first, ok := decodeOffer(c.Value)
	if !ok {
		return outcome{offer: offer(r, schoolOf, settings)}
	}

	// THE SCHOOL AND THE COUNTRY COME FROM THE REQUEST AND NEVER FROM THE
	// COOKIE.
	//
	// Everything else in a first touch was already the caller's to choose — a
	// referrer is a header they set, a path is what they asked for, a campaign
	// is a query string — so carrying those across in a cookie costs no trust
	// that was ever held, and `decodeOffer` bounds them exactly as the query
	// string was bounded. The school is resolved by the server from the host,
	// and it stays that way.
	//
	// The country is the same kind of thing and the cookie never carried one:
	// `encodeOffer` writes no field for it, so there is nothing to read back
	// and nothing a caller could put there. It is resolved here, from the
	// request that is writing the row.
	if schoolOf != nil {
		if id, _, ok := schoolOf(r.Context()); ok {
			first.TenantID = &id
		}
	}
	first.Country = geo.FromContext(r.Context())

	id, inserted, err := store.Create(r.Context(), offered, first)
	if err != nil {
		return outcome{}
	}
	return outcome{id: id, accepted: true, inserted: inserted}
}

// The page saying where it came from. See `ui/app/api.js`, and the paragraph
// below for why it has to.
const (
	HeaderLanding         = "X-Schooling-Landing"
	HeaderLandingReferrer = "X-Schooling-Landing-Referrer"
)

func firstTouch(r *http.Request, schoolOf SchoolOf) FirstTouch {
	first := FirstTouch{
		// TRIMMED, LIKE THE REST. A path and a `Referer` header are as much the
		// caller's to choose as a query parameter is, and these two were the
		// only fields going into a column with no bound on them at all — a ten
		// kilobyte referrer was a ten kilobyte row.
		Path:     trim(r.URL.Path),
		Referrer: trim(r.Referer()),
		// FROM THE REQUEST, RESOLVED ONCE, IN ONE PLACE. See `platform/geo`:
		// the address is read there and nowhere else, and what arrives here is
		// already two letters or `unknown`.
		Country: geo.FromContext(r.Context()),
		Locale:  locale(r.Header.Get("Accept-Language")),
	}
	q := r.URL.Query()

	/* THE REQUEST IS NOT THE ARRIVAL, and taking the first touch off it was
	   wrong in all three fields at once.

	   This middleware is mounted on `/api/v1/`; the page is served from `/` and
	   never reaches it. So what arrives here is an XHR the page fired, and:

	     the referrer  is this site, because that is the page the call came from
	     the path      is an API route, not the page anybody landed on
	     the campaign  is absent, because `?utm_source=` was on the ADDRESS BAR

	   Every one of those looked like data. `first_referrer` in particular read
	   as a plausible answer — the site's own name, on every row, forever.

	   So the page says. It reads `location.href` and `document.referrer` once,
	   at load, before its own routing rewrites the address, and sends them.

	   THE HEADER IS THE CALLER'S, AND SO WAS EVERYTHING IT REPLACES. A `Referer`
	   is a header, a path is a request line, a campaign is a query string —
	   there was never a version of this that a caller could not write. What
	   changes is that the values are now the right ones. They are bounded here
	   exactly as the query string was. */
	if path, landed, ok := landingOf(r); ok {
		first.Path = trim(path)
		q = landed

		// Read whether or not it is empty: empty is an answer — a typed address
		// or a bookmark — and falling back would answer with this site instead.
		first.Referrer = trim(r.Header.Get(HeaderLandingReferrer))
	}

	if schoolOf != nil {
		if id, _, ok := schoolOf(r.Context()); ok {
			first.TenantID = &id
		}
	}

	first.Source = trim(q.Get("utm_source"))
	first.Medium = trim(q.Get("utm_medium"))
	first.Campaign = trim(q.Get("utm_campaign"))

	return first
}

// landingOf answers the page somebody landed on, and the query it carried.
//
// # THE PAGE IS IN THE FRAGMENT, BECAUSE THE ROUTES ARE
//
// This interface routes on the fragment, so `https://school/#/plans` is the
// plans page and `/` is only the shell that every page shares. Reading
// `URL.Path` alone would record `/` for every visitor ever — the same species
// of plausible, useless answer this whole change exists to remove, arrived at
// from the other direction.
//
// A campaign can be on either side of the `#`. `?utm_source=x#/plans` is what
// a link builder writes and `#/plans?utm_source=x` is what somebody writes by
// hand, and both are the same intention. The query before the fragment wins
// where they disagree, and the fragment fills what it left empty.
//
// Bounded before it is parsed, and required to be absolute — a header that is
// not a URL is a header to ignore, not a reason to fail a request that was
// only ever going to serve a page.
func landingOf(r *http.Request) (string, url.Values, bool) {
	raw := r.Header.Get(HeaderLanding)
	if raw == "" || len(raw) > 512 {
		return "", nil, false
	}
	landing, err := url.Parse(raw)
	if err != nil || !landing.IsAbs() || landing.Path == "" {
		return "", nil, false
	}

	path, q := landing.Path, landing.Query()

	// `#/plans?utm_source=x` — a route, and possibly a query of its own.
	if route, rest, _ := strings.Cut(landing.Fragment, "?"); strings.HasPrefix(route, "/") {
		path = route
		if inner, err := url.ParseQuery(rest); err == nil {
			for key, values := range inner {
				if q.Get(key) == "" && len(values) > 0 {
					q.Set(key, values[0])
				}
			}
		}
	}
	return path, q, true
}

/* ---------- the offer ----------

   An identity a caller has not accepted yet. It is a cookie and nothing else:
   no row, no id anybody could join to, nothing that survives the caller
   throwing it away — which is exactly what most callers without a browser do.

   IT CARRIES THE FIRST TOUCH, so that the row written on the next request
   describes the FIRST request rather than the second one. Without that,
   "where did they come from" would answer with wherever they were one click
   later, which is usually this site. */

// offerPrefix is what tells an offer from an accepted identity. An accepted one
// is a bare uuid, so the prefix cannot collide with it: a uuid has no dot.
const offerPrefix = "offer."

// How long an offer is worth taking up. It only has to survive until the next
// request of the same page load, and a short life keeps a stale first touch
// from being attached to a visit that happened a week later.
const offerLifetime = time.Hour

func offer(r *http.Request, schoolOf SchoolOf, settings Settings) *http.Cookie {
	c := cookie(uuid.Nil, settings)
	c.Value = encodeOffer(uuid.New(), firstTouch(r, schoolOf))
	c.Expires = time.Now().Add(offerLifetime)
	c.MaxAge = int(offerLifetime.Seconds())
	return c
}

func encodeOffer(id uuid.UUID, f FirstTouch) string {
	v := url.Values{}
	v.Set("i", id.String())
	v.Set("p", f.Path)
	v.Set("r", f.Referrer)
	v.Set("s", f.Source)
	v.Set("m", f.Medium)
	v.Set("c", f.Campaign)
	v.Set("l", f.Locale)
	return offerPrefix + base64.RawURLEncoding.EncodeToString([]byte(v.Encode()))
}

// decodeOffer reads one back, and trusts none of it.
//
// A cookie is whatever the caller sends. Every field goes through `trim` again
// on the way in — the same bound the query string got — because a value that
// was bounded when this server wrote it is not the value that comes back.
func decodeOffer(value string) (uuid.UUID, FirstTouch, bool) {
	encoded, ok := strings.CutPrefix(value, offerPrefix)
	if !ok {
		return uuid.Nil, FirstTouch{}, false
	}
	decoded, err := base64.RawURLEncoding.DecodeString(encoded)
	if err != nil || len(decoded) > 4096 {
		return uuid.Nil, FirstTouch{}, false
	}
	v, err := url.ParseQuery(string(decoded))
	if err != nil {
		return uuid.Nil, FirstTouch{}, false
	}
	id, err := uuid.Parse(v.Get("i"))
	if err != nil {
		return uuid.Nil, FirstTouch{}, false
	}

	first := FirstTouch{
		Path:     trim(v.Get("p")),
		Referrer: trim(v.Get("r")),
		Source:   trim(v.Get("s")),
		Medium:   trim(v.Get("m")),
		Campaign: trim(v.Get("c")),

		// Overwritten by `resolve` from the request. It is set here so that a
		// FirstTouch is never handed on with an empty country, which is what
		// the column refuses.
		Country: geo.Unknown,
		Locale:  trim(v.Get("l")),
	}
	if first.Locale == "" {
		first.Locale = "unknown"
	}
	return id, first, true
}

// locale takes the first language off an Accept-Language header.
//
// The first is enough: what it is used for is grouping a report, and the
// weighted list underneath answers a question nobody asks.
func locale(header string) string {
	first, _, _ := strings.Cut(header, ",")
	first, _, _ = strings.Cut(first, ";")
	if first = trim(first); first == "" {
		return "unknown"
	}
	return strings.ToLower(first)
}

// trim bounds what a stranger can put in a column. The values come from a query
// string, which is to say from anybody with a keyboard.
func trim(s string) string {
	s = strings.TrimSpace(s)
	if len(s) > 128 {
		s = s[:128]
	}
	// A percent-encoded value that failed to decode is noise in a report.
	if decoded, err := url.QueryUnescape(s); err == nil {
		s = decoded
	}
	return strings.ToValidUTF8(s, "")
}

func cookie(id uuid.UUID, settings Settings) *http.Cookie {
	return &http.Cookie{
		Name:  CookieName,
		Value: id.String(),
		Path:  "/",

		// The parent domain, so one person crossing from the platform to a
		// school stays one visitor.
		Domain: settings.Domain,

		// HttpOnly because nothing in the browser has a reason to read it, and
		// an identifier JavaScript cannot touch is one an injected script
		// cannot take.
		HttpOnly: true,
		Secure:   settings.Secure,

		// Lax rather than Strict: an arrival from a link on another site is
		// precisely the visit this identity exists to record, and Strict would
		// withhold the cookie on exactly that request.
		SameSite: http.SameSiteLaxMode,

		Expires: time.Now().Add(cookieLifetime),
		MaxAge:  int(cookieLifetime.Seconds()),
	}
}
