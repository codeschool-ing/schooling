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
		Name: "job_runs", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "that a scheduled job ran, when, and how it went. It is about our own machinery " +
			"and names nobody — a run is not somebody's data even though what it reads is, " +
			"and the sentence it records about itself is a count of questions rather than " +
			"anything about a person",
	},
	{
		Name: "plan_prices", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "what the platform has asked for a subscription, for which term, and since " +
			"when. It is our offer " +
			"rather than anybody's data, and it is append-only for the reason a March " +
			"invoice has to stay explicable in November (K-14) — an erasure that could " +
			"take a price row with it would be a person's request deleting the answer to " +
			"why somebody else was charged what they were",
	},
	{
		Name: "support_contact", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the one address students are told to write to, to use the seven days the terms " +
			"promise. An e-mail address in a column is the shape this registry exists to " +
			"be suspicious of, and this one is still nobody's: it is a channel the " +
			"platform PUBLISHES, chosen so that it can be printed on a screen every " +
			"subscriber can read. The edge worth naming is an operator typing their own " +
			"personal address into it — that is still a decision to publish rather than " +
			"data held about them, it is undone by typing another, and an erasure that " +
			"reached this row would take the platform's only stated support channel away " +
			"on one person's request",
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
		Name: "account_recovery_codes", Holds: HoldsPseudonymous, Subject: SubjectAccount,
		OnErase: EraseDelete,
		Why: "ten hashes and whether each was spent: the way back into an account when the " +
			"authenticator app is gone. It holds nothing about the person, and it goes with " +
			"the account by cascade — a code that still worked after an erasure would be a " +
			"way into an account that is not there",
	},
	{
		Name: "account_email_confirmations", Holds: HoldsIdentifying, Subject: SubjectAccount,
		OnErase: EraseDelete,
		Why: "the address a confirmation link was sent to, which is the e-mail itself and not a " +
			"hash of it — the row keeps it so that a link issued for one address cannot verify " +
			"another. It goes with the account by cascade: a link that still worked after an " +
			"erasure would write a timestamp onto a row that is not there",
	},
	{
		Name: "account_email_changes", Holds: HoldsIdentifying, Subject: SubjectAccount,
		OnErase: EraseDelete,
		Why: "an address somebody asked to move their account to, which is an e-mail and not " +
			"a hash of one — redemption has to WRITE it onto the account, so it cannot be " +
			"one-way. It goes with the account by cascade: a link that still worked after an " +
			"erasure would move an account that is not there, and the row would meanwhile be " +
			"an address a person gave us surviving the request to forget them",
	},
	{
		Name: "mail_suppressions", Holds: HoldsPseudonymous, Subject: SubjectNobody,
		OnErase: EraseKeep,
		Why: "the SHA-256 of an address that refused our mail permanently, and never the " +
			"address. IT SURVIVES AN ERASURE PRECISELY BECAUSE IT HOLDS NOTHING THAT WAS " +
			"ERASED: somebody asks to be forgotten, signs up again a month later with the same " +
			"mailbox, and we write to an address that already told us to stop — which is the " +
			"complaint we were asked not to repeat. A hash answers 'may I write to THIS " +
			"address' and answers nothing else: it names nobody, it cannot be read back into a " +
			"list, and there is no account to attach it to, which is why the subject is nobody",
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
		Name: "catalog_track_links", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "which course a track puts after which, and about nobody",
	},
	{
		Name: "catalog_course_topics", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "what a course contains, in order, and about nobody",
	},
	{
		Name: "catalog_course_text", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "a course's name and syllabus in another language",
	},
	{
		Name: "catalog_course_topic_text", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "a topic's title in another language, keyed by the topic's id and not its position",
	},
	{
		Name: "catalog_track_text", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "a track's name and goal in another language",
	},
	{
		Name: "catalog_track_fork_text", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the words of a choice in a track, in another language",
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
		Name: "catalog_exercise_text", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "the same questions in another language — what a student READS, never what " +
			"decides their mark, which is why a translation cannot reach an answer key",
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
		Name: "practice_state", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "where one person is on each card they drill. It is DELETED rather than orphaned, " +
			"unlike practice_review beside it: the log is what a later scheduler is fitted " +
			"against and is worth keeping without a person attached, and this is only ever " +
			"read to build one person's queue",
	},
	{
		Name: "practice_drawn", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "how the card in front of one person was shuffled. It is a draft rather than a " +
			"record — nothing reads it once the answer is marked, and the worst a deletion " +
			"costs is drawing the card again",
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
		Name: "content_reports", Holds: HoldsIdentifying, Subject: SubjectAccount,
		OnErase: EraseDelete,
		Why: "free text a person wrote about our material, which is `notes` from the other " +
			"direction and identifying for the same reason: what somebody puts in a box is " +
			"not for this registry to assume. It goes with the account by cascade, and what " +
			"survives is the audit entry written when the report was settled — the operational " +
			"fact is the platform's own record and does not erase, the sentence is theirs and does",
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
		Name: "question_quarantine", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "which questions are out of circulation, and the numbers that decided it. About " +
			"a QUESTION and never a person — it is here because a table cannot be in the " +
			"database and absent from this list, not because it holds anything",
	},
	{
		Name: "item_statistics", Holds: HoldsNothing, Subject: SubjectNobody, OnErase: EraseKeep,
		Why: "what the answers came to, per QUESTION. Counts and ratios over an item, with no " +
			"account id and no room for one — the moment a row here could be traced to a " +
			"person it would be a second copy of what somebody answered, in a table nobody " +
			"would think to erase. It is a rollup of `events` and can be dropped and rebuilt",
	},
	{
		Name: "subscriptions", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "what one person is paying for, and it means nothing once there is nobody. It is " +
			"the state and not the history — the record that money changed hands is " +
			"ledger_entries, which is a different table for exactly this reason",
	},
	{
		Name: "subscription_events", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseOrphan,
		Why: "how a subscription got to where it is, append-only by trigger and holding only " +
			"ids. Orphaned rather than deleted for the same reason as the ledger it sits " +
			"beside: it is what lets a dispute about a payment be reconstructed a year " +
			"later, and a cascade would make erasure fail on everybody who ever subscribed",
	},
	{
		Name: "payment_customers", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseDelete,
		Why: "the handle a payment gateway answered with for one person, and nothing else. " +
			"Charging in Brazil needs a CPF or CNPJ; it is sent to create this handle and " +
			"is NOT stored here, so what this row holds is a string that means something " +
			"only at that processor. It goes on erasure because it is the join between a " +
			"person and a company that holds their tax id, nothing obliges us to keep it, " +
			"and a row that survived would be a way to find them again. What deleting it " +
			"cannot do is delete their customer at the gateway, which keeps the number " +
			"under its own retention",
	},
	{
		Name: "checkout_intents", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseOrphan,
		Why: "one attempt to buy: which price, what was actually charged, how it was paid, " +
			"and how far it got. ORPHANED for the ledger's reason exactly — a chargeback " +
			"can arrive months after somebody has gone and \"what was this payment for\" " +
			"has to stay answerable, while the identity that makes it theirs is deleted. " +
			"It holds no name, no address and no tax id",
	},
	{
		Name: "ledger_entries", Holds: HoldsPseudonymous, Subject: SubjectAccount, OnErase: EraseOrphan,
		Why: "every movement of money, append-only by trigger and holding only ids. It is " +
			"ORPHANED rather than deleted, and that is the only arrangement meeting both " +
			"obligations at once: a record that money changed hands is a tax obligation and " +
			"the other half of a bank statement, so it cannot go on request — but the " +
			"identity that makes it somebody's can, and does, which leaves it joinable to nobody",
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
		// NOT `code_hash`. The hash is not reversible and handing it over would
		// still be handing somebody a list of what to compare against, in a
		// file that leaves this system by design.
		{"account_recovery_codes", `
			SELECT created_at, used_at
			FROM account_recovery_codes WHERE account_id = $1 ORDER BY created_at`},
		// NOT `token_hash`, for the recovery codes' reason directly above. What
		// this row is worth to the person is the other three columns: which
		// address we wrote to, when, and whether they ever followed it — which
		// is the whole answer to "why does it say my e-mail is unconfirmed".
		{"account_email_confirmations", `
			SELECT email, created_at, expires_at, spent_at
			FROM account_email_confirmations WHERE account_id = $1 ORDER BY created_at`},
		// NOT `token_hash`, for the reason directly above. What this row is
		// worth to the person is the address they asked to move to, when, and
		// whether they ever followed it — which is the whole answer to "why is
		// my account still on the old address".
		{"account_email_changes", `
			SELECT email, created_at, expires_at, spent_at
			FROM account_email_changes WHERE account_id = $1 ORDER BY created_at`},
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
		{"practice_state", `
			SELECT exercise_id, interval_days, ease, repetition, lapses, due_on, last_reviewed_at
			FROM practice_state WHERE account_id = $1 ORDER BY exercise_id`},
		// `perm` IS NOT EXPORTED. It is how one card was shuffled for this
		// person and says nothing about them — but it is half of an answer key
		// for a question they may be asked again, and an export is a file they
		// can be asked to hand over. The row is named so the export is honest
		// about what is held; what it holds is not.
		{"practice_drawn", `
			SELECT exercise_id, exercise_version, drawn_at
			FROM practice_drawn WHERE account_id = $1 ORDER BY exercise_id`},
		{"notes", `
			SELECT course_id, lesson_id, section_id, body, updated_at
			FROM notes WHERE account_id = $1 ORDER BY course_id, lesson_id, section_id`},
		// `settled_by` IS NOT NAMED. What was decided is the person's business
		// and WHO decided it is not: the answer to a report is the platform's,
		// and handing somebody the account id of the operator who read their
		// complaint is a fact about a member of staff, in a file that leaves
		// this system by design.
		{"content_reports", `
			SELECT id, course_id, lesson_id, section_id, reason, note,
			       reported_at, settled_at, verdict
			FROM content_reports WHERE account_id = $1 ORDER BY reported_at`},
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
		// EXPORTED IN FULL, INCLUDING THE PROVIDER'S REFERENCE. What somebody
		// paid, when, and what was refunded is exactly the kind of thing an
		// export exists to answer — and the reference is what lets them match a
		// row here against a line on their own card statement, which is the
		// only way they can check that this file is telling the truth.
		// WHAT THEY TRIED TO BUY AND WHAT THEY WERE ASKED FOR. Not the
		// gateway's charge id: it is our reference for a conversation with a
		// processor, it means nothing to the person, and an export is not the
		// place to publish somebody else's internal identifiers.
		{"checkout_intents", `
			SELECT id, scope, cents, currency, method, instalments, stage,
			       invoice_url, created_at, updated_at
			FROM checkout_intents WHERE account_id = $1 ORDER BY created_at`},
		// The handle, and no tax id — because there is none here to give back.
		{"payment_customers", `
			SELECT provider, customer_id, created_at
			FROM payment_customers WHERE account_id = $1 ORDER BY created_at`},
		{"ledger_entries", `
			SELECT id, occurred_at, kind, amount_cents, currency, reverses,
			       source, source_ref, memo
			FROM ledger_entries WHERE account_id = $1 ORDER BY occurred_at`},
		{"subscriptions", `
			SELECT scope, model, state, paid_through, started_at, updated_at
			FROM subscriptions WHERE account_id = $1 ORDER BY started_at`},
		// BOTH SIDES OF EVERY TRANSITION. "It became suspended" is not an
		// answer to somebody asking why they were locked out while paying;
		// what it came from, and which ledger row caused it, is.
		//
		// AND WHAT EACH ONE COST AND BOUGHT (`0043`). `subscriptions` above
		// holds one price and one date, and the next purchase overwrites both;
		// these are the only copies that outlive it. Without them an export
		// says "you renewed in March" and not at what, or until when.
		{"subscription_events", `
			SELECT occurred_at, event, from_state, to_state, ledger_entry_id,
			       price_id, paid_through
			FROM subscription_events WHERE account_id = $1 ORDER BY occurred_at`},
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
