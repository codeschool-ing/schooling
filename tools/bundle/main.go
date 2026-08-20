// Command bundle writes one school into a single HTML file.
//
// # WHAT IT IS FOR
//
// A student with a laptop and no connection, a classroom with one download
// between thirty machines, a school handed to somebody on a memory stick. One
// file, opened by double-clicking it, that reads like the site.
//
// # ONE FILE, TWO LIVES
//
// Opened from `file://` it never touches the network: there is no server to
// reach and no origin to be the same as, and every answer it needs is already
// in the page. Served over http from the school's own address it is the
// application again, unchanged and signed in, because then it IS on that
// origin and the session cookie works.
//
// That is what the fragment routes bought. `#/course/web-fundamentals` needs
// no server to resolve it, so there is one client rather than a reader and an
// application that drift apart.
//
// WHAT IT REFUSES: signing in, progress and exams. They are the school's
// record of a student and a copy of a file has neither — a tick that vanished
// with the tab would be worse than no tick, and an exam marked here would be an
// exam whose answers were in the page. The interface says so, in a sentence,
// where it would otherwise have shown a control.
//
// # IT ASKS THE SERVER FOR EVERYTHING, INCLUDING ITSELF
//
// The interface, the stylesheets, the fonts and the catalogue all come from a
// running binary over HTTP. Nothing here reads `ui/` off the disk, and that is
// deliberate: a bundler with its own copy of the asset list is a bundler that
// ships last week's interface the first time somebody adds a file. What it
// writes is what that server serves, and there is no second source of truth to
// keep in step.
//
// It fetches as a stranger — no session, no cookie — so what lands in the file
// is what a visitor may see. A locked course is in there, locked.
//
//	go run ./tools/bundle -host code.example.tld -out bundle.html
package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path"
	"regexp"
	"sort"
	"strings"
	"time"
)

// The locales the interface can ask content in. It is a list rather than a
// question to the server because the API takes the locale as a parameter and
// has no endpoint that enumerates them; `i18n.js` is where the other copy
// lives, and the two disagreeing means a language reads in English.
var locales = []string{"en", "pt"}

const fileMode = 0o600

func main() {
	var (
		from = flag.String("from", "http://127.0.0.1:8099", "the running server to ask")
		host = flag.String("host", "", "the school's host, which is how the server knows which one")
		out  = flag.String("out", "bundle.html", "the file to write")
	)
	flag.Parse()

	if *host == "" {
		fmt.Fprintln(os.Stderr, "bundle: -host is required — it is how the server knows which school")
		os.Exit(1)
	}

	written, err := build(*from, *host, *out)
	if err != nil {
		fmt.Fprintln(os.Stderr, "bundle:", err)
		os.Exit(1)
	}
	fmt.Printf("%s — %.0f kB\n", *out, float64(written)/1000)
}

// A server, asked with one school's Host on every request.
type server struct {
	base string
	host string
	http *http.Client
}

// errLocked is the server refusing a stranger, which is the paywall doing its
// job rather than anything going wrong.
var errLocked = errors.New("that is behind the paywall")

func (s server) get(path string) ([]byte, string, error) {
	request, err := http.NewRequest(http.MethodGet, s.base+path, nil)
	if err != nil {
		return nil, "", err
	}
	// THE HOST HEADER IS THE TENANT. It is not a nicety: the server resolves
	// the school from it, and without it every answer is a 404 for a host
	// nobody registered.
	request.Host = s.host

	answer, err := s.http.Do(request)
	if err != nil {
		return nil, "", err
	}
	defer func() { _ = answer.Body.Close() }()

	body, err := io.ReadAll(answer.Body)
	if err != nil {
		return nil, "", err
	}
	/* A LOCKED COURSE'S PROSE IS NOT A FAILURE. This fetches as a stranger — no
	   session, no cookie — so what lands in the file is what a visitor may see,
	   and the server saying "that one is behind the paywall" is the paywall
	   working. It is reported to the caller as a state rather than an error, and
	   the caller skips the lesson: the course is still in the bundle, with its
	   shape and without its words, which is exactly how it looks online. */
	if answer.StatusCode == http.StatusPaymentRequired {
		return nil, "", errLocked
	}
	if answer.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("%s answered %s", path, answer.Status)
	}
	return body, answer.Header.Get("Content-Type"), nil
}

func (s server) text(path string) (string, error) {
	body, _, err := s.get(path)
	return string(body), err
}

func build(base, host, out string) (int, error) {
	s := server{base: base, host: host, http: &http.Client{Timeout: 30 * time.Second}}

	shell, err := s.text("/")
	if err != nil {
		return 0, fmt.Errorf("the shell: %w", err)
	}

	answers, pictures, err := gather(s)
	if err != nil {
		return 0, err
	}

	page, err := inline(s, shell, answers, pictures)
	if err != nil {
		return 0, err
	}
	return len(page), os.WriteFile(out, []byte(page), fileMode)
}

/* ---------- what the school is ---------- */

// EVERY ANSWER IS KEYED BY THE PATH THE CLIENT ASKS FOR, character for
// character. That is the whole trick: the offline half of `api.js` is a map
// lookup, so nothing in the browser has to know a second shape of the API, and
// an endpoint that changes shape changes in one place.
func gather(s server) (map[string]json.RawMessage, map[string]string, error) {
	answers := map[string]json.RawMessage{}

	// The pictures, as data URIs, keyed by the address the interface builds for
	// them. A labelling question whose diagram never loads is one a student
	// cannot answer however well they know the material — see `asset` in api.js
	// for the other half.
	pictures := map[string]string{}

	ask := func(path string) (json.RawMessage, error) {
		body, _, err := s.get(path)
		if err != nil {
			return nil, err
		}
		if !json.Valid(body) {
			return nil, fmt.Errorf("%s did not answer JSON", path)
		}
		answers[path] = json.RawMessage(body)
		return json.RawMessage(body), nil
	}

	/* One endpoint, once per language, keyed the way the client keys it.

	   IT RETURNS THE SOURCE LANGUAGE'S ANSWER, because the tool reads the
	   catalogue to find out what else to ask for — which tracks there are,
	   which lessons a course has — and those are ids. An id is the same in
	   every language, so any of the answers would do; the first is chosen so
	   that the walk is deterministic rather than "whichever locale sorted
	   last".

	   The plain path with no `?lang=` is NOT baked. Nothing asks for it: the
	   client always sends the language it is showing, and an unkeyed copy would
	   be dead weight in a file measured in megabytes and a second answer that
	   could disagree with the first. */
	askEvery := func(ask func(string) (json.RawMessage, error), path string) (json.RawMessage, error) {
		var first json.RawMessage
		for _, locale := range locales {
			body, err := ask(path + "?lang=" + url.QueryEscape(locale))
			if err != nil {
				return nil, fmt.Errorf("%s in %s: %w", path, locale, err)
			}
			if first == nil {
				first = body
			}
		}
		return first, nil
	}

	if _, err := ask("/api/v1/school"); err != nil {
		return nil, nil, err
	}

	// THE TWO DOCUMENTS, IN EVERY LANGUAGE. A bundle whose privacy policy said
	// "this needs the school" would be a policy that is unpublished for whoever
	// is reading the offline copy — and that reader is the one most likely to
	// want it, since a file on a laptop is what gets handed to somebody else.
	//
	// The names are the closed list the server publishes. A third document
	// added there and not here is a link in the footer that opens a sentence
	// about needing the school.
	for _, document := range []string{"terms", "privacy"} {
		for _, locale := range locales {
			path := "/api/v1/legal/" + url.PathEscape(document) +
				"?lang=" + url.QueryEscape(locale)
			if _, err := ask(path); err != nil {
				return nil, nil, fmt.Errorf("the %s document in %s: %w", document, locale, err)
			}
		}
	}

	/* THE CATALOGUE, IN EVERY LANGUAGE — and it used to be baked in none.

	   A course's name, summary, syllabus and topics were translated by a
	   dictionary that shipped with the interface until the school started
	   answering them itself, and the client now asks for them the way it asks
	   for a lesson: with `?lang=`. Baked without one, the file holds a
	   catalogue under a key nothing ever looks up. Not a WRONG catalogue — no
	   catalogue: the bundle opened to an empty school, no track, and every
	   course drawn with the placeholder for one nobody has written.

	   Which is the failure the note above the lessons describes, and it is
	   worth reading twice: a key that differs by one query parameter is content
	   that is IN the file and cannot be found. `bundle-test` is the only thing
	   that sees it — the tool exits zero and the page weighs the same either
	   way. */
	courses, err := askEvery(ask, "/api/v1/courses")
	if err != nil {
		return nil, nil, err
	}

	/* THE SHAPE OF EVERY COURSE — which lessons, which sections, and no prose.
	   One request, and every denominator on every screen comes out of it: how
	   many sections a lesson has, which order they are in, which of them are
	   video.

	   Left out, the client falls back to the placeholder it draws for a course
	   nobody has written yet — one section called "Content" — and the bundle
	   showed that for all 122 courses while the served page showed the real
	   ones. It also carries the lesson IDS, which is what the prose is asked
	   for by, so without it not one lesson could be read either.

	   IN EVERY LANGUAGE, because the section titles in it are translated rows
	   here rather than a file per language, and the offline copy switches
	   language with no server to ask. */
	for _, locale := range locales {
		path := "/api/v1/lessons?lang=" + url.QueryEscape(locale)
		if _, err := ask(path); err != nil {
			return nil, nil, fmt.Errorf("the shape of the school in %s: %w", locale, err)
		}
	}
	tracks, err := askEvery(ask, "/api/v1/tracks")
	if err != nil {
		return nil, nil, err
	}

	var trackList struct {
		Tracks []struct {
			ID string `json:"id"`
		} `json:"tracks"`
	}
	if err := json.Unmarshal(tracks, &trackList); err != nil {
		return nil, nil, fmt.Errorf("the track list: %w", err)
	}
	for _, t := range trackList.Tracks {
		if _, err := askEvery(ask, "/api/v1/tracks/"+url.PathEscape(t.ID)); err != nil {
			return nil, nil, err
		}
	}

	var courseList struct {
		Courses []struct {
			ID string `json:"id"`
		} `json:"courses"`
	}
	if err := json.Unmarshal(courses, &courseList); err != nil {
		return nil, nil, fmt.Errorf("the course list: %w", err)
	}

	for _, c := range courseList.Courses {
		one, err := askEvery(ask, "/api/v1/courses/"+url.PathEscape(c.ID))
		if err != nil {
			return nil, nil, err
		}

		// A course's lessons are named on the course, so the tool asks for what
		// it was told about rather than for what it guesses exists.
		var course struct {
			Lessons []struct {
				ID string `json:"id"`
			} `json:"lessons"`
			Images []string `json:"images"`
		}
		if err := json.Unmarshal(one, &course); err != nil {
			return nil, nil, fmt.Errorf("course %s: %w", c.ID, err)
		}

		// THE COURSE LISTS ITS OWN PICTURES, which is why that field is on the
		// view at all: there is nobody else to ask. This tool fetches as a
		// stranger and never sits an exam, so it cannot see the questions that
		// name them.
		for _, name := range course.Images {
			path := "/api/v1/courses/" + url.PathEscape(c.ID) + "/images/" + url.PathEscape(name)
			body, kind, err := s.get(path)
			if err != nil {
				return nil, nil, fmt.Errorf("the picture %s of %s: %w", name, c.ID, err)
			}
			if kind == "" {
				kind = "application/octet-stream"
			}
			pictures[path] = dataURI(kind, body)
		}

		for _, lesson := range course.Lessons {
			for _, locale := range locales {
				// Built exactly as `api.js` builds it, `?lang=` and all: a key
				// that differs by one character is a lesson that is in the file
				// and cannot be found.
				path := "/api/v1/courses/" + url.PathEscape(c.ID) +
					"/lessons/" + url.PathEscape(lesson.ID) +
					"?lang=" + url.QueryEscape(locale)
				if _, err := ask(path); err != nil {
					if errors.Is(err, errLocked) {
						continue
					}
					return nil, nil, fmt.Errorf("%s in %s: %w", lesson.ID, locale, err)
				}
			}
		}
	}

	return answers, pictures, nil
}

/* ---------- the page ---------- */

var (
	/* `/assets/` AND `/app/`. The interface used to be one directory; the client
	   is now `portal-frontend`'s, which is a tree of its own under `/app/`, and
	   a bundler that only knew about `/assets/` produced a file with the
	   stylesheets inlined and the whole application still pointing at a server
	   that is not there. */
	linkOf   = regexp.MustCompile(`<link[^>]*?href="(/(?:assets|app)/[^"]+)"[^>]*>`)
	scriptOf = regexp.MustCompile(`<script[^>]*?src="(/(?:assets|app)/[^"]+)"[^>]*></script>`)
	cssURLOf = regexp.MustCompile(`url\('([^']+\.woff2)'\)`)
)

func inline(s server, shell string, answers map[string]json.RawMessage,
	pictures map[string]string) (string, error) {
	var trouble error
	fail := func(err error) string {
		if trouble == nil {
			trouble = err
		}
		return ""
	}

	// Stylesheets and the icon.
	shell = linkOf.ReplaceAllStringFunc(shell, func(tag string) string {
		path := linkOf.FindStringSubmatch(tag)[1]
		body, kind, err := s.get(path)
		if err != nil {
			return fail(err)
		}

		if strings.HasSuffix(path, ".css") {
			style, err := inlineFonts(s, path, string(body))
			if err != nil {
				return fail(err)
			}
			return "<style>\n" + style + "\n</style>"
		}

		// The icon, and anything else a link carries: a data URI in place,
		// which keeps whatever `rel` and `type` the shell declared.
		if kind == "" {
			kind = "application/octet-stream"
		}
		return strings.Replace(tag, path, dataURI(kind, body), 1)
	})

	// Scripts. The module entry brings the whole graph with it.
	shell = scriptOf.ReplaceAllStringFunc(shell, func(tag string) string {
		path := scriptOf.FindStringSubmatch(tag)[1]

		if !strings.Contains(tag, `type="module"`) {
			body, err := s.text(path)
			if err != nil {
				return fail(err)
			}
			return script(body)
		}

		linked, err := link(s, path)
		if err != nil {
			return fail(err)
		}
		baked, err := bake(answers, pictures)
		if err != nil {
			return fail(err)
		}
		return script(baked) + "\n" + script(linked)
	})

	return shell, trouble
}

// A stylesheet's font files, folded into it. `fonts.css` names them relative to
// itself, which is a relative URL that means nothing once the stylesheet is a
// `<style>` element in a file somebody saved to their desktop.
func inlineFonts(s server, sheet, body string) (string, error) {
	dir := sheet[:strings.LastIndex(sheet, "/")+1]

	var trouble error
	body = cssURLOf.ReplaceAllStringFunc(body, func(match string) string {
		name := cssURLOf.FindStringSubmatch(match)[1]
		face, kind, err := s.get(dir + name)
		if err != nil {
			if trouble == nil {
				trouble = err
			}
			return match
		}
		if kind == "" {
			kind = "font/woff2"
		}
		return "url(" + dataURI(kind, face) + ")"
	})
	return body, trouble
}

func bake(answers map[string]json.RawMessage, pictures map[string]string) (string, error) {
	var b strings.Builder
	b.WriteString(`/* THE SCHOOL, AS IT WAS ON THE DAY THIS FILE WAS WRITTEN.

   Every key is the exact path api.js would have asked for. See the offline
   half of that file: opened from file:// this is where every answer comes
   from, and nothing that is not in here can be answered at all. */
window.SCHOOLING_BAKED = { answers: {`)

	for i, path := range sorted(answers) {
		key, err := json.Marshal(path)
		if err != nil {
			return "", err
		}
		if i > 0 {
			b.WriteString(",")
		}
		b.WriteString("\n" + string(key) + ": " + string(answers[path]))
	}
	b.WriteString("\n},\n")

	/* AND THE PICTURES, as data URIs, keyed by the address the interface builds
	   for them. `asset()` in api.js is the lookup. A diagram that failed to load
	   is a labelling question a student cannot answer however well they know the
	   material, so it travels in the file rather than being fetched. */
	b.WriteString("pictures: {")
	for i, path := range sorted(pictures) {
		key, err := json.Marshal(path)
		if err != nil {
			return "", err
		}
		value, err := json.Marshal(pictures[path])
		if err != nil {
			return "", err
		}
		if i > 0 {
			b.WriteString(",")
		}
		b.WriteString("\n" + string(key) + ": " + string(value))
	}
	b.WriteString("\n} };")
	return b.String(), nil
}

// The keys of a map, in order, so that building the same school twice gives the
// same file and a diff between two bundles is a difference in the school.
func sorted[V any](m map[string]V) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

/* ---------- the module graph, linked ----------

   The modules cannot stay modules. A `<script type="module">` in a file opened
   from `file://` cannot import a sibling — the specifier resolves to a file URL
   and the fetch is refused as cross-origin — and inlining each one as its own
   data: URL gives `i18n.js` TWO INSTANCES, one for `app.js` and one for
   `question.js`, so switching the language would change it in half the
   interface.

   So they are linked: each module body in its own closure, run once, in
   dependency order, with its exports handed to whoever imported it. Scope is
   preserved, identity is preserved, and nothing is renamed.

   IT UNDERSTANDS EXACTLY WHAT THIS INTERFACE WRITES and refuses the rest by
   name. A bundler that quietly mishandles `export default` is a bundler that
   ships a file which loads and then does the wrong thing on one screen. */

/*
THE THREE FORMS THE INTERFACE USES, and no others.

	Named, namespace and default — `import { a, b as c }`, `import * as ns` and
	`import thing`. Anything else is refused rather than guessed at: this is a
	linker of about a hundred lines standing in for a build step, and the day it
	silently mis-links a module is the day nobody can tell why the offline copy
	behaves differently from the site.
*/
var (
	importOf    = regexp.MustCompile(`(?m)^import\s*\{([^}]*)\}\s*from\s*'([^']+)';`)
	importAllOf = regexp.MustCompile(`(?m)^import\s*\*\s*as\s+([A-Za-z_$][\w$]*)\s*from\s*'([^']+)';`)
	importOneOf = regexp.MustCompile(`(?m)^import\s+([A-Za-z_$][\w$]*)\s*from\s*'([^']+)';`)
	/* `[\s\S]` AND NOT `.`, because an import may span lines:

	       import {
	         courseLessons,
	       } from './catalog.js';

	   is how the copied `state.js` writes one, and `.` does not match a newline.
	   With `.` here the dependency was never visited, so `catalog.js` was left
	   out of the bundle entirely and the page failed on the first module that
	   destructured it. */
	anyImportOf = regexp.MustCompile(`(?m)^import\s[\s\S]*?from\s*'([^']+)';`)
	exportOf    = regexp.MustCompile(`(?m)^export\s+(?:class|const|let|var|function|async\s+function)\s+([A-Za-z_$][\w$]*)`)
	/* A BINDING THAT CAN BE REASSIGNED AFTER ITS MODULE HAS RUN, which is the
	   one place where "hand the exports to whoever imported them" is not what a
	   browser does.

	   A real module exports a LIVE BINDING: `export let school = null` read by
	   an importer after `load()` has assigned it gives the school, because the
	   importer is looking at the variable. An object literal built when the
	   module body finished holds the value it had THEN, and `null` is what
	   every importer sees for ever.

	   This is not hypothetical, it shipped: the offline copy said
	   `codeschool.ing` in the bar where the served page said the school's name,
	   with nothing thrown and nothing logged, because `source.school` is
	   assigned by `load()` a moment after the copy was taken. These are emitted
	   as getters below, which is the live binding written out. */
	exportLetOf = regexp.MustCompile(`(?m)^export\s+(?:let|var)\s+([A-Za-z_$][\w$]*)`)
	exportDefOf = regexp.MustCompile(`(?m)^export\s+default\s+(?:async\s+)?function\s+([A-Za-z_$][\w$]*)`)
	// A default export, whatever follows it on the line. Go's regexp has no
	// negative lookahead, so the two cases are told apart by reading the rest of
	// the line rather than by the pattern: a DECLARATION keeps its name, and an
	// EXPRESSION becomes a binding. Stripping the keywords from
	// `export default { … }` would leave `{ … };` at statement position, which
	// JavaScript reads as a block — "Unexpected token '{'", which is what the
	// offline copy threw the first time the graders were linked into it.
	exportValOf = regexp.MustCompile(`(?m)^export\s+default\s+(.*)$`)
	leftOverOf  = regexp.MustCompile(`(?m)^\s*(import|export)\b.*$`)
	// `await` at the start of a line with no indentation: a statement of the
	// module itself rather than one inside a function.
	topLevelAwait = regexp.MustCompile(`(?m)^await\s`)
)

/*
Where an import points, as a name in the module map.

	IT IS RESOLVED AGAINST THE FILE THAT WROTE IT, which used to be unnecessary
	and now is not: the interface was one flat directory, and `./x.js` from
	anywhere meant the same file. It is a tree now — `./screens/course.js` from
	the entry and `../catalog.js` from inside `screens/` — and a linker keyed on
	the text of the import would give one file two entries and run it twice.
*/
// Whether what follows `export default` declares a name of its own.
func declaresAName(rest string) bool {
	rest = strings.TrimSpace(rest)
	return strings.HasPrefix(rest, "function ") ||
		strings.HasPrefix(rest, "async function ") ||
		strings.HasPrefix(rest, "class ")
}

func resolve(from, spec string) string {
	return path.Clean(path.Join(path.Dir(from), spec))
}

func link(s server, entry string) (string, error) {
	dir := entry[:strings.LastIndex(entry, "/")+1]

	sources := map[string]string{}
	exports := map[string][]string{}
	// Which of a module's exports may still change after it has run, by module
	// and then by name. See exportLetOf.
	live := map[string]map[string]bool{}
	var order []string

	var visit func(name string) error
	visit = func(name string) error {
		if _, seen := sources[name]; seen {
			return nil
		}
		body, err := s.text(dir + name)
		if err != nil {
			return err
		}

		// Depth first, so a module is emitted after everything it needs.
		sources[name] = "" // a placeholder, so a cycle is caught rather than looped
		for _, m := range anyImportOf.FindAllStringSubmatch(body, -1) {
			if err := visit(resolve(name, m[1])); err != nil {
				return err
			}
		}
		sources[name] = body

		live[name] = map[string]bool{}
		for _, m := range exportLetOf.FindAllStringSubmatch(body, -1) {
			live[name][m[1]] = true
		}

		exports[name] = nil
		for _, m := range exportOf.FindAllStringSubmatch(body, -1) {
			if live[name][m[1]] {
				// The live binding, written out: whoever holds this object
				// reads the variable each time, which is what a module does.
				exports[name] = append(exports[name],
					fmt.Sprintf("get %s() { return %s; }", m[1], m[1]))
				continue
			}
			exports[name] = append(exports[name], m[1])
		}
		for _, m := range exportDefOf.FindAllStringSubmatch(body, -1) {
			exports[name] = append(exports[name], "default: "+m[1])
		}
		for _, m := range exportValOf.FindAllStringSubmatch(body, -1) {
			if !declaresAName(m[1]) {
				exports[name] = append(exports[name], "default: __default")
			}
		}
		order = append(order, name)
		return nil
	}

	if err := visit(strings.TrimPrefix(entry, dir)); err != nil {
		return "", err
	}

	var b strings.Builder
	b.WriteString("/* Linked from the interface's modules by tools/bundle. " +
		"Each body is the file it came from, unchanged apart from its import " +
		"and export lines. */\n")
	b.WriteString("var __modules = {};\n")

	for _, name := range order {
		body := sources[name]

		/* AND THE ONE SHAPE THE GETTERS DO NOT SAVE. A named import destructures
		   — `var { school } = __modules['source.js']` — which reads the getter
		   once, at import time, and keeps the answer. The live binding is intact
		   on the module object and lost on the way out of it.

		   Refused rather than linked, because the failure is the silent one this
		   linker exists to avoid. `import * as source` reads it through the
		   object every time and is the shape that works. */
		for _, m := range importOf.FindAllStringSubmatch(body, -1) {
			dep := resolve(name, m[2])
			for _, one := range strings.Split(m[1], ",") {
				one = strings.TrimSpace(strings.SplitN(strings.TrimSpace(one), " as ", 2)[0])
				if one != "" && live[dep][one] {
					return "", fmt.Errorf("%s imports %q from %s by name, and %s exports it with "+
						"`let` or `var` — a name that may still change. Destructuring reads it "+
						"once and keeps the first answer, where a module would have followed it. "+
						"Import the module (`import * as …`) and read it through that",
						name, one, dep, dep)
				}
			}
		}

		// `import { a, b as c } from './x.js';` becomes the same names, taken
		// from the module that has already run.
		body = importOf.ReplaceAllStringFunc(body, func(statement string) string {
			m := importOf.FindStringSubmatch(statement)
			dep := resolve(name, m[2])

			var taken []string
			for _, one := range strings.Split(m[1], ",") {
				one = strings.TrimSpace(one)
				if one == "" {
					continue
				}
				if from, as, renamed := strings.Cut(one, " as "); renamed {
					taken = append(taken, strings.TrimSpace(from)+": "+strings.TrimSpace(as))
				} else {
					taken = append(taken, one)
				}
			}
			return fmt.Sprintf("var { %s } = __modules[%q];", strings.Join(taken, ", "), dep)
		})

		// `import * as ns from './x.js';` — the module object itself.
		body = importAllOf.ReplaceAllStringFunc(body, func(statement string) string {
			m := importAllOf.FindStringSubmatch(statement)
			return fmt.Sprintf("var %s = __modules[%q];", m[1], resolve(name, m[2]))
		})

		// `import thing from './x.js';` — the default export, under whatever
		// name the importer chose for it.
		body = importOneOf.ReplaceAllStringFunc(body, func(statement string) string {
			m := importOneOf.FindStringSubmatch(statement)
			return fmt.Sprintf("var %s = __modules[%q].default;", m[1], resolve(name, m[2]))
		})

		body = exportOf.ReplaceAllString(body, "$0")
		body = exportValOf.ReplaceAllStringFunc(body, func(line string) string {
			rest := exportValOf.FindStringSubmatch(line)[1]
			if declaresAName(rest) {
				return rest // `function dashboard() {` keeps its name
			}
			return "const __default = " + rest
		})
		body = regexp.MustCompile(`(?m)^export\s+`).ReplaceAllString(body, "")

		if left := leftOverOf.FindString(body); left != "" {
			return "", fmt.Errorf("%s has a line this linker does not understand:\n    %s\n"+
				"It handles `import { … } from './x.js';` and `export` on a declaration, "+
				"and refuses the rest rather than guess", name, strings.TrimSpace(left))
		}

		fmt.Fprintf(&b, "\n/* ---------- %s ---------- */\n", name)

		/* THE ENTRY IS WRAPPED IN AN ASYNC FUNCTION AND NOTHING ELSE IS.

		   A module may use `await` at its top level — the boot does, to load the
		   catalogue before the first screen renders — and that is legal in a
		   module and not inside the plain function this linker wraps each body
		   in. The entry is the one place it can be allowed: nothing imports it,
		   so nobody is handed the promise the wrapper returns.

		   Any other module that did it would have its exports replaced by a
		   promise, silently, and every importer would read `undefined` off it.
		   That is refused below rather than linked. */
		if name == order[len(order)-1] {
			fmt.Fprintf(&b, "__modules[%q] = (async function () {\n'use strict';\n%s\n})();\n",
				name, body)
			continue
		}

		if topLevelAwait.MatchString(body) {
			return "", fmt.Errorf("%s awaits at its top level, and it is imported by something "+
				"else — its exports would become a promise and every importer would read "+
				"undefined off it. Only the entry may do that", name)
		}

		fmt.Fprintf(&b, "__modules[%q] = (function () {\n'use strict';\n%s\nreturn { %s };\n})();\n",
			name, body, strings.Join(exports[name], ", "))
	}

	return b.String(), nil
}

/* ---------- odds ---------- */

func dataURI(kind string, body []byte) string {
	if at := strings.Index(kind, ";"); at >= 0 {
		kind = strings.TrimSpace(kind[:at])
	}
	return "data:" + kind + ";base64," + base64.StdEncoding.EncodeToString(body)
}

// Some JavaScript, wrapped so a browser will run it.
//
// `</script` ENDS A SCRIPT WHEREVER IT APPEARS — inside a string, inside a
// comment, inside a course's prose about writing HTML — because the parser is
// looking for the tag and not reading the language. `<\/script` is the same
// string to JavaScript and not the tag to HTML.
//
// The escape is applied HERE, to the body, and the tags are added after it.
// Doing both in one function ate the closing tag it had just written: the
// script never ended, the rest of the document was parsed as JavaScript, and
// the page died on `Unexpected token '<'` with nothing on screen.
func script(body string) string {
	return "<script>\n" + strings.ReplaceAll(body, "</script", `<\/script`) + "\n</script>"
}
