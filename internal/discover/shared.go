package discover

import (
	"html/template"
	"net/http"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
What every page here has in common, in one place.

	There are four page types now — a course, a lesson, a track, and the two
	lists — and the half of each that matters to a search engine is the same
	half: the canonical, the alternates, the cards, the row of languages. Three
	copies of that was two too many, and the copies had already started to
	differ: one of them named `x-default` and another did not.

	The CONTENT of each page is its own. This is the frame around it.
*/

// head is the part of a page that a search engine reads. Every page type embeds
// it, and `headOf` is the only thing that fills it — so a page cannot be given
// an alternate set that disagrees with its canonical.
type head struct {
	Lang        string
	Canonical   string
	XDefault    string
	Title       string
	Description string
	Alternates  []alternate
	OtherTongue []link
}

// headOf builds the frame for one page at one path, in one language. `path` is
// the address WITHOUT a language prefix — the prefix is this function's to add,
// which is what keeps the set consistent.
func headOf(origin, path string, here int, title, description string) head {
	h := head{
		Lang:        languages[here].tag,
		Canonical:   origin + languages[here].at + path,
		XDefault:    origin + path,
		Title:       title,
		Description: description,
	}
	for i, l := range languages {
		h.Alternates = append(h.Alternates, alternate{
			Rel: "alternate", HrefLang: l.tag, Href: origin + l.at + path,
		})
		h.OtherTongue = append(h.OtherTongue, link{
			Label: l.label, Href: origin + l.at + path, Here: i == here,
		})
	}
	return h
}

// write sends a page. The cache is short on purpose: these are built from a
// catalogue that is republished rather than edited, and a correction should be
// out the same day rather than at the end of the week.
func write(w http.ResponseWriter, r *http.Request, t *template.Template, data any) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "public, max-age=1800")
	if err := t.Execute(w, data); err != nil {
		web.LoggerFrom(r.Context()).Error("writing a page", "error", err, "path", r.URL.Path)
	}
}

// The head's tags, which are the same on every page and are why this file
// exists. `og:type` is `website` for a thing and `article` for a lesson, so it
// is the one the page decides; everything else is the frame.
const headTags = `<link rel="canonical" href="{{.Canonical}}">
{{- range .Alternates}}
<link rel="alternate" hreflang="{{.HrefLang}}" href="{{.Href}}">
{{- end}}
<link rel="alternate" hreflang="x-default" href="{{.XDefault}}">
<meta property="og:title" content="{{.Title}}">
{{- if .Description}}
<meta property="og:description" content="{{.Description}}">
{{- end}}
<meta property="og:url" content="{{.Canonical}}">
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="{{.Title}}">
{{- if .Description}}
<meta name="twitter:description" content="{{.Description}}">
{{- end}}`

// The row of languages, which is the only navigation these pages have and the
// only way a reader moves between the two of them.
const tongues = `  <div class="tongues">
  {{- range .OtherTongue}}
    <a href="{{.Href}}" {{if .Here}}aria-current="true"{{end}}>{{.Label}}</a>
  {{- end}}
  </div>
`

/*
The look, which is deliberately almost nothing.

	Somebody arriving from a search has not asked for the study interface and
	should not have to download it to read a description — and `assets/base.css`
	is written for a shell these pages do not have. This is a column of text
	that reads on a phone, in the system's own type, inheriting the reader's
	dark or light preference instead of insisting on one.

	`a{color:inherit}`: a visited link goes purple by default, which on a dark
	ground is the one pair here that stops reading. Underlined says the same
	thing in both schemes.
*/
const sheet = `<style>
:root{color-scheme:light dark}
body{margin:0;font:16px/1.7 system-ui,-apple-system,'Segoe UI',sans-serif}
main{max-width:44rem;margin:0 auto;padding:2rem 1rem 4rem}
h1{font-size:1.8rem;line-height:1.25;margin:.2em 0 .6em}
h2{font-size:1.2rem;margin:2.2em 0 .4em}
h3{font-size:1.05rem;margin:1.6em 0 .3em}
ul,ol{padding-left:1.3em}
li{margin:.35em 0}
a{color:inherit;text-decoration:underline;text-underline-offset:2px}
a.go{text-decoration:none}
.eyebrow{opacity:.7;margin:0;font-size:.85rem;text-transform:uppercase;letter-spacing:.08em}
.lede{font-size:1.1rem}
.facts{list-style:none;padding:0;display:flex;flex-wrap:wrap;gap:.5rem}
.facts li{border:1px solid;border-radius:3px;padding:.15rem .6rem;font-size:.85rem;opacity:.8}
.tongues{display:flex;gap:1rem;font-size:.85rem;margin-bottom:1.5rem}
.tongues [aria-current]{font-weight:600}
.whole{margin:2.5rem 0;padding:1rem;border:1px solid;border-radius:3px}
.whole p{margin:0}
.rows{list-style:none;padding:0}
.rows li{margin:1.1em 0}
.rows .note{display:block;opacity:.75;font-size:.92rem}
.go{display:inline-block;margin-top:.6rem;padding:.6rem 1.1rem;border:1px solid;border-radius:3px}
</style>`
