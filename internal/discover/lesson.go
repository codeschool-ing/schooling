package discover

import (
	"errors"
	"html/template"
	"net/http"
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
One lesson, as a page.

	# ONLY WHAT A STRANGER MAY ALREADY READ

	The catalogue opens the first course of every track to everybody and sells
	the rest. This page asks the store for a lesson with NO PLAN, which is what
	a crawler is — so a paid course refuses here exactly as it refuses the API,
	by the same call, and nothing in this package has to remember the rule or
	could get it wrong. Giving away a page of a course that is sold would be a
	product decision, and it is not one a search engine feature gets to make on
	its own.

	A locked lesson and a lesson that does not exist are one answer, 404. The
	alternative is a page that exists to say you may not read it, which is a
	page a search engine will index and a reader will resent.

	# ADDRESSED BY POSITION, LIKE THE INTERFACE

	`/course/linux-terminal/lesson/11` is the interface's own
	`#/course/linux-terminal/lesson/11` without the `#`, which means a person
	can read one off the other. The alternative is the lesson's id — `le-232xd54k`
	— which is stable where a position is not, and unreadable where a position
	is obvious. The cost is named rather than hidden: reordering a course's
	lessons moves these addresses, and a moved address is a 404 until a crawler
	comes back. Courses are republished from a snapshot and reordered rarely,
	and the sitemap is re-read on every crawl.
*/
func (h *Handler) lesson(w http.ResponseWriter, r *http.Request, code string) {
	at, err := strconv.Atoi(r.PathValue("at"))
	if err != nil || at < 1 {
		http.NotFound(w, r)
		return
	}

	slug := r.PathValue("slug")
	lesson, err := h.reading(r.Context(), slug, at, code)
	if errors.Is(err, ErrNoLesson) || errors.Is(err, ErrNoCourse) {
		http.NotFound(w, r)
		return
	}
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a lesson for its page", "error", err,
			"course", slug, "at", at)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	course, err := h.one(r.Context(), slug, code)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a lesson's course", "error", err, "course", slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	origin := origin(r)
	path := "/course/" + slug + "/lesson/" + strconv.Itoa(at)
	here := languageAt(code)

	data := lessonPage{
		head:     headOf(origin, path, here, lesson.Title, summarise(lesson.Sections)),
		Lesson:   *lesson,
		Course:   course.Name,
		CourseAt: origin + languages[here].at + "/course/" + slug,
		Words:    words[code],
		OpenAt:   origin + "/#/course/" + slug + "/lesson/" + strconv.Itoa(at),
	}
	if name, found := h.school(r.Context()); found {
		data.School = name
	}
	write(w, r, lessonTemplate, data)
}

type lessonPage struct {
	head
	School   string
	Course   string
	CourseAt string
	Lesson   Lesson
	Words    map[string]string
	OpenAt   string
}

/*
The description, which is the lesson's own opening words.

	A `<meta name="description">` written by a program is usually the first
	hundred characters of whatever it found, and reads like it. This takes the
	first paragraph the lesson actually opens with — which an author wrote to be
	read first.

	IT NO LONGER DOES THE CUTTING. `headOf` shortens every page's description,
	which is where the cut belongs: this used to be the only page that trimmed to
	a length, and the course and track pages went out whole and were cut by the
	search engine instead. Choosing the paragraph is this function's job; how long
	a description may be is the frame's.

	A heading is skipped because it is a title rather than a sentence, and a very
	short paragraph because a lesson that opens with "Let us begin." has said
	nothing a result should show.
*/
func summarise(sections []Section) string {
	first := ""
	for _, s := range sections {
		for _, p := range s.Prose {
			if p.Heading != "" || utf8.RuneCountInString(p.Text) < 40 {
				continue
			}
			if first == "" {
				first = p.Text
			}
			/* A PARAGRAPH THAT ENDS IN A COLON IS INTRODUCING SOMETHING THIS
			   PAGE DOES NOT HAVE. `prose.Extract` drops code blocks and tables
			   deliberately, so "…and lesson 3 already showed you both:" arrives
			   here as a promise with nothing after it — which in a result reads
			   like a page that was cut off. Three lessons in the catalogue open
			   that way; the paragraph after is what they are about.

			   It is a preference and not a filter: `first` keeps the colon one,
			   so a lesson whose only paragraph ends that way still describes
			   itself rather than saying nothing. */
			if strings.HasSuffix(strings.TrimSpace(p.Text), ":") {
				continue
			}
			return p.Text
		}
	}
	return first
}

var lessonTemplate = template.Must(template.New("lesson").Parse(`<!DOCTYPE html>
<html lang="{{.Lang}}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{.Lesson.Title}} — {{.Course}}</title>
` + headTags + `
<meta property="og:type" content="article">
{{- if .School}}
<meta property="og:site_name" content="{{.School}}">
{{- end}}
` + sheet + `
</head>
<body>
<main>
` + tongues + `
  <p class="eyebrow"><a href="{{.CourseAt}}">{{.Course}}</a>{{if .School}} · {{.School}}{{end}}</p>
  <h1>{{.Lesson.Title}}</h1>

{{- range .Lesson.Sections}}
  <h2>{{.Title}}</h2>
  {{- range .Prose}}
  {{- if .Heading}}
  <h3>{{.Heading}}</h3>
  {{- else}}
  <p>{{.Text}}</p>
  {{- end}}
  {{- end}}
{{- end}}

  <div class="whole">
    <p>{{.Words.inTheApp}}</p>
    <a class="go" href="{{.OpenAt}}">{{.Words.read}}</a>
  </div>
</main>
</body>
</html>
`))
