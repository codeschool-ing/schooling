package discover

import "html/template"

/*
The page itself.

	IT CARRIES ITS OWN FEW RULES AND NOT THE INTERFACE'S STYLESHEET. Somebody
	arriving from a search has not asked for the study interface and should not
	be made to download it to read a description — and `assets/base.css` is
	written for a shell this page does not have. What is here is a column of
	text that reads on a phone, in the system's own type, and it inherits the
	reader's dark or light preference instead of insisting on one.

	THE ALTERNATES AND THE CANONICAL ARE THE POINT OF IT. Everything else on
	this page a person reads; those two lines are the ones a search engine reads,
	and they are why the page exists at all.
*/
var page = template.Must(template.New("course").Parse(`<!DOCTYPE html>
<html lang="{{.Lang}}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{.Course.Name}}{{if .School}} — {{.School}}{{end}}</title>
<meta name="description" content="{{.Course.Summary}}">
<link rel="canonical" href="{{.Canonical}}">
{{- range .Alternates}}
<link rel="alternate" hreflang="{{.HrefLang}}" href="{{.Href}}">
{{- end}}
<link rel="alternate" hreflang="x-default" href="{{.XDefault}}">
<meta property="og:type" content="website">
<meta property="og:title" content="{{.Course.Name}}">
<meta property="og:description" content="{{.Course.Summary}}">
<meta property="og:url" content="{{.Canonical}}">
{{- if .School}}
<meta property="og:site_name" content="{{.School}}">
{{- end}}
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="{{.Course.Name}}">
<meta name="twitter:description" content="{{.Course.Summary}}">
<style>
:root{color-scheme:light dark}
body{margin:0;font:16px/1.6 system-ui,-apple-system,'Segoe UI',sans-serif}
main{max-width:46rem;margin:0 auto;padding:2rem 1rem 4rem}
h1{font-size:1.8rem;line-height:1.2;margin:.2em 0}
h2{font-size:1.1rem;margin:2em 0 .5em}
ul{padding-left:1.2em}
li{margin:.3em 0}
/* The reader's own colours, not the browser's: a visited link goes purple by
   default, which on a dark ground is the one pair here that stops reading.
   Underlined instead, which says the same thing in both schemes. */
a{color:inherit;text-decoration:underline;text-underline-offset:2px}
.eyebrow{opacity:.7;margin:0;font-size:.85rem;text-transform:uppercase;letter-spacing:.08em}
.lede{font-size:1.1rem}
.facts{list-style:none;padding:0;display:flex;flex-wrap:wrap;gap:.5rem}
.facts li{border:1px solid;border-radius:3px;padding:.15rem .6rem;font-size:.85rem;opacity:.8}
.tongues{display:flex;gap:1rem;font-size:.85rem;margin-bottom:1.5rem}
.tongues [aria-current]{font-weight:600}
.go{display:inline-block;margin-top:2rem;padding:.6rem 1.1rem;border:1px solid;border-radius:3px}
</style>
</head>
<body>
<main>
  <div class="tongues">
  {{- range .OtherTongue}}
    <a href="{{.Href}}" {{if .Here}}aria-current="true"{{end}}>{{.Label}}</a>
  {{- end}}
  </div>

  <p class="eyebrow">{{.Words.course}}{{if .School}} · {{.School}}{{end}}</p>
  <h1>{{.Course.Name}}</h1>
  <p class="lede">{{.Course.Summary}}</p>

  <ul class="facts">
    <li>{{.Course.Hours}} {{.Words.hours}}</li>
    <li>{{.Words.level}}: {{.Level}}</li>
  </ul>

{{- if .Course.Prerequisites}}
  <h2>{{.Words.prereq}}</h2>
  <p>{{.Course.Prerequisites}}</p>
{{- end}}

{{- if .Course.Syllabus}}
  <h2>{{.Words.syllabus}}</h2>
  <ul>{{range .Course.Syllabus}}
    <li>{{.}}</li>{{end}}
  </ul>
{{- end}}

{{- if .Lessons}}
  <h2>{{.Words.lessons}}</h2>
  <ul>{{range .Lessons}}
    <li>{{if .Href}}<a href="{{.Href}}">{{.Label}}</a>{{else}}{{.Label}}{{end}}</li>{{end}}
  </ul>
{{- end}}

  <p>
    <a class="go" href="{{.OpenAt}}">{{.Words.open}}</a>
    <a class="go" href="{{.Home}}">{{.Words.catalogue}}</a>
  </p>
</main>
<script type="application/ld+json">{{.JSONLD}}</script>
</body>
</html>
`))
