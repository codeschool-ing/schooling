package discover

import (
	"html/template"
	"net/http"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
The two lists: every course, and every track.

	A SITEMAP IS A HINT AND A LINK IS A PATH. The course pages were reachable
	from `sitemap.xml` and from nowhere else — nothing on this platform linked
	to one, because the interface's own links are fragments that never leave the
	browser. These are the pages that make the rest walkable: a crawler that
	finds one address here finds all of them, and so does a person.

	They are also the only pages a school can be sent as "here is what we
	teach", which the study interface cannot be: it is an application behind a
	fragment router, and what it shows depends on what the browser did after it
	loaded.
*/

type listPage struct {
	head
	School string
	Words  map[string]string
	Rows   []link
	Other  link // the other list, linked from the foot of this one

	// The heading a reader sees. `Title` carries the school too, because a tab
	// and a search result have to say whose page this is; an `<h1>` under an
	// eyebrow that already names the school would say it twice.
	Heading string
}

func (h *Handler) everyCourse(w http.ResponseWriter, r *http.Request, code string) {
	courses, err := h.list(r.Context(), code)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("listing the courses", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	at := origin(r)
	here := languageAt(code)
	data := listPage{
		Words: words[code],
		Other: link{Label: words[code]["everyTrack"], Href: at + languages[here].at + "/tracks"},
	}
	data.Heading = words[code]["everyCourse"]
	data.head = headOf(at, "/courses", here, data.Heading, "")
	if name, found := h.school(r.Context()); found {
		data.School = name
		data.Title = data.Heading + " — " + name
	}
	for _, c := range courses {
		data.Rows = append(data.Rows, link{
			Label: c.Name,
			Href:  at + languages[here].at + "/course/" + c.Slug,
			Note:  c.Summary,
		})
	}
	write(w, r, listTemplate, data)
}

func (h *Handler) everyTrack(w http.ResponseWriter, r *http.Request, code string) {
	tracks, err := h.paths(r.Context(), code)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("listing the tracks", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	at := origin(r)
	here := languageAt(code)
	data := listPage{
		Words: words[code],
		Other: link{Label: words[code]["everyCourse"], Href: at + languages[here].at + "/courses"},
	}
	data.Heading = words[code]["everyTrack"]
	data.head = headOf(at, "/tracks", here, data.Heading, "")
	if name, found := h.school(r.Context()); found {
		data.School = name
		data.Title = data.Heading + " — " + name
	}
	for _, t := range tracks {
		data.Rows = append(data.Rows, link{
			Label: t.Name,
			Href:  at + languages[here].at + "/track/" + t.Slug,
			Note:  t.Goal,
		})
	}
	write(w, r, listTemplate, data)
}

var listTemplate = template.Must(template.New("list").Parse(`<!DOCTYPE html>
<html lang="{{.Lang}}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{.Title}}</title>
` + headTags + `
` + sheet + `
</head>
<body>
<main>
` + tongues + `
{{- if .School}}
  <p class="eyebrow">{{.School}}</p>
{{- end}}
  <h1>{{.Heading}}</h1>

  <ul class="rows">{{range .Rows}}
    <li><a href="{{.Href}}">{{.Label}}</a>{{if .Note}}<span class="note">{{.Note}}</span>{{end}}</li>{{end}}
  </ul>

  <p><a class="go" href="{{.Other.Href}}">{{.Other.Label}}</a></p>
</main>
</body>
</html>
`))
