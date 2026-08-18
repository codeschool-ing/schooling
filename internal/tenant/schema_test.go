package tenant_test

import (
	"context"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

// The multi-tenancy rules the SCHEMA has to obey, read from the live database
// rather than agreed in a document.
//
// # WHY A TEST AND NOT A CONVENTION
//
// An index that does not lead with `tenant_id` is not a bug you can see. It
// works, it returns the right rows, and it scans across every school to do it —
// which costs nothing with two schools and one that nobody has data in. It
// becomes visible at the size where changing it is a migration on a table with
// history in it. So the moment to decide is when the index is written, and this
// is what makes that moment happen.
//
// # THE TWO RULES, AND WHY THEY ARE NOT ONE
//
// The roadmap says "`tenant_id` on every school-scoped table, with every index
// on one leading with it". Taken literally, this repository's own schema breaks
// it seven times over — and every one of those seven is deliberate: an account
// spans schools because there is one login for the whole platform, the audit is
// read platform-wide, and a report by event name is not about one school at
// all. A rule that the codebase violates on the day it is written gets deleted
// rather than obeyed.
//
// So it is split. Rule one is absolute. Rule two is the literal rule with its
// exceptions written down, each with a reason — which keeps the decision, and
// keeps it visible, without pretending the exceptions are not there.

// crossSchool are the indexes that deliberately do not lead with `tenant_id`.
//
// Adding one means adding it here, with a reason. That is the whole mechanism:
// not to forbid them, but to make the choice deliberate rather than a line
// somebody wrote while thinking about something else.
var crossSchool = map[string]string{
	"events_by_account": "one login covers the whole platform (N-01), so a person's own history " +
		"crosses schools and an index leading with tenant_id could not serve it",
	"events_by_visitor": "the same, and a visitor exists before any school is known",
	"events_by_name_and_time": "platform-wide reporting: 'how many signups last month' is not a " +
		"question about one school",
	"practice_review_by_exercise": "item analysis is per exercise — the exercise id already " +
		"narrows to the school that owns it",
	"certificates_by_code": "a verification code is the whole handle, typed by a stranger who has " +
		"no account and no school in mind, and its uniqueness has to be platform-wide: a code " +
		"that meant two certificates would make verification ambiguous to the one person it " +
		"exists for",
	"audit_log_by_time":    "the audit is read as one history by whoever is holding a pager",
	"audit_log_by_actor":   "the question is what a person did, and staff are not school-scoped",
	"audit_log_by_subject": "the subject is looked up by what it is, before its school is known",
}

// RULE ONE, and it is absolute: a table carrying `tenant_id` has at least one
// index leading with it.
//
// Without that index every school-scoped query starts with a scan the size of
// the whole platform. It is the one that has no legitimate exception, because a
// table with `tenant_id` on it is a table something asks "for this school"
// about.
func TestEverySchoolScopedTableCanBeQueriedByItsSchool(t *testing.T) {
	pool := testPool(t)

	scoped := tablesCarryingTenantID(t, pool)
	if len(scoped) == 0 {
		t.Fatal("no table carries tenant_id — the migrations have not run against this database")
	}

	leaders := indexesLeadingWithTenantID(t, pool)
	for _, table := range scoped {
		if !leaders[table] {
			t.Errorf("the table %q carries tenant_id and has no index leading with it — every "+
				"query scoped to one school starts by scanning every school's rows", table)
		}
	}
}

// RULE TWO: an index on a school-scoped table either leads with `tenant_id` or
// is written down above with a reason.
//
// Primary keys are exempt. A primary key is the row's identity rather than a
// query plan somebody chose, and `tenant_domains` is the case that proves it:
// its key is the host, because the question that table exists to answer is
// asked before any school is known.
func TestAnIndexThatCrossesSchoolsSaysWhy(t *testing.T) {
	pool := testPool(t)

	scoped := map[string]bool{}
	for _, table := range tablesCarryingTenantID(t, pool) {
		scoped[table] = true
	}

	rows, err := pool.Query(context.Background(), `
		SELECT c.relname, i.relname, a.attname
		FROM pg_index ix
		JOIN pg_class i ON i.oid = ix.indexrelid
		JOIN pg_class c ON c.oid = ix.indrelid
		JOIN pg_namespace n ON n.oid = c.relnamespace
		JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = ix.indkey[0]
		WHERE n.nspname = 'public' AND NOT ix.indisprimary
		ORDER BY c.relname, i.relname
	`)
	if err != nil {
		t.Fatalf("reading the indexes: %v", err)
	}
	defer rows.Close()

	seen := map[string]bool{}
	for rows.Next() {
		var table, index, first string
		if err := rows.Scan(&table, &index, &first); err != nil {
			t.Fatalf("reading the indexes: %v", err)
		}
		if !scoped[table] || first == "tenant_id" {
			continue
		}
		seen[index] = true

		if _, declared := crossSchool[index]; !declared {
			t.Errorf("the index %q on %q leads with %q rather than tenant_id, and no reason is "+
				"written down. Either lead with tenant_id, or add it to crossSchool with the "+
				"reason it legitimately crosses schools — an index that scans every school by "+
				"accident is invisible until the size where fixing it is a migration",
				index, table, first)
		}
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("reading the indexes: %v", err)
	}

	// And the other direction: a reason for an index nobody has any more is a
	// note that will be read as current, which is worse than no note.
	for index := range crossSchool {
		if !seen[index] {
			t.Errorf("crossSchool explains %q and there is no such index — the exception outlived "+
				"the thing it excused", index)
		}
	}
}

func tablesCarryingTenantID(t *testing.T, pool *pgxpool.Pool) []string {
	t.Helper()
	return oneColumn(t, pool, `
		SELECT table_name FROM information_schema.columns
		WHERE table_schema = 'public' AND column_name = 'tenant_id'
		ORDER BY table_name
	`)
}

func indexesLeadingWithTenantID(t *testing.T, pool *pgxpool.Pool) map[string]bool {
	t.Helper()
	out := map[string]bool{}
	for _, table := range oneColumn(t, pool, `
		SELECT DISTINCT c.relname
		FROM pg_index ix
		JOIN pg_class c ON c.oid = ix.indrelid
		JOIN pg_namespace n ON n.oid = c.relnamespace
		JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = ix.indkey[0]
		WHERE n.nspname = 'public' AND a.attname = 'tenant_id'
	`) {
		out[table] = true
	}
	return out
}

func oneColumn(t *testing.T, pool *pgxpool.Pool, query string) []string {
	t.Helper()
	rows, err := pool.Query(context.Background(), query)
	if err != nil {
		t.Fatalf("reading the schema: %v", err)
	}
	defer rows.Close()

	var out []string
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			t.Fatalf("reading the schema: %v", err)
		}
		out = append(out, s)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("reading the schema: %v", err)
	}
	return out
}
