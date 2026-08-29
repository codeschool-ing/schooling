package main

import (
	"fmt"
	"math"
	"math/rand"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/analysis"
	"github.com/codeschool-ing/schooling/internal/event"
)

/* The population, as a plan and before anything is written.

   THIS FILE TOUCHES NO DATABASE. What comes out of `populate` is a list of
   people and the moments they lived, and a test can read it without a Postgres
   — which is what makes "does the seeder produce a shape" a question with an
   answer rather than a thing somebody looks at on a screen afterwards.

   # A PERSON IS TWO NUMBERS

   `grit` decides how far down the funnel they get and `ability` decides how they
   answer. They are separate because conflating them is the classic mistake of a
   made-up population: a funnel where everybody who reaches the exam passes it is
   a funnel with no shape in the half that matters, and an item analysis where
   the strong students are simply the ones who kept going measures persistence
   and calls it knowledge.

   # THE DROP-OFFS ARE PESSIMISTIC ON PURPOSE

   Roughly nine people in a hundred who arrive will sit an exam. That is a
   plausible funnel for a product nobody has heard of, and it is the reason the
   command refuses to run for too few people: a screen showing `insufficient`
   against every question is a screen that reads as broken.

   # WHAT IT DOES NOT INVENT

   No subscription row and no ledger entry — see the command's header. A person
   the model decided is paying carries `full` in the plan dimension of their
   later events, which is what the stream would say, and nothing else in the
   database claims they paid. */

// The chance of surviving each step, before the person's own grit shifts it.
const (
	signsUp           = 0.45
	opensATrack       = 0.80
	opensALesson      = 0.85
	finishesASection  = 0.75
	finishesTheCourse = 0.55
	sitsTheExam       = 0.70
)

// reachesTheExam is the estimate the command refuses too small a population
// with. Grit shifts each step up or down around its base and is centred, so the
// product of the bases is what the whole population averages out to.
const reachesTheExam = signsUp * opensATrack * opensALesson *
	finishesASection * finishesTheCourse * sitsTheExam

// enoughPeople is the smallest population that puts the minimum sample through
// every exam question. It is arithmetic and it is stated once, because it is
// both the refusal above and the number that refusal has to suggest.
//
// IT IS THE SHIPPED SAMPLE AND NOT THE DEPLOYMENT'S. `MinimumSample` became a
// parameter, and a seeder that sized its population from whatever a console
// happens to be set to would plant a different fixture on two machines running
// the same command — and would need a database open to answer a question about
// how many people to invent. What this number is for is a demonstration that
// can be read, against the platform as it ships.
var enoughPeople = int(math.Ceil(float64(analysis.MinimumSample.Fallback) / reachesTheExam))

// How often the less common things happen.
const (
	onASecondDevice = 0.25 // a person who arrives again on another browser
	signsUpTwice    = 0.06 // the duplicate signup: one person, two accounts
	confirmsAddress = 0.68 // follows the link in the confirmation mail
	comesBack       = 0.22 // a gap of weeks in the middle of the story
	pays            = 0.30 // of those who get through the free course
	sitsItAgain     = 0.35 // of those who failed
)

type life struct {
	country, locale string

	visitors []visitorSpec
	accounts []accountSpec
	moments  []moment
}

type visitorSpec struct {
	path, referrer           string
	source, medium, campaign string
}

type accountSpec struct {
	name, email string

	// visitor is which of the person's browsers signed up, as an index. The
	// duplicate signup is the same browser twice, which is what makes it a
	// duplicate rather than two people.
	visitor int
}

// moment is one event, with the identities as INDEXES into the life rather than
// ids. Nothing here has been written yet, so there are no ids to hold; −1 is
// "this event carries no such identity", which is a real thing an arrival is.
type moment struct {
	name    string
	at      time.Time
	visitor int
	account int
	plan    string
	payload map[string]any
}

// populate plans everybody.
func populate(r *rand.Rand, s shape, from, to time.Time, people int) []life {
	run := fmt.Sprintf("%d", from.Unix()%100000)
	lives := make([]life, 0, people)
	for i := 0; i < people; i++ {
		lives = append(lives, one(r, s, from, to, run, i))
	}
	return lives
}

func one(r *rand.Rand, s shape, from, to time.Time, run string, n int) life {
	grit, ability := r.Float64(), r.Float64()
	country, locale := where(r)

	l := life{country: country, locale: locale}
	l.visitors = append(l.visitors, arrival(r))

	// Somewhere in the window, and never so late that the story would run past
	// today: a person who arrived yesterday and finished a course is not a
	// person, it is a clock that was not looked at.
	window := to.Sub(from)
	at := from.Add(time.Duration(r.Float64() * float64(window)))
	plan := event.PlanNone

	// `plan` is captured rather than passed: it changes once, partway through the
	// story, and every moment after that carries the new value.
	add := func(name string, visitor, account int, payload map[string]any) bool {
		if at.After(to) {
			return false // still going, which is what most people are
		}
		l.moments = append(l.moments, moment{
			name: name, at: at, visitor: visitor, account: account,
			plan: plan, payload: payload,
		})
		return true
	}

	// A SECOND BROWSER IS THE SAME PERSON. It is seeded because the funnel has
	// to fold two identities into one, and a population where nobody ever
	// arrived twice would let a wrong answer to that pass.
	browser := 0
	if r.Float64() < onASecondDevice {
		l.visitors = append(l.visitors, arrival(r))
	}

	if !add("visitor.arrived", browser, -1, map[string]any{
		"path": l.visitors[browser].path,
	}) {
		return l
	}

	if !survives(r, signsUp, grit) {
		return l // arrived and never came back, which is most people
	}
	at = at.Add(hours(r, 1, 48))
	if len(l.visitors) > 1 {
		browser = 1 // they came back on the other one
	}

	who, address := name(r, run, n)
	l.accounts = append(l.accounts, accountSpec{name: who, email: address, visitor: browser})
	if !add("account.created", browser, 0, nil) {
		return l
	}

	/* THE DUPLICATE SIGNUP, and it is here rather than at the end because that
	   is when it happens: somebody signs up, does not find the mail, and signs
	   up again the same evening. It is one person with two accounts on one
	   browser — which is the case the funnel's person-definition has to survive,
	   because that map holds one account per visitor. */
	if r.Float64() < signsUpTwice {
		// THE CLOCK MOVES WITH IT rather than the second signup being a moment
		// off to the side. Appended without advancing `at`, the next step of the
		// journey landed BEFORE it and the person's own history ran backwards —
		// which the model's test caught and nothing else would have, because
		// every event in it is individually plausible.
		at = at.Add(hours(r, 0, 6))
		other, otherAddress := name(r, run+"b", n)
		l.accounts = append(l.accounts,
			accountSpec{name: other, email: otherAddress, visitor: browser})
		if !add("account.created", browser, 1, nil) {
			return l
		}
	}

	/* CONFIRMING IS NOT A GATE, WHICH IS WHY IT IS NOT A `survives` CALL.

	   `survives` ends the journey; this does not. Registering signs a student in
	   and nothing waits on the address being proved, so somebody who never opens
	   the mail carries on to a track exactly as if they had. Modelled as a gate,
	   this would invent a third of the population dropping out of a step nobody
	   can drop out of — and the funnel screen would show it as a wall.

	   It happens BEFORE the track opens because that is the order in life: the
	   mail arrives within minutes and the next session is a day later. */
	if r.Float64() < confirmsAddress {
		at = at.Add(hours(r, 0, 12))
		if !add("account.confirmed", browser, 0, nil) {
			return l
		}
	}

	if !survives(r, opensATrack, grit) {
		return l
	}
	at = at.Add(hours(r, 0, 24))
	if !add("track.opened", browser, 0, map[string]any{"track": s.track}) {
		return l
	}

	// COMING BACK AFTER WEEKS IS A SHAPE THE FUNNEL HAS TO SURVIVE. A person who
	// arrived in March and finished a section in May is one person and one
	// journey, and a report that counted them per month would be counting a
	// visit rather than a person.
	if r.Float64() < comesBack {
		at = at.Add(hours(r, 20*24, 60*24))
	}

	if !survives(r, opensALesson, grit) || s.lesson == "" {
		return l
	}
	at = at.Add(hours(r, 0, 72))
	if !add("lesson.opened", browser, 0, map[string]any{
		"course": s.course, "lesson": s.lesson,
	}) {
		return l
	}

	// The sections, one at a time, with somebody stopping partway through.
	done := 0
	for _, section := range s.sections {
		if !survives(r, finishesASection, grit) {
			return l
		}
		at = at.Add(hours(r, 1, 96))
		if !add("section.completed", browser, 0, map[string]any{
			"course": s.course, "lesson": s.lesson, "section": section,
		}) {
			return l
		}
		done++
	}
	if done == 0 {
		return l
	}

	if !survives(r, finishesTheCourse, grit) {
		return l
	}
	at = at.Add(hours(r, 12, 240))
	if !add("course.completed", browser, 0, map[string]any{"course": s.course}) {
		return l
	}

	// PAYING IS A CHANGE OF DIMENSION AND NOT A ROW. From here on their events
	// carry `full`, which is what the stream would have said. Nothing else in
	// the database says they paid, because nothing else may be invented.
	if r.Float64() < pays {
		plan = "full"
	}

	if !survives(r, sitsTheExam, grit) || len(s.questions) == 0 {
		return l
	}
	at = at.Add(hours(r, 2, 120))

	passed := sit(r, s, &l, &at, to, browser, plan, ability)
	if !passed && r.Float64() < sitsItAgain {
		at = at.Add(hours(r, 48, 720))
		// A RESIT IS A SECOND ATTEMPT AND NOT A SECOND PERSON. Item analysis
		// groups by attempt, so somebody who sat twice is two rows in the
		// grouping and one person in the funnel — which is correct, and is only
		// correct because the attempt id travels on every answer.
		sit(r, s, &l, &at, to, browser, plan, ability+0.1)
	}
	return l
}

// sit answers one paper, and writes the events one at a time so that the mark of
// the whole attempt can travel on every one of them.
func sit(r *rand.Rand, s shape, l *life, at *time.Time, to time.Time,
	browser int, plan string, ability float64) bool {

	// A paper that would have been sat after today is a paper nobody has sat.
	if at.After(to) {
		return false
	}
	attempt := uuid.NewString()

	right := make([]bool, len(s.questions))
	score := 0
	for i, q := range s.questions {
		var chance float64
		if q.id == s.broken {
			/* THE PLANTED KEY. The chance of getting it right goes DOWN with
			   ability, which is what a wrong answer key looks like from the
			   outside: the students who understood the material picked the
			   answer that is actually correct, and the paper marked them wrong.
			   Nothing about the question is otherwise unusual, which is the
			   point — difficulty cannot tell you this and discrimination can. */
			chance = 0.80 - 0.65*ability
		} else {
			chance = 0.15 + 0.70*ability + q.ease
		}
		right[i] = r.Float64() < clamp(chance, 0.02, 0.98)
		if right[i] {
			score++
		}
	}

	of := len(s.questions)
	passMark := (of*60 + 99) / 100 // 60%, rounded up, as an integer of questions
	passedIt := score >= passMark

	l.moments = append(l.moments, moment{
		name: "exam.submitted", at: *at, visitor: browser, account: 0, plan: plan,
		payload: map[string]any{
			"scope": "course", "exam": s.course,
			"score": score, "of": of, "pass_mark": passMark, "passed": passedIt,
		},
	})

	for i, q := range s.questions {
		*at = at.Add(time.Second)
		l.moments = append(l.moments, moment{
			name: event.ItemAnswered, at: *at, visitor: browser, account: 0, plan: plan,
			payload: map[string]any{
				"scope": "course", "exam": s.course,
				"exercise": q.id, "version": q.version, "type": q.kind,
				"correct": right[i], "attempt": attempt,
				"score": score, "of": of,
			},
		})
	}
	return passedIt
}

// survives is one step of the funnel, shifted by how much grit this person has.
//
// The shift is CENTRED — grit of a half changes nothing — so the base rates
// above stay an honest description of what the whole population does.
func survives(r *rand.Rand, base, grit float64) bool {
	return r.Float64() < clamp(base+(grit-0.5)*0.3, 0.02, 0.98)
}

// arrival is where somebody came from. The mix is deliberately uneven: a first
// touch that was uniform across four campaigns would make every cohort screen
// look the same, which is the one thing a seeded population must not do.
func arrival(r *rand.Rand) visitorSpec {
	switch n := r.Float64(); {
	case n < 0.42:
		return visitorSpec{path: "/", referrer: ""}
	case n < 0.62:
		return visitorSpec{path: "/", referrer: "https://www.google.com/",
			source: "google", medium: "organic"}
	case n < 0.78:
		return visitorSpec{path: "/#/catalog", referrer: "https://news.ycombinator.com/",
			source: "hn", medium: "referral"}
	case n < 0.90:
		return visitorSpec{path: "/#/plans", source: "newsletter", medium: "email",
			campaign: "launch"}
	default:
		return visitorSpec{path: "/#/track/frontend", source: "instagram", medium: "social",
			campaign: "frontend"}
	}
}

// where is a country and a locale, weighted towards where this platform is.
//
// LOWER CASE, LIKE EVERY OTHER PRODUCER OF THIS COLUMN. `platform/geo`
// lowercases what the database answers, the console's map is keyed by lower
// case, and its `isRegion` refuses anything else — so a seeded `BR` was a
// country that matched no outline, showed no flag and got no name. It rendered
// as a row labelled `BR` next to rows labelled `Brazil`, which is the shape of
// this mistake: nothing fails, and the report is quietly two countries where
// there is one.
func where(r *rand.Rand) (string, string) {
	switch n := r.Float64(); {
	case n < 0.72:
		return "br", "pt-br"
	case n < 0.80:
		return "pt", "pt-pt"
	case n < 0.90:
		return "us", "en-us"
	case n < 0.96:
		return "ar", "es-ar"
	default:
		// Genuinely not known, which is what the platform sees today: Cloud Run
		// passes no country header, so this is not a hypothetical value.
		return event.Unknown, "en-us"
	}
}

func hours(r *rand.Rand, low, high int) time.Duration {
	return time.Duration(low+r.Intn(high-low+1)) * time.Hour
}

func clamp(v, low, high float64) float64 {
	switch {
	case v < low:
		return low
	case v > high:
		return high
	default:
		return v
	}
}
