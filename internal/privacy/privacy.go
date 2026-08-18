// Package privacy is the registry every table has to appear in, and the export
// and erase paths built from it.
//
// # WHY A REGISTRY AND NOT A PROCEDURE
//
// The obligation is to export and to erase a person's data. Written as two
// functions that somebody keeps up to date, it works for exactly as long as
// everybody remembers — and the failure is silent, because a table nobody wired
// in produces no error, just an export that is quietly incomplete. At twice
// this size finding it is archaeology, and the statutory clock runs while you
// look.
//
// So the registry is the source, and a test compares it against the LIVE
// SCHEMA: a table that exists and is not registered fails, a registered table
// that does not exist fails, and a classification that disagrees with the
// comment on the table fails. Adding a table without deciding what it holds
// becomes impossible rather than discouraged.
//
// # WHAT ERASURE ACTUALLY DOES HERE
//
// None of these tables holds a name. They hold uuids. Erasing a person deletes
// the rows that give those uuids a meaning — the identity rows and the link
// between a visitor and an account — which leaves the event and review rows
// pointing at nothing and joinable to nobody. The statistics survive; the
// person is not in them. That is also what lets the append-only triggers be
// absolute: nothing in this path ever updates or deletes one of those rows.
package privacy

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Holding is what a table has in it. Three values and no more — a fourth would
// be a judgement call, and a judgement call is what this is here to remove.
type Holding string

const (
	// Nothing about a person.
	HoldsNothing Holding = "none"
	// Identifiers and no name: meaningless once the identity rows are gone.
	HoldsPseudonymous Holding = "pseudonymous"
	// A name, an address, an e-mail — a person without being joined to anything.
	HoldsIdentifying Holding = "identifying"
)

// OnErase is what happens to a table's rows when a person is erased.
type OnErase string

const (
	// The rows go.
	EraseDelete OnErase = "delete"
	// The rows stay and stop meaning anybody, because what they pointed at was
	// deleted. This is not a euphemism for doing nothing: it is only available
	// to a table whose reference to the person is severed by another table's
	// deletion, and the registry says which.
	EraseOrphan OnErase = "orphan"
	// The rows stay and are meant to. An audit that can be deleted by the
	// person it recorded is not an audit.
	EraseKeep OnErase = "keep"
)

// Subject is whose data reaches this table.
type Subject string

const (
	SubjectNobody  Subject = ""
	SubjectAccount Subject = "account"
	SubjectStaff   Subject = "staff"
)

// Table is one row of the registry.
type Table struct {
	Name    string
	Holds   Holding
	Subject Subject
	OnErase OnErase

	// Why is not decoration. Every entry here is a decision with a legal edge,
	// and the reason is the part that cannot be reconstructed from the code.
	Why string
}

// Registry is every table in the database. A test holds it to that.
var Registry = []Table{
	{
		Name: "schema_migrations", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "which migrations ran",
	},
	{
		Name: "tenants", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the schools, which are ours and not people",
	},
	{
		Name: "tenant_domains", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the addresses schools answer at",
	},
	{
		Name: "visitors", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "the identity that precedes the account. Deleting it is what makes every " +
			"event and review carrying its id stop meaning a person",
	},
	{
		Name: "account_visitors", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "the link from a person to their devices — the one row that turns a visitor id " +
			"back into somebody, so it is the one that has to go",
	},
	{
		Name: "events", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseOrphan,
		Why: "append-only by trigger, and holds only ids. Once visitors and account_visitors " +
			"are gone these rows join to nobody, and the statistics they carry survive",
	},
	{
		Name: "practice_review", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseOrphan,
		Why: "the same: append-only, ids only, and the record a later scheduler is fitted against",
	},
	{
		Name: "audit_log", Holds: HoldsIdentifying, Subject: SubjectStaff, OnErase: EraseKeep,
		Why: "holds a staff member's name on purpose, so an entry still reads as an answer " +
			"after they have left. An audit a person can erase is not an audit — a staff " +
			"departure is handled by retention, not by this path",
	},
}

// ByName answers the registry entry for a table.
func ByName(name string) (Table, bool) {
	for _, t := range Registry {
		if t.Name == name {
			return t, true
		}
	}
	return Table{}, false
}

// AccountTables are the tables a student's export has to cover: every one the
// registry says their data reaches. The export is checked against this list by
// a test, so a new table with SubjectAccount fails until the export carries it.
func AccountTables() []string {
	var out []string
	for _, t := range Registry {
		if t.Subject == SubjectAccount {
			out = append(out, t.Name)
		}
	}
	return out
}

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// Export is everything the platform holds about one person.
//
// Keyed by table name, and it carries a key for every table the registry says
// reaches an account — including the empty ones. An export that silently omits
// a table it has no rows for is indistinguishable from one that forgot it.
func (s *Store) Export(ctx context.Context, accountID uuid.UUID) (map[string][]map[string]any, error) {
	out := map[string][]map[string]any{}
	for _, name := range AccountTables() {
		out[name] = []map[string]any{}
	}

	queries := []struct {
		table string
		sql   string
	}{
		{"account_visitors", `
			SELECT account_id, visitor_id, linked_at
			FROM account_visitors WHERE account_id = $1 ORDER BY linked_at`},
		{"visitors", `
			SELECT v.id, v.first_seen_at, v.last_seen_at, v.first_path, v.first_referrer,
			       v.utm_source, v.utm_medium, v.utm_campaign, v.country, v.locale
			FROM visitors v
			JOIN account_visitors av ON av.visitor_id = v.id
			WHERE av.account_id = $1 ORDER BY v.first_seen_at`},
		{"events", `
			SELECT id, occurred_at, name, visitor_id, account_id, school_slug,
			       plan, country, locale, payload
			FROM events
			WHERE account_id = $1
			   OR visitor_id IN (SELECT visitor_id FROM account_visitors WHERE account_id = $1)
			ORDER BY occurred_at`},
		{"practice_review", `
			SELECT id, reviewed_at, exercise_id, exercise_version, section_id,
			       correct, quality, elapsed_ms, scheduler
			FROM practice_review WHERE account_id = $1 ORDER BY reviewed_at`},
	}

	for _, q := range queries {
		rows, err := s.pool.Query(ctx, q.sql, accountID)
		if err != nil {
			return nil, fmt.Errorf("privacy: exporting %s: %w", q.table, err)
		}
		// By column name rather than into a struct: an export is for a person
		// to read and for a regulator to check, and a struct here would be one
		// more place a new column has to be added before it appears.
		collected, err := pgx.CollectRows(rows, pgx.RowToMap)
		if err != nil {
			return nil, fmt.Errorf("privacy: exporting %s: %w", q.table, err)
		}
		out[q.table] = collected
	}

	return out, nil
}

// Erase removes a person, by removing what makes their identifiers mean them.
//
// It is one transaction: half an erasure is worse than none, because the rows
// that remain are the ones somebody will later assume were dealt with.
func (s *Store) Erase(ctx context.Context, accountID uuid.UUID) error {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("privacy: erasing: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	// The visitors first: deleting them cascades account_visitors, and it is
	// their disappearance that severs every event and review row.
	if _, err := tx.Exec(ctx, `
		DELETE FROM visitors
		WHERE id IN (SELECT visitor_id FROM account_visitors WHERE account_id = $1)
	`, accountID); err != nil {
		return fmt.Errorf("privacy: erasing the visitors of an account: %w", err)
	}

	// Any link left over — a visitor already gone, an account linked twice.
	if _, err := tx.Exec(ctx,
		`DELETE FROM account_visitors WHERE account_id = $1`, accountID); err != nil {
		return fmt.Errorf("privacy: erasing the links of an account: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("privacy: erasing: %w", err)
	}
	return nil
}
