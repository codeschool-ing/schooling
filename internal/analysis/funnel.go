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
// Two of the eight cannot be emitted today: verifying an address, because
// nothing writes `email_verified_at`, and subscribing, because nothing creates
// a subscription until there is a gateway. Reported as zero they would read as
// everybody dropping out — the same mistake as a discrimination index of zero
// that was never measured. They come back saying no event exists yet, and a
// screen has to show that differently from a drop.

// Step is one step of the funnel, with what it is counted from.
type Step struct {
	// Event is the name in the stream, or empty when nothing emits this step.
	Event string

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

// Reached is one identity having reached one step, defined here and satisfied
// by the module that owns the stream.
type Reached func(ctx context.Context, tenantID uuid.UUID,
	names []string, since time.Time) ([]Reach, error)

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
	{
		Label: "Verified the address",
		Why: "nothing writes `email_verified_at` yet, so there is no event to count. " +
			"This is a missing feature and not a step nobody reaches",
	},
	{Event: "track.opened", Label: "Chose a track"},
	{Event: "lesson.opened", Label: "Opened the first lesson"},
	{Event: "section.completed", Label: "Finished the first section"},
	{Event: "course.completed", Label: "Finished the free course"},
	{
		Label: "Subscribed",
		Why: "nothing creates a subscription until there is a payment gateway, so there " +
			"is no event to count. A missing feature and not a step nobody reaches",
	},
}

// Funnel answers how many people reached each step in one school.
func (s *Store) Funnel(ctx context.Context, tenantID uuid.UUID, since time.Time) ([]Step, error) {
	if s.reached == nil || s.links == nil {
		return nil, fmt.Errorf("analysis: this store was built without the stream to read")
	}

	var names []string
	for _, step := range steps {
		if step.Event != "" {
			names = append(names, step.Event)
		}
	}

	reaches, err := s.reached(ctx, tenantID, names, since)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading who reached each step: %w", err)
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
