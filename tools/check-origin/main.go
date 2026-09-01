// Command check-origin holds this platform to P-03: nothing the browser fetches
// on its own comes from anywhere but the host that served the page.
//
// # THE FAILURE IT EXISTS TO CATCH
//
// Somebody adds `<link href="https://fonts.googleapis.com/…">`, or an icon from
// a CDN, or an analytics snippet. Everything works — better, usually, because a
// CDN is fast. And every student's browser now tells a third party which school
// they are reading, on every page load, with the `Referer` naming the lesson.
//
// Nothing fails. There is no error, no warning and nothing in a diff that looks
// like a decision: it looks like a font. That is the whole class of defect here,
// and until this tool there was no check for it at all — P-03 is cited in eight
// files as the reason for a design choice and was upheld by nobody.
//
// # A SUBRESOURCE IS NOT A LINK
//
// `<a href="https://…">` is a person choosing to go somewhere, and that choice
// is theirs to make. A `<script src>`, a stylesheet, an `<img>`, an `@import`, a
// `url()` in CSS, an `<iframe>`, a `fetch()` — those are the browser being told
// to ask a third party, by us, before anybody has chosen anything.
//
// So this reads what the browser fetches WITHOUT being asked, and leaves
// navigation alone. Getting that line wrong in the strict direction would fail
// on every external link in the terms and the privacy policy, which are the two
// pages most likely to have them.
//
// # AND AN EXCEPTION IS DECLARED, WITH ITS REASON
//
// There is one, and it is real: a student who clicks play on a video is asking
// for a YouTube player, and the video is on YouTube. Refusing that would not
// protect them, it would remove the video. So the player is `allowed` below,
// named, with the sentence saying why — and anything that is NOT in that list
// fails. An exception nobody wrote down is the thing this tool is for; an
// exception written down is a decision somebody can argue with later.
//
//	check-origin [directory ...]     (default: every interface this repository serves)
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// Where the interfaces are. Named here rather than discovered, so that a new one
// is a line in this file — a tree nobody added is a tree nobody checks, and it
// would pass in silence.
var interfaces = []string{"ui", "internal/console/ui"}

/*
allowed is every off-origin fetch this platform makes on purpose.

	THE HOST AND THE REASON, because a bare host is a rule with its argument
	deleted. Whoever reads this next has to be able to disagree with it, and
	they cannot disagree with `www.youtube-nocookie.com`.
*/
var allowed = map[string]string{
	"www.youtube-nocookie.com": "the player, and ONLY once a student has clicked play. " +
		"The video is on YouTube; refusing this would remove the video rather than " +
		"protect anybody. The `-nocookie` host is the one that does not set one until " +
		"playback, and the frame is built in a click handler rather than rendered with " +
		"the page — see `playsOnClick` in ui/app/screens/common.js",
}

/*
These are where a subresource's address goes — what a browser would ask for on
its own, as opposed to what a person clicks.

	IT IS A PATTERN AND NOT A PARSER, which is a smaller claim than it looks.
	The question is not "is this valid markup" but "does an absolute URL appear
	where a subresource goes", and the attributes that take one are a closed
	list. A pattern that is too eager fails loudly on something harmless; one
	that is too lax is the silence this tool exists to break, so the list leans
	long.

	`href` IS ONLY HERE FOR `rel="stylesheet"` and its friends, and it is the
	one that cannot be decided by the attribute alone — `<a href>` is a
	navigation. So `href` is matched only where the tag is a `<link>`, which is
	what the first pattern does, and every plain `<a>` is left alone.
*/
var (
	subresource = regexp.MustCompile(
		`(?i)\b(?:src|srcset|data-src|poster|formaction|ping)\s*=\s*["']([^"']+)["']`)
	linkHref = regexp.MustCompile(
		`(?i)<link\b[^>]*\bhref\s*=\s*["']([^"']+)["']`)
	cssURL    = regexp.MustCompile(`(?i)\burl\(\s*["']?([^)"']+)`)
	cssImport = regexp.MustCompile(`(?i)@import\s+["']([^"']+)["']`)
	fetches   = regexp.MustCompile(
		`(?i)\b(?:fetch|importScripts|EventSource|WebSocket)\s*\(\s*["']([^"']+)["']`)
)

// offOrigin is a URL a browser would send somewhere else: an absolute one, or a
// protocol-relative `//host/…`, which is the form people forget is absolute.
var offOrigin = regexp.MustCompile(`(?i)^\s*(?:[a-z][a-z0-9+.-]*:)?//`)

// hostOf is what would receive the request. A `data:` or `blob:` URL goes
// nowhere and is not one of these; they never match `offOrigin` in the first
// place, because neither carries `//`.
var hostOf = regexp.MustCompile(`(?i)^(?:[a-z][a-z0-9+.-]*:)?//([^/?#]+)`)

func main() {
	where := interfaces
	if len(os.Args) > 1 {
		where = os.Args[1:]
	}

	problems, checked, err := check(where)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if len(problems) == 0 {
		fmt.Printf("%d files, and nothing the browser fetches leaves the origin\n", checked)
		return
	}

	// Everything, then fail — a checker that stops at the first one turns a
	// mistake made twice into two runs.
	for _, p := range problems {
		fmt.Fprintln(os.Stderr, p)
	}
	fmt.Fprintf(os.Stderr, "\n%d off-origin fetches in %d files. If one of them is deliberate, "+
		"say so in `allowed` in tools/check-origin, with the reason — an exception nobody "+
		"wrote down is what this tool is for\n", len(problems), checked)
	os.Exit(1)
}

func check(where []string) (problems []string, checked int, err error) {
	var files []string
	for _, dir := range where {
		err := filepath.WalkDir(dir, func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			switch strings.ToLower(filepath.Ext(path)) {
			case ".html", ".css", ".js":
				files = append(files, path)
			}
			return nil
		})
		if err != nil {
			return nil, 0, err
		}
	}
	sort.Strings(files)

	if len(files) == 0 {
		return nil, 0, fmt.Errorf("check-origin: nothing to read in %s — either the "+
			"directories are wrong or this tool has stopped finding what it checks",
			strings.Join(where, ", "))
	}

	for _, path := range files {
		body, err := os.ReadFile(path) //nolint:gosec // a path from this tool's own walk
		if err != nil {
			return nil, 0, err
		}
		checked++
		for _, found := range fetchesIn(string(body)) {
			host := hostOf.FindStringSubmatch(found.url)
			if host == nil {
				continue
			}
			if _, ok := allowed[strings.ToLower(host[1])]; ok {
				continue
			}
			problems = append(problems, fmt.Sprintf(
				"%s:%d: the browser would fetch %s from %s without anybody asking it to — "+
					"which tells them the school, the page and the reader (P-03)",
				path, found.line, found.url, host[1]))
		}
	}
	return problems, checked, nil
}

type fetch struct {
	url  string
	line int
}

/*
fetchesIn is every off-origin subresource a source asks for.

	THE COMMENTS ARE NOT STRIPPED, which is the opposite of what `check-interface`
	decided about its own scan, and the difference is worth stating because the
	argument there applies here too. That tool reads comments out because every
	file where somebody has just learnt its rule writes the rule's example, and
	the example is indistinguishable from the thing. The same is true here: this
	paragraph cannot spell a full address without failing its own tool, and
	neither can the file that explains why a thumbnail was removed.

	It is still the right way round. A commented-out `script src` pointing at a
	CDN is one keystroke from being live, and it got into the tree without
	anybody deciding — which is exactly the arrival this tool is here to notice.
	The price is that prose about this rule names a host and leaves the scheme
	off, as the comment in `ui/app/screens/common.js` does; that costs a
	sentence, and the alternative costs the silence.

	It also costs no lexer. `check-interface` needs a real one, because a `/` in
	JavaScript is a comment, a regular expression or a division and only the
	tokens before it say which. Sharing that would mean a Go package for tool
	helpers, which does not exist and should not be invented for one function.
*/
func fetchesIn(source string) []fetch {
	var out []fetch
	for _, pattern := range []*regexp.Regexp{
		subresource, linkHref, cssURL, cssImport, fetches,
	} {
		for _, m := range pattern.FindAllStringSubmatchIndex(source, -1) {
			url := source[m[2]:m[3]]
			if !offOrigin.MatchString(url) {
				continue
			}
			out = append(out, fetch{
				url:  strings.TrimSpace(url),
				line: strings.Count(source[:m[0]], "\n") + 1,
			})
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].line < out[j].line })
	return out
}
