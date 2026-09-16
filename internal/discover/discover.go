// Package discover serves the pages a search engine can read.
//
// # WHY THERE WERE NONE
//
// The study interface is a fragment router — `#/course/linux-terminal`, not
// `/course/linux-terminal` — for a reason `ui`'s own comment gives: the offline
// bundle is a roadmap item and a single file opened from `file://` has no server
// to fall back on. Nothing about that is wrong, and it has one consequence
// nobody chose: EVERYTHING AFTER A `#` IS NEVER SENT TO THE SERVER, and is not
// an address to any crawler that has ever existed. A school's whole catalogue —
// every course, every lesson title — sat behind one address that says nothing
// but the name of the school.
//
// So this is a second, small, server-rendered surface beside it. Not a rewrite
// of the router: the interface goes on being the interface, and these are the
// pages that can be linked to, shared and found.
//
// # WHAT IS PUBLIC IS ALREADY DECIDED, AND NOT BY THIS PACKAGE
//
// `catalog`'s store says it plainly, where it builds a locked course: "what is
// behind the paywall is the MATERIAL; what a course contains is the shop
// window, and hiding it would be asking somebody to buy a title." A course
// nobody has paid for still answers with its name, its summary, what it needs
// first, its syllabus, its topics and the titles of its lessons. That is the
// page this package writes. The prose is not in it, for the same reason it is
// not in the API's answer.
//
// A DRAFT IS NOT IN IT EITHER, and that is not this package's judgement to
// make: the store answers a draft exactly as it answers a course that does not
// exist, so one cannot be reached here and cannot be listed here.
//
// # EVERY ADDRESS IS DERIVED, AND NONE IS WRITTEN DOWN
//
// A school is a subdomain, so there is no such thing as "the site's address":
// there are as many as there are schools, and the platform's own domain is a
// setting that will change. A canonical that names a host is a canonical that
// will be wrong — it asks a search engine to index somewhere else, which is the
// one failure worse than having no canonical at all.
//
// So the origin is the request's: its scheme, and the host it arrived at. That
// host is not taken on trust. `tenant.Resolve` runs in front of these routes
// and answers 404 for a host no school claims, so by the time a handler here
// runs, the host is one this platform serves — which is the check a
// hand-written allowlist would have been.
//
// # TWO LANGUAGES, BECAUSE THERE ARE TWO
//
// The interface offers five. The CONTENT exists in two: every course and every
// lesson is authored in English and translated to Portuguese, and there is no
// Spanish, French or Italian of either. An alternate for a language the content
// is not in would point a Spanish reader at an English page labelled Spanish,
// which is worse than not claiming it.
package discover

import (
	"context"
	"net/http"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Course is what a page is written from. It is this package's own shape and not
// the catalogue's, because a module may not import another module — see
// `internal/architecture_test.go`. `cmd/api` fills it.
type Course struct {
	Slug          string
	Name          string
	Summary       string
	Prerequisites string
	Level         string
	Hours         int
	Syllabus      []string

	/* THE LESSONS ARE THE COURSE'S `topics`, WHICH IS WHERE THE TITLES ARE
	   TRANSLATED. A course declares a list of topics, each with the ID OF A
	   LESSON and a title, and that list is what the interface draws a course
	   from — `ui/app/catalog.js`'s `courseLessons` maps `topic.title` straight
	   onto a lesson. `catalog_lessons.title` exists too and is the same English
	   string with no locale beside it, so reading THAT is how a Portuguese page
	   ends up with an English heading. This page reads the topic.

	   A topic whose lesson is not written yet has no `At`: 120 of the 122
	   courses are a catalogue entry with its contents planned and nothing
	   authored, and their contents are still worth reading. */
	Lessons []Lesson

	// Free is whether a stranger may read this course's lessons. It is the
	// store's answer and not a rule this package keeps: the first course of a
	// track is open to everybody, and the rest is a purchase.
	Free bool
}

// Lesson is one lesson of a course. `At` is its position among the lessons that
// are WRITTEN, one-based, and is how it is addressed — see `lesson.go`. Zero
// means the course declares this lesson and nobody has written it.
type Lesson struct {
	At       int
	Title    string
	Sections []Section
}

// Section is one step of a lesson: its title and, when the lesson may be read,
// its prose reduced to text. See `prose.go` for why it is text.
type Section struct {
	Title string
	Prose []Prose
}

// The catalogue, as this package needs to read it. Both take a locale and are
// expected to fall back to the source language field by field, which is what
// the store already does.
type (
	// List is every course this school publishes, in one language. Drafts are
	// not in it.
	List func(ctx context.Context, locale string) ([]Course, error)

	// One is a single course by slug, or ErrNoCourse.
	One func(ctx context.Context, slug, locale string) (*Course, error)

	// Reading is one lesson of a course, with its prose, or ErrNoLesson — which
	// is also the answer for a lesson nobody may read without paying. That the
	// two are one answer is deliberate: a page that said "this exists and you
	// may not see it" would be a page, and there is nothing here to show.
	Reading func(ctx context.Context, slug string, at int, locale string) (*Lesson, error)

	// Brand is the school this request arrived at: its name, for the pages to
	// say whose they are, and its accent, which is the ground a shared link's
	// picture is drawn on.
	Brand func(ctx context.Context) (name, accent string, ok bool)

	// Published is when this school's catalogue was last loaded, as RFC 3339,
	// or "" when it has not been loaded since the column existed. It is the
	// sitemap's `lastmod` and there is nothing finer to be had: the mirror is
	// rewritten whole, so no course has an age of its own.
	Published func(ctx context.Context) string
)

// ErrNoCourse is what One returns for a slug this school does not publish,
// including one that is only a draft.
type noCourse struct{}

func (noCourse) Error() string { return "discover: no such course in this school" }

// ErrNoCourse is the sentinel; compare with errors.Is.
var ErrNoCourse error = noCourse{}

type noLesson struct{}

func (noLesson) Error() string { return "discover: no such lesson to read here" }

// ErrNoLesson is a lesson this school does not have AND one nobody may read
// without paying. One answer for both: see `Reading`.
var ErrNoLesson error = noLesson{}

// The languages the CONTENT exists in, in the order a page lists them. `tag` is
// what goes in `hreflang` and `<html lang>`; `at` is the path a page of that
// language is served at, and English has none because English is the source and
// lives at the root of the address.
var languages = []struct {
	code, tag, at, label string
}{
	{code: "en", tag: "en", at: "", label: "English"},
	{code: "pt", tag: "pt-BR", at: "/pt", label: "Português"},
}

// Where a language sits in the list, which is how a page finds its own tag and
// its own path prefix. There is no "not found": a route exists per language, so
// a code that reached a handler is one of these.
func languageAt(code string) int {
	for i, l := range languages {
		if l.code == code {
			return i
		}
	}
	return 0
}

type Handler struct {
	list      List
	one       One
	reading   Reading
	paths     Paths
	route     Route
	brand     Brand
	published Published

	// indexable is whether this deployment may be listed by a search engine.
	// It reaches only `robots.txt`, which offers a sitemap or explains its
	// absence; refusing to be listed is `web.NoIndex`'s job and covers every
	// answer this process writes, not only the pages here.
	indexable bool
}

func NewHandler(list List, one One, reading Reading, paths Paths, route Route,
	brand Brand, published Published, indexable bool) *Handler {
	return &Handler{list: list, one: one, reading: reading, paths: paths,
		route: route, brand: brand, published: published, indexable: indexable}
}

// school is the name alone, which is all a page needs.
func (h *Handler) school(ctx context.Context) (string, bool) {
	name, _, ok := h.brand(ctx)
	return name, ok
}

/*
The routes, and why they are named rather than a catch-all.

	`ui` serves the interface at `/` and answers 404 for anything it does not
	know, deliberately — "instead of the shell rendering itself and a student
	staring at an empty screen wondering what they typed wrong". These are more
	specific patterns than `/`, so they win on this mux without taking that
	away.

	`GET /{lang}/course/{slug}` would match `/anything/course/x`, so `lang` is
	checked against the list above and anything else is a 404. A pattern that
	broad is worth the check; the alternative is one route per language, which
	is the same list written twice.
*/
/*
The routes, one per language rather than one with a language in it.

	`GET /{lang}/courses` was the obvious shape and it is the wrong one: it
	matches `/course/courses`, so does `GET /course/{slug}`, and neither is more
	specific — which `http.ServeMux` answers by PANICKING as it registers, so the
	server would not have started at all. Caught by a test, which is the only
	reason it was caught before a deploy.

	The languages are a closed list, so the paths are too. That also removes a
	check: a language nothing is written in has no route, and the mux answers
	404 without this package having to recognise the difference.

	These are more specific patterns than `ui`'s `/`, so they win on that mux
	without taking away its deliberate 404 for everything else.
*/
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /robots.txt", h.robots)
	mux.HandleFunc("GET /sitemap.xml", h.sitemap)
	for _, l := range languages {
		code := l.code
		mux.HandleFunc("GET "+l.at+"/courses", h.inLanguage(code, h.everyCourse))
		mux.HandleFunc("GET "+l.at+"/tracks", h.inLanguage(code, h.everyTrack))
		mux.HandleFunc("GET "+l.at+"/course/{slug}", h.inLanguage(code, h.course))
		mux.HandleFunc("GET "+l.at+"/course/{slug}/lesson/{at}", h.inLanguage(code, h.lesson))
		mux.HandleFunc("GET "+l.at+"/track/{slug}", h.inLanguage(code, h.track))
		mux.HandleFunc("GET "+l.at+"/card/{what}/{slug}", h.inLanguage(code, h.card))
	}
}

// Patterns is every address this package answers, and it is exported because
// `cmd/api` forwards exactly these paths to a mux of its own, through
// `tenant.Resolve`. Writing the list a second time by hand is what it looks
// like: two lesson routes were once added here and not there, and the sitemap
// advertised pages that answered 404.
var Patterns = patterns()

func patterns() []string {
	out := []string{"GET /robots.txt", "GET /sitemap.xml"}
	for _, l := range languages {
		out = append(out,
			"GET "+l.at+"/courses",
			"GET "+l.at+"/tracks",
			"GET "+l.at+"/course/{slug}",
			"GET "+l.at+"/course/{slug}/lesson/{at}",
			"GET "+l.at+"/track/{slug}",
			"GET "+l.at+"/card/{what}/{slug}",
		)
	}
	return out
}

// inLanguage hands a page the language its route is for. The alternative was
// reading a path segment and validating it, which is the same list of languages
// written twice and checked once.
func (h *Handler) inLanguage(code string, page func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) { page(w, r, code) }
}

// origin is where this request arrived, which is the only address this process
// may claim to be at. See the package comment.
func origin(r *http.Request) string {
	return web.SchemeOf(r) + "://" + r.Host
}
