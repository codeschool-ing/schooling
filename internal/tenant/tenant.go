// Package tenant answers one question: which school is this request for?
//
// The answer comes from the address the browser used, and from nowhere else.
// No path prefix, no header a client could set, no query parameter. The host
// is the one thing a student cannot get wrong by accident and cannot forge on
// purpose — it is what the certificate was issued for.
//
// WHAT THE REST OF THE CODE SEES is a Tenant in the context, put there once by
// the middleware. Business code never resolves a school and never mentions
// one; it asks this package and moves on.
package tenant

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrUnknownHost is the answer for an address no school claims. It is a state,
// not a failure: somebody typed a subdomain that does not exist.
var ErrUnknownHost = errors.New("tenant: no school answers at that host")

// School is one school. It is the whole of what the rest of the code is
// allowed to know about which one it is serving.
type School struct {
	ID     uuid.UUID
	Slug   string
	Name   string
	Accent string

	// Site is the school's own site, if it has one. The interface links to it
	// from the account menu and leaves the link out when it is empty — which
	// is better than the link every school used to get, to codeschool.ing.
	Site string

	// What the subscription costs here, in cents, and in which currency —
	// filled from the price in force at the moment this school was read.
	//
	// THEY ARE NOT COLUMNS ANY MORE (K-14). A price is a series of dated rows
	// in `school_prices`, append-only, so that the offer is as much a matter of
	// record as the payment; these two fields are the top of that series,
	// carried on the struct because every request that draws the offer wants it
	// and none of them wants the history.
	//
	// Zero and empty mean the school has no price, which is now "no rows"
	// rather than a zero in a column — a free school and an unpriced one were
	// the same number before, and one of those is a decision.
	PlanPriceCents int
	PlanCurrency   string
}

// Price is the offer, or nothing.
//
// HALF OF ONE IS NOT SERVED, and it stays written down although the shape that
// made it possible has gone. The currency used to carry a column default, so a
// school that had set NO price still had `BRL` in its row and answering it would
// have put a currency on a school that never chose one. A row now carries both
// or does not exist, so the guard below can no longer fire — which is a reason
// to keep it rather than to remove it: it costs a comparison, and the day
// somebody adds a way to write one half of a price it is the thing that refuses
// to serve it.
func (s School) Price() (cents int, currency string) {
	if s.PlanPriceCents <= 0 || s.PlanCurrency == "" {
		return 0, ""
	}
	return s.PlanPriceCents, s.PlanCurrency
}

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// ByHost reads the school for an address.
//
// IT IS NOT CACHED, and that is a decision rather than an omission. A cache
// would be right almost always — schools change about never — and "almost
// always" here means a school created a minute ago answers 404, or a school
// removed an hour ago still answers. It is one lookup on a primary key, on
// every request; when a profile says that costs something, the place to fix it
// is here, with creation invalidating it.
func (s *Store) ByHost(ctx context.Context, host string) (School, error) {
	h := Normalise(host)
	if h == "" {
		return School{}, ErrUnknownHost
	}

	/* THE PRICE COMES FROM A LATERAL AND NOT FROM A COLUMN. One row of the
	   series — the newest whose `effective_from` has passed — joined onto the
	   school, so the busiest read in the platform still costs one round trip.
	   `LEFT JOIN` because a school with no price is an ordinary school, and an
	   inner join would make it a 404. */
	var out School
	var cents *int
	var currency *string
	err := s.pool.QueryRow(ctx, `
		SELECT t.id, t.slug, t.name, t.accent, t.site, p.cents, p.currency
		FROM tenant_domains d
		JOIN tenants t ON t.id = d.tenant_id
		LEFT JOIN LATERAL (
			SELECT cents, currency FROM plan_prices
			WHERE scope = 'all' AND term_months = 12 AND effective_from <= now()
			ORDER BY effective_from DESC
			LIMIT 1
		) p ON true
		WHERE d.host = $1
	`, h).Scan(&out.ID, &out.Slug, &out.Name, &out.Accent, &out.Site,
		&cents, &currency)

	if errors.Is(err, pgx.ErrNoRows) {
		return School{}, ErrUnknownHost
	}
	if err != nil {
		return School{}, fmt.Errorf("tenant: reading the school for %q: %w", h, err)
	}
	if cents != nil && currency != nil {
		out.PlanPriceCents, out.PlanCurrency = *cents, *currency
	}
	return out, nil
}

// ByID is the same school, found by its id rather than by an address.
//
// IT EXISTS FOR THE ADDRESSES THAT BELONG TO NO SCHOOL. A request at a school's
// host resolves its school from the host and never needs this; the platform's
// own address has no host to resolve from, and an id is what it is holding —
// the school of a card in a queue that crosses them.
//
// The same LATERAL as `ByHost`, so a school read this way carries the price in
// force exactly as one read from a host does. Two ways to load a school that
// disagreed about a field would be discovered by a number on a screen.
func (s *Store) ByID(ctx context.Context, id uuid.UUID) (School, error) {
	var out School
	var cents *int
	var currency *string
	err := s.pool.QueryRow(ctx, `
		SELECT t.id, t.slug, t.name, t.accent, t.site, p.cents, p.currency
		FROM tenants t
		LEFT JOIN LATERAL (
			SELECT cents, currency FROM plan_prices
			WHERE scope = 'all' AND term_months = 12 AND effective_from <= now()
			ORDER BY effective_from DESC
			LIMIT 1
		) p ON true
		WHERE t.id = $1
	`, id).Scan(&out.ID, &out.Slug, &out.Name, &out.Accent, &out.Site,
		&cents, &currency)

	if errors.Is(err, pgx.ErrNoRows) {
		return School{}, ErrNoSchool
	}
	if err != nil {
		return School{}, fmt.Errorf("tenant: reading the school %s: %w", id, err)
	}
	if cents != nil && currency != nil {
		out.PlanPriceCents, out.PlanCurrency = *cents, *currency
	}
	return out, nil
}

// Scoped puts a school on a context for a request that did not arrive at its
// host.
//
// THE MIDDLEWARE IS STILL THE ONLY WAY A REQUEST AT A SCHOOL'S HOST GETS ONE.
// This is for the platform's own address, where the school comes from a row the
// student already owns rather than from the Host header — and it is
// deliberately the SAME context key, so everything downstream is the same code
// asking the same question. A second way to say which school a request is for
// would be a second thing to get wrong about a paywall.
func Scoped(ctx context.Context, s School) context.Context { return with(ctx, s) }

// Normalise turns what arrived in the Host header into what the table stores.
//
// Three things happen to it, and each is a way the same address arrives
// looking different: the port is dropped, because `code.example.tld` and
// `code.example.tld:8080` are one school and only the second appears in local
// development; the case is folded, because host names are case-insensitive and
// a link somebody typed in capitals must not miss; and a trailing dot is
// removed, because a fully qualified name is the same name.
func Normalise(host string) string {
	h := strings.ToLower(strings.TrimSpace(host))

	// Drop the port. An IPv6 literal is bracketed, so the last colon only
	// separates a port when it comes after the closing bracket.
	if i := strings.LastIndex(h, ":"); i > strings.LastIndex(h, "]") {
		h = h[:i]
	}
	h = strings.TrimSuffix(h, ".")
	h = strings.Trim(h, "[]")

	return h
}

/* ---------- the context ---------- */

type ctxKey int

const ctxSchool ctxKey = iota

func with(ctx context.Context, s School) context.Context {
	return context.WithValue(ctx, ctxSchool, s)
}

// FromContext answers the school this request is for.
//
// The second value is false only on a route that is not school-scoped —
// health, version, and later the payment webhooks, which arrive at an address
// the gateway knows and that belongs to no school. A handler mounted behind
// the middleware can rely on it being true, and a handler that cannot is
// mounted somewhere it should not be.
func FromContext(ctx context.Context) (School, bool) {
	s, ok := ctx.Value(ctxSchool).(School)
	return s, ok
}

// All is every school, in a settled order.
//
// IT IS FOR CROSSING SCHOOLS AND NOT FOR SERVING ONE. Every request on a
// school's host resolves exactly one school by its host, and nothing on that
// side may enumerate them — a screen that could would be a school's screen
// showing another school's name. This exists for the console, which belongs to
// none of them and has to loop.
//
// Ordered by slug rather than by creation, so a list of schools reads the same
// way twice and a person scanning it can find one by name.
func (s *Store) All(ctx context.Context) ([]School, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT t.id, t.slug, t.name, t.accent, t.site, p.cents, p.currency
		FROM tenants t
		LEFT JOIN LATERAL (
			SELECT cents, currency FROM plan_prices
			WHERE scope = 'all' AND term_months = 12 AND effective_from <= now()
			ORDER BY effective_from DESC
			LIMIT 1
		) p ON true
		ORDER BY t.slug
	`)
	if err != nil {
		return nil, fmt.Errorf("tenant: reading the schools: %w", err)
	}
	defer rows.Close()

	var out []School
	for rows.Next() {
		var t School
		var cents *int
		var currency *string
		if err := rows.Scan(&t.ID, &t.Slug, &t.Name, &t.Accent, &t.Site,
			&cents, &currency); err != nil {
			return nil, fmt.Errorf("tenant: reading a school: %w", err)
		}
		if cents != nil && currency != nil {
			t.PlanPriceCents, t.PlanCurrency = *cents, *currency
		}
		out = append(out, t)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("tenant: reading the schools: %w", err)
	}
	return out, nil
}

// ErrNoSchool is an id no school has.
var ErrNoSchool = errors.New("tenant: no school with that id")

// SetAccent writes one school's colour and answers what was there before.
//
// # THE FIRST WRITE THIS PACKAGE HAS
//
// School rows have been made by hand since the first migration — a slug, a name
// and a colour typed into psql — and that was survivable for one school and is
// not the shape this platform is. The colour is the first of them to get a
// screen, because it is the one a person changes more than once and the only
// one a student sees.
//
// # THE OLD VALUE COMES BACK FROM THE WRITE ITSELF
//
// `RETURNING` the row as it was, in the same statement that replaces it, so the
// value recorded as "before" is the one this write actually replaced. Read
// first and write second and the two can disagree — which is not a race worth
// having on a column an audit entry quotes.
//
// A colour that is already there is still a write and still answers with the
// same value. Deciding whether that is a change belongs to the caller, which is
// the only one that knows whether an entry is worth writing.
func (s *Store) SetAccent(ctx context.Context, id uuid.UUID, accent string) (string, error) {
	/* THE SELF-JOIN IS THE IDIOM AND NOT A FLOURISH. `RETURNING` sees the row as
	   it is AFTER the update, so it cannot answer with the value that was
	   replaced; joining the table to itself in `FROM` binds `old` to the row as
	   the statement found it. A sub-select in `RETURNING` looks like it would do
	   the same and is not defined to. */
	var was string
	err := s.pool.QueryRow(ctx, `
		UPDATE tenants AS t SET accent = $2
		  FROM tenants AS old
		 WHERE t.id = $1 AND old.id = t.id
		RETURNING old.accent
	`, id, accent).Scan(&was)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return "", ErrNoSchool
	case err != nil:
		return "", fmt.Errorf("tenant: setting a school's accent: %w", err)
	}
	return was, nil
}

// HostOf answers an address a school answers at.
//
// # A SCHOOL CAN HAVE SEVERAL AND THIS PICKS ONE
//
// `tenant_domains` is a list — a school may be reachable at more than one
// address while one is being moved to. Any of them resolves to the same school,
// so for building a link the question is not "which is canonical" but "which
// works", and the oldest is the one most likely to be the one people already
// use.
//
// IT EXISTS FOR VIEW-AS-STUDENT. The console answers on its own host and cannot
// set a cookie for a school's, so it hands the operator a link to follow — and a
// link needs an address. Deriving one from the slug and the platform domain
// would be a second copy of a rule this table already holds, and the copy is the
// one that is wrong the day a school gets a domain of its own.
//
// # IT SAID "OLDEST" AND ORDERED BY NAME
//
// The paragraph above has always said the oldest, and the query sorted the
// hosts ALPHABETICALLY — which is a different answer whenever a school has more
// than one, and no school had more than one until the day this was noticed.
//
// The one that did has `code.<domain>` and the service's own
// `schooling-….run.app`, and alphabetical order happens to put the right one
// first. That is luck and not a rule: a school at `zoology.<domain>` sorts
// AFTER `schooling-…`, so an operator following a view-as-student link would
// land on the raw Cloud Run URL — which works, serves the right school, and is
// an address nobody should be handed.
//
// `created_at` has been on the table since the first migration, so the fix is
// the column the comment was always describing. The tie-break on `host` is for
// the two rows written in the same statement: a query that can return either of
// two rows is a link that changes between refreshes.
func (s *Store) HostOf(ctx context.Context, id uuid.UUID) (string, error) {
	var host string
	err := s.pool.QueryRow(ctx, `
		SELECT host FROM tenant_domains
		WHERE tenant_id = $1
		ORDER BY created_at, host
		LIMIT 1
	`, id).Scan(&host)

	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrUnknownHost
	}
	if err != nil {
		return "", fmt.Errorf("tenant: reading a school's address: %w", err)
	}
	return host, nil
}
