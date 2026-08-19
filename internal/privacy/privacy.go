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
		Name: "accounts", Holds: HoldsIdentifying, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "the e-mail and the name. It is the row that makes every account_id in the database " +
			"mean a person, so deleting it is what the whole erase path is for",
	},
	{
		Name: "account_credentials", Holds: HoldsIdentifying, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "a password hash is derived from something the person chose and reused elsewhere. " +
			"It goes with the account, by cascade",
	},
	{
		Name: "staff", Holds: HoldsPseudonymous, Subject: SubjectStaff, OnErase: EraseKeep,
		Why: "who was allowed to operate the platform, and who let them in. It is the row the " +
			"audit's actor is checked against months later, so it survives — and it goes by " +
			"cascade if the account itself is ever erased, which is a staff departure rather " +
			"than a student's request",
	},
	{
		Name: "sessions", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "a token hash and a user agent. It goes with the account, by cascade — and a live " +
			"session outliving an erasure would be somebody still signed in as a person who asked " +
			"to be forgotten",
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
	// THE CATALOGUE HOLDS NOTHING ABOUT ANYBODY. It is a mirror of files in the
	// repository — courses, lessons, the words of a lesson, the questions. It
	// is listed here in full rather than waved past as a group, because the
	// registry's whole value is that a table cannot be in the database and
	// absent from this list: a group would be the one exception, and the next
	// table would be added inside it.
	{
		Name: "catalog_tracks", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "a mirror of tracks/*.json",
	},
	{
		Name: "catalog_track_forks", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the prose of a fork in a track",
	},
	{
		Name: "catalog_track_courses", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "which courses a track contains, flattened",
	},
	{
		Name: "catalog_courses", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "a mirror of courses/*/course.json",
	},
	{
		Name: "catalog_course_requires", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "what a student must know before a course — knowledge, not sequence",
	},
	{
		Name: "catalog_lessons", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "a mirror of lessons/*/lesson.json",
	},
	{
		Name: "catalog_sections", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the steps of a lesson",
	},
	{
		Name: "catalog_prose", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the words of a section, per locale — written by us, about nobody",
	},
	{
		Name: "catalog_exercises", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the questions and their answer keys. What a STUDENT answered is practice_review, " +
			"which is a different table for exactly this reason",
	},
	{
		Name: "catalog_images", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the diagrams a question is asked about. Bytes we wrote and published, about " +
			"nobody — and a picture of a person would be a content review problem rather " +
			"than something this classification could rescue",
	},
	// WHAT A STUDENT DID, AND IT GOES WHEN THEY DO. Unlike events and reviews,
	// which survive an erasure orphaned so the statistics stay whole, these
	// answer only "what has this person done" — nothing aggregate is computed
	// from them, because statistics come from the event stream (K-03). So they
	// have real foreign keys and cascade with the account.
	{
		Name: "section_progress", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "which sections one person finished. It answers nothing about anybody else, so " +
			"there is no aggregate to protect by keeping it",
	},
	{
		Name: "resume_pointer", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "where one person was in a course",
	},
	{
		Name: "notes", Holds: HoldsIdentifying, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "free text a person wrote in their own margin. What somebody puts there is not for " +
			"this registry to assume, which is why it is identifying rather than pseudonymous",
	},
	{
		Name: "exam_attempts", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "which exams one person sat and what they scored. The evidence about whether a " +
			"QUESTION is any good is not here — that is one event per answer, and events survive " +
			"orphaned, so erasing a person does not take the item analysis with them",
	},
	{
		Name: "exam_answers", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "the paper: what was asked, what was given, what it scored. It goes with the attempt " +
			"by cascade. It also holds the answer keys of the questions that were asked, in a " +
			"column the export deliberately does not name",
	},
	{
		Name: "certificates", Holds: HoldsIdentifying, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "it carries a person's NAME and is readable by anybody holding its code, which is the " +
			"whole point of it. Keeping one after an erasure request would mean publishing the " +
			"name of somebody who asked to be forgotten, so it goes — and the verification page " +
			"then answers exactly as it does for a code that never existed",
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
//
// THE COLUMNS ARE NAMED RATHER THAN SELECTED WITH *. An export is handed to the
// person it is about, so a column added later must be a decision to include it
// rather than something that arrives on its own — `account_credentials.secret`
// is the case that makes the point, and a test holds it out.
func (s *Store) Export(ctx context.Context, accountID uuid.UUID) (map[string][]map[string]any, error) {
	out := map[string][]map[string]any{}
	for _, name := range AccountTables() {
		out[name] = []map[string]any{}
	}

	queries := []struct {
		table string
		sql   string
	}{
		{"accounts", `
			SELECT id, email, name, locale, country, created_at, email_verified_at
			FROM accounts WHERE id = $1`},
		{"account_credentials", `
			SELECT kind, created_at, updated_at
			FROM account_credentials WHERE account_id = $1 ORDER BY kind`},
		{"sessions", `
			SELECT id, created_at, last_seen_at, expires_at, revoked_at, user_agent
			FROM sessions WHERE account_id = $1 ORDER BY created_at`},
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
		{"section_progress", `
			SELECT course_id, lesson_id, section_id, completed_at
			FROM section_progress WHERE account_id = $1 ORDER BY completed_at`},
		{"resume_pointer", `
			SELECT course_id, lesson_id, section_id, at
			FROM resume_pointer WHERE account_id = $1 ORDER BY at`},
		{"notes", `
			SELECT course_id, lesson_id, section_id, body, updated_at
			FROM notes WHERE account_id = $1 ORDER BY course_id, lesson_id, section_id`},
		{"exam_attempts", `
			SELECT id, scope, scope_id, started_at, submitted_at, score, of, pass_mark, passed
			FROM exam_attempts WHERE account_id = $1 ORDER BY started_at`},
		// NEITHER `sealed` NOR `shown` IS NAMED HERE, and the two omissions have
		// different reasons. `sealed` is the answer key — it must not leave the
		// database at all, and a test holds that. `shown` is the question text,
		// which is our content rather than a fact about the person: an export is
		// what the platform holds ABOUT SOMEBODY, and shipping them a copy of the
		// question bank would be a strange way to answer that.
		{"exam_answers", `
			SELECT q.attempt_id, q.position, q.exercise_id, q.exercise_version, q.type,
			       q.answer, q.answered_at, q.correct
			FROM exam_answers q
			JOIN exam_attempts a ON a.id = q.attempt_id
			WHERE a.account_id = $1 ORDER BY q.attempt_id, q.position`},
		{"certificates", `
			SELECT code, scope, scope_id, title, student_name, school_name, issued_at
			FROM certificates WHERE account_id = $1 ORDER BY issued_at`},
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

	// And the account, which is the row that made every account_id in the
	// database mean somebody. Credentials and sessions go with it by cascade;
	// a live session outliving an erasure would be a person still signed in as
	// somebody who asked to be forgotten.
	if _, err := tx.Exec(ctx, `DELETE FROM accounts WHERE id = $1`, accountID); err != nil {
		return fmt.Errorf("privacy: erasing an account: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("privacy: erasing: %w", err)
	}
	return nil
}
