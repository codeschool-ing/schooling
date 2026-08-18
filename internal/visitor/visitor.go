// Package visitor gives somebody an identity before they have an account.
//
// THE FIRST STEP OF THE FUNNEL HAPPENS BEFORE A STUDENT EXISTS. "How many of
// the people who arrived became students" needs the person who arrived to have
// been identifiable at the time they arrived — not identified, identifiable:
// a uuid in a cookie, with no name attached to it. Issued at signup instead, it
// answers for nobody who came earlier, and that period stays unanswerable
// permanently.
//
// It is deliberately thin. A uuid, when it was first and last seen, and where
// it came from the FIRST time. Nothing here is a profile.
package visitor

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrUnknown is the answer for a cookie naming a visitor the database has never
// heard of — an old cookie after a restore, or one somebody typed. It is a
// state and not a failure: the caller issues a new identity.
var ErrUnknown = errors.New("visitor: no such visitor")

// FirstTouch is what is recorded once, on the first request, and never
// overwritten. The most recent referrer of somebody who has been studying for a
// month is the site itself, which answers nothing.
type FirstTouch struct {
	TenantID *uuid.UUID
	Path     string
	Referrer string

	Source   string
	Medium   string
	Campaign string

	Country string
	Locale  string
}

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// Create issues a new identity.
func (s *Store) Create(ctx context.Context, first FirstTouch) (uuid.UUID, error) {
	country, locale := first.Country, first.Locale
	if country == "" {
		country = "unknown"
	}
	if locale == "" {
		locale = "unknown"
	}

	var id uuid.UUID
	err := s.pool.QueryRow(ctx, `
		INSERT INTO visitors
			(first_tenant_id, first_path, first_referrer, utm_source, utm_medium, utm_campaign,
			 country, locale)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, first.TenantID, first.Path, first.Referrer,
		first.Source, first.Medium, first.Campaign, country, locale).Scan(&id)
	if err != nil {
		return uuid.Nil, fmt.Errorf("visitor: issuing an identity: %w", err)
	}
	return id, nil
}

// Seen confirms a visitor exists, and moves last_seen_at along.
//
// THE CLOCK IS COARSE ON PURPOSE. Updating a row on every request turns a read
// path into a write path, and this is the busiest one there will be. An hour is
// close enough for every question anybody asks of last_seen_at, and it makes
// the write rare rather than constant.
func (s *Store) Seen(ctx context.Context, id uuid.UUID) error {
	var exists bool
	err := s.pool.QueryRow(ctx, `
		WITH touched AS (
			UPDATE visitors SET last_seen_at = now()
			WHERE id = $1 AND last_seen_at < now() - interval '1 hour'
			RETURNING id
		)
		SELECT EXISTS (SELECT 1 FROM visitors WHERE id = $1)
	`, id).Scan(&exists)
	if err != nil {
		return fmt.Errorf("visitor: touching %s: %w", id, err)
	}
	if !exists {
		return ErrUnknown
	}
	return nil
}

// Link joins a visitor to an account at signup.
//
// MANY VISITORS PER ACCOUNT. A person arrives on a phone and subscribes on a
// laptop, and both are them; a single column on the account would keep whichever
// device signed up and quietly discard the one the funnel started on. Linking
// the same pair twice is not an error — a second sign-in from the same browser
// is the ordinary case.
func (s *Store) Link(ctx context.Context, accountID, visitorID uuid.UUID) error {
	if accountID == uuid.Nil || visitorID == uuid.Nil {
		return errors.New("visitor: linking needs both an account and a visitor")
	}

	_, err := s.pool.Exec(ctx, `
		INSERT INTO account_visitors (account_id, visitor_id)
		VALUES ($1, $2)
		ON CONFLICT (account_id, visitor_id) DO NOTHING
	`, accountID, visitorID)
	if err != nil {
		// A visitor that no longer exists is the one real failure here, and it
		// is worth naming: it means the cookie outlived an erasure.
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrUnknown
		}
		return fmt.Errorf("visitor: linking %s to an account: %w", visitorID, err)
	}
	return nil
}

// Of answers every visitor an account has been seen as. It is what the export
// path needs, and what erasure deletes.
func (s *Store) Of(ctx context.Context, accountID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT visitor_id FROM account_visitors WHERE account_id = $1 ORDER BY linked_at`, accountID)
	if err != nil {
		return nil, fmt.Errorf("visitor: reading the visitors of an account: %w", err)
	}
	defer rows.Close()

	var out []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("visitor: reading the visitors of an account: %w", err)
		}
		out = append(out, id)
	}
	return out, rows.Err()
}
