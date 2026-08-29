package console

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/codeschool-ing/schooling/internal/platform/setting"
	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/google/uuid"
)

/* The knobs, all of them, on one screen.

   # THIS IS THE TABLE `writes.go` OPENS BY REFUSING, AND THE REFUSAL WAS HALF
   RIGHT

   That file's first paragraph turns down "a `system_parameters` table — a name,
   a value, a screen that edits any row of it", on the grounds that a
   configuration surface grows to fill the space it is given and that a registry
   makes the next knob cost "one INSERT and no argument".

   The danger is real and the fence was in the wrong place. What K-13 protects is
   that a knob costs an ARGUMENT; three tables for three parameters delivered
   that by making the mechanism expensive, which works at three and stops working
   at fifteen — the cost of a migration per knob is paid by whoever is tired
   enough to stop writing the sentence, and the sentence was the point.

   So the cost moved onto the declaration. `internal/platform/setting` holds the
   closed set of names, each with its unit, its bounds, the value the code
   shipped with and the sentence saying what it decides; a name absent from it is
   refused here and ignored on the way out. Adding a knob still costs a
   declaration and an argument. It no longer costs a table.

   # WHY ONE ROUTE AND NOT ONE PER PARAMETER

   Because a route per parameter would put the closed set in two places — Go and
   the mux — and a set kept in two places is kept in one and a half. The route
   below takes the name in the path and hands it to the registry, which is the
   only thing that decides whether it exists.

   That is also why this file is short. It has no opinions about instalments or
   pass marks; every opinion lives beside the code that reads it, and this is the
   screen that shows them.

   # WHAT MAY NOT ARRIVE HERE

   Anything about ACCESS. Reads come from a snapshot that can be up to fifteen
   seconds old (see the package comment over there), so a value that decided who
   may open something would be a permission that lags — and K-15 keeps the
   paywall out of every parameter surface anyway, of which this is now the
   broadest.

   And anything whose wrong value is a WEAKENING rather than a preference: the
   minimum length of a password, the number of recovery codes, the cost of the
   hash. Those have right answers — the highest the platform can afford — and a
   settable minimum is a weakening with an interface on it. No test can catch
   that; the sentence a declaration carries is where somebody says it out loud,
   and a review is what reads it.
*/

/*
Knobs is the seam onto the registry and its rows.

	IT IS NOT CALLED `Settings` because this package already has one, and that
	one is the console's own host — what it cannot work out for itself. The wire
	says settings because that is what an operator calls them; the code says
	knobs because two types of one name in one package is a rename waiting to go
	wrong.
*/
type Knobs struct {
	// Now is every declared parameter with what it is set to, whether that is a
	// row or the fallback, and when it last moved.
	Now func(ctx context.Context) ([]setting.Current, error)

	// Set writes one and answers what was in force before it — the row when
	// there was one and the fallback when there was not, because that is what
	// the platform was actually doing and it is what the audit entry names.
	Set func(ctx context.Context, name string, value int) (was int, err error)

	// Refused is a write the caller can fix by sending a different value or a
	// different name: out of bounds, not a number, nothing declares it. It
	// travels as a predicate for the reason `Plan.Refused` does.
	Refused func(error) bool
}

// SettingsHandler reads and writes every parameter this platform has.
type SettingsHandler struct {
	knobs  Knobs
	record Record
	label  Label
	who    func(ctx context.Context) (uuid.UUID, bool)

	// maySet is the second rank, like every other parameter here. Read-only
	// opened the door; moving a number the whole platform behaves by is not a
	// thing a read-only role does.
	maySet func(ctx context.Context) bool
}

func NewSettingsHandler(knobs Knobs, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	maySet func(ctx context.Context) bool,
) *SettingsHandler {
	return &SettingsHandler{knobs: knobs,
		record: record, label: label, who: who, maySet: maySet}
}

func (h *SettingsHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/settings", h.list)
	mux.HandleFunc("PUT /console/api/v1/settings/{name}", h.set)
}

/*
list is every declaration and what it is set to.

	THE ARGUMENT TRAVELS WITH THE NUMBER. `Why` is on the wire and on the screen
	because an operator moving a value should be reading the case for it — that
	sentence is the whole cost of the knob existing, and a screen that showed
	only a box and a number would be spending it and throwing it away.

	SO DOES THE FENCE, so the form can refuse before the server does, and so the
	screen can say what the bound is rather than only that something was
	outside it.
*/
func (h *SettingsHandler) list(w http.ResponseWriter, r *http.Request) {
	found, err := h.knobs.Now(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the parameters", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read those")
		return
	}

	out := make([]map[string]any, 0, len(found))
	for _, one := range found {
		body := map[string]any{
			"name":     one.Name,
			"unit":     string(one.Unit),
			"least":    one.Least,
			"most":     one.Most,
			"fallback": one.Fallback,
			"why":      one.Why,
			"value":    one.Value,

			// WHETHER ANYBODY HAS EVER DECIDED THIS ONE. "Nobody has changed
			// this" and "somebody set it back to what it was" are different
			// facts, and only the second says the number on screen was chosen.
			"set": one.Set,
		}
		if !one.Since.IsZero() {
			body["since"] = one.Since
		}
		out = append(out, body)
	}
	web.JSON(w, http.StatusOK, map[string]any{"settings": out})
}

/*
set moves one parameter, and records it first.

	THE ENTRY IS WRITTEN BEFORE THE VALUE, like every write in this console: a
	change nobody can account for cannot happen quietly, and if the write then
	fails the history says something happened that did not — which the message
	names out loud rather than swallowing.

	THE REASON IS ASKED FOR. There is no dated series behind these — a parameter
	is one row per name, replaced — so the audit IS the history of what this
	platform was set to and why. The support address asks for the same sentence
	for the same reason; the price does not, and `plan.go` says there that it is
	the write which most deserves one.
*/
func (h *SettingsHandler) set(w http.ResponseWriter, r *http.Request) {
	if !h.maySet(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"changing what this platform is set to asks for an operator")
		return
	}

	name := strings.TrimSpace(r.PathValue("name"))

	var asked struct {
		// A NUMBER AND NOT A STRING on the wire, so "6 " and "six" are refused
		// by the decoder rather than by a parser this file would have to carry.
		// The column is text because the declaration knows the type; the API is
		// typed because the caller does too.
		Value  *int   `json:"value"`
		Reason string `json:"reason"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&asked); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return
	}
	if asked.Value == nil {
		web.Fail(w, http.StatusBadRequest, "no_value",
			"send the number to set it to. There is no way to unset a parameter here: what "+
				"that would mean is the fallback, and setting it to the fallback says so "+
				"where an empty box would not")
		return
	}
	reason := strings.TrimSpace(asked.Reason)
	if reason == "" {
		web.Fail(w, http.StatusBadRequest, "no_reason",
			"say why in a few words. A parameter is one row that is replaced, so this log is "+
				"the whole history of what the platform was set to — and a number that moved "+
				"because a fee table changed is a different fact from one that moved because "+
				"somebody was testing")
		return
	}

	actor, label, ok := acting(w, r, h.who, h.label)
	if !ok {
		return
	}

	// What it is now, so the entry can name both sides. An unknown name is
	// caught here rather than after an entry has been written for a change that
	// cannot happen.
	found, err := h.knobs.Now(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the parameters", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read those")
		return
	}
	before, declared := 0, false
	for _, one := range found {
		if one.Name == name {
			before, declared = one.Value, true
		}
	}
	if !declared {
		web.Fail(w, http.StatusNotFound, "unknown_parameter",
			"nothing declares that parameter. The set of them is closed in Go, beside the "+
				"code that reads each one — a name that is not there decides nothing, whatever "+
				"is written against it")
		return
	}

	if err := h.record(r.Context(), actor, label,
		"setting.changed",
		/* THE SUBJECT IS THE PLATFORM, NAMED BY THE PARAMETER. Every other
		   subject in this console is a school, a plan or somebody's account;
		   this one is the whole deployment, and the id is the parameter's name
		   so an entry is legible to somebody with neither this screen nor the
		   declaration in front of them. */
		Subject{Kind: "platform", ID: name},

		/* BOTH SIDES, AS NUMBERS AND NOT AS A ROW-OR-NOT. A parameter nobody has
		   ever set is answering its fallback, which is what the platform was
		   ACTUALLY doing — an entry reading "nothing → 6" would be naming the
		   absence of a row rather than the behaviour that changed. */
		Changed{Before: strconv.Itoa(before), After: strconv.Itoa(*asked.Value)},
		reason,
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a parameter change", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	was, err := h.knobs.Set(r.Context(), name, *asked.Value)
	switch {
	case h.knobs.Refused != nil && h.knobs.Refused(err):
		web.Fail(w, http.StatusBadRequest, "refused", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("setting a parameter", "error", err, "parameter", name)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}

	if was != before {
		// Somebody else moved it between the read and the write, so the entry
		// above names a `before` that was already gone. This is the line that
		// says where to look — the same warning every other write here raises.
		web.LoggerFrom(r.Context()).Warn("a parameter moved under a change",
			"parameter", name, "recorded_before", before, "actually_was", was)
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"name":  name,
		"value": *asked.Value,
		"was":   was,
	})
}
