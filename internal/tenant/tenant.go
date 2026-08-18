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

	var out School
	err := s.pool.QueryRow(ctx, `
		SELECT t.id, t.slug, t.name, t.accent
		FROM tenant_domains d
		JOIN tenants t ON t.id = d.tenant_id
		WHERE d.host = $1
	`, h).Scan(&out.ID, &out.Slug, &out.Name, &out.Accent)

	if errors.Is(err, pgx.ErrNoRows) {
		return School{}, ErrUnknownHost
	}
	if err != nil {
		return School{}, fmt.Errorf("tenant: reading the school for %q: %w", h, err)
	}
	return out, nil
}

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
