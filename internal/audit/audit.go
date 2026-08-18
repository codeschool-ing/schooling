// Package audit records who did what, and refuses to record an action with
// nobody against it.
//
// TWO PEOPLE OPERATE THIS SYSTEM. That is the whole argument. An entry that
// cannot say which of them changed a student's plan is a log, not an audit, and
// the difference only becomes visible on the day somebody needs it — by which
// time the entries that were written without an actor cannot grow one.
//
// It is append-only in the database, by trigger, and there is no Update and no
// Delete here to match. A correction is a new entry.
package audit

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// The kinds of actor. Not an open field: an audit whose actor kinds are
// free text sprouts a fourth spelling of "system" and the entries stop
// grouping.
const (
	KindStaff  = "staff"
	KindSystem = "system"
)

// systemActor is the one uuid the platform itself acts under. It is written
// here rather than generated so that a year of entries share it, and it is not
// the nil uuid — nil is what an uninitialised variable looks like, and the
// point of this package is telling those apart.
var systemActor = uuid.MustParse("00000000-0000-4000-8000-000000000001")

// Actor is who took the action. Unexported fields, and two constructors: an
// entry cannot be assembled with the actor left out, because there is no way to
// write one down that does not name somebody.
type Actor struct {
	id    uuid.UUID
	kind  string
	label string
}

// Staff is a person. The label is their name AT THE TIME, copied in rather than
// joined later: people are renamed and people leave, and an entry that reads
// "changed a plan, actor 9f2c…" a year afterwards is not an answer.
func Staff(id uuid.UUID, label string) Actor {
	return Actor{id: id, kind: KindStaff, label: label}
}

// System is the platform acting on its own — a scheduled job, a webhook, a
// retry. It is a real actor and not an absent one, which is precisely why it
// has a name of its own rather than an empty column.
func System(label string) Actor {
	return Actor{id: systemActor, kind: KindSystem, label: label}
}

func (a Actor) valid() bool {
	return a.id != uuid.Nil && a.label != "" && (a.kind == KindStaff || a.kind == KindSystem)
}

// Entry is one administrative action.
type Entry struct {
	Actor  Actor
	Action string

	// What was acted upon. The kind is a word like "account" or "price"; the id
	// is text rather than a uuid because subjects are not all uuids — a plan is
	// named, a price is a currency and a region.
	SubjectKind string
	SubjectID   string

	// Null on a creation and a deletion respectively, which is how "did not
	// change" is told apart from "was not there".
	Before any
	After  any

	// Absent for a platform-wide action, which is a real thing an owner does.
	TenantID *uuid.UUID

	Reason    string
	RequestID string
}

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// Record writes one entry, and refuses one with no actor.
//
// THE REFUSAL IS AN ERROR AND NOT A DEFAULT. Filling in "system" for an entry
// whose caller forgot would produce an audit that reads plausibly and is wrong,
// and an audit that is wrong in a readable way is worse than one that is
// missing rows: the missing rows are noticed.
func (s *Store) Record(ctx context.Context, e Entry) error {
	if !e.Actor.valid() {
		return errors.New("audit: an entry with no actor is a log, not an audit — " +
			"build one with audit.Staff or audit.System")
	}
	if e.Action == "" || e.SubjectKind == "" {
		return errors.New("audit: an entry needs an action and a kind of subject")
	}

	before, err := encode(e.Before)
	if err != nil {
		return fmt.Errorf("audit: the before state of %s: %w", e.Action, err)
	}
	after, err := encode(e.After)
	if err != nil {
		return fmt.Errorf("audit: the after state of %s: %w", e.Action, err)
	}

	_, err = s.pool.Exec(ctx, `
		INSERT INTO audit_log
			(actor_id, actor_kind, actor_label, tenant_id, action,
			 subject_kind, subject_id, before, after, reason, request_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`, e.Actor.id, e.Actor.kind, e.Actor.label, e.TenantID, e.Action,
		e.SubjectKind, e.SubjectID, before, after, e.Reason, e.RequestID)
	if err != nil {
		return fmt.Errorf("audit: recording %s: %w", e.Action, err)
	}
	return nil
}

func encode(v any) ([]byte, error) {
	if v == nil {
		return nil, nil
	}
	return json.Marshal(v)
}
