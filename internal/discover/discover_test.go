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
		Lessons:       []string{"The terminal, and why"},
	}
}

func aHandler(courses ...Course) *Handler {
	if len(courses) == 0 {
		courses = []Course{aCourse()}
	}
	return NewHandler(
		func(context.Context, string) ([]Course, error) { return courses, nil },
		func(_ context.Context, slug, _ string) (*Course, error) {
			for i := range courses {
				if courses[i].Slug == slug {
					return &courses[i], nil
				}
			}
			return nil, ErrNoCourse
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
