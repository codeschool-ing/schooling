package discover

import (
	"bytes"
	"context"
	"encoding/json"
	"encoding/xml"
	"html"
	"image/png"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"unicode/utf8"
)

func aCourse() Course {
	return Course{
		Slug: "linux-terminal", Name: "Linux and the Command Line", Hours: 70,
		Level: "beginner", Summary: "The system that runs the internet.",
		Prerequisites: "No programming required.",
		Syllabus:      []string{"Distributions", "Permissions"},
		Free:          true,
		Lessons: []Lesson{{At: 1, Title: "The terminal, and why", Sections: []Section{{
			Title: "Where you are",
			Prose: []Prose{{Text: "A terminal is a window onto a machine that has no desktop."}},
		}}}},
	}
}

func aTrack() Track {
	return Track{
		Slug: "infrastructure", Name: "Networks and Infrastructure",
		Goal:    "Run the machines other people's work sits on.",
		Outcome: "Stand up a server, secure it, and know why it is slow.",
		Steps: []Step{
			{Name: "Linux and the Command Line", Slug: "linux-terminal"},
			{Name: "A course nobody wrote", Slug: ""},
		},
	}
}

func aHandler(courses ...Course) *Handler {
	if len(courses) == 0 {
		courses = []Course{aCourse()}
	}
	tracks := []Track{aTrack()}
	find := func(slug string) *Course {
		for i := range courses {
			if courses[i].Slug == slug {
				return &courses[i]
			}
		}
		return nil
	}
	return NewHandler(
		func(context.Context, string) ([]Course, error) { return courses, nil },
		func(_ context.Context, slug, _ string) (*Course, error) {
			if c := find(slug); c != nil {
				return c, nil
			}
			return nil, ErrNoCourse
		},
		func(_ context.Context, slug string, at int, _ string) (*Lesson, error) {
			c := find(slug)
			// What the store does: a course nobody may open refuses its
			// lessons, and refuses them as absent.
			if c == nil || !c.Free || at < 1 || at > len(c.Lessons) {
				return nil, ErrNoLesson
			}
			return &c.Lessons[at-1], nil
		},
		func(_ context.Context, _ string) ([]Track, error) { return tracks, nil },
		func(_ context.Context, slug, _ string) (*Track, error) {
			for i := range tracks {
				if tracks[i].Slug == slug {
					return &tracks[i], nil
				}
			}
			return nil, ErrNoTrack
		},
		func(context.Context) (string, string, bool) { return "codeschool", "#14a06a", true },
		func(context.Context) string { return "2026-09-16T00:00:00Z" },
		true,
	)
}

func get(t *testing.T, h *Handler, host, path string, headers map[string]string) *httptest.ResponseRecorder {
	t.Helper()
	mux := http.NewServeMux()
	h.Routes(mux)
	r := httptest.NewRequest(http.MethodGet, path, nil)
	r.Host = host
	for k, v := range headers {
		r.Header.Set(k, v)
	}
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, r)
	return w
}

/*
THE ADDRESS IS THE REQUEST'S, WHICH IS THE WHOLE DESIGN.

	A school is a subdomain and the platform's domain is a setting that will
	change, so nothing here may name a host. The proof is that two schools ask
	for the same page and are told two different canonicals — a constant would
	pass every other test in this file.
*/
func TestTheCanonicalIsTheHostTheRequestArrivedAt(t *testing.T) {
	h := aHandler()
	for _, host := range []string{"code.schooling.example", "maths.another.example"} {
		body := get(t, h, host, "/course/linux-terminal", nil).Body.String()
		want := `<link rel="canonical" href="http://` + host + `/course/linux-terminal">`
		if !strings.Contains(body, want) {
			t.Errorf("%s: no canonical of its own; wanted %s", host, want)
		}
		if strings.Contains(body, "schooling.lab") || strings.Contains(body, "codeschool.ing") {
			t.Errorf("%s: the page names a host nobody asked for", host)
		}
	}
}

// Cloud Run terminates TLS and hands this process a plain request, so reading
// `r.TLS` alone would call every production page `http` — in its own canonical,
// which is the one place being wrong is expensive.
func TestTheSchemeComesFromTheProxy(t *testing.T) {
	body := get(t, aHandler(), "code.example", "/course/linux-terminal",
		map[string]string{"X-Forwarded-Proto": "https"}).Body.String()
	if !strings.Contains(body, `href="https://code.example/course/linux-terminal">`) {
		t.Error("a request forwarded over TLS should declare an https canonical")
	}
}

/*
BOTH LANGUAGES NAME EACH OTHER AND THEMSELVES, plus `x-default`.

	A page that lists only the other one, or a pair that disagrees about who is
	in the set, is not half-believed: the set is discarded. So this asks for the
	Portuguese page and checks it claims the same set the English one does.
*/
func TestEveryPageNamesTheWholeSet(t *testing.T) {
	h := aHandler()
	for _, path := range []string{"/course/linux-terminal", "/pt/course/linux-terminal"} {
		body := get(t, h, "code.example", path, nil).Body.String()
		for _, want := range []string{
			`hreflang="en" href="http://code.example/course/linux-terminal"`,
			`hreflang="pt-BR" href="http://code.example/pt/course/linux-terminal"`,
			`hreflang="x-default" href="http://code.example/course/linux-terminal"`,
		} {
			if !strings.Contains(body, want) {
				t.Errorf("%s does not carry %s", path, want)
			}
		}
	}
}

// The content exists in two languages. A path shaped like a language page in a
// language nothing is written in would be an English page labelled Spanish.
func TestALanguageNothingIsWrittenInIsNotFound(t *testing.T) {
	for _, path := range []string{"/es/course/linux-terminal", "/de/course/linux-terminal"} {
		if code := get(t, aHandler(), "code.example", path, nil).Code; code != http.StatusNotFound {
			t.Errorf("%s answered %d; the content is not in that language", path, code)
		}
	}
}

func TestACourseThisSchoolDoesNotPublishIsNotFound(t *testing.T) {
	if code := get(t, aHandler(), "code.example", "/course/nothing-here", nil).Code; code != http.StatusNotFound {
		t.Errorf("answered %d for a slug this school has no course by", code)
	}
}

/*
EVERYTHING ON THIS PAGE CAME OUT OF A DATABASE A SCHOOL FILLS IN.

	Concatenation would put whatever is in a course's name straight into the
	markup. The template escapes per context, and this is what says so — in the
	title, in an attribute, and in the structured data, which are three
	different escapes.
*/
func TestWhatASchoolTypedCannotBecomeMarkup(t *testing.T) {
	nasty := aCourse()
	nasty.Name = `Bash <script>alert(1)</script> & "quotes"`
	nasty.Summary = `</title><script>alert(2)</script>`

	body := get(t, aHandler(nasty), "code.example", "/course/linux-terminal", nil).Body.String()
	if strings.Contains(body, "<script>alert(1)") || strings.Contains(body, "<script>alert(2)") {
		t.Fatal("a course name reached the page as markup")
	}
	if !strings.Contains(body, "Bash &lt;script&gt;") {
		t.Error("the name should be on the page, escaped, rather than missing")
	}
}

// `template.JS` turns the template's own escaping off, so the structured data
// has to be JSON by construction. If it ever stops being, this is what says so.
func TestTheStructuredDataIsJSON(t *testing.T) {
	nasty := aCourse()
	nasty.Name = `A & B </script>`

	body := get(t, aHandler(nasty), "code.example", "/course/linux-terminal", nil).Body.String()
	at := strings.Index(body, `<script type="application/ld+json">`)
	if at < 0 {
		t.Fatal("no structured data on the page")
	}
	block := body[at+len(`<script type="application/ld+json">`):]
	block = block[:strings.Index(block, "</script>")]

	var got map[string]any
	if err := json.Unmarshal([]byte(block), &got); err != nil {
		t.Fatalf("the structured data is not JSON: %v\n%s", err, block)
	}
	if got["@type"] != "Course" {
		t.Errorf("@type is %v", got["@type"])
	}
	if got["url"] != "http://code.example/course/linux-terminal" {
		t.Errorf("the structured data names %v rather than this request's address", got["url"])
	}
}

/*
THE ONE PLACE THE TEMPLATE'S ESCAPING IS TURNED OFF, held to its reason.

	`course.go` carries a `//nolint:gosec` saying the structured data cannot
	close its own `<script>` because `json.Marshal` escapes `<`, `>` and `&`.
	That is a claim about a standard library, on a line a linter was told to
	ignore, which is exactly the kind of sentence that stops being true quietly.
*/
func TestTheStructuredDataCannotCloseItsOwnScript(t *testing.T) {
	nasty := aCourse()
	nasty.Name = `</script><img src=x onerror=alert(1)>`
	nasty.Summary = `& < > and </SCRIPT >`

	body := get(t, aHandler(nasty), "code.example", "/course/linux-terminal", nil).Body.String()
	at := strings.Index(body, `<script type="application/ld+json">`)
	block := body[at+len(`<script type="application/ld+json">`):]
	end := strings.Index(block, "</script>")
	if end < 0 {
		t.Fatal("the structured data never ends")
	}
	if strings.Contains(block[:end], "<") || strings.Contains(block[:end], ">") {
		t.Errorf("an angle bracket survived into the script element: %s", block[:end])
	}
	/* The words themselves are ON the page, escaped, and that is right — a
	   course really is called that. What must not be there is a TAG, so the
	   assertion is about the bracket and not about the text inside it. The
	   first version of this looked for `onerror=alert(1)` and failed on the
	   escaped copy, which is the page working. */
	if strings.Contains(body, "<img") || strings.Contains(body, "<SCRIPT") {
		t.Error("a course name became a tag")
	}
	if !strings.Contains(body, "&lt;/script&gt;") {
		t.Error("the name should be on the page as the characters it is")
	}
}

func TestRobotsPointsAtThisHostsSitemap(t *testing.T) {
	body := get(t, aHandler(), "maths.example", "/robots.txt", nil).Body.String()
	if !strings.Contains(body, "Sitemap: http://maths.example/sitemap.xml") {
		t.Errorf("robots.txt does not name this school's sitemap:\n%s", body)
	}
	if !strings.Contains(body, "Disallow: /api/") {
		t.Error("the API is the same catalogue as JSON and should not be crawled as well")
	}
}

/*
The sitemap carries the alternates too, which is the half that is usually left
out: a crawler reaching one language from a link learns about the other without
fetching it first.
*/
func TestTheSitemapCarriesBothLanguagesAndTheirAlternates(t *testing.T) {
	body := get(t, aHandler(), "code.example", "/sitemap.xml", nil).Body.Bytes()

	var set struct {
		URLs []struct {
			Loc  string `xml:"loc"`
			Link []struct {
				HrefLang string `xml:"hreflang,attr"`
				Href     string `xml:"href,attr"`
			} `xml:"link"`
		} `xml:"url"`
	}
	if err := xml.Unmarshal(body, &set); err != nil {
		t.Fatalf("the sitemap is not XML: %v", err)
	}

	locs := map[string]int{}
	for _, u := range set.URLs {
		locs[u.Loc] = len(u.Link)
	}
	for _, want := range []string{
		"http://code.example/",
		"http://code.example/course/linux-terminal",
		"http://code.example/pt/course/linux-terminal",
	} {
		if _, ok := locs[want]; !ok {
			t.Errorf("the sitemap does not list %s", want)
		}
	}
	// two languages and x-default, on each of the course pages
	if n := locs["http://code.example/course/linux-terminal"]; n != 3 {
		t.Errorf("the English course page carries %d alternates in the sitemap, wanted 3", n)
	}
}

// A page nobody can read is not a page. The one thing every visitor gets is the
// language they asked for, in the words as well as the tag.
func TestThePortuguesePageIsInPortuguese(t *testing.T) {
	body := get(t, aHandler(), "code.example", "/pt/course/linux-terminal", nil).Body.String()
	if !strings.Contains(body, `<html lang="pt-BR">`) {
		t.Error("the Portuguese page does not declare Portuguese")
	}
	if !strings.Contains(body, "O que você vai aprender") {
		t.Error("the Portuguese page is in English")
	}
}

/*
A LESSON THE COURSE DECLARES AND NOBODY HAS WRITTEN IS NAMED AND NOT LINKED.

	120 of the 122 courses are exactly that: a catalogue entry with its contents
	planned and no lesson authored. The contents are worth reading and there is
	nowhere to go from them.
*/
func TestAnUnwrittenLessonIsListedWithoutALink(t *testing.T) {
	planned := aCourse()
	planned.Lessons = append(planned.Lessons, Lesson{At: 0, Title: "Permissions, and the three of them"})

	body := get(t, aHandler(planned), "code.example", "/course/linux-terminal", nil).Body.String()
	if !strings.Contains(body, "Permissions, and the three of them") {
		t.Error("a planned lesson should still be on the page")
	}
	if strings.Contains(body, "/lesson/0") {
		t.Error("a lesson nobody has written was linked")
	}
}

/*
A COURSE THAT IS SOLD DOES NOT HAVE ITS LESSONS HERE, and this is the test that
matters most in the file.

	The rule is the store's — a lesson read with no plan refuses — and this
	package asks with no plan, so it cannot get it wrong by remembering it
	wrongly. What it CAN do is stop asking, or start showing what it was handed
	anyway, and that is what this notices.

	A locked lesson answers 404 rather than "you may not read this": a page that
	exists to say so is a page a search engine will index.
*/
func TestALessonOfACourseThatIsSoldIsNotAPage(t *testing.T) {
	sold := aCourse()
	sold.Free = false

	w := get(t, aHandler(sold), "code.example", "/course/linux-terminal/lesson/1", nil)
	if w.Code != http.StatusNotFound {
		t.Fatalf("a paid course's lesson answered %d", w.Code)
	}
	if strings.Contains(w.Body.String(), "A terminal is a window") {
		t.Fatal("the prose of a paid lesson reached the page")
	}

	// and its course page names the lessons without linking to any of them
	body := get(t, aHandler(sold), "code.example", "/course/linux-terminal", nil).Body.String()
	if !strings.Contains(body, "The terminal, and why") {
		t.Error("a paid course should still list its lesson titles — that is the shop window")
	}
	if strings.Contains(body, "/course/linux-terminal/lesson/1") {
		t.Error("a paid course links to a lesson page nobody may read")
	}
}

func TestAFreeLessonIsAPageAndItsCourseLinksToIt(t *testing.T) {
	body := get(t, aHandler(), "code.example", "/course/linux-terminal/lesson/1", nil).Body.String()
	for _, want := range []string{
		"The terminal, and why",
		"Where you are",
		"A terminal is a window onto a machine that has no desktop.",
		`<link rel="canonical" href="http://code.example/course/linux-terminal/lesson/1">`,
		`hreflang="pt-BR" href="http://code.example/pt/course/linux-terminal/lesson/1"`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("the lesson page does not carry %q", want)
		}
	}

	course := get(t, aHandler(), "code.example", "/course/linux-terminal", nil).Body.String()
	if !strings.Contains(course, `href="http://code.example/course/linux-terminal/lesson/1"`) {
		t.Error("a free course should link to the lesson pages it has")
	}
}

func TestALessonThatIsNotThereIsNotFound(t *testing.T) {
	for _, path := range []string{
		"/course/linux-terminal/lesson/99",
		"/course/linux-terminal/lesson/0",
		"/course/linux-terminal/lesson/first",
		"/course/nothing-here/lesson/1",
	} {
		if code := get(t, aHandler(), "code.example", path, nil).Code; code != http.StatusNotFound {
			t.Errorf("%s answered %d", path, code)
		}
	}
}

/*
THE PROSE IS TEXT AND NOTHING IS BUILT FROM IT.

	`prose.go` says why at length: the interface has the renderer, a second one
	kept in step by nobody is the failure `markdown.js` warns about, and this
	deliberately supports nothing so that it cannot support half of something.
	These are the shapes a lesson actually contains.
*/
func TestTheProseComesOutAsWords(t *testing.T) {
	for _, c := range []struct {
		name, in string
		want     []Prose
	}{
		{"a heading and a paragraph", "## Where you are\n\nA terminal is a window.",
			[]Prose{{Heading: "Where you are"}, {Text: "A terminal is a window."}}},
		{"bold and code lose their marks", "The **shell** runs `ls` for you.",
			[]Prose{{Text: "The shell runs ls for you."}}},
		{"a link keeps its words and drops its address",
			"See [the manual](https://example.tld/man) for more.",
			[]Prose{{Text: "See the manual for more."}}},
		{"a fence is a construction, not prose",
			"Before.\n\n```sh\nrm -rf /\n```\n\nAfter.",
			[]Prose{{Text: "Before."}, {Text: "After."}}},
		{"a figure's JSON never reaches the page",
			"Look:\n\n```schooling-figure\n{\"svg\": \"<svg/>\"}\n```\n\nThat.",
			[]Prose{{Text: "Look:"}, {Text: "That."}}},
		{"a table is dropped rather than flattened",
			"Two:\n\n| a | b |\n|---|---|\n| 1 | 2 |\n\nDone.",
			[]Prose{{Text: "Two:"}, {Text: "Done."}}},
		{"a list item is a sentence without its marker",
			"- first thing\n- second thing",
			[]Prose{{Text: "first thing"}, {Text: "second thing"}}},
		{"a numbered item too", "1. first\n2. second",
			[]Prose{{Text: "first"}, {Text: "second"}}},
		{"lines of one paragraph join up", "one line\nand the next\n\nelsewhere",
			[]Prose{{Text: "one line and the next"}, {Text: "elsewhere"}}},
		{"an asterisk on its own is an asterisk", "a * b",
			[]Prose{{Text: "a * b"}}},
	} {
		t.Run(c.name, func(t *testing.T) {
			got := Extract(c.in)
			if len(got) != len(c.want) {
				t.Fatalf("%d blocks, wanted %d: %#v", len(got), len(c.want), got)
			}
			for i := range got {
				if got[i] != c.want[i] {
					t.Errorf("block %d is %#v, wanted %#v", i, got[i], c.want[i])
				}
			}
		})
	}
}

// A lesson about HTML contains HTML, and `prose.go` does not remove it — the
// template does, by putting it in a text node. This says so, because the two
// halves of that sentence live in different files.
func TestALessonAboutMarkupDoesNotBecomeMarkup(t *testing.T) {
	c := aCourse()
	c.Lessons[0].Sections[0].Prose = []Prose{{Text: `A tag looks like <script>alert(1)</script>.`}}

	body := get(t, aHandler(c), "code.example", "/course/linux-terminal/lesson/1", nil).Body.String()
	if strings.Contains(body, "<script>alert(1)") {
		t.Fatal("a lesson's own words reached the page as markup")
	}
	if !strings.Contains(body, "&lt;script&gt;") {
		t.Error("the words should be on the page, escaped")
	}
}

/*
THE ROUTES MUST NOT BE AMBIGUOUS, and this is the test that found out they were.

	`GET /{lang}/courses` and `GET /course/{slug}` both match `/course/courses`
	and neither is more specific, which `http.ServeMux` answers by PANICKING as
	it registers — so the server would not have started. The languages are a
	closed list, so the paths are registered per language instead.

	Registering them is the assertion: a conflict panics, and a panic in a test
	is a failure.
*/
func TestTheRoutesCanAllBeRegistered(t *testing.T) {
	mux := http.NewServeMux()
	aHandler().Routes(mux)

	// and `Patterns` is what `cmd/api` forwards, so it has to be the same set
	registered := http.NewServeMux() // a conflict panics here too
	for _, p := range Patterns {
		registered.HandleFunc(p, func(http.ResponseWriter, *http.Request) {})
	}
	if len(Patterns) != 2+len(languages)*6 {
		t.Errorf("%d patterns for %d languages", len(Patterns), len(languages))
	}
}

func TestTheListsLinkWhatTheyList(t *testing.T) {
	for _, c := range []struct{ path, wants string }{
		{"/courses", "http://code.example/course/linux-terminal"},
		{"/pt/courses", "http://code.example/pt/course/linux-terminal"},
		{"/tracks", "http://code.example/track/infrastructure"},
		{"/pt/tracks", "http://code.example/pt/track/infrastructure"},
	} {
		body := get(t, aHandler(), "code.example", c.path, nil).Body.String()
		if !strings.Contains(body, `href="`+c.wants+`"`) {
			t.Errorf("%s does not link %s", c.path, c.wants)
		}
	}
}

/*
A track's page names its courses in order and links the ones that have a page.

	A FORK IS NAMED AND NOT LINKED. A step where the student chooses is a
	decision rather than a thing, so it has no page of its own; the courses
	inside it have pages, reached from the catalogue.
*/
func TestATrackLinksItsCoursesAndNamesItsForks(t *testing.T) {
	body := get(t, aHandler(), "code.example", "/pt/track/infrastructure", nil).Body.String()
	if !strings.Contains(body, `href="http://code.example/pt/course/linux-terminal"`) {
		t.Error("the track does not link the course it starts with")
	}
	if !strings.Contains(body, "A course nobody wrote") {
		t.Error("a step with no page should still be named")
	}
	if strings.Contains(body, `href="http://code.example/pt/course/"`) {
		t.Error("a step with no course was linked to nowhere")
	}
	if !strings.Contains(body, `<link rel="canonical" href="http://code.example/pt/track/infrastructure">`) {
		t.Error("the track page has no canonical of its own")
	}
}

func TestATrackThisSchoolDoesNotPublishIsNotFound(t *testing.T) {
	if code := get(t, aHandler(), "code.example", "/track/nothing-here", nil).Code; code != http.StatusNotFound {
		t.Errorf("answered %d for a track this school does not have", code)
	}
}

/*
`lastmod` IS THE CATALOGUE'S DATE OR IT IS ABSENT.

	A school that has not been loaded since the column existed does not know
	when its catalogue was published, and a sitemap that answered `time.Now()`
	would tell a crawler everything changed on every crawl — which teaches it to
	ignore the field on every page, including the ones that did change.
*/
func TestTheSitemapCarriesThePublishedDateOrNone(t *testing.T) {
	body := get(t, aHandler(), "code.example", "/sitemap.xml", nil).Body.String()
	if !strings.Contains(body, "<lastmod>2026-09-16T00:00:00Z</lastmod>") {
		t.Error("the sitemap does not carry the date the catalogue was published")
	}

	quiet := NewHandler(
		func(context.Context, string) ([]Course, error) { return []Course{aCourse()}, nil },
		func(context.Context, string, string) (*Course, error) { return nil, ErrNoCourse },
		func(context.Context, string, int, string) (*Lesson, error) { return nil, ErrNoLesson },
		func(context.Context, string) ([]Track, error) { return nil, nil },
		func(context.Context, string, string) (*Track, error) { return nil, ErrNoTrack },
		func(context.Context) (string, string, bool) { return "codeschool", "#14a06a", true },
		func(context.Context) string { return "" },
		true,
	)
	if body := get(t, quiet, "code.example", "/sitemap.xml", nil).Body.String(); strings.Contains(body, "<lastmod>") {
		t.Error("a school with no published date should have no lastmod, not an invented one")
	}
}

/*
THE INK MOVES, NOT THE SCHOOL'S COLOUR.

	A school picks its own accent and some of them are pale. White on a pale
	yellow is a card nobody can read, and the yellow is the school's choice —
	so the text goes dark instead. Checked by reading the pixel a letter is
	drawn on rather than by trusting the arithmetic.
*/
func TestTheCardsTextIsReadableOnWhateverColourASchoolPicked(t *testing.T) {
	for _, c := range []struct {
		accent string
		dark   bool // is the ink expected to be the dark one
	}{
		{"#14a06a", false}, // the seeded green
		{"#0a0e14", false}, // nearly black
		{"#ffe680", true},  // a pale yellow
		{"#ffffff", true},  // white
		{"not a colour", false},
	} {
		body, err := drawCard("Linux", "codeschool", c.accent)
		if err != nil {
			t.Fatal(err)
		}
		got, err := png.Decode(bytes.NewReader(body))
		if err != nil {
			t.Fatal(err)
		}

		// the darkest pixel on the card is the ink, whatever the ground is
		darkest := 1.0
		b := got.Bounds()
		for y := b.Min.Y; y < b.Max.Y; y += 2 {
			for x := b.Min.X; x < b.Max.X; x += 2 {
				r, g, bl, _ := got.At(x, y).RGBA()
				if v := float64(r+g+bl) / (3 * 65535); v < darkest {
					darkest = v
				}
			}
		}
		if c.dark && darkest > 0.2 {
			t.Errorf("%s: nothing dark was drawn, so the text is pale on pale", c.accent)
		}
		if !c.dark && darkest > 0.9 {
			t.Errorf("%s: nothing was drawn at all", c.accent)
		}
	}
}

// A card is 1200x630 whatever the name is, because that is the size every
// platform crops to and a card of another shape is cropped by somebody else.
func TestACardIsAlwaysTheSameSize(t *testing.T) {
	for _, name := range []string{
		"Go",
		"Git and Teamwork: Versioning, Review and Process",
		strings.Repeat("a very long name indeed ", 40),
	} {
		body, err := drawCard(name, "codeschool", "#14a06a")
		if err != nil {
			t.Fatal(err)
		}
		got, err := png.DecodeConfig(bytes.NewReader(body))
		if err != nil {
			t.Fatal(err)
		}
		if got.Width != 1200 || got.Height != 630 {
			t.Errorf("%dx%d for %q", got.Width, got.Height, name[:min(20, len(name))])
		}
	}
}

// The page points at a card that exists, in its own language, and says the size
// every platform wants told rather than discovered.
func TestACoursePageCarriesItsCard(t *testing.T) {
	body := get(t, aHandler(), "code.example", "/pt/course/linux-terminal", nil).Body.String()
	for _, want := range []string{
		`<meta property="og:image" content="http://code.example/pt/card/course/linux-terminal">`,
		`<meta property="og:image:width" content="1200">`,
		`<meta name="twitter:card" content="summary_large_image">`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("the page does not carry %s", want)
		}
	}
	if code := get(t, aHandler(), "code.example", "/pt/card/course/linux-terminal", nil).Code; code != http.StatusOK {
		t.Errorf("the card the page points at answers %d", code)
	}
	if code := get(t, aHandler(), "code.example", "/card/nonsense/linux-terminal", nil).Code; code != http.StatusNotFound {
		t.Errorf("a card of a kind that does not exist answered %d", code)
	}
}

/*
THE BYTE BUG, WHICH IS THE ONE THAT WOULD HAVE SHIPPED QUIETLY.

	The first version of `shorten` counted with `len` and cut with `s[:160]`, and
	both are bytes in Go. On Portuguese — where a good share of the words carry
	an accent — a cut at byte 160 can land between the two bytes of a single
	rune, and the page then carries a replacement character in the one attribute
	whose whole job is to be read by a stranger.

	The fixture is built to hit exactly that: one ASCII character and then
	two-byte runes, so byte 160 falls in the middle of one. It is not a
	hypothetical, it is arithmetic.
*/
func TestADescriptionIsNeverCutThroughALetter(t *testing.T) {
	// "x" then 200 two-byte runes with no space anywhere: byte 160 is mid-rune.
	tight := "x" + strings.Repeat("á", 200)
	// The realistic shape: Portuguese prose, accented, longer than a result.
	prose := strings.TrimSpace(strings.Repeat("A configuração não é óbvia à primeira vista, e é por isso que ela está aqui. ", 4))

	for _, s := range []string{tight, prose} {
		got := shorten(s)
		if !utf8.ValidString(got) {
			t.Errorf("shorten cut through a letter and left invalid UTF-8: %q", got)
		}
		if n := utf8.RuneCountInString(got); n > mostOfADescription+1 { // +1 for the ellipsis
			t.Errorf("shorten left %d runes, which a result would cut: %q", n, got)
		}
	}
}

func TestADescriptionStopsWhereSomebodyWouldStopReading(t *testing.T) {
	long := "Run the machines other people's work sits on, from the first login " +
		"to a server nobody has to think about. It is the track for whoever wants " +
		"the pager rather than the design tool, and it is long on purpose."

	got := shorten(long)
	if !strings.HasSuffix(got, ".") {
		t.Errorf("cut somewhere that is not the end of a sentence: %q", got)
	}
	if !strings.HasPrefix(long, got) {
		t.Errorf("shorten changed the words rather than ending them: %q", got)
	}

	// Nothing to shorten comes back untouched, ellipsis and all.
	if short := "A short one."; shorten(short) != short {
		t.Errorf("a description that already fits was changed to %q", shorten(short))
	}

	// A line break in the source is not a line break in an attribute.
	if got := shorten("Two lines\nin the source."); got != "Two lines in the source." {
		t.Errorf("a newline survived into the attribute: %q", got)
	}
}

/*
EVERY PAGE, BECAUSE EVERY PAGE WAS DOING IT ITS OWN WAY.

	The course page described itself from `.Course.Summary`, the track from
	`.Track.Goal`, the lesson from a summary it had already cut, and the two lists
	from nothing at all — while the `og:` and `twitter:` descriptions beside them
	all came from one field. Two of the four disagreed with themselves and two
	said nothing.

	A track's goal is the proof: all 38 in the catalogue are over the line, the
	median is 339 characters, so this fixture is what the real ones look like.
*/
func TestEveryPageDescribesItselfOnceAndAtTheLengthAResultShows(t *testing.T) {
	h := aHandler()
	h.route = func(_ context.Context, slug, _ string) (*Track, error) {
		track := aTrack()
		track.Goal = "Run the machines other people's work sits on: the first login, " +
			"the network under it, the storage beside it and the alarm that wakes " +
			"somebody at three in the morning. It is the longest track here and its " +
			"goal is the longest sentence in the catalogue, which is the whole point."
		return &track, nil
	}

	for _, path := range []string{
		"/course/linux-terminal",
		"/pt/course/linux-terminal",
		"/track/infrastructure",
		"/course/linux-terminal/lesson/1",
		"/courses",
		"/pt/tracks",
	} {
		body := get(t, h, "code.example", path, nil).Body.String()

		meta := attribute(t, body, `<meta name="description" content="`)
		if meta == "" {
			t.Errorf("%s says nothing about itself", path)
			continue
		}
		if n := utf8.RuneCountInString(meta); n > mostOfADescription+1 {
			t.Errorf("%s describes itself in %d runes, which a result would cut: %q", path, n, meta)
		}

		// The same words to a search engine and to everything else.
		for _, other := range []string{
			`<meta property="og:description" content="`,
			`<meta name="twitter:description" content="`,
		} {
			if got := attribute(t, body, other); got != meta {
				t.Errorf("%s describes itself two ways:\n  meta %q\n  %s %q", path, meta, other, got)
			}
		}
	}
}

/*
attribute reads the value of the first attribute opened by `opens`.

	The pages are written by `html/template`, so a quote inside the value is
	`&#34;` and the first `"` really is the end.

	IT UNESCAPES, AND THAT MATTERS TO THE COUNT. `html/template` writes an
	apostrophe as `&#39;` — five runes where a reader sees one — so measuring the
	attribute as written would call a 160-rune description 172 and fail on
	perfectly good content. What a result shows is the unescaped text, so that is
	what is counted.
*/
func attribute(t *testing.T, body, opens string) string {
	t.Helper()
	at := strings.Index(body, opens)
	if at < 0 {
		return ""
	}
	rest := body[at+len(opens):]
	end := strings.Index(rest, `"`)
	if end < 0 {
		t.Fatalf("an attribute opened by %q is never closed", opens)
	}
	return html.UnescapeString(rest[:end])
}

/*
THE TWO LISTS WERE THE PAGES WITH NO PICTURE.

	They are the pages most likely to be pasted into a message — "here is what we
	teach" is the catalogue, not one course — and they were the only two without
	`og:image`, because a card is addressed by slug and a list has none. `list`
	is the `what` and which list is the `slug`, so they need no route of their
	own.
*/
func TestTheListsCarryADescriptionAndACard(t *testing.T) {
	for _, list := range []struct{ path, card string }{
		{"/courses", "http://code.example/card/list/courses"},
		{"/tracks", "http://code.example/card/list/tracks"},
		{"/pt/courses", "http://code.example/pt/card/list/courses"},
		{"/pt/tracks", "http://code.example/pt/card/list/tracks"},
	} {
		body := get(t, aHandler(), "code.example", list.path, nil).Body.String()
		want := `<meta property="og:image" content="` + list.card + `">`
		if !strings.Contains(body, want) {
			t.Errorf("%s does not carry %s", list.path, want)
		}
		if !strings.Contains(body, `<meta name="twitter:card" content="summary_large_image">`) {
			t.Errorf("%s asks for a small card and points at a wide one", list.path)
		}

		// And the address it points at is one that answers with an image.
		w := get(t, aHandler(), "code.example", strings.TrimPrefix(list.card, "http://code.example"), nil)
		if w.Code != http.StatusOK {
			t.Errorf("the card %s answers %d", list.card, w.Code)
			continue
		}
		if got := w.Header().Get("Content-Type"); got != "image/png" {
			t.Errorf("the card %s is %q", list.card, got)
		}
		if _, err := png.Decode(bytes.NewReader(w.Body.Bytes())); err != nil {
			t.Errorf("the card %s is not a PNG: %v", list.card, err)
		}
	}

	// A list nobody has is not a card.
	if code := get(t, aHandler(), "code.example", "/card/list/nonsense", nil).Code; code != http.StatusNotFound {
		t.Errorf("a card for a list that does not exist answered %d", code)
	}
}

// The card says what the page says, in the language the page is in. A card
// drawn from the English heading and served at `/pt/` would be the defect the
// topic titles already were.
func TestAListsCardIsDrawnInItsOwnLanguage(t *testing.T) {
	en := get(t, aHandler(), "code.example", "/card/list/courses", nil).Body.Bytes()
	pt := get(t, aHandler(), "code.example", "/pt/card/list/courses", nil).Body.Bytes()
	if bytes.Equal(en, pt) {
		t.Error("`Every course` and `Todos os cursos` drew the same pixels")
	}
}

/*
A LEAD-IN IS NOT A DESCRIPTION.

	`prose.Extract` drops code blocks on purpose, so a paragraph that ends in a
	colon arrives here as a promise with nothing after it — and in a result that
	reads like a page that was cut off. Three lessons in the real catalogue open
	exactly that way.

	The fallback is the half worth testing: preferring the next paragraph must
	not leave a lesson with no description at all when the colon one is all there
	is.
*/
func TestALessonThatOpensWithALeadInIsDescribedByWhatFollowsIt(t *testing.T) {
	lead := "Every file has an owner and a group, and lesson 3 already showed you both:"
	body := "Permissions are three bits repeated three times, and the whole of the rest is bookkeeping."

	got := summarise([]Section{{Prose: []Prose{{Text: lead}, {Text: body}}}})
	if got != body {
		t.Errorf("described the lesson with the lead-in rather than what follows it:\n  %q", got)
	}

	// The colon paragraph alone is still better than nothing.
	if got := summarise([]Section{{Prose: []Prose{{Text: lead}}}}); got != lead {
		t.Errorf("a lesson whose only paragraph is a lead-in described itself as %q", got)
	}
}

/*
A DEPLOYMENT THAT MAY NOT BE LISTED STILL LETS ITSELF BE CRAWLED.

	This is the mistake the whole arrangement is built to avoid, and it is the
	tempting one: `Disallow: /` reads like the strongest possible "stay away"
	and is in fact the weakest. `robots.txt` answers whether a page may be
	FETCHED; the header answers whether it may be LISTED — and a header nobody
	is allowed to fetch is a header nobody reads, which leaves the pages
	listable from anybody else's link, with no description, because the crawler
	was never permitted to look.

	So this asserts the absence of a line rather than its presence, which is
	unusual enough to say why: somebody tidying this file later will reach for
	`Disallow: /`, and this is the test that stops them.
*/
func TestALabIsNotListedAndIsStillCrawlable(t *testing.T) {
	quiet := aHandler()
	quiet.indexable = false

	body := get(t, quiet, "code.example", "/robots.txt", nil).Body.String()

	if strings.Contains(body, "Disallow: /\n") {
		t.Errorf("robots.txt blocks the crawl, which hides the noindex header:\n%s", body)
	}
	if !strings.Contains(body, "Allow: /") {
		t.Errorf("robots.txt does not allow the crawl that the header needs:\n%s", body)
	}
	if strings.Contains(body, "Sitemap:") {
		t.Errorf("a deployment that may not be listed is offering a sitemap:\n%s", body)
	}
	if !strings.Contains(body, "X-Robots-Tag") {
		t.Errorf("robots.txt does not say where the refusal actually lives:\n%s", body)
	}

	// And the one that may be listed still offers it.
	loud := get(t, aHandler(), "code.example", "/robots.txt", nil).Body.String()
	if !strings.Contains(loud, "Sitemap: http://code.example/sitemap.xml") {
		t.Errorf("an indexable deployment stopped offering its sitemap:\n%s", loud)
	}
}
