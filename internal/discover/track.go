package discover

import (
	"context"
	"errors"
	"html/template"
	"net/http"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
A track, as a page, and the catalogue as the page that links them all.

	# WHY A TRACK IS WORTH ITS OWN ADDRESS

	A track is what somebody actually searches for. Nobody types "course on
	bandwidth and latency"; they type the name of the job they want, and a
	track IS that — a name, what it is for, what somebody can do at the end of
	it, and the courses in the order they are taken. All of it is written, all
	of it is translated, and until now none of it was at an address.

	# AND WHY THE CATALOGUE PAGE EXISTS AT ALL

	`/` is the study interface: one file, the same bytes for every school, that
	builds itself from the API. A crawler that lands there finds a shell. The
	course pages are in the sitemap, so they are reachable — but a sitemap is a
	hint and a link is a path, and a catalogue with no page has nothing linking
	its courses to each other.

	So `/courses` lists every course this school publishes and `/tracks` lists
	every track, each linking the pages beside it. Between them, every page this
	package serves is two clicks from an address a person can be given.

	THE INTERFACE IS NOT TOUCHED AND `/` STILL SERVES IT. A crawler getting a
	different page from the one a reader gets is cloaking, and it is punished
	rather than rewarded. These are additional pages, linked from the ones
	beside them, and they say plainly that the school itself is through the
	link at the bottom.
*/

// Track is what a track page is written from.
type Track struct {
	Slug    string
	Name    string
	Goal    string
	Outcome string
	Steps   []Step
}

// Step is one step of a track: a course, or a choice between courses. `Slug` is
// empty for a choice, because a choice has no page — it is a decision, and the
// courses inside it have pages of their own.
type Step struct {
	Name    string
	Slug    string
	Choice  string
	Options []string
}

type (
	// Paths is every track this school publishes, in one language.
	Paths func(ctx context.Context, locale string) ([]Track, error)

	// Route is one track by slug, or ErrNoTrack.
	Route func(ctx context.Context, slug, locale string) (*Track, error)
)

type noTrack struct{}

func (noTrack) Error() string { return "discover: no such track in this school" }

// ErrNoTrack is the sentinel for a track this school does not publish.
var ErrNoTrack error = noTrack{}

func (h *Handler) track(w http.ResponseWriter, r *http.Request, code string) {
	slug := r.PathValue("slug")
	track, err := h.route(r.Context(), slug, code)
	if errors.Is(err, ErrNoTrack) {
		http.NotFound(w, r)
		return
	}
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a track for its page", "error", err, "slug", slug)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	at := origin(r)
	path := "/track/" + track.Slug
	here := languageAt(code)

	data := trackPage{
		head:  headOf(at, path, here, track.Name, track.Goal),
		Track: *track,
		Words: words[code],
		Home:  at + languages[here].at + "/courses",
	}
	if name, found := h.school(r.Context()); found {
		data.School = name
	}
	for _, s := range track.Steps {
		row := link{Label: s.Name}
		if s.Slug != "" {
			row.Href = at + languages[here].at + "/course/" + s.Slug
		}
		data.Course = append(data.Course, row)
	}

	data.Card = at + languages[here].at + "/card/track/" + track.Slug

	write(w, r, trackTemplate, data)
}

type trackPage struct {
	head
	School string
	Track  Track
	Course []link
	Words  map[string]string
	Home   string
}

var trackTemplate = template.Must(template.New("track").Parse(`<!DOCTYPE html>
<html lang="{{.Lang}}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{.Track.Name}}{{if .School}} — {{.School}}{{end}}</title>
{{- if .Track.Goal}}
<meta name="description" content="{{.Track.Goal}}">
{{- end}}
` + headTags + `
` + sheet + `
</head>
<body>
<main>
` + tongues + `
  <p class="eyebrow">{{.Words.track}}{{if .School}} · {{.School}}{{end}}</p>
  <h1>{{.Track.Name}}</h1>
{{- if .Track.Goal}}
  <p class="lede">{{.Track.Goal}}</p>
{{- end}}
{{- if .Track.Outcome}}
  <h2>{{.Words.outcome}}</h2>
  <p>{{.Track.Outcome}}</p>
{{- end}}

{{- if .Course}}
  <h2>{{.Words.inOrder}}</h2>
  <ol>{{range .Course}}
    <li>{{if .Href}}<a href="{{.Href}}">{{.Label}}</a>{{else}}{{.Label}}{{end}}</li>{{end}}
  </ol>
{{- end}}

  <p><a class="go" href="{{.Home}}">{{.Words.catalogue}}</a></p>
</main>
</body>
</html>
`))
