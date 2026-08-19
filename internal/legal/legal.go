// Package legal serves the two documents a platform that takes money and holds
// personal data has to publish: the terms of use and the privacy policy.
//
// # WHY THEY ARE FILES AND NOT ROWS
//
// They are content we wrote, in the repository, reviewed in a pull request like
// everything else. A legal document held in a database is one somebody can
// change without a diff — and the entire value of a published policy is that
// what it said on the day somebody agreed to it can be established afterwards.
// Git is a better archive for that than a table with an `updated_at`.
//
// They are also not part of the catalogue: the catalogue is a school's material
// and is mirrored from `content/`, while these are the platform's and are the
// same in every school.
//
// # WHY THE PRIVACY POLICY NAMES ITS TABLES
//
// Each document carries a `covers:` line in its front matter listing the tables
// it accounts for, and a test compares that against `privacy.Registry`. A
// policy is a promise about what is held, and the way it goes wrong is not that
// somebody lies — it is that a table is added and the document is not opened.
// Silent, dated, and exactly the kind of failure the privacy registry itself
// exists to prevent one layer down.
//
// The list is in the front matter rather than in the prose because a policy is
// read by people, and a person does not want a table name. The check is exact
// and the reading is human.
package legal

import (
	"embed"
	"errors"
	"fmt"
	"io/fs"
	"path"
	"regexp"
	"sort"
	"strings"
)

//go:embed documents/*.md
var documents embed.FS

// ErrNoSuchDocument is a name this does not publish.
var ErrNoSuchDocument = errors.New("legal: there is no such document")

// The documents. A closed list, because a route that served any file name from
// an embedded directory is a route that serves whatever lands in it.
const (
	Terms   = "terms"
	Privacy = "privacy"
)

// Names is every document, in the order they are linked.
func Names() []string { return []string{Terms, Privacy} }

// Document is one of them, in one language.
type Document struct {
	Name   string `json:"document"`
	Locale string `json:"locale"`
	Title  string `json:"title"`

	// Effective is the day this version took effect, as YYYY-MM-DD. It is in
	// the file rather than derived from the commit date: a typo fix is not a new
	// policy, and a date that moved because somebody corrected a comma would
	// make every real change indistinguishable from noise.
	Effective string `json:"effective"`

	// Covers is the tables this document accounts for. It is not sent to a
	// browser — see MarshalJSON's absence and the field tag.
	Covers []string `json:"-"`

	// Body is Markdown, rendered by the client with the same renderer a lesson
	// uses. One renderer, so a heading looks the same in a policy as in a
	// lesson and there is one place for it to be wrong.
	Body string `json:"body"`
}

/* ---------- what is not filled in yet ---------- */

// unfilled finds `{{a.token}}` in a document.
//
// # WHY A TOKEN IN THE FILE AND NOT A SETTING
//
// The company's name, its registration number and its address are facts with a
// right answer that simply is not known here yet. Only something WITHOUT a right
// answer becomes a parameter (K-13) — a setting for this would be a knob whose
// only correct position is one value, configurable in an environment where
// getting it wrong means publishing a policy attributed to the wrong company.
//
// So it stays in the document, as a token nobody could mistake for prose.
// Filling it in is a search and replace across four files, and the test below
// is what stops that happening in three of them.
var unfilled = regexp.MustCompile(`\{\{[a-z0-9._-]+\}\}`)

// Placeholders answers the tokens in a document that nobody has filled in yet,
// sorted and without repeats.
func Placeholders(body string) []string {
	seen := map[string]bool{}
	for _, token := range unfilled.FindAllString(body, -1) {
		seen[token] = true
	}

	out := make([]string, 0, len(seen))
	for token := range seen {
		out = append(out, token)
	}
	sort.Strings(out)
	return out
}

// Fallback is the language a document is served in when it has no version in
// the one that was asked for. English is the source language (N-06), so it is
// the one that always exists — and answering nothing at all would mean a policy
// that is unpublished for whoever set an unusual browser.
const Fallback = "en"

// Read answers one document. An unknown locale falls back to English rather
// than failing: a missing translation is a document in the wrong language,
// which is a problem, and a blank page is a worse one.
func Read(name, locale string) (Document, error) {
	if name != Terms && name != Privacy {
		return Document{}, fmt.Errorf("%w: %q", ErrNoSuchDocument, name)
	}

	body, err := documents.ReadFile(file(name, locale))
	if err != nil {
		if body, err = documents.ReadFile(file(name, Fallback)); err != nil {
			return Document{}, fmt.Errorf("%w: %q in %q", ErrNoSuchDocument, name, locale)
		}
		locale = Fallback
	}

	doc, err := parse(string(body))
	if err != nil {
		return Document{}, fmt.Errorf("legal: %s in %s: %w", name, locale, err)
	}
	doc.Name, doc.Locale = name, locale
	return doc, nil
}

// file is the path of one version. The locale is not interpolated into a path
// that could escape the directory: `path.Base` and the closed list of names
// above are what keep a request for `../../etc/passwd` a miss rather than a
// read.
func file(name, locale string) string {
	return path.Join("documents", path.Base(name)+"."+path.Base(locale)+".md")
}

// Locales answers which languages a document exists in, which is what the
// checker uses to say a translation is missing rather than assume it is.
func Locales(name string) []string {
	entries, err := fs.Glob(documents, "documents/"+path.Base(name)+".*.md")
	if err != nil {
		return nil
	}

	var out []string
	for _, entry := range entries {
		base := strings.TrimSuffix(path.Base(entry), ".md")
		if _, locale, found := strings.Cut(base, "."); found {
			out = append(out, locale)
		}
	}
	sort.Strings(out)
	return out
}

/* ---------- the front matter ---------- */

// parse reads the header and the body.
//
// The format is deliberately tiny — `key: value` lines between two `---` rules
// — because a document with a YAML parser behind it is a document that can fail
// to load for a reason nobody reading it can see. Anything it does not
// understand is an error rather than a skipped line: a `covers:` that was
// silently ignored would take the check with it.
func parse(text string) (Document, error) {
	rest, found := strings.CutPrefix(strings.TrimSpace(text), "---\n")
	if !found {
		return Document{}, errors.New("it has no header")
	}
	header, body, found := strings.Cut(rest, "\n---\n")
	if !found {
		return Document{}, errors.New("its header is not closed")
	}

	var doc Document
	for line := range strings.SplitSeq(header, "\n") {
		if strings.TrimSpace(line) == "" {
			continue
		}
		key, value, found := strings.Cut(line, ":")
		if !found {
			return Document{}, fmt.Errorf("the header line %q is not `key: value`", line)
		}
		key, value = strings.TrimSpace(key), strings.TrimSpace(value)

		switch key {
		case "title":
			doc.Title = value
		case "effective":
			doc.Effective = value
		case "covers":
			for _, table := range strings.Split(value, ",") {
				if table = strings.TrimSpace(table); table != "" {
					doc.Covers = append(doc.Covers, table)
				}
			}
		default:
			return Document{}, fmt.Errorf("the header key %q is not one this knows", key)
		}
	}

	if doc.Title == "" {
		return Document{}, errors.New("it has no title")
	}
	if doc.Effective == "" {
		return Document{}, errors.New("it says no date it took effect")
	}

	doc.Body = strings.TrimSpace(body)
	if doc.Body == "" {
		return Document{}, errors.New("it has a header and nothing else")
	}
	return doc, nil
}
