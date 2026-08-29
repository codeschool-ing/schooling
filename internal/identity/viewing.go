package identity

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/setting"
	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* Seeing what a student sees.

   # THREE RESTRAINTS, AND THEY SHIP TOGETHER OR NOT AT ALL (K-02)

   Audited, time-limited, visible banner. Each covers what the others do not:
   the audit answers afterwards, the expiry bounds a machine left unlocked, and
   the banner is the only one of the three that works WHILE it is happening.

   # AND A FOURTH THAT IS NOT IN K-02: IT CANNOT WRITE

   A support tool that can answer an exam question as the student is a tool that
   can forge a pass, and the audit would explain that afterwards rather than
   prevent it. So a viewing session is refused anything but a GET, in one place,
   by `RefuseWrites` — one rule rather than a list of protected routes, because a
   list of routes is where the one nobody added lives.

   This is why it is "viewing" everywhere in the code and never "impersonation".
   The operator is not the student and cannot act as them; they are looking.

   # THE HANDOFF, AND WHY A TOKEN IS BRIEFLY IN A URL

   The console answers on its own host and cannot set a cookie for a school's.
   So the token crosses in a link the operator follows, and the school's side
   moves it out of the URL into a host-only cookie and redirects.

   A URL is the worst place a credential can be — browser history, a referrer, a
   link pasted into a chat — so this one is spent on first use and is minted with
   seconds to live. What survives is a cookie on one host, which is where a
   session belongs.

   # THE COOKIE IS ITS OWN, AND THAT IS THE POINT

   The ordinary session cookie is scoped to the whole platform domain: one
   browser, one identity, across the console and every school. Minting a student
   session into it would sign the operator out of their own console — and worse,
   would leave a browser whose single session is somebody else's.

   So a viewing lives in a SECOND cookie, host-only, which the school's side
   prefers when it is there. The operator's own session is untouched, the console
   stays open in the next tab, and ending a viewing is deleting one cookie.
*/

// ViewingCookie is where a viewing session lives on a school's host.
//
// A DIFFERENT NAME FROM THE ORDINARY ONE, deliberately: they can both be present
// in the same browser at the same time, and they must be, or the operator loses
// the console the moment they look at anything.
const ViewingCookie = "schooling_viewing"

/*
ViewingLifetime is how long a viewing lasts before it stops working.

	LONG ENOUGH TO READ A SCREEN AND SHORT ENOUGH THAT A MACHINE LEFT UNLOCKED
	IS NOT AN OPEN DOOR. Half an hour is the time-limited half of K-02.

	THE OLD COMMENT REFUSED TO MAKE IT A PARAMETER AND NAMED THE EXACT FAILURE:
	"a knob here would be a knob somebody turns up on the afternoon it is
	inconvenient". That is right, and it is a statement about ONE DIRECTION.

	SO THE CEILING IS THE SHIPPED VALUE AND THE KNOB ONLY GOES DOWN. `Most` is
	30 and nothing can raise it — not a console, not an operator having an
	inconvenient afternoon, not `cmd` wiring it wrongly. What a deployment may
	do is ask for LESS, which is the preference the old comment did not have a
	name for: an organisation that wants ten minutes is tightening K-02 and not
	loosening it, and there is no argument for refusing them.

	THIS IS THE ONLY DECLARATION IN THE REGISTRY WHOSE FENCE PROTECTS A DECISION
	RATHER THAN A TYPO. The others guard a digit too many; this one guards a
	rule, and the direction is the whole of it — a `Most` of 31 would make the
	refusal above true again.

	FIVE MINUTES IS THE FLOOR because a viewing shorter than the screen it
	exists to read is a feature that does not work, and an operator who cannot
	finish looking will start another one — which is the same access with more
	audit rows and less attention paid to each.
*/
var ViewingLifetime = setting.Declared{
	Name:     "identity.viewinglife",
	Unit:     setting.Minutes,
	Least:    5,
	Most:     30,
	Fallback: 30,
	Why: "how long an operator may look at a student's screens before the viewing stops " +
		"working (K-02). It may only be made SHORTER: thirty is the ceiling and nothing " +
		"can raise it, because a knob that went up would be one somebody turns on the " +
		"afternoon it is inconvenient. An organisation that wants ten minutes is " +
		"tightening the rule rather than loosening it, and there is no argument for " +
		"refusing them.",
}

// HandoffLifetime is how long the link is worth following.
//
// It is seconds rather than minutes because the operator follows it immediately
// or not at all: the console makes it and opens it. Anything longer is a
// credential sitting in a URL for no reason.
const HandoffLifetime = 30 * time.Second

// ErrNotAViewing is a token that is not a live, unspent viewing handoff.
var ErrNotAViewing = errors.New("identity: that is not a viewing waiting to start")

// Viewing says a session is somebody looking at a student rather than the
// student. Zero on every ordinary session.
type Viewing struct {
	// By is the operator who started it.
	By uuid.UUID

	// School is the one school it may be used on. A cookie is host-only, so a
	// browser would not send it elsewhere — this is the same rule where a copied
	// cookie cannot argue with it.
	School uuid.UUID
}

// Is answers whether this session is a viewing at all.
func (v Viewing) Is() bool { return v.By != uuid.Nil }

// StartViewing mints a viewing of one student, on one school, and answers the
// token that starts it.
//
// IT DOES NOT AUDIT, AND THAT IS NOT AN OVERSIGHT. The console writes the entry,
// before calling this, because the console is what knows the operator's name and
// because an action recorded only on success is an action nobody can review when
// it fails. See `console.NewViewHandler`.
func (s *Store) StartViewing(ctx context.Context,
	operator, student, school uuid.UUID) (string, error) {

	if operator == uuid.Nil || student == uuid.Nil || school == uuid.Nil {
		return "", fmt.Errorf("identity: a viewing needs an operator, a student and a school")
	}
	if operator == student {
		// Not a hazard, just nonsense — and nonsense that would put a banner on
		// somebody's own screens with their own name on it.
		return "", fmt.Errorf("identity: an operator cannot view themselves")
	}

	token, err := newToken()
	if err != nil {
		return "", err
	}

	if _, err := s.pool.Exec(ctx, `
		INSERT INTO sessions
			(account_id, token_hash, expires_at, user_agent, viewed_by, viewing_tenant)
		VALUES ($1, $2, now() + $3::interval, 'view-as-student', $4, $5)
	`, student, tokenHash(token), s.viewingLife().String(), operator, school); err != nil {
		return "", fmt.Errorf("identity: starting a viewing: %w", err)
	}
	return token, nil
}

// RedeemViewing spends a handoff token, once.
//
// THE WINDOW IS THE HANDOFF'S AND NOT THE VIEWING'S. A link that still worked
// twenty minutes later would be a credential in a URL for twenty minutes; the
// session it starts lives its own half hour from the moment it was made.
func (s *Store) RedeemViewing(ctx context.Context, token string) error {
	if token == "" {
		return ErrNotAViewing
	}

	tag, err := s.pool.Exec(ctx, `
		UPDATE sessions SET redeemed_at = now()
		WHERE token_hash = $1
		  AND viewed_by IS NOT NULL
		  AND redeemed_at IS NULL
		  AND revoked_at IS NULL
		  AND expires_at > now()
		  AND created_at > now() - $2::interval
	`, tokenHash(token), HandoffLifetime.String())
	if err != nil {
		return fmt.Errorf("identity: starting a viewing: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotAViewing
	}
	return nil
}

/* ---------- the context, and the rule ---------- */

const ctxViewing ctxKey = 1

// ViewingFromContext answers whether this request is somebody looking at a
// student, and who.
func ViewingFromContext(ctx context.Context) (Viewing, bool) {
	v, ok := ctx.Value(ctxViewing).(Viewing)
	return v, ok && v.Is()
}

// WithViewing puts one on a request, which is the middleware's job and the
// tests'.
func WithViewing(ctx context.Context, v Viewing) context.Context {
	return context.WithValue(ctx, ctxViewing, v)
}

// RefuseWrites is the fourth restraint: a viewing session may read and may not
// act.
//
// # ONE RULE RATHER THAN A LIST OF ROUTES
//
// Every route that changes anything here is a POST, PUT or DELETE — answering a
// question, handing in a paper, changing a password, enrolling a second factor.
// So the rule is the method, checked once, in the chain. A list of protected
// paths would be a list somebody adds a route to and forgets, and the failure of
// that list is an operator quietly holding a pen in somebody else's exam.
//
// # IT REFUSES LOUDLY
//
// 403 with a sentence, not a redirect and not a silent no-op. Somebody who has
// tried to click something needs to know the click did nothing, or they will
// report the button as broken — and the honest answer is that they are looking
// at a record rather than using an account.
func RefuseWrites(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, viewing := ViewingFromContext(r.Context()); viewing {
			switch r.Method {
			case http.MethodGet, http.MethodHead, http.MethodOptions:
			default:
				web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
					"you are looking at this student's screens, not using their account — "+
						"nothing here can be changed while that is true")
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}

/* ---------- the handoff, over HTTP ---------- */

// ViewingRoutes are how a viewing starts and ends on a school's host.
//
// THEY ARE NOT UNDER `Require`. Starting one is authenticated by the token in
// the link and nothing else — the operator's own session is on another host and
// its cookie does not travel here, which is the entire reason the handoff
// exists.
//
// AND THEY ARE NOT UNDER `/api/v1/` EITHER, which is deliberate rather than
// tidy. That prefix carries `RefuseWrites`, and a viewing that could not END
// itself would be a banner whose only button is refused by the rule the banner
// exists to announce.
func (h *Handler) ViewingRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /view", h.startViewing)
	mux.HandleFunc("POST /viewing/stop", h.stopViewing)
}

// startViewing moves the token out of the URL and into a host-only cookie.
//
// # IT REDIRECTS RATHER THAN RENDERING
//
// So that the address in the bar, in the history and in any referrer sent from
// the next page is `/` and not a credential. The token is spent by the time the
// redirect is followed, so even the copy in the operator's history is inert.
func (h *Handler) startViewing(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("t")

	if err := h.store.RedeemViewing(r.Context(), token); err != nil {
		if !errors.Is(err, ErrNotAViewing) {
			web.LoggerFrom(r.Context()).Error("starting a viewing", "error", err)
		}
		/* THE REFUSAL SAYS WHAT TO DO AND NOT WHAT WENT WRONG. A link that has
		   been followed once, or that is a minute old, or that somebody found in
		   a chat, all get this — and telling them apart would say whether a token
		   was ever real. */
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"that link is spent. Viewing links last seconds and work once — "+
				"start another from the console")
		return
	}

	http.SetCookie(w, h.viewingCookie(token))
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// stopViewing ends it from the student's side of the platform, which is where
// the operator is when they want to stop.
//
// IT IS A POST AND IT IS THE ONE WRITE A VIEWING MAY MAKE, which is why it is
// mounted outside `/api/v1/`. Ending a viewing is not acting as the student; it
// is the opposite.
func (h *Handler) stopViewing(w http.ResponseWriter, r *http.Request) {
	if c, err := r.Cookie(ViewingCookie); err == nil && c.Value != "" {
		if err := h.store.Revoke(r.Context(), c.Value); err != nil {
			web.LoggerFrom(r.Context()).Error("ending a viewing", "error", err)
		}
	}

	// The cookie goes whether or not the revocation worked. A browser still
	// holding it after somebody pressed stop is the worst of both.
	http.SetCookie(w, h.expiredViewingCookie())
	web.JSON(w, http.StatusOK, map[string]string{"status": "ended"})
}

// viewingCookie is host-only, and every difference from the ordinary one is the
// point.
//
// NO `Domain`, so the browser scopes it to exactly the host that set it: the
// school being looked at, and nowhere else. The ordinary session cookie names
// the platform domain and is shared across the console and every school, which
// is why a viewing could not live in it without taking the operator's own
// session with it.
//
// AND `Strict` RATHER THAN `Lax`: nothing should ever arrive at a viewing by
// following a link from somewhere else. There is no e-mail into a viewing and
// there never will be.
func (h *Handler) viewingCookie(token string) *http.Cookie {
	return &http.Cookie{
		Name:     ViewingCookie,
		Value:    token,
		Path:     "/",
		HttpOnly: true,
		Secure:   h.settings.Secure,
		SameSite: http.SameSiteStrictMode,
		/* THE COOKIE AND THE ROW READ THE SAME DECLARATION, a moment apart,
		   and the row is what decides. A change landing between the two makes
		   the cookie outlive the row — the operator's browser keeps a token the
		   server has already stopped honouring, which is a sign-out one refresh
		   later — or the reverse, which is a sign-out one refresh early. Both
		   are the harmless direction: ACCESS is the row's, always, and the
		   cookie is only how the browser carries the token. */
		Expires: time.Now().Add(h.store.viewingLife()),
		MaxAge:  int(h.store.viewingLife().Seconds()),
	}
}

func (h *Handler) expiredViewingCookie() *http.Cookie {
	c := h.viewingCookie("")
	c.Expires = time.Unix(0, 0)
	c.MaxAge = -1
	return c
}
