package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The funnel screen's half of the contract, against fakes.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES. Whether the arithmetic is
   right is `analysis`'s test, and whether the SQL counts the right rows is
   `event`'s against a real Postgres. What this file holds is the part in
   between, and it is almost entirely about ONE hazard: that the population a
   request asked for and the population the answer is about are the same one. */

type funnelFake struct {
	schools []console.School

	// What the seam was actually asked for, on the last call.
	askedFor string
	askedAt  time.Time
	fail     bool

	// The item analysis this fake answers with, and whether it was asked at all.
	rollup console.Rollup
	asked  bool

	// The cohorts, and what the seam was asked for.
	table        []console.Cohort
	askedMonths  int
	askedCohorts string
}

func (f *funnelFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewUnderstandHandler(
		console.Schools{
			All: func(context.Context) ([]console.School, error) { return f.schools, nil },
		},
		func(_ context.Context, _ uuid.UUID, since time.Time,
			counting string) ([]console.Step, error) {

			f.askedFor, f.askedAt = counting, since
			if f.fail {
				return nil, fmt.Errorf("the stream is not there")
			}
			return []console.Step{
				{Label: "Arrived", People: 12, Measured: true},
				{Label: "Subscribed", Measured: false, Why: "there is no gateway yet"},
			}, nil
		},
		func(context.Context, uuid.UUID) (console.Rollup, error) {
			f.asked = true
			if f.fail {
				return console.Rollup{}, fmt.Errorf("the rollup is not there")
			}
			return f.rollup, nil
		},
		func(_ context.Context, _ uuid.UUID, months int,
			counting string) ([]console.Cohort, string, error) {

			f.askedMonths, f.askedCohorts = months, counting
			if f.fail {
				return nil, "", fmt.Errorf("the stream is not there")
			}
			return f.table, "section.completed", nil
		},
	).Routes(mux)
	return mux
}

// `school_test.go` has an `aSchool` of its own and it returns that file's fake,
// so this one is named for what it is: the row, not the harness around it.
func oneSchool() console.School {
	return console.School{ID: uuid.New(), Slug: "code", Name: "Programming"}
}

func askFunnel(t *testing.T, f *funnelFake, school uuid.UUID, query string) (int, map[string]any) {
	t.Helper()
	r := httptest.NewRequest(http.MethodGet,
		"/console/api/v1/schools/"+school.String()+"/funnel"+query, nil)
	w := httptest.NewRecorder()
	f.handler().ServeHTTP(w, r)

	var body map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, w.Body.String())
	}
	return w.Code, body
}

// THE DEFAULT IS REAL PEOPLE, and it is the default in the request rather than
// only in the SQL. A screen opened with no opinion is a screen about the
// platform's actual students (K-11).
func TestAskingNothingCountsRealPeople(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}}

	code, body := askFunnel(t, f, school.ID, "")
	if code != http.StatusOK {
		t.Fatalf("asking for a school's funnel answered %d: %v", code, body)
	}
	if f.askedFor != "real" {
		t.Errorf("a request with no population read %q", f.askedFor)
	}
	if body["counting"] != "real" {
		t.Errorf("the answer says it counted %v", body["counting"])
	}
	if body["banner"] != "" {
		t.Errorf("real people need no banner, and one came back: %v", body["banner"])
	}
}

// THE HAZARD THIS WHOLE FILE IS ABOUT. The word travels to the reader AND comes
// back on the answer, so a screen cannot draw one population under a heading
// naming another.
func TestThePopulationAskedForIsTheOneReadAndTheOneReportedBack(t *testing.T) {
	school := oneSchool()

	for _, who := range []string{"real", "seeded", "everybody"} {
		f := &funnelFake{schools: []console.School{school}}
		code, body := askFunnel(t, f, school.ID, "?counting="+who)
		if code != http.StatusOK {
			t.Fatalf("%q answered %d: %v", who, code, body)
		}
		if f.askedFor != who {
			t.Errorf("asked for %q and the seam was told %q", who, f.askedFor)
		}
		if body["counting"] != who {
			t.Errorf("asked for %q and the answer says %v", who, body["counting"])
		}

		// And the two that are not the truth say so on the answer, not on the
		// screen — a banner the interface holds is a banner that can be shown
		// over the wrong numbers.
		banner, _ := body["banner"].(string)
		if who == "real" && banner != "" {
			t.Errorf("real people came back with a banner: %q", banner)
		}
		if who != "real" && banner == "" {
			t.Errorf("%q came back with nothing saying the numbers are not about "+
				"real people", who)
		}
	}
}

// A WORD IT DOES NOT KNOW IS A REFUSAL AND NOT A QUIET FALLBACK.
//
// The stream answers `everbody` with real people, which is right for SQL and
// wrong for a screen: the chart would be real students under a switch reading
// "including the seeded population". Nothing may be read at all in that case.
func TestAMisspeltPopulationIsRefusedRatherThanAnswered(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}}

	code, body := askFunnel(t, f, school.ID, "?counting=everbody")
	if code != http.StatusBadRequest {
		t.Fatalf("a misspelt population answered %d: %v", code, body)
	}
	if f.askedFor != "" {
		t.Errorf("it was refused and the funnel was read anyway, as %q", f.askedFor)
	}
}

// The window is a whole number of days, and a negative one is somebody meaning
// something. Answering it with thirty days, or with everything, is a guess
// dressed as an answer.
func TestTheWindowIsDaysAndANegativeOneIsRefused(t *testing.T) {
	school := oneSchool()

	f := &funnelFake{schools: []console.School{school}}
	if code, body := askFunnel(t, f, school.ID, "?days=30"); code != http.StatusOK {
		t.Fatalf("thirty days answered %d: %v", code, body)
	}
	if f.askedAt.IsZero() {
		t.Error("`days=30` read since the beginning")
	}

	for _, bad := range []string{"?days=-30", "?days=soon", "?days=1.5"} {
		f := &funnelFake{schools: []console.School{school}}
		if code, body := askFunnel(t, f, school.ID, bad); code != http.StatusBadRequest {
			t.Errorf("%q answered %d: %v", bad, code, body)
		}
	}

	// Nothing and zero are the same question, and both mean everything.
	for _, all := range []string{"", "?days=0"} {
		f := &funnelFake{schools: []console.School{school}}
		if code, _ := askFunnel(t, f, school.ID, all); code != http.StatusOK {
			t.Errorf("%q answered %d", all, code)
		}
		if !f.askedAt.IsZero() {
			t.Errorf("%q read from %v rather than the beginning", all, f.askedAt)
		}
	}
}

// AN ID BELONGING TO NOBODY IS A 404 AND NOT EIGHT ZEROES, which would read as
// a school everybody left.
func TestASchoolThatDoesNotExistIsNotAnEmptyFunnel(t *testing.T) {
	f := &funnelFake{schools: []console.School{oneSchool()}}

	code, _ := askFunnel(t, f, uuid.New(), "")
	if code != http.StatusNotFound {
		t.Errorf("a school nobody has answered %d", code)
	}
	if f.askedFor != "" {
		t.Error("the funnel was read for a school that does not exist")
	}
}

// A step nothing emits keeps saying so all the way to the browser. Flattened to
// a zero on the way out it would report a missing feature as the worst drop-off
// on the screen.
func TestAnUnmeasuredStepStaysUnmeasuredInTheAnswer(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}}

	code, body := askFunnel(t, f, school.ID, "")
	if code != http.StatusOK {
		t.Fatalf("answered %d", code)
	}

	steps, ok := body["steps"].([]any)
	if !ok || len(steps) != 2 {
		t.Fatalf("the answer carries %v", body["steps"])
	}
	last, _ := steps[1].(map[string]any)
	if last["measured"] != false {
		t.Errorf("an unmeasured step came back as %v", last["measured"])
	}
	if last["why"] == nil || last["why"] == "" {
		t.Error("an unmeasured step came back with nothing saying what is missing")
	}
}

/* ---------- what the answers say about a question ---------- */

func askQuestions(t *testing.T, f *funnelFake, school uuid.UUID) (int, map[string]any) {
	t.Helper()
	r := httptest.NewRequest(http.MethodGet,
		"/console/api/v1/schools/"+school.String()+"/questions", nil)
	w := httptest.NewRecorder()
	f.handler().ServeHTTP(w, r)

	var body map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, w.Body.String())
	}
	return w.Code, body
}

func aRollup() console.Rollup {
	return console.Rollup{
		Questions: []console.Question{{
			ExerciseID: "ex-6yyzbgfd", Version: 1, Type: "choice",
			Attempts: 41, Correct: 19, Difficulty: 0.46, Discrimination: -0.32,
			StrongGroup: 11, WeakGroup: 11, Verdict: "inverted", MinimumSample: 30,
			Withdrawn:   true,
			FirstAnswer: time.Date(2026, 3, 1, 9, 0, 0, 0, time.UTC),
			LastAnswer:  time.Date(2026, 8, 1, 9, 0, 0, 0, time.UTC),
		}},
		Thresholds: console.Thresholds{
			MinimumSample: 30, GroupShare: 0.27, InvertedBelow: -0.10,
			WeakBelow: 0.15, TooEasyAbove: 0.95, TooHardBelow: 0.05,
		},
		ComputedAt: time.Date(2026, 8, 22, 3, 0, 0, 0, time.UTC),
		Computed:   true,
	}
}

// THE BARS COME FROM THE CODE THAT APPLIED THEM, all six of them.
//
// This is the roadmap's "every threshold displayed beside the number it
// produced". A screen writing `-0.10` into its own markup would be a second copy
// of a decision — and the copy is the one that goes wrong, because the constant
// moves and the screen keeps saying what it used to be. The only way it cannot
// is if the screen never holds one.
func TestEveryThresholdComesBackWithTheNumbers(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}, rollup: aRollup()}

	code, body := askQuestions(t, f, school.ID)
	if code != http.StatusOK {
		t.Fatalf("the item analysis answered %d: %v", code, body)
	}

	bars, ok := body["thresholds"].(map[string]any)
	if !ok {
		t.Fatalf("no thresholds came back: %v", body["thresholds"])
	}
	for name, want := range map[string]float64{
		"minimum_sample": 30, "group_share": 0.27, "inverted_below": -0.10,
		"weak_below": 0.15, "too_easy_above": 0.95, "too_hard_below": 0.05,
	} {
		got, present := bars[name].(float64)
		if !present {
			t.Errorf("the answer carries no %q, so the screen would have to know it", name)
			continue
		}
		if got != want {
			t.Errorf("%q came back as %v, want %v", name, got, want)
		}
	}
}

// WHETHER A QUESTION IS OUT OF CIRCULATION IS READ, NOT INFERRED.
//
// The sweep runs nightly, so a question flagged this afternoon is flagged AND
// still being asked; one released by hand is in circulation carrying the verdict
// it was condemned on. A screen deriving one from the other would be confidently
// wrong in both directions, so the field survives to the browser on its own.
func TestWhetherAQuestionIsWithdrawnTravelsOnItsOwn(t *testing.T) {
	school := oneSchool()

	rollup := aRollup()
	rollup.Questions = append(rollup.Questions, console.Question{
		ExerciseID: "ex-still-asked", Version: 1, Type: "choice",
		Attempts: 44, Correct: 20, Discrimination: -0.31,
		StrongGroup: 12, WeakGroup: 12, Verdict: "inverted", MinimumSample: 30,
		Withdrawn: false, // flagged tonight, swept tomorrow
	})
	f := &funnelFake{schools: []console.School{school}, rollup: rollup}

	code, body := askQuestions(t, f, school.ID)
	if code != http.StatusOK {
		t.Fatalf("answered %d", code)
	}

	rows, _ := body["questions"].([]any)
	if len(rows) != 2 {
		t.Fatalf("two questions went in and %d came out", len(rows))
	}
	first, _ := rows[0].(map[string]any)
	second, _ := rows[1].(map[string]any)
	if first["withdrawn"] != true {
		t.Error("a withdrawn question came back as still in circulation")
	}
	if second["withdrawn"] != false {
		t.Error("a question flagged and not yet swept came back as withdrawn — " +
			"the two are a night apart and the screen has to be able to say which")
	}
	if first["verdict"] != second["verdict"] {
		t.Error("the fixture is wrong: both are inverted, and the point is that the " +
			"verdict does not decide the quarantine")
	}
}

// A JOB THAT NEVER RAN AND A SCHOOL WITH NO QUESTIONS LOOK IDENTICAL IN THE DATA
// AND ARE DIFFERENT PROBLEMS. The first is broken machinery; the second is a
// school nobody has answered anything in.
func TestNeverComputedIsNotTheSameAsNothingToSay(t *testing.T) {
	school := oneSchool()

	// Never run: no rows, and nothing to date them by.
	f := &funnelFake{schools: []console.School{school}}
	code, body := askQuestions(t, f, school.ID)
	if code != http.StatusOK {
		t.Fatalf("answered %d", code)
	}
	if body["computed"] != false {
		t.Errorf("a rollup that was never made says computed=%v", body["computed"])
	}
	if body["computed_at"] != "" && body["computed_at"] != nil {
		t.Errorf("a rollup that was never made carries a date: %v", body["computed_at"])
	}

	// Run, and it found nothing to say — which is an answer.
	f = &funnelFake{schools: []console.School{school}, rollup: console.Rollup{
		ComputedAt: time.Date(2026, 8, 22, 3, 0, 0, 0, time.UTC), Computed: true,
	}}
	_, body = askQuestions(t, f, school.ID)
	if body["computed"] != true {
		t.Error("a run that found nothing came back as never having run")
	}
	if body["computed_at"] == "" || body["computed_at"] == nil {
		t.Error("a run that found nothing came back with no date, so a stale screen " +
			"would be indistinguishable from a fresh one")
	}
}

// THE ABSENCE OF THE SWITCH IS SAID RATHER THAN LEFT TO BE NOTICED. The funnel
// beside this screen has one; an operator who has seen it would reasonably look
// for it here, and the reason there is none is a rule (K-11) rather than an
// omission.
func TestTheItemAnalysisSaysItIsRealPeopleAndWhyThereIsNoChoice(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}, rollup: aRollup()}

	_, body := askQuestions(t, f, school.ID)
	if body["counting"] != "real" {
		t.Errorf("the item analysis says it counted %v", body["counting"])
	}
	if why, _ := body["why_no_switch"].(string); why == "" {
		t.Error("there is no switch on this screen and nothing saying why not")
	}
}

// An id belonging to nobody is a 404 rather than a school whose questions are
// all fine.
func TestQuestionsOfASchoolThatDoesNotExist(t *testing.T) {
	f := &funnelFake{schools: []console.School{oneSchool()}, rollup: aRollup()}

	code, _ := askQuestions(t, f, uuid.New())
	if code != http.StatusNotFound {
		t.Errorf("a school nobody has answered %d", code)
	}
	if f.asked {
		t.Error("the rollup was read for a school that does not exist")
	}
}

/* ---------- who started when ---------- */

func askCohorts(t *testing.T, f *funnelFake, school uuid.UUID, query string) (int, map[string]any) {
	t.Helper()
	r := httptest.NewRequest(http.MethodGet,
		"/console/api/v1/schools/"+school.String()+"/cohorts"+query, nil)
	w := httptest.NewRecorder()
	f.handler().ServeHTTP(w, r)

	var body map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, w.Body.String())
	}
	return w.Code, body
}

func aTable() []console.Cohort {
	return []console.Cohort{
		{Month: time.Date(2026, 3, 1, 0, 0, 0, 0, time.UTC), People: 40, Active: []int{31, 18, 11}},
		{Month: time.Date(2026, 4, 1, 0, 0, 0, 0, time.UTC), People: 52, Active: []int{44, 25}},
		{Month: time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC), People: 61, Active: []int{50}},
	}
}

// A MONTH IS A BUCKET AND NOT A MOMENT, and the wire says so: `2026-03`, not an
// instant with a timezone on it that a browser would render in its own.
func TestACohortsMonthIsABucketAndNotAnInstant(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}, table: aTable()}

	code, body := askCohorts(t, f, school.ID, "")
	if code != http.StatusOK {
		t.Fatalf("the cohorts answered %d: %v", code, body)
	}
	rows, _ := body["cohorts"].([]any)
	if len(rows) != 3 {
		t.Fatalf("three cohorts went in and %d came out", len(rows))
	}
	first, _ := rows[0].(map[string]any)
	if first["month"] != "2026-03" {
		t.Errorf("the month came back as %v, want a bucket like 2026-03", first["month"])
	}
}

// THE TRIANGLE SURVIVES THE WIRE. A younger cohort has fewer months, and padding
// it out on the way to the browser would draw a cliff where nothing has happened
// yet — the same mistake as reporting an unmeasured funnel step as zero.
func TestAYoungerCohortStaysShorterInTheAnswer(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}, table: aTable()}

	_, body := askCohorts(t, f, school.ID, "")
	rows, _ := body["cohorts"].([]any)

	want := []int{3, 2, 1}
	for i, n := range want {
		row, _ := rows[i].(map[string]any)
		active, _ := row["active"].([]any)
		if len(active) != n {
			t.Errorf("cohort %d carries %d months, want %d — the table is triangular "+
				"because the future has not happened", i, len(active), n)
		}
	}
}

// WHAT "ACTIVE" MEANS COMES BACK WITH THE NUMBERS. A cohort table means whatever
// that word means, so a screen drawing one without saying it is a screen whose
// numbers cannot be argued with. It is the same rule as the item analysis's
// thresholds, one report over.
func TestTheCohortsSayWhatCountsAsActive(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}, table: aTable()}

	_, body := askCohorts(t, f, school.ID, "")
	if body["active"] != "section.completed" {
		t.Errorf("the answer says activity is %v, and the screen would have to guess",
			body["active"])
	}
}

// THE HALF THAT IS NOT BUILT SAYS SO. Grouping by subscription start needs a
// subscription in the stream and there is none — and an empty table would read
// as "nobody ever subscribed", which is a claim about students rather than about
// a missing payment gateway.
func TestGroupingBySubscriptionSaysItIsNotBuiltRatherThanEmpty(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}, table: aTable()}

	_, body := askCohorts(t, f, school.ID, "")
	if body["by_subscription"] != false {
		t.Errorf("the answer claims cohorts by subscription: %v", body["by_subscription"])
	}
	if why, _ := body["why_no_subscription"].(string); why == "" {
		t.Error("the half that is missing came back with nothing saying why")
	}
}

// The population switch is the funnel's, on this report too — it reads the same
// stream and may be told to look at the seeded students for the same reason.
func TestTheCohortsCarryThePopulationTheyWereAskedFor(t *testing.T) {
	school := oneSchool()

	for _, who := range []string{"real", "seeded", "everybody"} {
		f := &funnelFake{schools: []console.School{school}, table: aTable()}
		code, body := askCohorts(t, f, school.ID, "?counting="+who)
		if code != http.StatusOK {
			t.Fatalf("%q answered %d", who, code)
		}
		if f.askedCohorts != who {
			t.Errorf("asked for %q and the seam was told %q", who, f.askedCohorts)
		}
		if body["counting"] != who {
			t.Errorf("asked for %q and the answer says %v", who, body["counting"])
		}
	}

	f := &funnelFake{schools: []console.School{school}, table: aTable()}
	if code, _ := askCohorts(t, f, school.ID, "?counting=everbody"); code != http.StatusBadRequest {
		t.Errorf("a misspelt population answered %d", code)
	}
	if f.askedCohorts != "" {
		t.Error("it was refused and the cohorts were read anyway")
	}
}

// A CEILING ON THE MONTHS, because each one is a column on the screen and a
// column in every row above it. `months=100000` is a table nobody can read.
func TestTheNumberOfMonthsIsBoundedAndDefaulted(t *testing.T) {
	school := oneSchool()

	f := &funnelFake{schools: []console.School{school}, table: aTable()}
	if code, _ := askCohorts(t, f, school.ID, ""); code != http.StatusOK {
		t.Fatalf("asking for nothing answered %d", code)
	}
	if f.askedMonths != 12 {
		t.Errorf("the default is %d months, want a year", f.askedMonths)
	}

	for _, bad := range []string{"?months=0", "?months=-3", "?months=100000", "?months=soon"} {
		f := &funnelFake{schools: []console.School{school}, table: aTable()}
		if code, _ := askCohorts(t, f, school.ID, bad); code != http.StatusBadRequest {
			t.Errorf("%q answered %d", bad, code)
		}
		if f.askedMonths != 0 {
			t.Errorf("%q was refused and the cohorts were read anyway, over %d months",
				bad, f.askedMonths)
		}
	}
}
