package practice_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/practice"
)

/* The queue that crosses schools.

   WHAT THESE TESTS ARE ABOUT IS THE THING THAT COULD NOT BE TESTED BEFORE. Every
   other test in this package works inside one school, because every route did;
   these seed a student into TWO and ask the question a school's own host cannot
   be asked. Three of them are about a gate holding across the boundary, which is
   the whole risk of a second entry point over the same rows: a paywall that
   applied at `code.` and not at `my.` would be a way to read paid material by
   typing a different address. */

// Where each school is, as the wiring answers it. The host is derived here
// rather than read from `tenant_domains`, because these tests seed schools
// directly and the shape is what is under test, not the lookup.
func places(t *testing.T, pool *pgxpool.Pool) practice.Schools {
	t.Helper()
	return func(ctx context.Context, ids []uuid.UUID) ([]practice.Where, error) {
		out := make([]practice.Where, 0, len(ids))
		for _, id := range ids {
			var slug, name string
			if err := pool.QueryRow(ctx,
				`SELECT slug, name FROM tenants WHERE id = $1`, id).Scan(&slug, &name); err != nil {
				return nil, err
			}
			out = append(out, practice.Where{
				ID: id, Slug: slug, Name: name, Host: slug + ".example.tld",
			})
		}
		return out, nil
	}
}

// Scoping, as `cmd/api` does it — except that this package may not import
// `tenant`, so the tests carry their own key. What matters for these is that
// the two gates are asked with SOMETHING that identifies the school, and both
// of them are given the id directly.
func nowhereInParticular(ctx context.Context, _ uuid.UUID) context.Context { return ctx }

// A door that closes on a whole school rather than on a course, which is the
// case a single-school test cannot produce.
func openExceptIn(locked uuid.UUID) practice.In {
	return func(ctx context.Context, school uuid.UUID) context.Context {
		if school == locked {
			return context.WithValue(ctx, lockedKey{}, true)
		}
		return ctx
	}
}

type lockedKey struct{}

func doorFor(_ context.Context, courseID string) (bool, error) {
	return courseID != "paid-course", nil
}

func doorThatReadsTheContext(ctx context.Context, courseID string) (bool, error) {
	if shut, _ := ctx.Value(lockedKey{}).(bool); shut {
		return false, nil
	}
	return doorFor(ctx, courseID)
}

// A student with a card due in each of two schools, answered yesterday and
// backdated so both are due today.
func inTwoSchools(t *testing.T, pool *pgxpool.Pool) (me, first, second uuid.UUID) {
	t.Helper()

	me = student(t, pool)
	first, second = school(t, pool), school(t, pool)
	questions(t, pool, first)
	questions(t, pool, second)

	s := store(t, pool)
	for _, where := range []uuid.UUID{first, second} {
		if _, err := answer(t, s, where, me, "free-1", true, 4*time.Second); err != nil {
			t.Fatalf("answering in a school: %v", err)
		}
	}

	// SM-2 puts a first correct answer a day out. Both are pulled back so the
	// queue has something in it today — the alternative is a test that only
	// passes tomorrow.
	if _, err := pool.Exec(context.Background(),
		`UPDATE practice_state SET due_on = current_date - 1 WHERE account_id = $1`,
		me); err != nil {
		t.Fatalf("backdating: %v", err)
	}
	return me, first, second
}

func waitingIn(all []practice.Waiting, school uuid.UUID) (practice.Waiting, bool) {
	for _, one := range all {
		if one.School == school {
			return one, true
		}
	}
	return practice.Waiting{}, false
}

// THE SENTENCE THE PHASE IS DONE WHEN IT IS TRUE: yesterday's review comes back
// today, from every school at once, in one place.
func TestWhatIsDueComesBackFromEverySchoolAtOnce(t *testing.T) {
	pool := testPool(t)
	me, first, second := inTwoSchools(t, pool)

	all, err := store(t, pool).Across(context.Background(),
		nowhereInParticular, places(t, pool), me, 20)
	if err != nil {
		t.Fatalf("reading the queue across schools: %v", err)
	}
	if len(all) != 2 {
		t.Fatalf("a student with cards due in two schools got %d school(s) back", len(all))
	}

	for _, where := range []uuid.UUID{first, second} {
		one, ok := waitingIn(all, where)
		if !ok {
			t.Fatalf("a school with a card due is not in the queue")
		}
		if !has(one.Cards, "free-1") {
			t.Errorf("the card due in %s is not in its share of the queue", one.Slug)
		}
		if one.Host == "" || one.Name == "" {
			t.Errorf("a school in the queue has no name or no address: %+v", one)
		}
	}
}

/*
A CARD IS ONLY HERE IF IT HAS A SCHEDULE.

	`Due` offers two kinds — what is scheduled and what has never been answered —
	and this queue carries only the first. `free-2` has never been answered in
	either school, so it belongs to those schools' own queues and not to this
	one: four schools' worth of never-seen questions interleaved by nothing is a
	catalogue with a timer on it, not a review.
*/
func TestAQuestionNobodyHasAnsweredIsNotInTheCrossSchoolQueue(t *testing.T) {
	pool := testPool(t)
	me, _, _ := inTwoSchools(t, pool)

	all, err := store(t, pool).Across(context.Background(),
		nowhereInParticular, places(t, pool), me, 20)
	if err != nil {
		t.Fatal(err)
	}
	for _, one := range all {
		if has(one.Cards, "free-2") {
			t.Error("a question never answered is in the review queue — that is the other " +
				"kind of card, and it belongs to a school's own screen")
		}
	}
}

// THE PAYWALL IS THE SAME PAYWALL. `paid-course` is locked by the door every
// school's queue uses, and a card in it must not appear here — an address that
// crossed schools and dropped the gate would be a way to reach paid material by
// typing a different host.
func TestACardBehindThePaywallIsNotOfferedAcrossSchoolsEither(t *testing.T) {
	pool := testPool(t)
	me := student(t, pool)
	where := school(t, pool)
	questions(t, pool, where)

	s := store(t, pool)
	// Answered while the door was open, so there IS a schedule for it — which
	// is the only way to get a locked card into the rows this reads.
	open := practice.NewStore(pool, func(context.Context, string) (bool, error) {
		return true, nil
	}, nothingWithdrawn)
	if _, err := answer(t, open, where, me, "behind-the-till", true, 3*time.Second); err != nil {
		t.Fatalf("answering while the door was open: %v", err)
	}
	if _, err := pool.Exec(context.Background(),
		`UPDATE practice_state SET due_on = current_date - 1 WHERE account_id = $1`, me); err != nil {
		t.Fatal(err)
	}

	all, err := s.Across(context.Background(), nowhereInParticular, places(t, pool), me, 20)
	if err != nil {
		t.Fatal(err)
	}
	for _, one := range all {
		if has(one.Cards, "behind-the-till") {
			t.Error("a card in a course this student may not open came back from the " +
				"cross-school queue")
		}
	}
}

/*
AND THE DOOR IS ASKED PER SCHOOL, NOT ONCE FOR THE REQUEST.

	This is the failure a single-school test cannot see: two schools hold a course
	with the same id, the student may open it in one and not the other, and a
	cache keyed on the course alone would let the first school's answer stand for
	the second's. It is keyed on both, and this is what says so.
*/
func TestOneSchoolsPaywallDoesNotAnswerForAnothers(t *testing.T) {
	pool := testPool(t)
	me, first, second := inTwoSchools(t, pool)

	s := practice.NewStore(pool, doorThatReadsTheContext, nothingWithdrawn)
	all, err := s.Across(context.Background(), openExceptIn(second), places(t, pool), me, 20)
	if err != nil {
		t.Fatal(err)
	}

	if _, ok := waitingIn(all, first); !ok {
		t.Error("the school whose door is open lost its cards")
	}
	if one, ok := waitingIn(all, second); ok {
		t.Errorf("the school whose door is shut still offered %d card(s) — one school's "+
			"paywall answered for another's", len(one.Cards))
	}
}

// A WITHDRAWN QUESTION IS WITHDRAWN HERE TOO, and it is asked per school for the
// same reason the door is: a question taken out of circulation is a fact about
// one school's catalogue.
func TestAWithdrawnCardIsNotInTheCrossSchoolQueue(t *testing.T) {
	pool := testPool(t)
	me, first, _ := inTwoSchools(t, pool)

	s := practice.NewStore(pool, mayOpen,
		func(_ context.Context, school uuid.UUID) (map[practice.Item]bool, error) {
			if school != first {
				return nil, nil
			}
			return map[practice.Item]bool{{ExerciseID: "free-1", Version: 1}: true}, nil
		})

	all, err := s.Across(context.Background(), nowhereInParticular, places(t, pool), me, 20)
	if err != nil {
		t.Fatal(err)
	}
	if one, ok := waitingIn(all, first); ok && has(one.Cards, "free-1") {
		t.Error("a question withdrawn in this school came back from the cross-school queue")
	}
	if _, ok := waitingIn(all, first); ok {
		t.Error("a school whose only due card was withdrawn is still in the queue, with " +
			"nothing in it")
	}
}

// ONE STUDENT'S QUEUE IS ONE STUDENT'S, which is the same claim the school-scoped
// queue makes and is worth making again here: this read is not scoped by a host,
// so the account is the whole of what separates two people.
func TestTheCrossSchoolQueueIsOneStudentsOwn(t *testing.T) {
	pool := testPool(t)
	me, _, _ := inTwoSchools(t, pool)
	somebodyElse := student(t, pool)

	all, err := store(t, pool).Across(context.Background(),
		nowhereInParticular, places(t, pool), somebodyElse, 20)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 0 {
		t.Errorf("a student who has practised nowhere got %d school(s) of somebody else's "+
			"queue", len(all))
	}

	mine, err := store(t, pool).Across(context.Background(),
		nowhereInParticular, places(t, pool), me, 20)
	if err != nil {
		t.Fatal(err)
	}
	if len(mine) == 0 {
		t.Error("and the student who did practise got nothing, so the check above proves " +
			"nothing")
	}
}

// A STUDENT WITH NOTHING DUE IS NOT AN ERROR, and the empty answer has to be
// distinguishable from a read that failed — the screen says something different
// for each.
func TestAStudentWithNothingDueGetsAnEmptyQueue(t *testing.T) {
	pool := testPool(t)
	me := student(t, pool)

	all, err := store(t, pool).Across(context.Background(),
		nowhereInParticular, places(t, pool), me, 20)
	if err != nil {
		t.Fatalf("a student with nothing due is an error: %v", err)
	}
	if len(all) != 0 {
		t.Errorf("got %d school(s) for a student who has never practised", len(all))
	}
}

// THE WIRING MISTAKE IS AN ERROR AND NOT AN EMPTY QUEUE. A handler built without
// a way to scope a school would otherwise answer every student "nothing due",
// which is the most convincing possible way to be broken.
func TestAQueueWiredWithoutAWayToScopeRefuses(t *testing.T) {
	pool := testPool(t)
	me := student(t, pool)

	_, err := store(t, pool).Across(context.Background(), nil, places(t, pool), me, 20)
	if err == nil {
		t.Error("a queue with no way to scope a school answered as though the student had none")
	}
}

/* ---------- the address ---------- */

// ONE PLACE THE DOMAIN IS WRITTEN, which is `console.HostOf`'s argument in the
// same words. The empty case is the one that matters: a deployment with no
// platform domain configured must not produce a host of `my.`, which would
// match nothing and be reported as a routing bug.
func TestThePlatformsAddressIsDerivedFromTheDomain(t *testing.T) {
	for domain, want := range map[string]string{
		"example.tld":      "my.example.tld",
		"  Schooling.App ": "my.schooling.app",
		"":                 "",
		"   ":              "",
	} {
		if got := practice.Host(domain); got != want {
			t.Errorf("Host(%q) = %q, want %q", domain, got, want)
		}
	}
}

/*
AND IT IS A LABEL NO SCHOOL CAN TAKE.

	The reservation goes in before the address answers anywhere, which is the
	only order in which such a rule works: added after a school had taken the
	name, it is a migration that cannot run — and the way out of that is renaming
	a school students have bookmarked.

	BOTH LABELS ARE CHECKED, because the one that is NOT used is the one that
	quietly stops being reserved. `app` was going to be this address until the
	domain became `schooling.app` and `app.schooling.app` turned out to be a
	stutter; `0033` keeps it anyway, and this is what would notice if a later
	migration tidied it away.
*/
func TestTheLabelThePlatformUsesIsReserved(t *testing.T) {
	pool := testPool(t)

	for _, label := range []string{"my", "app"} {
		_, err := pool.Exec(context.Background(),
			`INSERT INTO tenants (slug, name) VALUES ($1, 'A school that would shadow the platform')`,
			label)
		if err == nil {
			t.Fatalf("a school was created at %q, which the platform answers on or has "+
				"reserved against exactly that", label)
		}
		if !strings.Contains(err.Error(), "reserved") {
			t.Errorf("%q was refused for the wrong reason: %v", label, err)
		}
	}
}

/* ---------- the sentence the server writes ---------- */

/*
THE ONE STRING NO STATIC SCAN CAN CATCH, held here instead.

	`check-interface` reads literal `txt('…')` calls out of the interface and
	asks the dictionary for each one. `About` is not one: it arrives over HTTP,
	in English, and is translated at the point of display — so the tool sees the
	dictionary entry with nothing saying it, reports it as an entry the interface
	does not say, and cannot tell that from a genuinely stale line.

	Which leaves the two halves free to drift apart, and they did: the paragraph
	shipped in English under two translated ones. Rewording this constant is the
	way it happens again, because the rewording is in Go and the dictionary is in
	JavaScript and nothing else joins them.

	IT COMPARES THE ESCAPED FORM, because the sentence contains an apostrophe and
	the dictionary is single-quoted JavaScript. That is not incidental: a key
	written `school's` in a `'…'` literal is a syntax error, so the escaping is
	part of what has to match.
*/
func TestThePortugueseCarriesTheServersSentence(t *testing.T) {
	const dictionary = "../../ui/my/assets/i18n-pt.js"

	source, err := os.ReadFile(dictionary)
	if err != nil {
		t.Fatalf("reading %s: %v", dictionary, err)
	}

	key := "'" + strings.ReplaceAll(practice.About, "'", `\'`) + "':"
	if !strings.Contains(string(source), key) {
		t.Errorf("%s does not translate the sentence the server sends.\n\n"+
			"It has to carry this key, character for character:\n\n  %s\n\n"+
			"Without it the paragraph under the queue reads in English on a page "+
			"read in Portuguese. If `About` was reworded, reword the key with it.",
			dictionary, key)
	}
}
