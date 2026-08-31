package analysis

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// The funnel: of the people who arrived, how many got to each step.
//
// # THE ONE THING THAT MAKES IT HARD
//
// The top of the funnel is browsers and the bottom is accounts. Somebody
// arrives with no account and subscribes with one, so counting the two halves
// by the identity each event happens to carry would compare different
// populations and call the result a conversion rate.
//
// So a PERSON is defined once, here: an account if the identity is linked to
// one, and the visitor otherwise. That is what `account_visitors` is for, and
// it is the reason the visitor has an identity before the account exists at all
// (K-10).
//
// # A STEP WITH NO EVENT IS NOT A STEP WITH NOBODY
//
// ONE of the eight cannot be emitted today: subscribing, because nothing
// creates a subscription until there is a gateway. Reported as zero it would
// read as everybody dropping out — the same mistake as a discrimination index
// of zero that was never measured. It comes back saying no event exists yet,
// and a screen has to show that differently from a drop.
//
// Verifying an address was the second until `account.confirmed` started being
// emitted. It is measured now, and `cmd/seed` emits it too — a step named here
// that the seeder does not produce would put a cliff in every seeded funnel,
// which is this same mistake wearing different clothes.

// Step is one step of the funnel, with what it is counted from.
type Step struct {
	// Event is the name in the stream, or empty when nothing emits this step.
	Event string

	/* Platform says this step is not something that happens inside a school.

	   THERE IS EXACTLY ONE, AND IT IS NOT AN OVERSIGHT. One subscription covers
	   every school (N-02), so a subscription belongs to no school and its event
	   carries no tenant — `event.ForPlatform` says exactly that. Seven steps of
	   this funnel are things somebody did at a school and the eighth is not,
	   and flattening the difference would mean picking a school to attribute a
	   purchase to that was never about one.

	   WHAT THE STEP THEN MEANS is: of the people who arrived HERE, how many
	   went on to subscribe — anywhere. That is the honest reading and it is the
	   question somebody opens a funnel to ask. It also means somebody who
	   arrived at two schools and subscribed once is counted under both, which
	   is true rather than double-counted: each funnel is asking about its own
	   arrivals. It is the shape the countries screen already carries a sentence
	   about, and this screen now carries its own. */
	Platform bool

	// Label is what it is called on a screen, in English. The source language
	// is English and the key is the string (N-06).
	Label string

	// People is how many distinct people reached it.
	People int

	// Measured is false where nothing emits this step. It is a separate field
	// rather than `People == 0`, because "nobody got here" and "nothing counts
	// this" are different facts and a screen that showed them alike would
	// report a missing feature as a total drop-off.
	Measured bool

	// Why says what is missing, for a step that is not measured.
	Why string
}

// Counting says which population the funnel counts.
//
// IT IS THIS PACKAGE'S OWN WORD AND NOT THE STREAM'S. `internal/event` has a
// type of the same name with the same three values, and this one exists rather
// than importing it because a module may not import another module (X-02) —
// `cmd/api` is what says the two are the same, in one line, where the rest of
// the wiring already is.
//
// The duplication is small and it is the price of the boundary. What makes it
// safe is that BOTH sides fall back to `real` for anything they do not
// recognise: a value lost in translation narrows the population and never
// widens it into a report about people that quietly counts invented ones.
type Counting string

const (
	// CountingReal is people who came here on their own. The default, and what
	// a screen shows unless somebody asks otherwise.
	CountingReal Counting = "real"

	// CountingSeeded is the seeded population alone — what `cmd/seed` wrote.
	CountingSeeded Counting = "seeded"

	// CountingEverybody is both, for a screen that is showing a demonstration
	// and says on its face that it is.
	CountingEverybody Counting = "everybody"
)

// Reading answers whether a word is one of the three.
//
// THE FALLBACK IS SAFE AND THE REFUSAL IS HONEST, and they are different jobs.
// `Counting("everbody")` counts real people, which is the right thing for the
// SQL to do and the wrong thing for a screen to do quietly — the switch would
// say "including the seeded population" over a chart that excluded it. So a
// caller that took the word from a request refuses it here instead.
func Reading(word string) (Counting, bool) {
	switch Counting(word) {
	case CountingReal, CountingSeeded, CountingEverybody:
		return Counting(word), true
	default:
		return CountingReal, false
	}
}

// Reached is one identity having reached one step, defined here and satisfied
// by the module that owns the stream.
type Reached func(ctx context.Context, tenantID uuid.UUID,
	names []string, since time.Time, who Counting) ([]Reach, error)

/*
ReachedAnywhere is the same question asked of the events that belong to no
school.

	IT IS A SECOND READER AND NOT A NULLABLE TENANT ON THE FIRST. `Reached` takes
	a `uuid.UUID`, and the way to say "no school" through it would be
	`uuid.Nil` — a value that means "the zero school" as readily as it means
	"every school", at a call site where getting it wrong returns an empty
	answer rather than an error. Two functions cannot be confused for each
	other, and each one's SQL says plainly which rows it is about.

	IT IS STILL SCOPED BY THE PEOPLE, not by nothing. The funnel folds what
	comes back into the same set of identities as every other step, so a
	platform event only reaches a school's chart through somebody who arrived
	at that school. The query is wide; the reading is not.
*/
type ReachedAnywhere func(ctx context.Context,
	names []string, since time.Time, who Counting) ([]Reach, error)

// Reach is the stream's answer: a step, and whichever identities were on the
// event.
type Reach struct {
	Name      string
	VisitorID *uuid.UUID
	AccountID *uuid.UUID
}

// Links is the visitor-to-account map, from the module that owns it.
type Links func(ctx context.Context) (map[uuid.UUID]uuid.UUID, error)

// The eight steps, in order, and the event each is counted from.
//
// THE ORDER IS THE PRODUCT AND NOT THE DATA. It is written here rather than
// derived from what the stream happens to contain, so that a step nobody has
// reached still appears — a funnel that hid its empty steps would hide exactly
// the drop somebody is looking for.
var steps = []Step{
	{Event: "visitor.arrived", Label: "Arrived"},
	{Event: "account.created", Label: "Created an account"},
	/* CONFIRMING IS NOT A GATE, so this step can be HIGHER than the one below
	   it and that is not a bug. Registering signs a student in and nothing waits
	   on the address being proved — somebody who never opens the mail carries
	   straight on to a track. A reader who expects a funnel to fall at every
	   step will read the rise as broken, which is why it is written here rather
	   than left to be rediscovered.

	   What the step is worth is exactly that comparison: the gap between it and
	   "Chose a track" is how many people we cannot reach among the ones who are
	   actually studying. */
	{Event: "account.confirmed", Label: "Verified the address"},
	{Event: "track.opened", Label: "Chose a track"},
	{Event: "lesson.opened", Label: "Opened the first lesson"},
	{Event: "section.completed", Label: "Finished the first section"},
	{Event: "course.completed", Label: "Finished the free course"},
	/* AND THE EIGHTH IS MEASURED NOW, which it was not since this file existed.

	   What it used to say — "nothing creates a subscription until there is a
	   payment gateway" — stopped being true when phase 3 shipped and stayed on
	   the screen anyway, which is the quietest kind of wrong: a sentence that
	   explains an absence somebody would otherwise investigate. Billing has
	   created subscriptions for weeks; what did not exist was the event, and
	   `billing.EventStarted` is it.

	   IT COUNTS STARTING AND NOT PAYING. A renewal is a different name in the
	   stream on purpose — a funnel asks how many people got this far, once, and
	   a step that counted every payment would grow every year without one more
	   person ever reaching it.

	   THE NAME IS THIS PACKAGE'S OWN AND NOT `billing.EventStarted`, which is
	   X-02: modules do not import modules. It is the arrangement every other
	   step is already under — `section.completed` is written out in `progress`
	   where it is emitted and again in `cohort.go` where it is read — because a
	   name in an append-only stream is a contract with rows written years ago
	   rather than a variable one package owns. A rename reaching only one end
	   is a query that matches nothing and a report that says nobody ever
	   subscribed, so `TestTheStreamsNamesAreWrittenAtBothEnds` holds the pair. */
	{Event: SubscribedEvent, Label: "Subscribed", Platform: true},
}

// SubscribedEvent is the name this package reads the last step from. Its other
// end is `billing.EventStarted`; see the step above for why there are two.
const SubscribedEvent = "subscription.started"

// Funnel answers how many people reached each step in one school, over the
// population `who` names.
//
// THE POPULATION IS AN ARGUMENT AND NOT A DEFAULT BURIED IN THE SQL, because
// this report is the one place the seeded students are allowed to be counted —
// a screen showing a demonstration, which says so on its face. Everything that
// ACTS stays on `CountingReal` and has no way to ask for otherwise; see
// `event.Counting`, which this mirrors.
func (s *Store) Funnel(ctx context.Context, tenantID uuid.UUID, since time.Time,
	who Counting) ([]Step, error) {
	if s.reached == nil || s.anywhere == nil || s.links == nil {
		return nil, fmt.Errorf("analysis: this store was built without the stream to read")
	}

	/* TWO LISTS, BECAUSE THEY ARE TWO QUESTIONS. Seven of these steps happened
	   inside this school and the eighth did not belong to any — see `Platform`
	   on `Step`. Asking for all eight with a tenant would drop the eighth
	   silently, which is the failure this whole file is written against: a step
	   that reports zero where it should report a number, and looks like a
	   cliff. */
	var here, anywhere []string
	for _, step := range steps {
		switch {
		case step.Event == "":
		case step.Platform:
			anywhere = append(anywhere, step.Event)
		default:
			here = append(here, step.Event)
		}
	}

	reaches, err := s.reached(ctx, tenantID, here, since, who)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading who reached each step: %w", err)
	}

	beyond, err := s.anywhere(ctx, anywhere, since, who)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading who subscribed: %w", err)
	}

	links, err := s.links(ctx)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading which visitors belong to an account: %w", err)
	}

	// One set of people per step. A person can reach a step from several
	// browsers and on several days; the set is what makes them one.
	people := map[string]map[string]bool{}
	for _, r := range reaches {
		who := personOf(r, links)
		if who == "" {
			// An event with neither identity on it. It happened, and there is
			// nobody to count it for — dropping it is right, and counting it as
			// an anonymous person would inflate every step it appears in.
			continue
		}
		if people[r.Name] == nil {
			people[r.Name] = map[string]bool{}
		}
		people[r.Name][who] = true
	}

	/* WHO THIS SCHOOL HAS SEEN AT ALL, which is what makes the platform's
	   events into this school's number.

	   THE PLATFORM READ IS DELIBERATELY WIDE AND HAS TO BE NARROWED HERE. It
	   returns every subscription on the platform, because a subscription
	   carries no school to filter by — so folding it in with the rest, as the
	   first version of this did, would have put every subscriber on the
	   platform into every school's last step. Eight schools would each have
	   claimed the same conversions, and the number would have looked plausible
	   on all eight.

	   THE SET IS EVERY STEP AND NOT JUST THE FIRST. "Arrived" is the honest
	   denominator and it is also the event most likely to be missing — it is
	   emitted for a signed-out browser, before any account exists, and it is
	   the one a blocked script or a direct link never produces. Somebody whose
	   arrival was never recorded but who opened four lessons here is plainly
	   somebody this school has seen, and requiring the first step would drop
	   them from the last one while leaving them in the middle six. */
	seen := map[string]bool{}
	for _, step := range steps {
		if step.Event == "" || step.Platform {
			continue
		}
		for who := range people[step.Event] {
			seen[who] = true
		}
	}

	for _, r := range beyond {
		who := personOf(r, links)
		if who == "" || !seen[who] {
			continue
		}
		if people[r.Name] == nil {
			people[r.Name] = map[string]bool{}
		}
		people[r.Name][who] = true
	}

	out := make([]Step, 0, len(steps))
	for _, step := range steps {
		one := step
		if step.Event != "" {
			one.Measured = true
			one.People = len(people[step.Event])
		}
		out = append(out, one)
	}
	return out, nil
}

// personOf folds the two identities on an event into one person.
//
// AN ACCOUNT WINS OVER A VISITOR, ALWAYS. Somebody signed in on two browsers is
// one person, and the account is the identity that says so. A visitor linked to
// an account is that account even when the event carried no account id — which
// is the case that matters, because it is how an arrival on Monday and a
// subscription on Friday become the same person.
func personOf(r Reach, links map[uuid.UUID]uuid.UUID) string {
	if r.AccountID != nil {
		return "account:" + r.AccountID.String()
	}
	if r.VisitorID != nil {
		if account, linked := links[*r.VisitorID]; linked {
			return "account:" + account.String()
		}
		return "visitor:" + r.VisitorID.String()
	}
	return ""
}
