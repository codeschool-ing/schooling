package discover

import (
	"context"
	"encoding/json"
	"encoding/xml"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func aCourse() Course {
	return Course{
		Slug: "linux-terminal", Name: "Linux and the Command Line", Hours: 70,
		Level: "beginner", Summary: "The system that runs the internet.",
		Prerequisites: "No programming required.",
		Syllabus:      []string{"Distributions", "Permissions"},
		Topics:        []string{"ls, cd, pwd"},
		Free:          true,
		Lessons: []Lesson{{At: 1, Title: "The terminal, and why", Sections: []Section{{
			Title: "Where you are",
			Prose: []Prose{{Text: "A terminal is a window onto a machine that has no desktop."}},
		}}}},
	}
}

func aHandler(courses ...Course) *Handler {
	if len(courses) == 0 {
		courses = []Course{aCourse()}
	}
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
		func(context.Context) (string, bool) { return "codeschool", true },
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
