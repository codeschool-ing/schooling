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
	"time"

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

/* ---------- reading it back ---------- */

// ItemAnswered is the name of the event this module reads back for item
// analysis. It is a constant here and not a string in two places, because the
// reader and the writer agreeing is the whole contract.
const ItemAnswered = "exam.item.answered"

// ItemAnswer is one answer to one exam question, as the stream recorded it.
//
// EVERYTHING HERE CAME OFF THE EVENT AND NOTHING IS JOINED. The mark of the
// attempt is on the row because it was carried at emission — see where the
// event is written for why, and note that it is the same argument as the
// dimensions: a number joined afterwards answers with today's value.
type ItemAnswer struct {
	ExerciseID string
	Version    int
	Type       string
	AttemptID  string
	Correct    bool
	Score      int
	Of         int
	AnsweredAt time.Time
}

// ItemAnswers reads every answer to an exam question in one school since a
// moment.
//
// # WHY THIS IS HERE AND NOT IN THE MODULE THAT INTERPRETS IT
//
// This package is the stream everything is counted from, and reading rows out
// of it is its business. What those rows MEAN — the minimum sample, the groups,
// the thresholds, the word "inverted" — is a judgement, and it lives in
// `internal/analysis`, which never touches this table. The split is the same one
// the catalogue uses: it answers which door a plan opens and does not decide
// which plan somebody has.
//
// # A ROW PER ANSWER, NOT AN AGGREGATE
//
// Aggregating here would mean the group split — the 27% — living in this
// package, and then two places would have an opinion about what a strong
// student is. The volume is one row per question per exam anybody sits, and the
// caller is a job rather than a screen.
func (s *Store) ItemAnswers(ctx context.Context, tenantID uuid.UUID, since time.Time) ([]ItemAnswer, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT payload->>'exercise',
		       (payload->>'version')::int,
		       coalesce(payload->>'type', ''),
		       coalesce(payload->>'attempt', ''),
		       (payload->>'correct')::boolean,
		       coalesce((payload->>'score')::int, 0),
		       coalesce((payload->>'of')::int, 0),
		       occurred_at
		FROM events
		WHERE name = $1 AND tenant_id = $2 AND occurred_at >= $3
		  AND payload ? 'exercise' AND payload ? 'version' AND payload ? 'correct'
		ORDER BY occurred_at
	`, ItemAnswered, tenantID, since)
	if err != nil {
		return nil, fmt.Errorf("event: reading the answers to exam questions: %w", err)
	}
	defer rows.Close()

	var out []ItemAnswer
	for rows.Next() {
		var a ItemAnswer
		if err := rows.Scan(&a.ExerciseID, &a.Version, &a.Type, &a.AttemptID,
			&a.Correct, &a.Score, &a.Of, &a.AnsweredAt); err != nil {
			return nil, fmt.Errorf("event: reading the answers to exam questions: %w", err)
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

// Schools answers every school that has any event at all, which is how a job
// that runs over all of them knows where to look without importing the module
// that owns schools.
func (s *Store) Schools(ctx context.Context) ([]uuid.UUID, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT DISTINCT tenant_id FROM events WHERE tenant_id IS NOT NULL ORDER BY tenant_id`)
	if err != nil {
		return nil, fmt.Errorf("event: reading which schools have any history: %w", err)
	}
	defer rows.Close()

	var out []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("event: reading which schools have any history: %w", err)
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

// Reach is one person having reached one step, once. The stream is deduplicated
// here rather than in the reader: a funnel asks how many people got this far,
// and somebody who opened forty lessons is one of them.
type Reach struct {
	Name      string
	VisitorID *uuid.UUID
	AccountID *uuid.UUID
}

// Reached answers, for each named step, which identities reached it in one
// school since a moment.
//
// # BOTH IDENTITIES COME BACK, AND NEITHER IS RESOLVED HERE
//
// An arrival has only a visitor; a completion has an account and usually a
// visitor too. Folding those into one person is what makes the top and the
// bottom of a funnel count the same thing — and it needs the link between a
// visitor and an account, which belongs to another module. So this hands over
// what the stream says and the caller decides who is who.
//
// # THE STEP NAMES ARE THE CALLER'S
//
// This package does not know what a funnel is or which events are in one. It is
// given the names and counts them, which is the same split as everywhere else
// here: the stream reports and something else interprets.
func (s *Store) Reached(ctx context.Context, tenantID uuid.UUID,
	names []string, since time.Time) ([]Reach, error) {

	if len(names) == 0 {
		return nil, nil
	}

	rows, err := s.pool.Query(ctx, `
		SELECT DISTINCT name, visitor_id, account_id
		FROM events
		WHERE name = ANY($1) AND tenant_id = $2 AND occurred_at >= $3
	`, names, tenantID, since)
	if err != nil {
		return nil, fmt.Errorf("event: reading who reached each step: %w", err)
	}
	defer rows.Close()

	var out []Reach
	for rows.Next() {
		var r Reach
		if err := rows.Scan(&r.Name, &r.VisitorID, &r.AccountID); err != nil {
			return nil, fmt.Errorf("event: reading who reached each step: %w", err)
		}
		out = append(out, r)
	}
	return out, rows.Err()
}
