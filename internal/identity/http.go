package identity

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/geo"
	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// CookieName is the session. On the parent domain, so one login covers every
// school (N-01), and HttpOnly so the token never touches JavaScript — which is
// the whole reason the app and the API share an origin (P-03).
const CookieName = "schooling_session"

// Settings are what the handler cannot work out for itself.
type Settings struct {
	// The platform's parent domain. Empty means host-only, which is what local
	// development wants.
	Domain string

	// Off in development, because a Secure cookie is not stored over plain
	// http — and the sign-in would then appear to work and forget immediately.
	Secure bool
}

// SignedUp is called after an account is created, inside the request.
//
// IT IS A CALLBACK AND NOT AN IMPORT. Sign-up is the moment the visitor who
// arrived becomes a student, which is the join the whole funnel rests on
// (K-10) — and it is also an event to emit. Both of those live in other
// modules, and modules talk through what the consumer defines, wired in cmd/.
//
// It returns nothing on purpose. A funnel that cannot record a signup must not
// be able to fail one.
type SignedUp func(ctx context.Context, account Account)

/*
Refused answers whether an address has permanently refused our mail.

	IT IS A CALLBACK FOR `SignedUp`'S REASON. The suppression list belongs to
	`notify`, and modules talk through what the consumer defines, wired in
	`cmd/`. The alternative was one more `EXISTS` beside the sub-select that
	already computes `ConfirmationPending` — the table is right there, and the
	architecture test reads imports rather than SQL, so nothing would have caught
	it. That is the argument against it and not for it.

	IT IS ON THE HANDLER AND NOT ON THE STORE, which is what bounds the cost.
	Every authenticated request verifies a session; only two ask what an account
	looks like. On the store this would have been a second query on every request
	this platform serves, in order to draw a banner.
*/
type Refused func(ctx context.Context, address string) (bool, error)

type Handler struct {
	store    *Store
	settings Settings
	signedUp SignedUp
	refused  Refused
}

func NewHandler(store *Store, settings Settings, signedUp SignedUp, refused Refused) *Handler {
	return &Handler{store: store, settings: settings, signedUp: signedUp, refused: refused}
}

/*
refusedBy is that question, answered safely.

	AN ERROR IS A "NO" HERE, WHICH IS THE OPPOSITE OF `notify.mayWrite`, and the
	two differ because being wrong costs opposite things. There, a list that
	cannot be read must not become permission to write to somebody who said stop.
	Here the consequence is a sentence on a screen — and telling somebody their
	address refused our mail when we do not actually know is worse than saying
	nothing, because they cannot check it and have no reason to doubt us.

	NO LIST WIRED MEANS NO REFUSALS, for the deployments that have none: a test,
	and a laptop whose outbox nobody reads.
*/
func (h *Handler) refusedBy(ctx context.Context, address string) bool {
	if h.refused == nil {
		return false
	}
	refused, err := h.refused(ctx, address)
	if err != nil {
		web.LoggerFrom(ctx).Error("reading the suppression list for the banner", "error", err)
		return false
	}
	return refused
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/sign-up", h.signUp)
	mux.HandleFunc("POST /api/v1/sign-in", h.signIn)
	mux.HandleFunc("POST /api/v1/sign-out", h.signOut)
	mux.HandleFunc("GET /api/v1/me", h.me)
}

type credentials struct {
	Email    string `json:"email"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

func (h *Handler) signUp(w http.ResponseWriter, r *http.Request) {
	var in credentials
	if !decode(w, r, &in) {
		return
	}

	/* THE COUNTRY IS WHERE THE ACCOUNT WAS OPENED, AND IT IS NEVER REWRITTEN.
	   It answers "where do our students come from", which is a fact about a
	   person that does not change when they travel. Where somebody is
	   PRACTISING is a different question and a different column: it rides on
	   each event, resolved per request, so the two can disagree — and a screen
	   that showed them as one number would be answering neither. */
	account, err := h.store.Create(r.Context(), NewAccount{
		Email: in.Email, Name: in.Name, Password: in.Password,
		Country: geo.FromContext(r.Context()),

		/* AND THE LANGUAGE THE BROWSER DECLARED, NOT THE ONE THE PAGE IS IN.
		   `web.Locale` reads `?lang=` and falls back to English, which is
		   right for choosing a translation and wrong for recording a person:
		   sign-up sends no `lang` at all, so it would have written `en`
		   against every account ever created. `unknown` is the honest fourth
		   answer and the column already holds it. */
		Locale: web.Declared(r),
	})
	switch {
	case errors.Is(err, ErrTaken):
		// Saying "that address already has an account" tells a stranger who has
		// one. Saying nothing tells the person who typed their own address
		// wrongly nothing either — so it is a 409 with a sentence that fits
		// both readings, and the address itself is told by e-mail later.
		web.Fail(w, http.StatusConflict, "already_registered",
			"if that address does not already have an account, try a different one")
		return
	case err != nil:
		h.refuse(w, r, err)
		return
	}

	if h.signedUp != nil {
		h.signedUp(r.Context(), account)

		/* AND THE ACCOUNT IS READ AGAIN, because that callback is where a
		   confirmation link gets issued and the struct in hand is older than
		   it. Without this the response says no link is outstanding about a
		   link that was just put in the post, and the screen offers to send
		   one that is already on its way.

		   A FAILED RE-READ KEEPS THE STALE COPY rather than failing the
		   sign-up. The account exists; what would be lost is one sentence on a
		   banner, and losing a sign-up over it is the wrong trade. */
		if fresh, err := h.store.ByID(r.Context(), account.ID); err == nil {
			account = fresh
		} else {
			web.LoggerFrom(r.Context()).Error("re-reading a new account", "error", err,
				"account", account.ID)
		}
	}

	h.start(w, r, account, http.StatusCreated)
}

func (h *Handler) signIn(w http.ResponseWriter, r *http.Request) {
	var in credentials
	if !decode(w, r, &in) {
		return
	}

	account, err := h.store.Authenticate(r.Context(), in.Email, in.Password)
	switch {
	case errors.Is(err, ErrNoAccount), errors.Is(err, ErrWrongPassword):
		// ONE ANSWER FOR BOTH. Distinguishing them turns the sign-in form into
		// a way to ask whether somebody has an account here.
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized,
			"that address and password do not go together")
		return
	case err != nil:
		h.refuse(w, r, err)
		return
	}

	h.start(w, r, account, http.StatusOK)
}

func (h *Handler) signOut(w http.ResponseWriter, r *http.Request) {
	if c, err := r.Cookie(CookieName); err == nil {
		if err := h.store.Revoke(r.Context(), c.Value); err != nil {
			web.LoggerFrom(r.Context()).Error("ending a session", "error", err)
		}
	}

	// The cookie goes whether or not the revocation worked. A browser holding a
	// token the server has forgotten is a confusing state; a browser holding
	// nothing is not.
	http.SetCookie(w, h.expiredCookie())
	web.JSON(w, http.StatusOK, map[string]string{"status": "signed out"})
}

func (h *Handler) me(w http.ResponseWriter, r *http.Request) {
	account, ok := FromContext(r.Context())
	if !ok {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}
	web.JSON(w, http.StatusOK, h.viewOf(r, account))
}

/*
viewOf is `view` plus what the interface cannot work out for itself.

	THE SCREEN HAD NO WAY TO KNOW EITHER OF THESE. `ui/app/api.js` refused to
	complete a second factor with "this school does not have multi-factor sign-in
	yet" — true of the CLIENT and never of the server — and the sign-in screen's
	code step was reached by a `mfaRequired` flag nothing ever sent. So an account
	with a second factor could be signed into through the interface and could not
	present the code, which is how the first one here came to be enrolled through
	the browser's own console.

	`secondFactor` is a property of the account: does it have one. `mfaRequired`
	is a property of THIS SITTING: does it still owe a code. They are different
	questions and a screen needs both — the first to decide what the account
	screen offers, the second to decide whether to ask for a code right now.
*/
func (h *Handler) viewOf(r *http.Request, account Account) map[string]any {
	out := view(account, h.refusedBy(r.Context(), account.Email))

	/* AND WHETHER THIS IS SOMEBODY LOOKING RATHER THAN THE STUDENT.

	   The banner is the third of K-02's restraints and it is the only one that
	   works while the viewing is happening — so what it needs comes back on the
	   same answer that says who the session belongs to, and the interface cannot
	   draw the screens without also learning that it is drawing them for
	   somebody else.

	   THE OPERATOR IS NAMED. "You are viewing as a student" is a warning; "Grace
	   Hopper is viewing Ada Lovelace's screens" is an account of what is
	   happening, and it is the sentence that matches the audit entry when
	   somebody asks later. The school's name the interface already has, from
	   `/api/v1/school`, so it is not repeated here. */
	if v, viewing := ViewingFromContext(r.Context()); viewing {
		seen := map[string]any{"student": account.Name}
		if by, err := h.store.ByID(r.Context(), v.By); err == nil {
			seen["by"] = by.Name
			seen["byEmail"] = by.Email
		} else {
			// A viewing whose operator cannot be read is still a viewing, and
			// the banner still has to appear. An unnamed one is worse than a
			// named one and far better than none.
			web.LoggerFrom(r.Context()).Error("reading who is viewing", "error", err)
		}
		out["viewing"] = seen

		/* AND IT IS NEVER ASKED FOR A SECOND FACTOR. The account may have one;
		   the operator does not have the student's phone, and a viewing that
		   stopped at a code prompt would be a feature that never works for
		   exactly the accounts most worth looking at. What authorised this is the
		   operator's own factor, at the console door, which they have already
		   presented. */
		out["secondFactor"] = false
		out["mfaRequired"] = false
		return out
	}

	has, err := h.store.HasSecondFactor(r.Context(), account.ID)
	if err != nil {
		// A read that failed is not a "no": saying the account has no second
		// factor because the database hiccuped is how a screen offers to enrol
		// one over the top of the one that is there.
		web.LoggerFrom(r.Context()).Error("reading the second factor", "error", err)
		return out
	}
	out["secondFactor"] = has
	if !has {
		return out
	}

	shown := false
	if c, err := r.Cookie(CookieName); err == nil {
		if s, err := h.store.SecondFactorShown(r.Context(), c.Value); err == nil {
			shown = s
		}
	}
	out["mfaRequired"] = !shown
	return out
}

func (h *Handler) start(w http.ResponseWriter, r *http.Request, account Account, status int) {
	token, err := h.store.Issue(r.Context(), account.ID, r.UserAgent())
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	http.SetCookie(w, h.cookie(token))

	/* THE ANSWER SAYS WHETHER A CODE IS STILL OWED. A session is issued on the
	   password alone — the code comes after — so the screen has to be told, and
	   until now nothing told it. The cookie is on the response rather than the
	   request at this point, so the freshly issued token is passed straight in. */
	body := view(account, h.refusedBy(r.Context(), account.Email))
	if has, err := h.store.HasSecondFactor(r.Context(), account.ID); err == nil && has {
		body["secondFactor"] = true
		body["mfaRequired"] = true
	}
	web.JSON(w, status, body)
}

// view is what an account looks like over the wire. Explicit rather than the
// struct: `synthetic` is an operational flag, and a person told they are
// synthetic learns something true and useless.
func view(a Account, refused bool) map[string]any {
	return map[string]any{
		"id":      a.ID,
		"email":   a.Email,
		"name":    a.Name,
		"locale":  a.Locale,
		"country": a.Country,

		/* WHETHER THEY HAVE PROVED THEY CAN READ THE ADDRESS, and not WHEN.

		   The screen that reads this shows a nudge or does not; the date would
		   be a second fact nothing draws, in a response every signed-in request
		   carries. `api.js` has hard-coded this to `true` since the banner was
		   written, which is why the banner has never appeared for anybody. */
		"emailVerified": a.EmailVerifiedAt != nil,

		/* AND WHETHER A LINK IS OUT THERE, which is what stops the nudge saying
		   something false. "We sent a link to X" is true for somebody who just
		   signed up and a lie for every account that predates confirmations, or
		   whose link expired unread — and the screen had no way to tell those
		   apart because nothing told it. */
		"confirmationPending": a.ConfirmationPending,

		/* AND WHETHER THE ADDRESS REFUSED US, which makes both of the above
		   beside the point.

		   "We sent a link to X" is TRUE and USELESS once X has hard-bounced: the
		   message left, it was refused, and the button beside that sentence
		   offers to do it again. Somebody watches a link that will never arrive
		   and has no way to learn why — which is the state a real address in
		   production sat in for the length of an afternoon before anybody
		   noticed the account existed at all. */
		"emailRefused": refused,
	}
}

func (h *Handler) refuse(w http.ResponseWriter, r *http.Request, err error) {
	// A validation problem is the caller's and says so; anything else is ours
	// and says nothing, because the detail is for the log.
	if errors.Is(err, ErrNoAccount) {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}
	if isCallerError(err) {
		web.Fail(w, http.StatusBadRequest, "invalid", err.Error())
		return
	}
	web.LoggerFrom(r.Context()).Error("identity", "error", err)
	web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
}

// isCallerError is true for the problems a person can fix by typing something
// else. They are built by validate, which joins them, so the test is on the
// text rather than on a type — a sentinel per rule would be five sentinels
// nobody branches on.
func isCallerError(err error) bool {
	var joined interface{ Unwrap() []error }
	return errors.As(err, &joined) || errors.Is(err, ErrWrongPassword)
}

func (h *Handler) cookie(token string) *http.Cookie {
	return &http.Cookie{
		Name:     CookieName,
		Value:    token,
		Path:     "/",
		Domain:   h.settings.Domain,
		HttpOnly: true,
		Secure:   h.settings.Secure,
		// Lax rather than Strict: a student following a link from an e-mail
		// into a lesson should already be signed in when they arrive.
		SameSite: http.SameSiteLaxMode,
		Expires:  time.Now().Add(sessionLifetime),
		MaxAge:   int(sessionLifetime.Seconds()),
	}
}

func (h *Handler) expiredCookie() *http.Cookie {
	c := h.cookie("")
	c.Expires = time.Unix(0, 0)
	c.MaxAge = -1
	return c
}

func decode(w http.ResponseWriter, r *http.Request, into any) bool {
	// A megabyte of JSON on a sign-in form is not a sign-in form.
	r.Body = http.MaxBytesReader(w, r.Body, 64*1024)

	if err := json.NewDecoder(r.Body).Decode(into); err != nil {
		web.Fail(w, http.StatusBadRequest, "invalid", "that is not the JSON this route expects")
		return false
	}
	return true
}

/* ---------- the context ---------- */

type ctxKey int

const ctxAccount ctxKey = iota

// FromContext answers who is making this request, if anybody.
func FromContext(ctx context.Context) (Account, bool) {
	a, ok := ctx.Value(ctxAccount).(Account)
	return a, ok
}

// AccountID is the same question where only the id is wanted.
func AccountID(ctx context.Context) (uuid.UUID, bool) {
	a, ok := FromContext(ctx)
	return a.ID, ok
}

// Where is which school this request arrived at, for the heartbeat that answers
// "who is here now".
//
// IT IS A FUNCTION AND NOT AN IMPORT, like everything else that crosses a module
// boundary here: `tenant` owns the answer and this package may not see it.
type Where func(ctx context.Context) (uuid.UUID, bool)

// Nowhere is the Where for a host that is not a school's — the console, and the
// platform's own address.
//
// IT EXISTS SO THAT THE ANSWER IS TYPED RATHER THAN OMITTED. A nil function
// would work and would read as "this was not wired up yet"; this reads as what
// it is, which is a request that legitimately happened in no school.
func Nowhere(context.Context) (uuid.UUID, bool) { return uuid.Nil, false }

// Authenticate puts the account on the request when there is a live session,
// and does nothing when there is not.
//
// IT NEVER REFUSES. Half this API is legitimately anonymous — the catalogue, a
// free course, the sign-in route itself — so refusing here would mean listing
// exceptions, and a list of exceptions is where the one nobody added lives.
// Refusing is Require's job, on the routes that say so.
func Authenticate(store *Store, where Where) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			/* THE VIEWING COOKIE WINS WHERE THERE IS ONE.

			   Both can be present at once, and that is the whole design: the
			   ordinary cookie is the operator's, scoped to the platform domain,
			   and the viewing is host-only on the school being looked at. On
			   that host the viewing is what the operator asked to see, so it is
			   what answers — and the console, on its own host, never sees it.

			   A student's browser has only the first, and nothing about this
			   changes for them. */
			token, viewing := "", false
			if c, err := r.Cookie(ViewingCookie); err == nil && c.Value != "" {
				token, viewing = c.Value, true
			} else if c, err := r.Cookie(CookieName); err == nil {
				token = c.Value
			}
			if token == "" {
				next.ServeHTTP(w, r)
				return
			}

			/* WHERE THIS LANDED, RESOLVED BEFORE THE SESSION IS READ, because
			   it travels into the same query: the heartbeat is a clause of the
			   statement that authenticates rather than a write after it. A host
			   that is no school's answers nothing, and nothing does not erase
			   the school this session was last used in — see `Verify`. */
			var at *uuid.UUID
			if school, ok := where(r.Context()); ok {
				at = &school
			}

			account, seeing, err := store.Verify(r.Context(), token, at)
			if err != nil {
				if !errors.Is(err, ErrNoSession) {
					web.LoggerFrom(r.Context()).Error("verifying a session", "error", err)
				}
				next.ServeHTTP(w, r)
				return
			}

			/* A VIEWING COOKIE THAT IS NOT A VIEWING IS NOT A SESSION.

			   It would mean somebody put an ordinary session token into the
			   viewing cookie — by hand, or by a bug — and honouring it would be a
			   session with none of the restraints and no banner, which is the
			   exact thing this feature is not allowed to be. */
			if viewing && !seeing.Is() {
				next.ServeHTTP(w, r)
				return
			}

			ctx := context.WithValue(r.Context(), ctxAccount, account)
			if seeing.Is() {
				ctx = WithViewing(ctx, seeing)
			}
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// Require refuses a request that has no account behind it.
func Require(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, ok := FromContext(r.Context()); !ok {
			web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
			return
		}
		next.ServeHTTP(w, r)
	})
}

/* ---------- the second factor, over HTTP ---------- */

// SecondFactorRoutes are how somebody enrols and presents one.
//
// THEY ARE NOT UNDER RequireStaff. A person enrolling has a role and no factor,
// which is precisely the state the staff door refuses — so putting enrolment
// behind that door would lock out everybody who has not already been through
// it. They need a session and nothing more.
func (h *Handler) SecondFactorRoutes(mux *http.ServeMux) {
	mux.Handle("POST /api/v1/second-factor/start", Require(http.HandlerFunc(h.startFactor)))
	mux.Handle("POST /api/v1/second-factor/enrol", Require(http.HandlerFunc(h.enrolFactor)))
	mux.Handle("POST /api/v1/second-factor/present", Require(http.HandlerFunc(h.presentFactor)))
	mux.Handle("GET /api/v1/second-factor/recovery-codes",
		Require(http.HandlerFunc(h.recoveryCodesLeft)))
	mux.Handle("POST /api/v1/second-factor/recovery-codes",
		Require(http.HandlerFunc(h.reissueRecoveryCodes)))
}

// startFactor answers a fresh secret and the URI an authenticator app scans.
//
// THE SECRET IS NOT STORED YET. Keeping it server-side between the two calls
// would mean pending state with a lifetime, an expiry and a cleanup; handing it
// back and taking it again costs nothing, because the person has it in their
// app by then anyway. Nothing is written until a code proves that.
func (h *Handler) startFactor(w http.ResponseWriter, r *http.Request) {
	account, _ := FromContext(r.Context())

	secret, err := NewTOTPSecret()
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	issuer := h.settings.Domain
	if issuer == "" {
		issuer = "schooling"
	}

	web.JSON(w, http.StatusOK, map[string]string{
		"secret": secret,
		"uri":    TOTPURI(secret, issuer, account.Email),
	})
}

type secondFactor struct {
	Secret string `json:"secret"`
	Code   string `json:"code"`
}

func (h *Handler) enrolFactor(w http.ResponseWriter, r *http.Request) {
	var in secondFactor
	if !decode(w, r, &in) {
		return
	}
	account, _ := FromContext(r.Context())

	/* THE SESSION IS AN ARGUMENT AND NOT AN AFTERTHOUGHT. Replacing a second
	   factor asks whether THIS session has already shown the one being
	   replaced, so the token goes in — rather than being fetched afterwards
	   only to mark the session as having enrolled. */
	c, err := r.Cookie(CookieName)
	if err != nil {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}

	codes, err := h.store.EnrolSecondFactor(r.Context(), account.ID, c.Value, in.Secret, in.Code)
	if err != nil {
		switch {
		case errors.Is(err, ErrWrongCode):
			web.Fail(w, http.StatusBadRequest, "wrong_code",
				"that code does not come from that secret — check the clock on the device")
		case errors.Is(err, ErrAlreadyEnrolled):
			web.Fail(w, http.StatusForbidden, "already_enrolled",
				"this account already has a second factor — present the one it has "+
					"before replacing it")
		default:
			h.refuse(w, r, err)
		}
		return
	}

	// The session that enrolled has just proved it holds the factor, so it is
	// marked. Asking for a second code straight afterwards teaches people that
	// this system asks for codes twice for no reason.
	if err := h.store.PresentSecondFactor(r.Context(), c.Value, in.Code); err != nil {
		web.LoggerFrom(r.Context()).Error("marking the enrolling session", "error", err)
	}

	/* THE ONE TIME THE CODES ARE READABLE. They are not fetchable afterwards
	   and there is no route that returns them again — only one that replaces
	   the set. A screen that could re-read them would make them a second
	   password sitting behind the first. */
	web.JSON(w, http.StatusOK, map[string]any{
		"status":        "enrolled",
		"recoveryCodes": codes,
	})
}

// reissueRecoveryCodes replaces the set and returns the new one.
//
// IT ASKS FOR THE FACTOR THIS SESSION HAS ALREADY SHOWN, not merely for a
// session. Otherwise a password alone mints ten new ways past the second
// factor, which is the hole `EnrolSecondFactor` was just closed against, one
// door along.
func (h *Handler) reissueRecoveryCodes(w http.ResponseWriter, r *http.Request) {
	account, _ := FromContext(r.Context())

	c, err := r.Cookie(CookieName)
	if err != nil {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}

	shown, err := h.store.SecondFactorShown(r.Context(), c.Value)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	if !shown {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"present the second factor on this session before replacing its recovery codes")
		return
	}

	codes, err := h.store.IssueRecoveryCodes(r.Context(), account.ID)
	if err != nil {
		h.refuse(w, r, err)
		return
	}

	// REPLACES, and the answer says so: whatever was written down before this
	// call stopped working the moment it returned.
	web.JSON(w, http.StatusOK, map[string]any{
		"status":        "reissued",
		"recoveryCodes": codes,
	})
}

// recoveryCodesLeft is how many are unspent. It is a count and never the codes.
func (h *Handler) recoveryCodesLeft(w http.ResponseWriter, r *http.Request) {
	account, _ := FromContext(r.Context())

	left, err := h.store.RecoveryCodesLeft(r.Context(), account.ID)
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	web.JSON(w, http.StatusOK, map[string]int{"left": left})
}

func (h *Handler) presentFactor(w http.ResponseWriter, r *http.Request) {
	var in secondFactor
	if !decode(w, r, &in) {
		return
	}

	c, err := r.Cookie(CookieName)
	if err != nil {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}

	switch err := h.store.PresentSecondFactor(r.Context(), c.Value, in.Code); {
	case errors.Is(err, ErrWrongCode), errors.Is(err, ErrNoSecondFactor):
		// One answer for both: which of them it is tells somebody holding a
		// stolen session whether the account has a factor at all.
		web.Fail(w, http.StatusUnauthorized, "wrong_code", "that code is not right")
		return
	case err != nil:
		h.refuse(w, r, err)
		return
	}

	web.JSON(w, http.StatusOK, map[string]string{"status": "accepted"})
}
