package audit

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

/* Reading the history back.

   THE WRITE SIDE HAS EXISTED SINCE PHASE 0 AND THE READ SIDE HAS NOT, which
   means every entry this system has ever written could only be reached with a
   SQL client pointed at production. That is the same shape as the export and
   the erasure before the console had a screen for them: the power existed, and
   the only way to use it was the way with no gate and no record.

   # ONLY WHAT AN INDEX ALREADY SORTS (K-21)

   `audit_log` carries four indexes, and this file asks for exactly three of the
   four shapes they cover:

       audit_log_by_time    (occurred_at DESC)                     recent first
       audit_log_by_actor   (actor_id, occurred_at DESC)           one person's doing
       audit_log_by_subject (subject_kind, subject_id, occurred_at DESC)
                                                                   done to one thing
       audit_log_by_school  (tenant_id, occurred_at DESC)          not asked for yet

   The fourth is left unasked deliberately. It is not that filtering by school
   would be slow — it is the one index here with no screen behind it, and a
   parameter nothing sends is a parameter nobody maintains. It goes in the day a
   screen declares that scope.

   WHAT IS NOT HERE IS THE EXPENSIVE HALF: no free text through `before` and
   `after`, no totals, no filter on `action` without a time bound. Each of those
   is a sequential scan of a table that only grows, and the day one is genuinely
   needed it becomes an index or a rollup — decided then, on a real question,
   rather than guessed at now.

   # PAGING BY THE ROW AND NOT BY THE OFFSET

   `OFFSET 400` reads four hundred rows to throw them away, and — worse for an
   append-only table read newest-first — an entry written between two pages
   shifts every row after it, so a reader paging down sees one twice and misses
   another. The cursor is the last row itself, which cannot drift. */

// Row is one entry as it is read back, which is not `Entry` as it is written.
//
// The write side takes `any` for the two states and an `Actor` whose fields are
// unexported, because it is refusing to build an entry with nobody against it.
// Nothing is being refused here — the row exists — so this is a plain record of
// what the table holds.
type Row struct {
	ID         int64
	OccurredAt time.Time

	ActorID    uuid.UUID
	ActorKind  string
	ActorLabel string

	Action      string
	SubjectKind string
	SubjectID   string

	// Absent for a platform-wide action.
	TenantID *uuid.UUID

	Reason    string
	RequestID string

	// Raw JSON, decoded by whoever is showing it. They are omitted by `Recent`
	// and filled in by `One`: see the comment there.
	Before json.RawMessage
	After  json.RawMessage
}

// Cursor is the row a page continues after — the pair the ordering is on, so
// that two entries sharing a timestamp cannot hide each other.
type Cursor struct {
	At time.Time
	ID int64
}

// Query is what a page asks for. The zero value is "the most recent entries,
// whoever wrote them, about whatever".
type Query struct {
	// ActorID selects one person's doing.
	ActorID *uuid.UUID

	// SubjectKind and SubjectID select everything done to one thing. They are
	// used together or not at all: the index leads with the kind, so a subject
	// id without one would be a scan.
	SubjectKind string
	SubjectID   string

	After *Cursor
	Limit int
}

// ErrHalfASubject is a subject id with no kind or a kind with no id.
var ErrHalfASubject = errors.New("audit: a subject is a kind and an id, or neither")

const (
	defaultLimit = 50
	maxLimit     = 100
)

// Recent answers one page, newest first, and never carries `before` or `after`.
//
// THE TWO STATES ARE THE PERSONAL DATA IN THIS TABLE. `actor_label` is a
// name — the table is classified `identifying` because of it — and `before` and
// `after` are whatever the action was about, which for an account is an address
// and a name. A list that carried fifty of those would hand a browser fifty
// people's details to render six words of each.
//
// So the list is metadata and one entry at a time is the whole thing, which is
// the same shape as the personal-data screen: counts on the list, contents only
// when somebody asks for exactly one.
func (s *Store) Recent(ctx context.Context, q Query) ([]Row, error) {
	if (q.SubjectKind == "") != (q.SubjectID == "") {
		return nil, ErrHalfASubject
	}

	limit := q.Limit
	if limit <= 0 {
		limit = defaultLimit
	}
	if limit > maxLimit {
		limit = maxLimit
	}

	/* ONE STATEMENT WITH THREE OPTIONAL HALVES, and the nulls are what make it
	   one. Written as string concatenation this would be four query texts, four
	   plans and four places for a filter to be forgotten; written like this the
	   planner still reaches the right index, because a null parameter makes its
	   clause constant-true and the remaining one leads. */
	rows, err := s.pool.Query(ctx, `
		SELECT id, occurred_at, actor_id, actor_kind, actor_label,
		       action, subject_kind, subject_id, tenant_id, reason, request_id
		  FROM audit_log
		 WHERE ($1::uuid IS NULL OR actor_id = $1)
		   AND ($2::text IS NULL OR (subject_kind = $2 AND subject_id = $3))
		   AND ($4::timestamptz IS NULL OR (occurred_at, id) < ($4, $5))
		 ORDER BY occurred_at DESC, id DESC
		 LIMIT $6
	`, q.ActorID, nullable(q.SubjectKind), q.SubjectID,
		cursorAt(q.After), cursorID(q.After), limit)
	if err != nil {
		return nil, fmt.Errorf("audit: reading the history: %w", err)
	}
	defer rows.Close()

	out := make([]Row, 0, limit)
	for rows.Next() {
		var r Row
		if err := rows.Scan(&r.ID, &r.OccurredAt, &r.ActorID, &r.ActorKind, &r.ActorLabel,
			&r.Action, &r.SubjectKind, &r.SubjectID, &r.TenantID, &r.Reason, &r.RequestID); err != nil {
			return nil, fmt.Errorf("audit: reading an entry: %w", err)
		}
		out = append(out, r)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("audit: reading the history: %w", err)
	}
	return out, nil
}

// ErrNoEntry is an id that is not in the table. History does not grow entries
// afterwards and does not lose them either, so this means the id is wrong.
var ErrNoEntry = errors.New("audit: no such entry")

// One answers a single entry, with what the value was before and after.
func (s *Store) One(ctx context.Context, id int64) (Row, error) {
	var r Row
	err := s.pool.QueryRow(ctx, `
		SELECT id, occurred_at, actor_id, actor_kind, actor_label,
		       action, subject_kind, subject_id, tenant_id, reason, request_id,
		       before, after
		  FROM audit_log
		 WHERE id = $1
	`, id).Scan(&r.ID, &r.OccurredAt, &r.ActorID, &r.ActorKind, &r.ActorLabel,
		&r.Action, &r.SubjectKind, &r.SubjectID, &r.TenantID, &r.Reason, &r.RequestID,
		&r.Before, &r.After)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return Row{}, ErrNoEntry
	case err != nil:
		return Row{}, fmt.Errorf("audit: reading entry %d: %w", id, err)
	}
	return r, nil
}

func nullable(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func cursorAt(c *Cursor) *time.Time {
	if c == nil {
		return nil
	}
	return &c.At
}

func cursorID(c *Cursor) int64 {
	if c == nil {
		return 0
	}
	return c.ID
}
