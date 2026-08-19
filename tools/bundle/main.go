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
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
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

	answers, err := gather(s)
	if err != nil {
		return 0, err
	}

	page, err := inline(s, shell, answers)
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
func gather(s server) (map[string]json.RawMessage, error) {
	answers := map[string]json.RawMessage{}

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

	if _, err := ask("/api/v1/school"); err != nil {
		return nil, err
	}

	courses, err := ask("/api/v1/courses")
	if err != nil {
		return nil, err
	}
	tracks, err := ask("/api/v1/tracks")
	if err != nil {
		return nil, err
	}

	var trackList struct {
		Tracks []struct {
			ID string `json:"id"`
		} `json:"tracks"`
	}
	if err := json.Unmarshal(tracks, &trackList); err != nil {
		return nil, fmt.Errorf("the track list: %w", err)
	}
	for _, t := range trackList.Tracks {
		if _, err := ask("/api/v1/tracks/" + url.PathEscape(t.ID)); err != nil {
			return nil, err
		}
	}

	var courseList struct {
		Courses []struct {
			ID string `json:"id"`
		} `json:"courses"`
	}
	if err := json.Unmarshal(courses, &courseList); err != nil {
		return nil, fmt.Errorf("the course list: %w", err)
	}

	for _, c := range courseList.Courses {
		one, err := ask("/api/v1/courses/" + url.PathEscape(c.ID))
		if err != nil {
			return nil, err
		}

		// A course's lessons are named on the course, so the tool asks for what
		// it was told about rather than for what it guesses exists.
		var course struct {
			Lessons []struct {
				ID string `json:"id"`
			} `json:"lessons"`
		}
		if err := json.Unmarshal(one, &course); err != nil {
			return nil, fmt.Errorf("course %s: %w", c.ID, err)
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
					return nil, fmt.Errorf("%s in %s: %w", lesson.ID, locale, err)
				}
			}
		}
	}

	return answers, nil
}

/* ---------- the page ---------- */

var (
	linkOf   = regexp.MustCompile(`<link[^>]*?href="(/assets/[^"]+)"[^>]*>`)
	scriptOf = regexp.MustCompile(`<script[^>]*?src="(/assets/[^"]+)"[^>]*></script>`)
	cssURLOf = regexp.MustCompile(`url\('([^']+\.woff2)'\)`)
)

func inline(s server, shell string, answers map[string]json.RawMessage) (string, error) {
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
		baked, err := bake(answers)
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

func bake(answers map[string]json.RawMessage) (string, error) {
	// Sorted, so that building the same school twice gives the same file and a
	// diff between two bundles is a difference in the school.
	paths := make([]string, 0, len(answers))
	for path := range answers {
		paths = append(paths, path)
	}
	sort.Strings(paths)

	var b strings.Builder
	b.WriteString(`/* THE SCHOOL, AS IT WAS ON THE DAY THIS FILE WAS WRITTEN.

   Every key is the exact path api.js would have asked for. See the offline
   half of that file: opened from file:// this is where every answer comes
   from, and nothing that is not in here can be answered at all. */
window.SCHOOLING_BAKED = { answers: {`)

	for i, path := range paths {
		key, err := json.Marshal(path)
		if err != nil {
			return "", err
		}
		if i > 0 {
			b.WriteString(",")
		}
		b.WriteString("\n" + string(key) + ": " + string(answers[path]))
	}
	b.WriteString("\n} };")
	return b.String(), nil
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

var (
	importOf   = regexp.MustCompile(`(?m)^import\s*\{([^}]*)\}\s*from\s*'([^']+)';`)
	exportOf   = regexp.MustCompile(`(?m)^export\s+(?:class|const|let|var|function)\s+([A-Za-z_$][\w$]*)`)
	leftOverOf = regexp.MustCompile(`(?m)^\s*(import|export)\b.*$`)
)

func link(s server, entry string) (string, error) {
	dir := entry[:strings.LastIndex(entry, "/")+1]

	sources := map[string]string{}
	exports := map[string][]string{}
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
		sources[name] = body

		// Depth first, so a module is emitted after everything it needs.
		sources[name] = "" // a placeholder, so a cycle is caught rather than looped
		for _, m := range importOf.FindAllStringSubmatch(body, -1) {
			dep := strings.TrimPrefix(m[2], "./")
			if err := visit(dep); err != nil {
				return err
			}
		}
		sources[name] = body

		exports[name] = nil
		for _, m := range exportOf.FindAllStringSubmatch(body, -1) {
			exports[name] = append(exports[name], m[1])
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

		// `import { a, b as c } from './x.js';` becomes the same names, taken
		// from the module that has already run.
		body = importOf.ReplaceAllStringFunc(body, func(statement string) string {
			m := importOf.FindStringSubmatch(statement)
			dep := strings.TrimPrefix(m[2], "./")

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

		body = exportOf.ReplaceAllString(body, "$0")
		body = regexp.MustCompile(`(?m)^export\s+`).ReplaceAllString(body, "")

		if left := leftOverOf.FindString(body); left != "" {
			return "", fmt.Errorf("%s has a line this linker does not understand:\n    %s\n"+
				"It handles `import { … } from './x.js';` and `export` on a declaration, "+
				"and refuses the rest rather than guess", name, strings.TrimSpace(left))
		}

		fmt.Fprintf(&b, "\n/* ---------- %s ---------- */\n", name)
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
