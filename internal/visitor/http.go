package visitor

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"
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

// Identify puts a visitor on every request, issuing one where there is none.
//
// IT NEVER FAILS A REQUEST. A database that cannot issue an identity is a
// reason to serve the page anyway and count nothing — refusing to show a
// prospective student the catalogue because analytics is down would be the
// funnel destroying the thing it exists to measure.
//
// # THE ARRIVAL IS EMITTED HERE OR NOWHERE
//
// "Of the people who arrived, how many signed up" is the question the visitor
// identity exists for (K-10), and the arrival is the one step of the funnel
// that CANNOT BE RECONSTRUCTED AFTERWARDS. By the time somebody signs up, the
// visit that brought them is over; by the time anybody notices the event is
// missing, every earlier period is permanently unanswerable.
//
// It fires on the request that issues the identity and on no other, which is
// what makes it "arrived" rather than "came back".
func Identify(store *Store, schoolOf SchoolOf, settings Settings, arrived Arrived) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			id, issued := resolve(r, store, schoolOf)
			if id == uuid.Nil {
				next.ServeHTTP(w, r) // counted nothing; still serving
				return
			}

			ctx := context.WithValue(r.Context(), ctxVisitor, id)
			if issued {
				http.SetCookie(w, cookie(id, settings))
				if arrived != nil {
					// With the visitor already in the context, so the event
					// carries it the same way every other event does.
					arrived(ctx, id)
				}
			}
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// resolve answers the visitor for this request, and whether it is new.
func resolve(r *http.Request, store *Store, schoolOf SchoolOf) (uuid.UUID, bool) {
	if c, err := r.Cookie(CookieName); err == nil {
		if id, err := uuid.Parse(c.Value); err == nil {
			switch err := store.Seen(r.Context(), id); {
			case err == nil:
				return id, false
			case errors.Is(err, ErrUnknown):
				// A cookie that outlived its row: after an erasure, or after a
				// restore. Issue a new identity rather than carrying an id
				// that joins to nothing.
			default:
				return uuid.Nil, false
			}
		}
	}

	id, err := store.Create(r.Context(), firstTouch(r, schoolOf))
	if err != nil {
		return uuid.Nil, false
	}
	return id, true
}

func firstTouch(r *http.Request, schoolOf SchoolOf) FirstTouch {
	first := FirstTouch{
		Path:     r.URL.Path,
		Referrer: r.Referer(),
		Country:  "unknown", // Cloud Run passes no country header; see the plan
		Locale:   locale(r.Header.Get("Accept-Language")),
	}

	if schoolOf != nil {
		if id, _, ok := schoolOf(r.Context()); ok {
			first.TenantID = &id
		}
	}

	q := r.URL.Query()
	first.Source = trim(q.Get("utm_source"))
	first.Medium = trim(q.Get("utm_medium"))
	first.Campaign = trim(q.Get("utm_campaign"))

	return first
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
