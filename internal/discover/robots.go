package discover

import (
	"encoding/xml"
	"net/http"
	"strconv"
	"strings"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
`robots.txt`, which a school did not have and therefore did not need to be read
to be obeyed.

	ITS ABSENCE IS NOT NEUTRAL. With no file, a crawler is free to spend this
	school's crawl budget on `/api/v1/…` — hundreds of JSON answers that render
	as nothing, that duplicate the pages below, and that cost a database read
	each. The file says where the pages are and where they are not.

	`Sitemap:` IS ABSOLUTE AND THAT IS NOT THIS FILE'S CHOICE. The sitemap
	protocol requires it, and it is the one line here that has to name a host —
	which is why it names the host the request arrived at, and no other.
*/
func (h *Handler) robots(w http.ResponseWriter, r *http.Request) {
	body := strings.Join([]string{
		"User-agent: *",
		"Allow: /",
		"",
		"# JSON, and the same catalogue the pages below carry as prose.",
		"Disallow: /api/",
		"",
		"# A link somebody was handed, one session long. Nothing to index and",
		"# not ours to hand around.",
		"Disallow: /view",
		"",
		"Sitemap: " + origin(r) + "/sitemap.xml",
		"",
	}, "\n")

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	// Short, because it names the host and a school may be given another one.
	w.Header().Set("Cache-Control", "public, max-age=3600")
	_, _ = w.Write([]byte(body))
}

/*
The sitemap: every course this school publishes, in both languages, each naming
the other.

	THE ALTERNATES GO IN HERE AS WELL AS IN THE PAGES, which is the half that is
	usually left out. A crawler that reaches one language from a link learns
	about the other without having to fetch it first, and the two statements
	agreeing is what makes either believed.

	IT IS BUILT PER REQUEST AND NOT CACHED ON DISK, because there is no disk to
	cache it on that would be right for every school: this is one binary serving
	as many schools as there are hosts, and the answer differs per host and per
	what that school has published today.
*/
type urlset struct {
	XMLName xml.Name  `xml:"urlset"`
	NS      string    `xml:"xmlns,attr"`
	XHTML   string    `xml:"xmlns:xhtml,attr"`
	URLs    []sitemap `xml:"url"`
}

type sitemap struct {
	Loc string `xml:"loc"`

	/* `lastmod` IS THE CATALOGUE'S, NOT EACH PAGE'S, and saying so is better
	   than a date per page that nobody records. Nothing in the mirror carries a
	   timestamp per course — a load rewrites every row in one transaction, so
	   what there IS to know is when the catalogue was last published, and that
	   is the same answer for every page built from it.

	   A crawler uses it to decide what to re-read. One honest date it can
	   believe is worth more than a page-shaped date that is really the same
	   date wearing a disguise, and far more than `time.Now()`, which says
	   everything changed on every crawl and teaches it to ignore the field. */
	LastMod    string      `xml:"lastmod,omitempty"`
	Alternates []alternate `xml:"xhtml:link"`
}

type alternate struct {
	Rel      string `xml:"rel,attr"`
	HrefLang string `xml:"hreflang,attr"`
	Href     string `xml:"href,attr"`
}

func (h *Handler) sitemap(w http.ResponseWriter, r *http.Request) {
	at := origin(r)

	// The English listing decides what is in the sitemap. Both languages carry
	// the same courses — a translation is columns on a row, not a row — so
	// reading the other would be a second query answering the same question.
	courses, err := h.list(r.Context(), "en")
	if err != nil {
		web.LoggerFrom(r.Context()).Error("the sitemap could not be built", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	alternatesOf := func(path string) []alternate {
		out := make([]alternate, 0, len(languages)+1)
		for _, l := range languages {
			out = append(out, alternate{Rel: "alternate", HrefLang: l.tag, Href: at + l.at + path})
		}
		return append(out, alternate{Rel: "alternate", HrefLang: "x-default", Href: at + path})
	}

	set := urlset{
		NS:    "http://www.sitemaps.org/schemas/sitemap/0.9",
		XHTML: "http://www.w3.org/1999/xhtml",
	}
	when := h.published(r.Context())
	tracks, err := h.paths(r.Context(), "en")
	if err != nil {
		web.LoggerFrom(r.Context()).Error("the sitemap could not be built", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the catalogue cannot be read just now")
		return
	}

	// The school's own address first. It is the interface rather than one of
	// these pages, and it is still the page every other one is reached from.
	set.URLs = append(set.URLs, sitemap{Loc: at + "/"})
	for _, path := range []string{"/courses", "/tracks"} {
		for _, l := range languages {
			set.URLs = append(set.URLs, sitemap{Loc: at + l.at + path, Alternates: alternatesOf(path)})
		}
	}
	for _, tr := range tracks {
		path := "/track/" + tr.Slug
		for _, l := range languages {
			set.URLs = append(set.URLs, sitemap{Loc: at + l.at + path, Alternates: alternatesOf(path)})
		}
	}
	for _, c := range courses {
		paths := []string{"/course/" + c.Slug}
		// A FREE COURSE'S LESSONS HAVE PAGES AND ARE LISTED; a course that is
		// sold has none, so there is nothing here to list. The listing is where
		// that is known, which is why the sitemap reads it and does not ask
		// again per course.
		if c.Free {
			for _, l := range c.Lessons {
				paths = append(paths, "/course/"+c.Slug+"/lesson/"+strconv.Itoa(l.At))
			}
		}
		for _, path := range paths {
			for _, l := range languages {
				set.URLs = append(set.URLs, sitemap{Loc: at + l.at + path, Alternates: alternatesOf(path)})
			}
		}
	}

	w.Header().Set("Content-Type", "application/xml; charset=utf-8")
	w.Header().Set("Cache-Control", "public, max-age=3600")
	for i := range set.URLs {
		set.URLs[i].LastMod = when
	}

	_, _ = w.Write([]byte(xml.Header))
	enc := xml.NewEncoder(w)
	enc.Indent("", "  ")
	if err := enc.Encode(set); err != nil {
		// The status is already sent; nothing left but to say so.
		web.LoggerFrom(r.Context()).Error("writing the sitemap", "error", err)
	}
}

/*
And the two addresses that are not for finding.

	`my.` is one student's own place and the console is staff software. Both
	already carry `<meta name="robots" content="noindex, nofollow">`, and that
	tag only works once the page has been FETCHED — it answers "may this be
	listed", not "may this be crawled". This answers the second, which is the
	one that keeps a crawler off a login screen it was never going to index.

	No `Sitemap:` line, because there is nothing here to offer.
*/
func Disallow() http.Handler {
	return plainly("User-agent: *\nDisallow: /\n")
}

/*
And the one that does want to be found and has nothing to offer yet.

	The platform's front door already says `index, follow` in its head. It has
	no sitemap because it has no second page — see `ui/front/app/main.js`, which
	says what is on it and why that is deliberate — so this is the short form:
	nothing is disallowed, and there is nothing to point at.

	It matters anyway. A missing `robots.txt` is a 404 on the most public
	address this platform has, on every crawl, and "not found" is not the same
	answer as "help yourself".
*/
func Allow() http.Handler {
	return plainly("User-agent: *\nAllow: /\n")
}

func plainly(body string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.Header().Set("Cache-Control", "public, max-age=86400")
		_, _ = w.Write([]byte(body))
	})
}
