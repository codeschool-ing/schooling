package discover

import (
	"encoding/json"
	"errors"
	"html/template"
	"net/http"
	"strconv"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
One course, as a page.

	`html/template` AND NOT A STRING, and the reason is that everything on this
	page came from a database a school fills in. A course called `A & B` or a
	school whose name carries an apostrophe would break the markup with
	concatenation, and one that carried a `<script>` would do worse than break
	it. The template escapes per context — inside an attribute, inside text,
	inside the JSON of the structured data — which is the part a careful writer
	gets wrong by hand.

	THE PAGE IS NOT THE INTERFACE AND DOES NOT PRETEND TO BE. It is a sheet of
	text with a link into the app, which is what a search result should land on:
	the thing described, and one way in. Styling it like the study interface
	would mean shipping the interface's stylesheet to somebody who has not asked
	for the interface.
*/

// The words these pages use, in the two languages the content exists in. They
// are here rather than in the interface's dictionaries because the interface
// translates a DOM it owns at runtime, and this is HTML written on a server —
// one string table for two languages is smaller than the machinery to share
// theirs.
var words = map[string]map[string]string{
	"en": {
		"course": "Course", "hours": "hours", "level": "Level",
		"prereq": "What you need first", "syllabus": "What you will learn",
		"topics": "Full topic list", "lessons": "Lessons",
		"open": "Open this course", "catalogue": "All courses",
		"read":     "Read this lesson",
		"inTheApp": "This page is the lesson's words. The figures, the worked examples and the exercises are in the school itself.",
		"beginner": "beginner", "intermediate": "intermediate", "advanced": "advanced",
	},
	"pt": {
		"course": "Curso", "hours": "horas", "level": "Nível",
		"prereq": "O que você precisa antes", "syllabus": "O que você vai aprender",
		"topics": "Lista completa de tópicos", "lessons": "Aulas",
		"open": "Abrir este curso", "catalogue": "Todos os cursos",
		"read":     "Ler esta aula",
		"inTheApp": "Esta página são as palavras da aula. As figuras, os exemplos resolvidos e os exercícios estão na escola.",
		"beginner": "iniciante", "intermediate": "intermediário", "advanced": "avançado",
	},
}

type pageData struct {
	Lang        string
	School      string
	Course      Course
	Level       string
	Words       map[string]string
	Canonical   string
	Alternates  []alternate
	XDefault    string
	OpenAt      string
	Home        string
	OtherTongue []link
	// Lessons is the course's lessons as links. A free course's lessons have a
	// page of their own; a course that is sold lists its titles and links
	// nowhere, because there is nowhere a stranger may go.
	Lessons []link
	JSONLD  template.JS
}

type link struct {
	Label string
	Href  string
	Here  bool
}

func (h *Handler) course(w http.ResponseWriter, r *http.Request) {
	code := "en"
	if given := r.PathValue("lang"); given != "" {
		if _, ok := languageAt(given); !ok {
			// A path shaped like a language page in a language nothing is
			// written in. It is not a page, so it is not found.
			http.NotFound(w, r)
			return
		}
		code = given
	}

	slug := r.PathValue("slug")
	course, err := h.one(r.Context(), slug, code)
	if errors.Is(err, ErrNoCourse) {
		http.NotFound(w, r)
		return
	}
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a course for its page", "error", err, "slug", slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	at := origin(r)
	path := "/course/" + course.Slug
	here, _ := languageAt(code)

	data := pageData{
		Lang:      languages[here].tag,
		Course:    *course,
		Words:     words[code],
		Canonical: at + languages[here].at + path,
		XDefault:  at + path,
		// The interface's own route for this course. A fragment, because that
		// is what the interface routes on — this link is the way in, not a
		// second address for a search engine to find.
		OpenAt: at + "/#/course/" + course.Slug,
		Home:   at + "/",
		/* `gosec` is right that this conversion turns the template's escaping
		   off, and it cannot see the one thing that makes it safe: the value
		   comes from `json.Marshal`, which writes `<`, `>` and `&` as `\u003c`,
		   `\u003e` and `\u0026` — so it cannot close this script element or
		   open any other tag, whatever a school typed into a course's name.
		   `TestTheStructuredDataCannotCloseItsOwnScript` is that claim as a
		   test rather than as this sentence. */
		JSONLD: template.JS(jsonLD(*course, at+languages[here].at+path, //nolint:gosec // json.Marshal escapes the three characters that could end the element; see the test named above
			languages[here].tag)),
	}
	if name, ok := h.school(r.Context()); ok {
		data.School = name
	}
	if l, ok := words[code][course.Level]; ok {
		data.Level = l
	} else {
		data.Level = course.Level
	}
	for _, l := range course.Lessons {
		row := link{Label: l.Title}
		if course.Free {
			row.Href = at + languages[here].at + path + "/lesson/" + strconv.Itoa(l.At)
		}
		data.Lessons = append(data.Lessons, row)
	}
	for i, l := range languages {
		data.Alternates = append(data.Alternates, alternate{
			Rel: "alternate", HrefLang: l.tag, Href: at + l.at + path,
		})
		data.OtherTongue = append(data.OtherTongue, link{
			Label: l.label, Href: at + l.at + path, Here: i == here,
		})
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	// A course page changes when the catalogue is republished, which is rare
	// and is not on a clock. Long enough to be worth caching, short enough that
	// a correction is out the same day.
	w.Header().Set("Cache-Control", "public, max-age=1800")
	if err := page.Execute(w, data); err != nil {
		web.LoggerFrom(r.Context()).Error("writing a course page", "error", err, "slug", slug)
	}
}

/*
schema.org, which is what a course in a search result is made of.

	`offers` IS DELIBERATELY ABSENT. A price is a school's, it is per plan and it
	changes; a wrong one in structured data is a complaint from somebody who
	read it and believed it. What is here is what the catalogue knows and does
	not have to be kept in step with billing.

	It is built as a value and marshalled, rather than written as a string,
	because `template.JS` turns off the escaping that would otherwise protect
	this — so the JSON has to be JSON by construction.
*/
func jsonLD(c Course, url, tag string) string {
	teaches := c.Syllabus
	if len(teaches) == 0 {
		teaches = c.Topics
	}
	if len(teaches) > 12 {
		teaches = teaches[:12]
	}

	// A struct, so the JSON is JSON by construction and in a settled order.
	// `encoding/json` escapes `<`, `>` and `&` on the way out, which is what
	// makes it safe to hand to `template.JS` — the one place on this page where
	// the template's own escaping is turned off.
	body, err := json.Marshal(struct {
		Context      string   `json:"@context"`
		Type         string   `json:"@type"`
		Name         string   `json:"name"`
		Description  string   `json:"description"`
		URL          string   `json:"url"`
		InLanguage   string   `json:"inLanguage"`
		TimeRequired string   `json:"timeRequired"`
		Teaches      []string `json:"teaches,omitempty"`
	}{
		Context: "https://schema.org", Type: "Course",
		Name: c.Name, Description: c.Summary, URL: url, InLanguage: tag,
		TimeRequired: "PT" + strconv.Itoa(c.Hours) + "H", Teaches: teaches,
	})
	if err != nil {
		// Nothing here can fail to marshal; an empty object is a page without
		// structured data rather than a page that did not render.
		return "{}"
	}
	return string(body)
}
