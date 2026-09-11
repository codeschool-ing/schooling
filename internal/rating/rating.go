// Package rating is what a student thinks of a course, a track, or this place.
//
// # IT IS NOT `report`, AND THE DIFFERENCE IS THE WHOLE DESIGN
//
// `report` carries a DEFECT: this key is wrong, this video does not play, I
// cannot follow this sentence. It is precise, it names coordinates, it goes in
// a queue, somebody settles it with a verdict, and then it is finished.
//
// This carries a JUDGEMENT, and judgements do not get settled. "This course is
// thin" is not a defect of any section — there is no line to fix and no verdict
// to write — and it is the most useful thing a student can tell us, because
// nothing else in this system can measure it. The grader knows whether they
// answered; the funnel knows whether they left; neither knows whether it was
// worth their evening.
//
// Two consequences follow, and they are why this is its own package rather than
// a column on `content_reports`:
//
//   - A rating is STATE and not an event. One per person per subject, edited
//     rather than appended. Somebody who comes back after a rewrite should be
//     able to say it is better now.
//   - There is NO FREE TEXT, ever. The moment a comment box exists this becomes
//     `report` under another name, with the queue and the settling and the
//     erasure class that come with it. Five bounded integers cannot carry a
//     confession, and that is a CHECK constraint rather than a hope.
//
// # ONE STAR IS THE CONTRACT AND THE PAIRS ARE THE INFORMATION
//
// The interface may ask for exactly one gesture and must survive being given
// exactly one. A 1-to-5 alone says THAT something is wrong and never WHAT,
// which is a number to worry about rather than a number to act on — so four
// opposed pairs sit behind it, each optional, each a real question with a
// direction.
//
// # IT IMPORTS NO OTHER MODULE
//
// Whether a course or a track exists arrives as a function the caller supplies,
// the same shape `report` uses, enforced by `internal/architecture_test.go`.
package rating

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/platform/setting"
)

var (
	// ErrNoSuchSubject is a rating of a course or a track this school does not
	// have. It is checked for the reason `report` checks its coordinates: a
	// number nobody can resolve to a thing is a number nobody can act on.
	ErrNoSuchSubject = errors.New("rating: no such course or track")

	// ErrRefused wraps everything a caller can fix by sending something else —
	// an unknown kind, a star outside the scale, an aspect this does not know.
	// One sentinel and not one per rule, which is `report`'s shape: what the
	// handler needs to know is whether the person can fix it, and the sentence
	// says which part.
	ErrRefused = errors.New("rating: refused")
)

// What can be rated.
//
// THREE KINDS AND NOT A TABLE EACH. Everything about them is identical — the
// scale, the pairs, the upsert, the console read — and what differs is one word
// and what the id points at.
const (
	// KindCourse is one course. The common case, and the one a student is
	// offered at the moment they finish.
	KindCourse = "course"

	// KindTrack is a whole track, which is a different question and not the
	// mean of its courses: a track can be four good courses in an order that
	// teaches nothing.
	KindTrack = "track"

	// KindPlatform is this place — the interface, not the material. It names
	// nothing in the catalogue, which is why a subject id can be empty, and it
	// is deliberately not asked at the end of a course: "was the course good"
	// and "is this site good" contaminate each other when asked together.
	KindPlatform = "platform"
)

// Kinds is the closed list, in no particular order — nothing offers a choice
// between them, the screen a student is on decides.
var Kinds = []string{KindCourse, KindTrack, KindPlatform}

// The scale. Both ends inclusive, and the same for the stars and for all four
// pairs so that an interface has one widget rather than two.
const (
	Lowest  = 1
	Highest = 5
)

/*
THE FOUR PAIRS, WHICH ARE THE PART WORTH HAVING.

Each is answered on the same 1..5 and each has a DIRECTION that the sentence
beside it supplies. They are named here, and the sentences live in the
interface, for the reason the reasons of `report` live here: a screen holding
its own copy of the list keeps offering the old one, and what it then sends is
refused.

TWO OF THEM HAVE NO GOOD END, and that is deliberate rather than sloppy.
`completeness` and `interest` read high-is-better. `padding` does too. `depth`
does not: too easy and too hard are both misses, and the useful reading of it is
the SHAPE of the distribution rather than its mean — a course sitting at 3 for
everybody and a course where half say 1 and half say 5 have the same mean and
opposite problems. Nothing in this package encodes which end is good, precisely
so that nothing averages `depth` into a score.
*/
const (
	// AspectCompleteness — 1 something was left out, 5 nothing was missing.
	// This is C-37 with a number on it: the premise that a course omitting a
	// subject is defective, asked of the only people who can tell.
	AspectCompleteness = "completeness"

	// AspectPadding — 1 it is padded, 5 it is direct. The opposite failure to
	// the one above, and a course can manage both at once.
	AspectPadding = "padding"

	// AspectInterest — 1 it did not interest me, 5 it did.
	AspectInterest = "interest"

	// AspectDepth — 1 too easy, 5 too hard. Neither end is the good one.
	AspectDepth = "depth"
)

// Aspects is the list, in the order a person is offered it.
var Aspects = []string{AspectCompleteness, AspectPadding, AspectInterest, AspectDepth}

/*
AskDeeper is the star rating AT OR BELOW WHICH the four pairs are offered.

# WHY A THRESHOLD AT ALL

Somebody who taps five stars has told us what they think and has nothing more to
add; somebody who taps two has the information. Asking everybody the same four
questions to collect the half that is already implied is how a one-gesture
control becomes a form, which is the one thing this feature may not become.

# WHY IT IS A DECLARED PARAMETER AND NOT A CONSTANT

Because the threshold has a cost that only data can price. Offering the pairs
only below it means their distribution is CONDITIONED ON DISSATISFACTION — you
can say "here is why the low ratings are low" and you cannot say "students think
this course is complete", because the people who thought so were never asked.

That may be the right trade and it may not, and a constant would make finding
out a deploy. Set to 5 it asks everybody and the conditioning disappears; set to
1 it asks almost nobody. The console can move it with a reason, which is what
every other number of this kind here does.
*/
var AskDeeper = setting.Declared{
	Name:     "rating.askdeeper",
	Unit:     setting.Count,
	Least:    Lowest,
	Most:     Highest,
	Fallback: 3,
	Why: "the star rating at or below which a student is also offered the four pairs. Above it " +
		"they are thanked and left alone, because a five-star rating has already said what it " +
		"has to say and a fifth question is how a one-tap control becomes a form. Raising it to " +
		"five asks everybody — which costs a little patience and buys the only thing this " +
		"threshold takes away, a baseline from the people who were happy.",
}

// Known answers whether a word is on a list.
func Known(list []string, word string) bool {
	for _, one := range list {
		if one == word {
			return true
		}
	}
	return false
}

// Given is a rating as the student makes it.
//
// THE ASPECTS ARE A MAP AND NOT FOUR FIELDS, so that a client sending three of
// them, or none, is the ordinary case rather than four zero values the store
// has to guess about. An aspect this package does not know is refused rather
// than dropped: silently ignoring it would let a screen offer a fifth question
// for a release and a half before anybody noticed nothing was recorded.
type Given struct {
	School  uuid.UUID
	Account uuid.UUID

	Kind      string
	SubjectID string

	Stars   int
	Aspects map[string]int

	// Version is the release this was given against. THE SERVER'S: the handler
	// reads it from the binary. It is a field rather than something this store
	// looks up so that a test can be at two releases at once, which is the only
	// way to test the thing the column exists for.
	Version string
}

// Rating is one row.
type Rating struct {
	School  uuid.UUID
	Account uuid.UUID

	Kind      string
	SubjectID string

	Stars   int
	Aspects map[string]int

	Version   string
	RatedAt   time.Time
	ChangedAt *time.Time
}

// Knows answers whether a kind and an id name something in this school's
// catalogue. The platform is never passed to it — there is one platform and it
// is not in any catalogue.
//
// IT IS A FUNCTION BECAUSE THIS PACKAGE MAY NOT IMPORT `catalog`, which is the
// same shape and the same reason as `report.Knows`.
type Knows func(ctx context.Context, school uuid.UUID, kind, id string) (bool, error)

type Store struct {
	pool  *pgxpool.Pool
	knows Knows
}

func NewStore(pool *pgxpool.Pool, knows Knows) *Store {
	return &Store{pool: pool, knows: knows}
}

// Give records what somebody thinks, or changes what they thought.
//
// IT IS AN UPSERT AND THAT IS THE FEATURE. A rating is a state; a person who
// comes back after the course was rewritten is not a second person. `rated_at`
// keeps the first time and `changed_at` records that there was a second, which
// together are the whole history this keeps — and `rated_version` moves to the
// release the new opinion was formed against, because that is the one it is
// about.
//
// A CHANGE MAY CLEAR AN ASPECT. Sending the stars alone after having answered
// the pairs sets them back to null, which is the honest reading of somebody
// answering the short form the second time: what they told us is the stars.
func (s *Store) Give(ctx context.Context, in Given) (Rating, error) {
	in.Kind = strings.TrimSpace(in.Kind)
	in.SubjectID = strings.TrimSpace(in.SubjectID)
	in.Version = strings.TrimSpace(in.Version)

	if !Known(Kinds, in.Kind) {
		return Rating{}, fmt.Errorf("%w: %q is not something this knows how to rate — say one "+
			"of %s", ErrRefused, in.Kind, strings.Join(Kinds, ", "))
	}
	if in.Stars < Lowest || in.Stars > Highest {
		return Rating{}, fmt.Errorf("%w: %d stars is outside %d to %d",
			ErrRefused, in.Stars, Lowest, Highest)
	}

	/* THE PLATFORM NAMES NOTHING AND EVERYTHING ELSE NAMES SOMETHING. The
	   database holds the same rule as a constraint; this is the half that can
	   say which part is wrong in a sentence. */
	if in.Kind == KindPlatform {
		if in.SubjectID != "" {
			return Rating{}, fmt.Errorf("%w: the platform is not a course and has no id, "+
				"and %q was sent as one", ErrRefused, in.SubjectID)
		}
	} else {
		if in.SubjectID == "" {
			return Rating{}, fmt.Errorf("%w: a %s rating has to say which one", ErrRefused, in.Kind)
		}
		ok, err := s.knows(ctx, in.School, in.Kind, in.SubjectID)
		if err != nil {
			return Rating{}, fmt.Errorf("rating: looking for %s %q: %w", in.Kind, in.SubjectID, err)
		}
		if !ok {
			return Rating{}, ErrNoSuchSubject
		}
	}

	for name, value := range in.Aspects {
		if !Known(Aspects, name) {
			return Rating{}, fmt.Errorf("%w: %q is not one of the things this asks about — "+
				"they are %s", ErrRefused, name, strings.Join(Aspects, ", "))
		}
		if value < Lowest || value > Highest {
			return Rating{}, fmt.Errorf("%w: %s was answered %d, outside %d to %d",
				ErrRefused, name, value, Lowest, Highest)
		}
	}

	if in.Version == "" {
		in.Version = "dev"
	}

	at := func(name string) *int {
		if v, ok := in.Aspects[name]; ok {
			return &v
		}
		return nil
	}

	var out Rating
	var completeness, padding, interest, depth *int
	err := s.pool.QueryRow(ctx, `
		INSERT INTO ratings (tenant_id, account_id, subject_kind, subject_id, stars,
		                     completeness, padding, interest, depth, rated_version)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (tenant_id, account_id, subject_kind, subject_id) DO UPDATE SET
			stars         = EXCLUDED.stars,
			completeness  = EXCLUDED.completeness,
			padding       = EXCLUDED.padding,
			interest      = EXCLUDED.interest,
			depth         = EXCLUDED.depth,
			rated_version = EXCLUDED.rated_version,
			changed_at    = now()
		RETURNING subject_kind, subject_id, stars, completeness, padding, interest, depth,
		          rated_version, rated_at, changed_at`,
		in.School, in.Account, in.Kind, in.SubjectID, in.Stars,
		at(AspectCompleteness), at(AspectPadding), at(AspectInterest), at(AspectDepth),
		in.Version,
	).Scan(&out.Kind, &out.SubjectID, &out.Stars,
		&completeness, &padding, &interest, &depth,
		&out.Version, &out.RatedAt, &out.ChangedAt)
	if err != nil {
		return Rating{}, fmt.Errorf("rating: recording: %w", err)
	}

	out.School, out.Account = in.School, in.Account
	out.Aspects = map[string]int{}
	for name, value := range map[string]*int{
		AspectCompleteness: completeness, AspectPadding: padding,
		AspectInterest: interest, AspectDepth: depth,
	} {
		if value != nil {
			out.Aspects[name] = *value
		}
	}
	return out, nil
}

// Mine is everything this student has rated, so the interface can draw a
// subject they have already rated as rated — with their own stars showing,
// because a control that forgot what you told it invites you to tell it again.
//
// IT ANSWERS ONLY THIS ACCOUNT'S. There is no route anywhere that reads
// somebody else's: the aggregate is the console's, behind the console's gates.
func (s *Store) Mine(ctx context.Context, school, account uuid.UUID) ([]Rating, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT subject_kind, subject_id, stars, completeness, padding, interest, depth,
		       rated_version, rated_at, changed_at
		FROM ratings
		WHERE tenant_id = $1 AND account_id = $2
		ORDER BY subject_kind, subject_id`, school, account)
	if err != nil {
		return nil, fmt.Errorf("rating: reading a student's own: %w", err)
	}
	defer rows.Close()

	var out []Rating
	for rows.Next() {
		var one Rating
		var completeness, padding, interest, depth *int
		if err := rows.Scan(&one.Kind, &one.SubjectID, &one.Stars,
			&completeness, &padding, &interest, &depth,
			&one.Version, &one.RatedAt, &one.ChangedAt); err != nil {
			return nil, fmt.Errorf("rating: reading a student's own: %w", err)
		}
		one.School, one.Account = school, account
		one.Aspects = map[string]int{}
		for name, value := range map[string]*int{
			AspectCompleteness: completeness, AspectPadding: padding,
			AspectInterest: interest, AspectDepth: depth,
		} {
			if value != nil {
				one.Aspects[name] = *value
			}
		}
		out = append(out, one)
	}
	return out, rows.Err()
}

// Spread is how a set of answers fell across the scale, which is the only
// honest summary of one.
//
// THE COUNTS AND NOT THE MEAN, and this is the entire reason this type exists
// rather than a float. A mean of 3.0 from everybody answering 3 and a mean of
// 3.0 from half answering 1 and half answering 5 are two different problems,
// and only one of them is urgent. A console that drew the mean would show them
// as the same course.
//
// The mean is here too, because it is what a person asks for first and
// computing it twice in two places is how two numbers disagree. It is a
// convenience on top of the counts and never a substitute for them.
type Spread struct {
	// At[n] is how many answered n. Index 0 is unused so that the index is the
	// answer rather than the answer minus one, which is a subtraction somebody
	// eventually gets wrong.
	At [Highest + 1]int

	Count int
	Mean  float64
}

func (s *Spread) add(value int) {
	if value < Lowest || value > Highest {
		return
	}
	s.At[value]++
	s.Count++
	total := 0
	for n := Lowest; n <= Highest; n++ {
		total += s.At[n] * n
	}
	s.Mean = float64(total) / float64(s.Count)
}

// Summary is what one subject looks like at one release.
//
// IT IS PER RELEASE AND NOT OVERALL, which is what makes the whole table worth
// keeping. A course rewritten because it scored badly has to be comparable to
// itself, and nobody writes down the old number before the rewrite — so the row
// carries the release it was given against and this groups by it. Without that
// the only thing a rating can say is "it is bad", forever, with a mean that
// sinks more slowly after the fix.
type Summary struct {
	Kind      string
	SubjectID string
	Version   string

	Stars   Spread
	Aspects map[string]*Spread

	// When the earliest and the latest of these were given, which is how the
	// console can say whether a version's number is still moving.
	First time.Time
	Last  time.Time
}

// Over reads every rating of one kind in one school, grouped by subject and by
// the release it was given against.
//
// ONE QUERY AND THE GROUPING IN GO. The aggregate is five distributions over a
// few thousand rows at the very most, and SQL that produced it would be four
// `filter (where ...)` clauses per aspect — twenty of them — which is a query
// nobody can read and which has to be edited every time an aspect is added.
func (s *Store) Over(ctx context.Context, school uuid.UUID, kind string) ([]Summary, error) {
	if !Known(Kinds, kind) {
		return nil, fmt.Errorf("%w: %q is not something this knows how to rate", ErrRefused, kind)
	}

	rows, err := s.pool.Query(ctx, `
		SELECT subject_id, stars, completeness, padding, interest, depth,
		       rated_version, COALESCE(changed_at, rated_at)
		FROM ratings
		WHERE tenant_id = $1 AND subject_kind = $2`, school, kind)
	if err != nil {
		return nil, fmt.Errorf("rating: reading %s ratings: %w", kind, err)
	}
	defer rows.Close()

	type key struct{ subject, version string }
	seen := map[key]*Summary{}
	var order []key

	for rows.Next() {
		var subject, version string
		var stars int
		var completeness, padding, interest, depth *int
		var at time.Time
		if err := rows.Scan(&subject, &stars, &completeness, &padding, &interest, &depth,
			&version, &at); err != nil {
			return nil, fmt.Errorf("rating: reading %s ratings: %w", kind, err)
		}

		k := key{subject, version}
		one, ok := seen[k]
		if !ok {
			one = &Summary{
				Kind: kind, SubjectID: subject, Version: version,
				Aspects: map[string]*Spread{},
				First:   at, Last: at,
			}
			for _, name := range Aspects {
				one.Aspects[name] = &Spread{}
			}
			seen[k] = one
			order = append(order, k)
		}

		one.Stars.add(stars)
		for name, value := range map[string]*int{
			AspectCompleteness: completeness, AspectPadding: padding,
			AspectInterest: interest, AspectDepth: depth,
		} {
			if value != nil {
				one.Aspects[name].add(*value)
			}
		}
		if at.Before(one.First) {
			one.First = at
		}
		if at.After(one.Last) {
			one.Last = at
		}
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rating: reading %s ratings: %w", kind, err)
	}

	/* ORDERED BY WHAT WAS READ AND NOT BY THE MAP, because a console screen
	   that reshuffles itself between two loads of the same data is a screen
	   nobody trusts. The query has no ORDER BY of its own — the grouping is
	   here — so the order is the scan's, which is stable for a static table and
	   is then sorted properly by the console that draws it. */
	out := make([]Summary, 0, len(order))
	for _, k := range order {
		out = append(out, *seen[k])
	}
	return out, nil
}

// ErrNoRows is what a scan says when there is nothing; named so that callers do
// not import pgx to compare against it.
var ErrNoRows = pgx.ErrNoRows
