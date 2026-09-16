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
` + headTags + `
<meta property="og:type" content="website">
{{- if .School}}
<meta property="og:site_name" content="{{.School}}">
{{- end}}
` + sheet + `
</head>
<body>
<main>
` + tongues + `
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
