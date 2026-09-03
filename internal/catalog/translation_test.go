package catalog_test

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/codeschool-ing/schooling/internal/catalog"
)

// THE CATALOGUE ITSELF IS TRANSLATED, AND IT USED NOT TO BE.
//
// Every course name, summary, syllabus and track outcome came out of the
// database in the language it was written in, and the interface translated them
// afterwards with a dictionary keyed by codeschool.ing's course ids. For that
// school it looked right. For any other one — a school whose ids the dictionary
// has never heard of — every course showed in English on a Portuguese page, and
// nothing looked broken, because a missing key falls back to itself and the key
// is the English string.
//
// So the words live beside the file they translate, `course.<locale>.json` and
// `tracks/<id>.<locale>.json`, and come back from the store per request.

// A course asked for in Portuguese comes back in Portuguese — and FIELD BY
// FIELD (C-11). The fixture's `course.pt.json` translates the name and the
// prerequisites and says nothing about the summary, so the summary has to
// survive in English rather than come back blank.
func TestACourseIsTranslatedFieldByField(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)
	store := catalog.NewStore(pool)
	ctx := context.Background()

	pt, err := store.Course(ctx, id, htmlCSS, "pt", catalog.PlanFull)
	if err != nil {
		t.Fatalf("reading the course in Portuguese: %v", err)
	}
	if pt.Name != "HTML e CSS" {
		t.Errorf("the Portuguese name was not used: %q", pt.Name)
	}
	if pt.Prerequisites != "O curso anterior a ele." {
		t.Errorf("the Portuguese prerequisites were not used: %q", pt.Prerequisites)
	}
	if pt.Summary != "A course about html-css." {
		t.Errorf("an untranslated field came back as %q — a translation carries what somebody "+
			"translated, and the rest keeps the source language", pt.Summary)
	}

	// And English is still English: a fallback that overwrote the source would
	// be invisible in the test above.
	en, err := store.Course(ctx, id, htmlCSS, "en", catalog.PlanFull)
	if err != nil {
		t.Fatalf("reading the course in English: %v", err)
	}
	if en.Name != "html-css" {
		t.Errorf("English answered %q", en.Name)
	}
}

// A LANGUAGE NOBODY TRANSLATED IS THE SOURCE LANGUAGE, NOT AN EMPTY SCHOOL.
// There is no `course.fr.json` in the fixture, and a French student has to get
// a readable catalogue rather than a list of blanks.
func TestALanguageWithNoTranslationFallsBackWhole(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)

	course, err := catalog.NewStore(pool).Course(context.Background(), id,
		htmlCSS, "fr", catalog.PlanFull)
	if err != nil {
		t.Fatalf("reading the course in an untranslated language: %v", err)
	}
	if course.Name != "html-css" || course.Summary != "A course about html-css." {
		t.Errorf("an untranslated language lost the source text: %+v", course.Listing)
	}
}

// The listing is translated too, and not only the course view. It is the screen
// a student lands on, so a catalogue translated one course at a time would show
// English on the way in and Portuguese once they clicked.
func TestTheListingIsTranslatedAsWell(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)

	listing, err := catalog.NewStore(pool).Courses(context.Background(), id, catalog.PlanFull, "pt")
	if err != nil {
		t.Fatalf("listing in Portuguese: %v", err)
	}
	for _, c := range listing {
		if c.ID != htmlCSS {
			continue
		}
		if c.Name != "HTML e CSS" {
			t.Errorf("the listing answered %q in Portuguese", c.Name)
		}
		return
	}
	t.Fatal("the translated course is not in the listing")
}

// A TRACK'S FORK IS TRANSLATED BY POSITION, because a fork has no id — its
// identity is where it sits in `courses`. That makes this the one join in the
// catalogue a reordering can silently break, so it is worth a test that reads
// the option names back in order rather than merely counting them.
func TestATracksForkIsTranslatedByPosition(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)

	track, err := catalog.NewStore(pool).Track(context.Background(), id, frontend, "pt")
	if err != nil {
		t.Fatalf("reading the track in Portuguese: %v", err)
	}
	if track.Name != "Desenvolvimento Front-end" {
		t.Errorf("the track name answered %q", track.Name)
	}
	if track.Outcome != "Pessoa Desenvolvedora Front-end Júnior" {
		t.Errorf("the outcome answered %q", track.Outcome)
	}
	// The goal is not in `frontend.pt.json`; it keeps the English.
	if track.Goal != "Build and ship an interface that other people use." {
		t.Errorf("an untranslated goal answered %q", track.Goal)
	}

	fork := track.Steps[2]
	if fork.Choice != "o framework" {
		t.Errorf("the fork's question answered %q", fork.Choice)
	}
	if fork.Note != "Either one; the ideas transfer." {
		t.Errorf("an untranslated note answered %q", fork.Note)
	}
	if len(fork.Options) != 2 {
		t.Fatalf("%d options, want 2", len(fork.Options))
	}
	// The options are matched by their position in the list, and the courses
	// behind each one must still be the courses that option offers — an option
	// renamed onto the wrong branch sends a student to the other framework.
	if fork.Options[0].Name != "React + TypeScript" || fork.Options[0].Courses[0] != reactTS {
		t.Errorf("the first option came back as %+v", fork.Options[0])
	}
	if fork.Options[1].Name != "Angular" || fork.Options[1].Courses[0] != angular {
		t.Errorf("the second option came back as %+v", fork.Options[1])
	}
}

// `links` IS THE TRACK'S OWN SEQUENCE and it survives the round trip through
// the mirror in both of its shapes — a course id and a step number. Dropped at
// the import, the vitrine's front-end track drew fourteen edges where it draws
// seventeen, and nothing looked broken: the graph falls back to the previous
// step, so a missing link is a WRONG edge rather than an absent one.
func TestATracksLinksSurviveTheMirror(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)

	track, err := catalog.NewStore(pool).Track(context.Background(), id, frontend, "en")
	if err != nil {
		t.Fatalf("reading the track: %v", err)
	}
	if len(track.Links) != 2 {
		t.Fatalf("%d links, want the two the fixture declares: %+v", len(track.Links), track.Links)
	}

	after, ok := track.Links[angular]
	if !ok || len(after) != 1 {
		t.Fatalf("angular's link came back as %+v", after)
	}
	if after[0].Course != htmlCSS || after[0].Step != nil {
		t.Errorf("a link to a course came back as %+v", after[0])
	}

	after, ok = track.Links[reactTS]
	if !ok || len(after) != 1 {
		t.Fatalf("react-ts's link came back as %+v", after)
	}
	if after[0].Step == nil || *after[0].Step != 1 || after[0].Course != "" {
		t.Errorf("a link to a step came back as %+v", after[0])
	}
}

// The shape of every course at once is answered in a language too. It carries
// the section TITLES, which is what a dashboard puts under a course — answered
// in English only, a Portuguese dashboard reads "Introduction".
func TestTheShapeOfTheCatalogueCarriesTranslatedTitles(t *testing.T) {
	pool := testPool(t)
	// The fixture's `roles.pt.md` is a copy of the English one, title and all —
	// which is a fine thing for the tests that read its body and useless here,
	// because two identical titles pass whether or not a locale was used.
	id := loaded(t, pool, write(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/roles.pt.md",
		"---\ntitle: As duas funções\nversion: 1\n---\n"))
	store := catalog.NewStore(pool)
	ctx := context.Background()

	pt, err := store.Structure(ctx, id, "pt")
	if err != nil {
		t.Fatalf("reading the shape in Portuguese: %v", err)
	}
	en, err := store.Structure(ctx, id, "en")
	if err != nil {
		t.Fatalf("reading the shape in English: %v", err)
	}

	title := func(shape map[string][]catalog.LessonView) string {
		t.Helper()
		for _, section := range shape[webFundamentals] {
			if section.ID != clientAndServer {
				continue
			}
			for _, s := range section.Sections {
				if s.ID == rolesSection {
					return s.Title
				}
			}
		}
		t.Fatal("the fixture's translated section is not in the shape")
		return ""
	}

	if title(pt) != "As duas funções" {
		t.Errorf("the shape answered %q in Portuguese", title(pt))
	}
	if title(en) != "The two roles" {
		t.Errorf("the shape answered %q in English", title(en))
	}
}

// THE ID SURVIVES THE MIRROR, which is the half of this that a file check
// cannot see. `catalog_course_topics` is written by the load job and read back
// as `{id, title}` — and the title is the one the language asked for while the
// id is the same string in every language.
func TestATopicsIDIsTheSameInEveryLanguage(t *testing.T) {
	pool := testPool(t)
	id := loaded(t, pool)
	store := catalog.NewStore(pool)
	ctx := context.Background()

	en, err := store.Course(ctx, id, webFundamentals, "en", catalog.PlanFull)
	if err != nil {
		t.Fatalf("reading the course: %v", err)
	}
	if len(en.Topics) != 2 {
		t.Fatalf("%d topics came back, want the two the fixture declares", len(en.Topics))
	}
	if en.Topics[0].ID != clientAndServer {
		t.Errorf("the declared id came back from the mirror as %q", en.Topics[0].ID)
	}
	if en.Topics[0].Title != "Who asks and who answers" {
		t.Errorf("the title came back as %q", en.Topics[0].Title)
	}

	// The second one's id says nothing about its title either, which is the form
	// every topic in `content/` takes. Both reach the mirror as written, so no
	// screen has to work one out.
	if en.Topics[1].ID != "le-9x2mk4qv" {
		t.Errorf("the second topic reached the mirror as %q", en.Topics[1].ID)
	}
}

// THE ONE THIS WHOLE CHANGE EXISTS FOR.
//
// Rewrite the words and the identity does not move. The plan for this catalogue
// is that the tracks, courses and topics are settled while the lesson content
// is scaffolding to be written again to a higher standard — so a title being
// rewritten is not a hazard to guard against, it is the intention.
//
// Before this, the id WAS the title: `slug(title)` for twenty-seven of the
// twenty-eight written lessons. Rewording one moved every progress row, note
// and exam attempt out from under the student who earned them, with nothing
// raised anywhere.
func TestRewritingATopicsTitleDoesNotMoveItsID(t *testing.T) {
	pool := testPool(t)

	before := catalog.NewStore(pool)
	id := loaded(t, pool)
	was, err := before.Course(context.Background(), id, webFundamentals, "en", catalog.PlanFull)
	if err != nil {
		t.Fatalf("reading the course: %v", err)
	}

	// The same catalogue with every word of that topic rewritten, as a
	// regeneration would deliver it.
	rewritten := loaded(t, pool, patchJSON("courses/web-fundamentals/course.json",
		func(d map[string]any) {
			topics, _ := d["topics"].([]any)
			first, _ := topics[0].(map[string]any)
			first["title"] = "Which machine is asking, and which is answering"
			d["topics"] = topics
		}))

	now, err := catalog.NewStore(pool).Course(context.Background(), rewritten,
		webFundamentals, "en", catalog.PlanFull)
	if err != nil {
		t.Fatalf("reading the rewritten course: %v", err)
	}

	if now.Topics[0].Title == was.Topics[0].Title {
		t.Fatal("the title did not change, so this proves nothing")
	}
	if now.Topics[0].ID != was.Topics[0].ID {
		t.Errorf("the id moved with the words: %q became %q — every progress row, note and "+
			"exam attempt filed under the old one is now orphaned",
			was.Topics[0].ID, now.Topics[0].ID)
	}
}

// AND THE COUNTERPART IS NO LONGER A BEHAVIOUR, IT IS A REFUSAL.
//
// There was a test here that rewrote a bare-string topic's title and watched
// its id move with it. That was the fallback being honest about what it could
// offer, and it was the reason the test above mattered: a reader who saw only
// that one could conclude ids are magic, and this said what they cost.
//
// The fallback is gone. A topic with no id is refused before it can be loaded,
// so there is nothing left to observe here — the cost is now paid at the pull
// request instead of by a student. `TestATopicWithNoIDIsRefused`, in
// `catalog_test.go`, is what that test became.

/* ---------- a question in another language ---------- */

// FIELD BY FIELD, AND WHAT NOBODY TRANSLATED STAYS ENGLISH (C-11).
//
// The interesting half is the second one. A merge that replaced the payload
// with the translation would give a Portuguese student a question missing every
// field somebody had not got to yet — and each of those absences is a different
// kind of broken: no `hint` is a question with less help, no `why` is a wrong
// answer with no explanation, and no `correct` is a question nobody can pass.
func TestAQuestionIsTranslatedFieldByField(t *testing.T) {
	english := []byte(`{
		"id": "ex-spr8rdb4", "version": 1, "type": "quiz",
		"prompt": "What is it?",
		"hint": "Think about the moment.",
		"choices": [
			{"text": "A client", "correct": true,  "why": "Whoever asks is the client."},
			{"text": "A server",  "correct": false, "why": "It is asking, not answering."}
		]
	}`)

	prompt := "O que ele é?"
	first := "Um cliente"

	body, err := catalog.Translated(english, catalog.ExerciseText{
		Prompt: &prompt,
		// No `hint`, and only the first option's text: the rest has to survive.
		Choices: []catalog.ChoiceText{{Text: &first}, {}},
	})
	if err != nil {
		t.Fatalf("translating: %v", err)
	}

	var got map[string]any
	if err := json.Unmarshal(body, &got); err != nil {
		t.Fatalf("the translation is not an object: %v", err)
	}

	if got["prompt"] != prompt {
		t.Errorf("the prompt is %q, want %q", got["prompt"], prompt)
	}
	if got["hint"] != "Think about the moment." {
		t.Errorf("the untranslated hint became %q — a translation carries what somebody "+
			"translated, and the English survives the rest", got["hint"])
	}

	choices, _ := got["choices"].([]any)
	if len(choices) != 2 {
		t.Fatalf("the translation has %d options and the question has 2", len(choices))
	}
	one, _ := choices[0].(map[string]any)
	two, _ := choices[1].(map[string]any)

	if one["text"] != first {
		t.Errorf("the first option reads %q, want %q", one["text"], first)
	}
	if one["why"] != "Whoever asks is the client." {
		t.Errorf("the first option's untranslated reason became %q", one["why"])
	}
	if two["text"] != "A server" {
		t.Errorf("the option nobody translated became %q rather than staying English", two["text"])
	}

	// AND THE KEY IS WHERE IT WAS. This is the property the whole shape of
	// ExerciseText exists for: a translation that could reach `correct` would
	// mark the same answer differently in two languages, and nobody would find
	// it, because both screens read perfectly well on their own.
	if one["correct"] != true || two["correct"] != false {
		t.Errorf("the answer key moved during a translation: %v, %v",
			one["correct"], two["correct"])
	}
}

// AND THE KEY CANNOT BE NAMED AT ALL.
//
// The test above proves the merge does not carry `correct` across. This proves
// the file cannot even ask: `ExerciseText` declares the translatable fields and
// `readJSON` refuses anything else, so a `pt.json` reaching for an answer fails
// on a pull request rather than being quietly dropped — which is the difference
// between a rule and a habit.
func TestATranslationThatReachesForTheAnswerIsRefused(t *testing.T) {
	for _, reaching := range []string{"correct", "accept", "value", "tolerance"} {
		problems := school(t, patchJSON(
			"courses/web-fundamentals/lessons/"+clientAndServer+"/exercises.pt.json",
			func(d map[string]any) {
				one, _ := d[rolesQuiz].(map[string]any)
				one[reaching] = "anything at all"
			}))

		if !says(problems, reaching) {
			t.Errorf("a translation setting %q was accepted:\n%s", reaching, report(t, problems))
		}
	}
}

// A TRANSLATION IS JOINED BY ID AND ITS LISTS BY POSITION, and both ends are
// checked, because both come loose in silence: the English survives either way,
// so the only symptom is a Portuguese screen reading the wrong words.
func TestATranslationThatHasComeLooseIsRefused(t *testing.T) {
	naming := school(t, patchJSON(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/exercises.pt.json",
		func(d map[string]any) { d["ex-4mzk8p2r"] = map[string]any{"prompt": "Uma pergunta"} }))
	if !says(naming, "which is not there") {
		t.Errorf("a translation of a question that does not exist was accepted:\n%s",
			report(t, naming))
	}

	short := school(t, patchJSON(
		"courses/web-fundamentals/lessons/"+clientAndServer+"/exercises.pt.json",
		func(d map[string]any) {
			one, _ := d[rolesQuiz].(map[string]any)
			choices, _ := one["choices"].([]any)
			one["choices"] = choices[:1]
		}))
	if !says(short, "matched by position") {
		t.Errorf("a translation one option short was accepted:\n%s", report(t, short))
	}
}

// AND A FINAL IS TRANSLATED TOO, which is worth its own test only because its
// file is named differently: `tracks/frontend-exam.pt.json` sits beside
// `frontend-exam.json`, and the track's own translation is
// `tracks/frontend.pt.json`. Two globs a stem apart, and a mistake in either
// would be silent — a translation nobody reads looks exactly like one nobody
// wrote.
func TestATracksFinalIsTranslatedAndChecked(t *testing.T) {
	problems := school(t, patchJSON("tracks/frontend-exam.pt.json",
		func(d map[string]any) {
			one, _ := d["ex-9ractp7g"].(map[string]any)
			items, _ := one["items"].([]any)
			one["items"] = items[:2]
		}))

	if !says(problems, "frontend/exam", "matched by position") {
		t.Errorf("a final's translation two items short was accepted:\n%s", report(t, problems))
	}
}
