package identity

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

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

type Handler struct {
	store    *Store
	settings Settings
	signedUp SignedUp
}

func NewHandler(store *Store, settings Settings, signedUp SignedUp) *Handler {
	return &Handler{store: store, settings: settings, signedUp: signedUp}
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

	account, err := h.store.Create(r.Context(), NewAccount{
		Email: in.Email, Name: in.Name, Password: in.Password,
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
	web.JSON(w, http.StatusOK, view(account))
}

func (h *Handler) start(w http.ResponseWriter, r *http.Request, account Account, status int) {
	token, err := h.store.Issue(r.Context(), account.ID, r.UserAgent())
	if err != nil {
		h.refuse(w, r, err)
		return
	}
	http.SetCookie(w, h.cookie(token))
	web.JSON(w, status, view(account))
}

// view is what an account looks like over the wire. Explicit rather than the
// struct: `synthetic` is an operational flag, and a person told they are
// synthetic learns something true and useless.
func view(a Account) map[string]any {
	return map[string]any{
		"id":      a.ID,
		"email":   a.Email,
		"name":    a.Name,
		"locale":  a.Locale,
		"country": a.Country,
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

// Authenticate puts the account on the request when there is a live session,
// and does nothing when there is not.
//
// IT NEVER REFUSES. Half this API is legitimately anonymous — the catalogue, a
// free course, the sign-in route itself — so refusing here would mean listing
// exceptions, and a list of exceptions is where the one nobody added lives.
// Refusing is Require's job, on the routes that say so.
func Authenticate(store *Store) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			c, err := r.Cookie(CookieName)
			if err != nil {
				next.ServeHTTP(w, r)
				return
			}

			account, err := store.Verify(r.Context(), c.Value)
			if err != nil {
				if !errors.Is(err, ErrNoSession) {
					web.LoggerFrom(r.Context()).Error("verifying a session", "error", err)
				}
				next.ServeHTTP(w, r)
				return
			}

			next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), ctxAccount, account)))
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

	if err := h.store.EnrolSecondFactor(r.Context(), account.ID, in.Secret, in.Code); err != nil {
		if errors.Is(err, ErrWrongCode) {
			web.Fail(w, http.StatusBadRequest, "wrong_code",
				"that code does not come from that secret — check the clock on the device")
			return
		}
		h.refuse(w, r, err)
		return
	}

	// The session that enrolled has just proved it holds the factor, so it is
	// marked. Asking for a second code straight afterwards teaches people that
	// this system asks for codes twice for no reason.
	if c, err := r.Cookie(CookieName); err == nil {
		if err := h.store.PresentSecondFactor(r.Context(), c.Value, in.Code); err != nil {
			web.LoggerFrom(r.Context()).Error("marking the enrolling session", "error", err)
		}
	}

	web.JSON(w, http.StatusOK, map[string]string{"status": "enrolled"})
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
