// Package event is the stream everything is counted from.
//
// STATISTICS COME FROM HERE AND NEVER FROM CURRENT STATE, because current state
// has been overwritten. "How many students finished this course last March" is
// not a question the courses table can answer, and it stops being answerable
// the first time somebody unpublishes one.
//
// # THE DIMENSIONS ARE CARRIED, NOT JOINED
//
// Every event copies the plan, the school, the country and the locale at the
// moment it happens. Storing only an account id and joining later gives the
// plan they are on TODAY, so "which plan were they on when they finished this"
// answers with the wrong number rather than with an error — which is worse,
// because nobody notices.
//
// That is why Dimensions has no exported fields and cannot be built by naming
// the ones you remembered. It comes from ForSchool or ForPlatform, both of
// which take every dimension as an argument, so a dimension added later breaks
// every call site instead of silently defaulting to blank in all of them.
package event

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// The words for a dimension that has no value, as opposed to one nobody
// supplied. The database refuses an empty string, so a caller that does not
// know has to say so — and a report can then tell "no plan" from "we lost it".
const (
	PlanNone = "none"    // a visitor, or an account without a subscription
	Unknown  = "unknown" // genuinely not known: Cloud Run passes no country header
)

// Dimensions are what every event carries about the world at the moment it
// happened. The fields are unexported on purpose: see the package comment.
type Dimensions struct {
	tenantID   *uuid.UUID
	schoolSlug string
	plan       string
	country    string
	locale     string
}

// ForSchool is the usual case: something happened inside one school.
func ForSchool(tenantID uuid.UUID, schoolSlug, plan, country, locale string) Dimensions {
	return Dimensions{
		tenantID:   &tenantID,
		schoolSlug: schoolSlug,
		plan:       plan,
		country:    country,
		locale:     locale,
	}
}

// ForPlatform is the other case, and it is real rather than a fallback: a visit
// to the platform's own address, or a subscription, belongs to no school. It
// takes no slug, so "which school" cannot be answered with a guess.
func ForPlatform(plan, country, locale string) Dimensions {
	return Dimensions{plan: plan, country: country, locale: locale}
}

func (d Dimensions) validate() error {
	var problems []error
	if d.tenantID != nil && d.schoolSlug == "" {
		problems = append(problems, errors.New("a school event carries the slug as well as the id"))
	}
	if d.tenantID == nil && d.schoolSlug != "" {
		problems = append(problems, errors.New("a platform event names no school"))
	}
	for _, f := range []struct{ name, value string }{
		{"plan", d.plan}, {"country", d.country}, {"locale", d.locale},
	} {
		if f.value == "" {
			problems = append(problems, fmt.Errorf(
				"%s is empty — say %q or %q rather than nothing, so a report can tell "+
					"an absent value from a lost one", f.name, PlanNone, Unknown))
		}
	}
	return errors.Join(problems...)
}

// Event is one thing that happened.
type Event struct {
	Name       string
	Dimensions Dimensions

	// Both optional and both meaningful: a visitor with no account has not
	// signed up, and an account with no visitor is a server-side event.
	VisitorID *uuid.UUID
	AccountID *uuid.UUID

	// Whatever else this kind of event is about. It is deliberately loose —
	// the dimensions are the part that has to be uniform, and forcing a column
	// per event type is how an event stream stops being written to.
	Payload any

	RequestID string
}

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// Emit writes one event.
//
// It returns an error and does not swallow one, but a caller counting something
// should think hard before failing a student's request over it: the answer is
// usually to log and carry on. That is the caller's decision to make, which is
// why it is not made here.
func (s *Store) Emit(ctx context.Context, e Event) error {
	if e.Name == "" {
		return errors.New("event: an event with no name cannot be counted")
	}
	if err := e.Dimensions.validate(); err != nil {
		return fmt.Errorf("event %q: %w", e.Name, err)
	}

	payload := []byte("{}")
	if e.Payload != nil {
		var err error
		if payload, err = json.Marshal(e.Payload); err != nil {
			return fmt.Errorf("event %q: encoding the payload: %w", e.Name, err)
		}
	}

	_, err := s.pool.Exec(ctx, `
		INSERT INTO events
			(name, visitor_id, account_id, tenant_id, school_slug, plan, country, locale, payload, request_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`, e.Name, e.VisitorID, e.AccountID,
		e.Dimensions.tenantID, e.Dimensions.schoolSlug,
		e.Dimensions.plan, e.Dimensions.country, e.Dimensions.locale,
		payload, e.RequestID)
	if err != nil {
		return fmt.Errorf("event %q: writing it: %w", e.Name, err)
	}
	return nil
}
