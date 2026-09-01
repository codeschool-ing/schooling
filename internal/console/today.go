package console

import (
	"context"
	"fmt"
	"net/http"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* ==========================================================================
   What needs a person today.

   # THE QUESTION FOURTEEN SCREENS COULD NOT ANSWER

   Every screen here answers one question well and says its scope. None of them
   answers "what should I look at?", so opening this console cold meant already
   knowing which screen held the thing that was wrong — and the screens somebody
   opens are the ones they already suspect. The defect nobody suspects is the
   one that stays.

   # IT IS FINDINGS AND NOT FIGURES, WHICH IS THE WHOLE DESIGN

   A dashboard of numbers is a screen with no question, and this console's rule
   is that a screen says what it is about (K-18). "1,204 students" under no
   scope, no population and no date is exactly what that decision exists against
   — and there is nowhere on a tile to put the sentence the cohorts screen needs
   a paragraph for.

   So every line here is something that is TRUE and wants a person: a question
   still being asked that the analysis condemned, a night that did not run, a
   report nobody answered. On a platform where nothing is wrong this screen is
   empty, which is the right amount of information and the opposite of a wall of
   figures that always has something to look at.

   # EVERY FINDING IS A FACT AND ALMOST NONE OF THEM IS A THRESHOLD

   `granted and never used` is a fact. `no second factor` is a fact. `waiting to
   be answered` is a fact. Only the adrift run is a judgement, and its threshold
   is the one the jobs screen already draws and the store already decided —
   K-16, one layer along: a number that decided something appears beside the
   thing it decided, and never in two places with a chance to disagree.

   # AND IT ASKS THE SAME FUNCTIONS THE SCREENS ASK

   `Operators` and `Jobs` are the seams the staff and jobs screens are built on,
   passed in here unchanged. A home screen with its own idea of "has this person
   ever opened the console" would be a second definition of the same fact, and
   the two would disagree on exactly the row somebody is trying to understand.
   That is the mistake `personOf` is shared to avoid, one report over.

   # IT IS NOT AN ALARM AND SAYS SO

   K-08: alerts have to reach a phone when this console is down, which is when
   they matter. This is a screen somebody opens, and everything on it is true
   for as long as nobody acts on it — which is a different job from waking
   anybody up.
   ========================================================================== */

// Finding is one thing that is true and wants somebody.
type Finding struct {
	// Kind is what it is, in this console's own words, and it is what the
	// screen keys its wording off. A kind this interface does not know is drawn
	// as itself rather than folded into another, the way every closed list here
	// behaves.
	Kind string

	// Count is how many, and it is never zero: a finding that is not true is
	// not sent. "Nothing is wrong" is an empty list rather than a column of
	// zeroes, because a zero is a thing to read and this screen is for the
	// things that are not.
	Count int

	// Where is the section id the reader should go to, so every finding is one
	// click from the screen that owns it and can explain it.
	Where string
}

/*
Today is what the home screen reads.

	THE TWO COUNTS ARE THEIR OWN SEAMS AND THE OTHER TWO ARE NOT. `Condemned`
	and `Waiting` are questions no existing screen asks — they are across every
	school, where the screens are about one — so they arrive as functions this
	package names. `Operators` and `Jobs` already exist and are handed over as
	they are, because asking the same function is what stops two screens
	disagreeing about one fact.
*/
type Today struct {
	// Condemned is how many questions the analysis called inverted that are
	// still being given to students, across every school.
	Condemned func(ctx context.Context) (int, error)

	// Waiting is how many reports nobody has answered, across every school.
	Waiting func(ctx context.Context) (int, error)

	// Operators is the staff screen's own reader, unchanged.
	Operators Operators

	// Jobs is the jobs screen's own, unchanged.
	Jobs Jobs
}

type findingBody struct {
	Kind  string `json:"kind"`
	Count int    `json:"count"`

	// Empty for a finding about this screen rather than another, which the
	// interface draws as a sentence instead of a control.
	Where string `json:"where,omitempty"`
}

// TodayHandler answers the home screen. It reads and never writes, so it
// carries no audit seam and no second rank — every staff role may look, which
// is the same rule the aggregates are under.
type TodayHandler struct{ today Today }

func NewTodayHandler(today Today) *TodayHandler { return &TodayHandler{today: today} }

func (h *TodayHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/today", h.findings)
}

/*
findings gathers what is true right now.

	A READER THAT FAILS IS A FINDING OF ITS OWN AND NOT A DEAD SCREEN. Four
	questions are asked and any of them can fail; refusing the whole page
	because the jobs table was unreachable would hide the three findings that
	did arrive — on the one screen whose job is to say what is wrong. So a
	failure is carried as `unreadable`, which the screen draws as the finding it
	is: something here could not be checked, and the number beside it is not
	zero because nobody looked.
*/
func (h *TodayHandler) findings(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	log := web.LoggerFrom(ctx)

	var out []Finding
	var unreadable int

	add := func(kind, where string, n int) {
		if n > 0 {
			out = append(out, Finding{Kind: kind, Count: n, Where: where})
		}
	}

	ask := func(what string, of func(ctx context.Context) (int, error)) int {
		if of == nil {
			return 0
		}
		n, err := of(ctx)
		if err != nil {
			log.Error("reading what needs a person", "finding", what, "error", err)
			unreadable++
			return 0
		}
		return n
	}

	add("questions-still-asked", "questions", ask("questions", h.today.Condemned))
	add("reports-waiting", "reports", ask("reports", h.today.Waiting))

	people, err := h.operators(ctx)
	if err != nil {
		log.Error("reading what needs a person", "finding", "staff", "error", err)
		unreadable++
	} else {
		add("roles-without-a-second-factor", "staff", people.noFactor)
		add("roles-never-used", "staff", people.neverUsed)
	}

	jobs, err := h.jobs(ctx)
	if err != nil {
		log.Error("reading what needs a person", "finding", "jobs", "error", err)
		unreadable++
	} else {
		add("jobs-that-failed", "jobs", jobs.failed)
		add("jobs-adrift", "jobs", jobs.adrift)
		add("jobs-that-never-ran", "jobs", jobs.never)
	}

	add("could-not-be-checked", "", unreadable)

	/* THE JSON NAMES ARE A TYPE OF THEIR OWN, which is this package's shape for
	   every answer — `stepBody`, `cohortBody` — and the reason is what happened
	   without it: `Finding` went out as `Kind`, `Count` and `Where`, the screen
	   read `kind` and `count`, and every row drew "undefined — undefined". It
	   rendered perfectly and said nothing, which is the failure this whole
	   console is written against. Found by opening the screen.

	   THE CONVERSION IS SAFE BECAUSE THE COMPILER CHECKS IT, which is the
	   reason `stepBody` is written the same way one file over: the two types
	   having the same fields is what makes this one expression rather than
	   three, and the day they stop matching this line stops building rather
	   than quietly dropping a field. */
	body := make([]findingBody, 0, len(out))
	for _, one := range out {
		body = append(body, findingBody(one))
	}

	web.JSON(w, http.StatusOK, map[string]any{
		// EMPTY RATHER THAN NIL, so a quiet platform is an empty list and not a
		// field that failed to arrive — the distinction the funnel's `Measured`
		// makes, one screen along.
		"findings": body,

		/* AND WHAT THIS SCREEN IS NOT, said by the thing that knows. Somebody
		   looking at a console home reasonably expects it to tell them when
		   something breaks; K-08 says that cannot be this, and a screen which
		   let the expectation stand would be one people rely on at exactly the
		   wrong moment. */
		"not_an_alarm": "Everything here is true for as long as nobody acts on it. It is " +
			"not an alarm and cannot be: an alert has to reach a phone when this console " +
			"is down, which is exactly when it matters.",

		// WHY IT IS EMPTY, WHEN IT IS. An empty screen and a screen that failed
		// to load look identical, and this is the one place that would be read
		// as good news.
		"nothing_to_do": "Nothing on this platform is asking for a person right now. This " +
			"screen is empty when that is true, which is most days — it is the screens " +
			"under Measure that are worth opening when nothing is wrong.",
	})
}

type roster struct{ noFactor, neverUsed int }

/*
operators counts the two findings a roster carries.

	NEITHER IS A THRESHOLD. A role with no second factor opens nothing, which is
	a fact about the door. A role granted and never used is access nobody is
	missing — also a fact, and the row an access review exists to find.

	THE STAFF SCREEN'S NINETY DAYS IS DELIBERATELY NOT HERE. That number is a
	reading aid on a screen full of dates; here it would decide whether a line
	appears at all, which makes it a threshold that judges (K-16) rather than
	one that helps somebody read. `never` needs no number and is the stronger
	finding anyway.

	AND A REVOKED ROW IS NOT A FINDING. Somebody who left has no access to
	review; counting them would put a permanent number on this screen that no
	action can ever clear, which teaches people to ignore it.
*/
func (h *TodayHandler) operators(ctx context.Context) (roster, error) {
	if h.today.Operators == nil {
		return roster{}, nil
	}
	all, err := h.today.Operators(ctx)
	if err != nil {
		return roster{}, err
	}

	var out roster
	for _, one := range all {
		if one.RevokedAt != nil {
			continue
		}
		if !one.SecondFactor {
			out.noFactor++
		}
		if one.LastOpenedConsole == nil {
			out.neverUsed++
		}
	}
	return out, nil
}

type nights struct{ failed, adrift, never int }

/*
jobs counts what the scheduled work did last, one job at a time.

	THE LATEST RUN AND NOT THE HISTORY. "Did it work last night" is a question
	about the most recent attempt: a job that failed on Tuesday and has run
	every night since is a job that is fine, and a screen that counted failures
	would keep reporting Tuesday for ever.

	A JOB THAT HAS RECORDED NOTHING IS A FINDING AND NOT A ZERO. `Names` reads
	what has ever recorded a run, so a job that never has does not appear there
	at all — which is why the startable list is asked as well. A scheduled job
	with no runs is either newly deployed or a scheduler that never fired, and
	both want a person.
*/
func (h *TodayHandler) jobs(ctx context.Context) (nights, error) {
	var out nights
	if h.today.Jobs.Names == nil || h.today.Jobs.Latest == nil {
		return out, nil
	}

	ran, err := h.today.Jobs.Names(ctx)
	if err != nil {
		return out, err
	}

	seen := map[string]bool{}
	for _, name := range ran {
		seen[name] = true

		latest, err := h.today.Jobs.Latest(ctx, name, 1)
		if err != nil {
			return out, fmt.Errorf("reading the last run of %s: %w", name, err)
		}
		if len(latest) == 0 {
			continue
		}
		switch one := latest[0]; {
		case one.Adrift:
			out.adrift++
		case one.Outcome == "failed":
			out.failed++
		}
	}

	for _, name := range h.today.Jobs.Startable {
		if !seen[name] {
			out.never++
		}
	}
	return out, nil
}
