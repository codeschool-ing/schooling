package tenant

import (
	"context"
	"errors"
	"net/http"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Resolve is the middleware every school-scoped route sits behind.
//
// AN UNKNOWN HOST IS A 404, AND NEVER A DEFAULT SCHOOL. That is the single
// most important line in this package. Falling back to "the first school" or
// "the only school" is the kind of convenience that works perfectly until
// there are two, and then serves one school's catalogue at another's address
// without anything looking wrong — no error, no log, no symptom. The
// correctness of every school-scoped query downstream rests on this refusing.
//
// A lookup that FAILS is a different thing from a host that is unknown, and
// they answer differently: the first is a 503, because the database blinked
// and the address may well be fine. Answering 404 there would tell a student
// their school does not exist because a connection dropped.
func Resolve(store *Store) web.Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			school, err := store.ByHost(r.Context(), r.Host)

			if errors.Is(err, ErrUnknownHost) {
				web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no school answers at this address")
				return
			}
			if err != nil {
				web.LoggerFrom(r.Context()).Error("resolving the school", "error", err, "host", r.Host)
				web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not tell which school this is")
				return
			}

			next.ServeHTTP(w, r.WithContext(with(r.Context(), school)))
		})
	}
}

// Handler serves what a school says about itself. It is the smallest possible
// school-scoped route, and it exists as much to prove the resolution end to
// end as to be useful — though it is useful: the app reads its name, its accent
// colour, its own address and what a subscription costs from here before it
// paints anything.
type Handler struct {
	// passMark is the share of an exam a student has to reach, in whole percent.
	//
	// IT IS HANDED IN RATHER THAN IMPORTED, because `exam` owns it and a module
	// may not import another module (X-02). `cmd/api` is the one line that says
	// the two are the same number.
	//
	// WHY A SCHOOL SAYS IT AT ALL. The interface prints "minimum to pass" on a
	// course card, before any exam has been started and so before any paper
	// exists to carry it. Until this field, it printed a `PASS_MARK = 70` of its
	// own — two copies of one decision, where moving the constant marks the exam
	// at the new number and describes it as the old one.
	//
	// AND IT IS A FUNCTION NOW, which is that same failure moved one process
	// further out. It was a constant read at start-up; `0046` made it a declared
	// parameter, so it can move on a console screen while this process runs —
	// and a number captured when this handler was built would have the card
	// printing one minimum while the exam applied another. All three fields here
	// are functions for that reason, arrived at from three directions.
	passMark func(ctx context.Context) int

	// instalments is the most parts a card sale may be split into.
	//
	// HANDED IN FOR passMark's REASON EXACTLY: `billing` owns it and a module may
	// not import another module (X-02), so `cmd/api` is the one line saying that
	// this and `billing.MostInstalments` are the same number.
	//
	// WHY THE SCREEN IS TOLD RATHER THAN KNOWING. The subscribe screen draws one
	// option per instalment and had the count written into it — so the day the
	// policy moved, the browser would offer a split the server refuses, which is
	// a form that fails after somebody has already chosen. That is the failure
	// `passMark` above was introduced to end, on a different number.
	//
	// AND IT IS A FUNCTION RATHER THAN A NUMBER, because the day the policy
	// moves is a Tuesday afternoon on a console screen and not a deployment. A
	// number read once at start-up would make this the copy that is stale — the
	// same failure as the browser's, one process further in.
	instalments func(ctx context.Context) int

	/* pixDiscount is what a Pix payment takes off, in basis points.

	   HANDED IN LIKE THE OTHER TWO, and here for the reason the subscribe screen
	   wrote down and could not fix on its own: it held a copy of this number
	   with a comment saying it was a copy. The invitation now draws a Pix figure
	   too, so the copy would have become two — and two copies of a rate is a
	   rate that drifts, with the SERVER's number being the one charged and the
	   browser's being the one somebody read.

	   IT IS A FUNCTION, which is what `0045` changed here. The rate is a dated
	   series now, settable from the console, so a number captured when this
	   handler was constructed would be the number until the next deployment —
	   and the screen quoting it would drift from the checkout charging it, which
	   is exactly the drift this field exists to prevent. It takes a context so
	   the read belongs to the request.

	   ALL THREE OF THESE ARE FUNCTIONS, arrived at from three directions and one
	   at a time: this one because a rate is a dated series (`0045`), the two
	   above because they became declared parameters (`0046`). This comment
	   claimed to be the ONLY function twice on its way here, which is what a
	   field comment describing its neighbours costs — so it now says what the
	   three have in common instead: not one of them is settled when this handler
	   is built.

	   AN ERROR IS NO DISCOUNT, not a broken screen. The invitation without a
	   struck-through figure is the invitation this platform drew before there
	   was one; a school that could not be described because a rate could not be
	   read would be the worse answer. */
	pixDiscount func(ctx context.Context) int

	offer Offer
}

/*
Offer is what can be bought, wired in by `cmd`.

	IT IS A FUNCTION TYPE because `billing` owns the prices and this package may
	not import it — the same seam every other pair of modules here uses. A nil
	one is a deployment that sells nothing, which draws the invitation without a
	figure rather than failing.
*/
type Offer func(ctx context.Context) ([]Plan, error)

// Plan is one thing somebody can buy. It is `planBody`'s twin without the
// tags, so that the wire format is this package's business and the seam is not.
type Plan struct {
	TermMonths int
	Cents      int
	Currency   string
}

func NewHandler(passMark, instalments, pixDiscount func(ctx context.Context) int,
	offer Offer) *Handler {

	return &Handler{
		passMark: passMark, instalments: instalments,
		pixDiscount: pixDiscount, offer: offer,
	}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/school", h.school)
}

/*
THE THREE READERS BELOW ALL GUARD A NIL, AND EACH ANSWERS DIFFERENTLY.

	None of the three is a value any more, so each can be un-wired — and what an
	un-wired one should say is not the same question three times. It is the SAFE
	end of a wiring mistake in each case, and safe points in a different
	direction for each: no discount, a card paid in full, an exam nobody passes
	by accident.

	The guards were not written together. `mostInstalments` had one from the
	day it became a function; `pixOff` did not, and called through — a
	deployment that forgot to wire it would have panicked on the one route
	every storefront asks for. Two branches in flight at once, neither wrong
	alone. This block exists so the third one could not repeat it.
*/

/*
theMark is what a course card prints as the minimum to pass.

	AN UNWIRED HANDLER SAYS 100 rather than nothing, because the wire format has
	no way to say nothing: `passMark` is deliberately not `omitempty`, since a
	screen reading a missing key as "no minimum" would tell a student an exam is
	passed by answering nothing. A hundred is the safe end — an exam nobody
	passes by accident — and it is visibly wrong on the card rather than
	quietly permissive.
*/
func (h *Handler) theMark(ctx context.Context) int {
	if h.passMark == nil {
		return 100
	}
	if mark := h.passMark(ctx); mark > 0 {
		return mark
	}
	return 100
}

/*
pixOff is what the storefront is told a Pix takes off, in basis points.

	AN UNWIRED HANDLER SAYS ZERO, which is a real answer — a platform that has
	stopped discounting Pix — and it is the one this field's own comment already
	promises: an invitation without a struck-through figure is the invitation
	this platform drew before there was a discount.
*/
func (h *Handler) pixOff(ctx context.Context) int {
	if h.pixDiscount == nil {
		return 0
	}
	if off := h.pixDiscount(ctx); off > 0 {
		return off
	}
	return 0
}

/*
mostInstalments is what the storefront is told a card sale splits into.

	AN UNWIRED HANDLER SAYS ONE, not zero. Zero would have the
	subscribe screen draw an empty picker and the invitation quote a payment in
	no parts; one is a card paid in full, which is a thing this platform sells
	and the honest floor. It is a wiring mistake either way, and this is the
	version of it a buyer can still use.
*/
func (h *Handler) mostInstalments(ctx context.Context) int {
	if h.instalments == nil {
		return 1
	}
	if got := h.instalments(ctx); got >= 1 {
		return got
	}
	return 1
}

type schoolBody struct {
	Slug   string `json:"slug"`
	Name   string `json:"name"`
	Accent string `json:"accent"`
	// Absent rather than empty: the interface draws the link only when there
	// is one, and `omitempty` is that rule said once instead of on both sides.
	Site string `json:"site,omitempty"`

	/* WHAT CAN BE BOUGHT, ONE ENTRY PER TERM.

	   It was two fields and one number, which was the whole offer while the
	   platform sold one thing. It is a LIST because it now sells up to three —
	   a year, two years, and a month abroad — and a screen that has to show a
	   choice cannot be given a single figure.

	   `omitempty`, so nothing priced sends no key at all rather than an empty
	   array: the interface draws the invitation without a figure, which is what
	   it already did for a school with no price, and a made-up number is worse
	   than no number.

	   THE ORDER IS THE SERVER'S. Shortest term first, because that is how a
	   list of options reads and because leaving it to five interfaces to sort
	   is five chances to sort it differently. */
	Plans []planBody `json:"plans,omitempty"`

	// What an exam has to reach here, in whole percent. NOT `omitempty`: zero is
	// not a pass mark anybody set, and a screen that read a missing field as
	// "no minimum" would say an exam is passed by answering nothing.
	PassMark int `json:"passMark"`

	// The most parts a card sale may be split into. NOT `omitempty` for
	// `passMark`'s reason: zero is not a policy anybody set, and a screen
	// reading a missing key as "no limit" would draw a picker the server
	// refuses at every option but the first.
	Instalments int `json:"instalments"`

	// What Pix takes off, in basis points. NOT `omitempty` for the same reason
	// as the two above: zero is a real answer — a platform that has stopped
	// discounting Pix — and it has to be distinguishable from a field the
	// interface failed to read.
	PixDiscount int `json:"pixDiscount"`
}

// planBody is one thing somebody can buy.
type planBody struct {
	TermMonths int    `json:"termMonths"`
	Cents      int    `json:"cents"`
	Currency   string `json:"currency"`
}

func (h *Handler) school(w http.ResponseWriter, r *http.Request) {
	school, ok := FromContext(r.Context())
	if !ok {
		/* Only reachable by mounting this route outside the middleware, which
		   is a programming mistake rather than a request the client got wrong.
		   It says so instead of pretending. */
		web.LoggerFrom(r.Context()).Error("a school-scoped route ran without a school in the context", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return
	}

	/* THE OFFER IS ASKED FOR HERE AND NOWHERE ELSE, which is the point of it no
	   longer being on the school. This route is one request per page load; the
	   school itself is resolved on every request there is.

	   AN OFFER THAT COULD NOT BE READ IS NOT A FAILED PAGE. The rest of this
	   answer is what the interface needs to draw a school at all — its name, its
	   colour, its pass mark — and refusing all of it because a price list was
	   unavailable would take the platform down to protect a figure. It is logged
	   and the invitation goes out without a number, which is exactly what it
	   does for a platform that has priced nothing. */
	var plans []planBody
	if h.offer != nil {
		found, err := h.offer(r.Context())
		if err != nil {
			web.LoggerFrom(r.Context()).Error("reading what can be bought", "error", err)
		}
		for _, one := range found {
			plans = append(plans, planBody(one))
		}
	}

	web.JSON(w, http.StatusOK, schoolBody{
		Slug: school.Slug, Name: school.Name, Accent: school.Accent, Site: school.Site,
		Plans:       plans,
		PassMark:    h.theMark(r.Context()),
		Instalments: h.mostInstalments(r.Context()),
		PixDiscount: h.pixOff(r.Context()),
	})
}
