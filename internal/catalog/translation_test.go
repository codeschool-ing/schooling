package catalog_test

import (
	"context"
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
		"---\ntitle: As duas funções\n---\n"))
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
