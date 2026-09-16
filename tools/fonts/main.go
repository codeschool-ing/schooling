// Command fonts brings the webfonts into the repository.
//
// # WHY THE FILES ARE COMMITTED AND NOT FETCHED
//
// The interface used to ask fonts.googleapis.com for three families on every
// visit. Three things were wrong with that, and only the first is the obvious
// one:
//
//  1. every student's browser told a third party which school they were
//     reading, on every page load, before anything was rendered;
//  2. the OFFLINE BUNDLE is one file opened from `file://` with no network at
//     all, so it could never have looked like the site;
//  3. the two machines that render this interface disagreed. CI reaches the
//     CDN and the development sandbox does not, so the cards were measured in
//     one set of fonts here and another there — and the graph test failed on
//     the build machine at two window sizes and on none here. That cost three
//     rounds of guessing before anybody thought to ask which fonts had loaded.
//
// A font served from the same origin removes all three at once.
//
// # WHY A TOOL AND NOT SIX BINARY FILES
//
// Committed binaries with no provenance are the kind of thing nobody dares
// touch in two years. This says exactly which families, which weights and
// which subsets, fetches them, and writes a stylesheet that matches. Changing
// a weight is an edit here and one command, rather than archaeology.
//
// IT IS RUN BY HAND. It is the only thing in this repository that reaches the
// network, nothing in CI calls it, and the files it writes are the artefact.
//
//	go run ./tools/fonts
//
// # LICENCE
//
// Space Grotesk and the IBM Plex families are all SIL Open Font License 1.1,
// which permits redistribution — including bundled into another file, which is
// what the offline bundle does with them.
package main

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

// WHAT THE INTERFACE ACTUALLY USES, and nothing else. Every weight here is one
// more file in the bundle, so this list is checked against `app.css` rather
// than copied from the old CDN link — that link asked for four weights of
// Space Grotesk where the stylesheet names two.
//
// Two of the three are VARIABLE fonts: one file covers the whole range, which
// is smaller than the two static weights it replaces and leaves 500 available
// for nothing. IBM Plex Mono is not variable on Google Fonts, and the
// interface only ever sets it at 400.
var families = []family{
	{name: "Space Grotesk", axis: "wght@300..700", file: "space-grotesk"},
	{name: "IBM Plex Sans", axis: "wght@100..700", file: "ibm-plex-sans"},
	{name: "IBM Plex Mono", axis: "wght@400", file: "ibm-plex-mono"},
}

// LATIN AND LATIN-EXT, and no more. The interface speaks five languages and
// all five are Latin — `latin` carries the accents Portuguese, Spanish, French
// and Italian need, and `latin-ext` carries the ones a course's content might
// (a name, a quoted word) without doubling anything that matters. The
// Cyrillic, Greek and Vietnamese cuts Google offers would be dead weight in
// every bundle for a school that does not exist yet.
var subsets = []string{"latin", "latin-ext"}

// ---------- and one cut Google does not offer as a subset ----------
//
// # THE LINE DID NOT REACH THE CORNER
//
// `linux-terminal` draws 76 screens in box-drawing characters — an editor's
// frame, `pstree`'s branches — and `latin` and `latin-ext` contain none of
// them: U+2500..U+257F is a block of its own and neither subset above comes
// near it. So every one of those glyphs was drawn by whatever mono font the
// reader's machine happens to have, at whatever width that font gives it,
// INSIDE a block whose every other character is ours at 0.6 em.
//
// On the machine this was written on the two widths happened to agree and the
// drawings looked right. On a Windows laptop the fallback's box glyph is about
// 92% of a cell, so a rule of 72 dashes stopped six characters short of the
// corner it was drawn to meet. That is what a reader reported, with a
// screenshot, from a released build.
//
// A monospaced block is a grid or it is nothing, and a character we do not ship
// is a cell whose width is the local machine's business.
//
// # ASKED FOR BY ITS CHARACTERS
//
// css2 has no subset to name for any of this, but it takes `text=`, cuts a face
// to exactly the characters given, and answers with the `unicode-range` it
// derived — which is the one field this tool would otherwise have to invent,
// and the field `validate-content` then reads to say whether the catalogue uses
// a character nobody ships.
//
// THE TWO BLOCKS ARE ASKED FOR WHOLE, and not narrowed to the characters the
// catalogue uses today: IBM Plex Mono has every one of the 160, they cost 4 kB
// together, and a cut fitted to today's content is one that silently stops
// covering it the day somebody draws a double line.
//
// THE ARROWS ARE LISTED ONE BY ONE, and that is the opposite decision for a
// reason. IBM Plex Mono has 22 of the 112 in U+2190..U+21FF, so asking for the
// block would come back declaring a range four times wider than the glyphs
// behind it — and a declared range that overstates its font is worse than no
// range at all here, because it is what the checker reads. Asked for by
// character, the range Google derives is the truth.
//
// `→` is not decoration: `systemctl` prints it (`Created symlink … → …`), and a
// course that quotes a command quotes what it printed.
var terminalGlyphs = func() string {
	var b strings.Builder
	for _, block := range [][2]rune{
		{0x2500, 0x257F}, // box drawing — a frame, a tree, a rule
		{0x2580, 0x259F}, // block elements — a bar chart in a terminal
	} {
		for r := block[0]; r <= block[1]; r++ {
			b.WriteRune(r)
		}
	}
	b.WriteString("←↑→↓↔↕↖↗↘↙↩↪↰↱↲↳↶↷↺↻⇄⇆")
	return b.String()
}()

// It is a subset in every way that matters here — one file, one range — except
// that Google has no word for it, so this tool supplies one.
const (
	terminalFamily = "IBM Plex Mono"
	terminalSubset = "terminal"
)

// The directory the files land in, relative to the repository root.
const out = "ui/assets/fonts"

// THE MODES ARE TIGHT AND IT COSTS NOTHING. A woff2 that every visitor
// downloads is the opposite of a secret, so 0644 was the honest intent — but
// the mode never travels: git records the executable bit and nothing else, and
// a checkout takes the mode from the reader's umask. Since these are identical
// everywhere it matters, they are the ones the linter asks every writer in this
// repository for, rather than an exception that has to be explained twice.
const (
	dirMode  = 0o750
	fileMode = 0o600
)

// A browser's user agent, because the CSS endpoint answers with woff2 for a
// modern browser and with an older format for anything it does not recognise.
// Asking as Go would fetch fonts twice the size that every browser we support
// cannot use.
const agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " +
	"(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

type family struct {
	name string // as Google Fonts spells it
	axis string // the weight axis or list, in css2's syntax
	file string // the stem of the files written here
}

// One @font-face, after parsing.
type face struct {
	family  string
	subset  string
	style   string
	weight  string
	stretch string
	unicode string
	url     string
	local   string // the filename it is written as
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "fonts:", err)
		os.Exit(1)
	}
}

func run() error {
	root, err := repositoryRoot()
	if err != nil {
		return err
	}

	sheet, err := fetchStylesheet()
	if err != nil {
		return err
	}

	faces, err := parse(sheet)
	if err != nil {
		return err
	}
	if len(faces) == 0 {
		return fmt.Errorf("the stylesheet named no face in %v — has the subset been renamed?", subsets)
	}

	box, err := fetchTerminal()
	if err != nil {
		return err
	}
	faces = append(faces, box)
	sort.Slice(faces, func(i, j int) bool { return faces[i].local < faces[j].local })

	dir := filepath.Join(root, out)
	if err := os.MkdirAll(dir, dirMode); err != nil {
		return err
	}

	total := 0
	for i := range faces {
		n, err := download(faces[i].url, filepath.Join(dir, faces[i].local))
		if err != nil {
			return fmt.Errorf("%s %s: %w", faces[i].family, faces[i].subset, err)
		}
		total += n
		fmt.Printf("%-34s %6.1f kB\n", faces[i].local, float64(n)/1000)
	}

	if err := os.WriteFile(filepath.Join(dir, "fonts.css"), stylesheet(faces), fileMode); err != nil {
		return err
	}

	fmt.Printf("\n%d files, %.1f kB, and a stylesheet, in %s\n", len(faces), float64(total)/1000, out)
	return nil
}

// The repository root, found by walking up to the go.mod. The tool is run from
// wherever somebody happens to be standing.
func repositoryRoot() (string, error) {
	here, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for dir := here; ; dir = filepath.Dir(dir) {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		} else if parent := filepath.Dir(dir); parent == dir {
			return "", fmt.Errorf("no go.mod above %s", here)
		}
	}
}

func fetchStylesheet() (string, error) {
	query := make([]string, 0, len(families))
	for _, f := range families {
		query = append(query, "family="+strings.ReplaceAll(f.name, " ", "+")+":"+f.axis)
	}
	return fetch("https://fonts.googleapis.com/css2?" + strings.Join(query, "&") + "&display=swap")
}

// One stylesheet, asked for as a browser would. Two callers now: the subsets
// above and the box-drawing cut below.
func fetch(from string) (string, error) {
	request, err := http.NewRequest(http.MethodGet, from, nil)
	if err != nil {
		return "", err
	}
	request.Header.Set("User-Agent", agent)

	client := &http.Client{Timeout: 30 * time.Second}
	answer, err := client.Do(request)
	if err != nil {
		return "", err
	}
	defer func() { _ = answer.Body.Close() }()

	if answer.StatusCode != http.StatusOK {
		return "", fmt.Errorf("the stylesheet answered %s", answer.Status)
	}
	body, err := io.ReadAll(answer.Body)
	return string(body), err
}

// The terminal cut, which comes back as ONE face and with no comment naming a
// subset, because it is not one. Everything else about the answer is the same
// shape, so the fields are read with the same expressions.
//
// THE RANGE IS COMPARED WITH WHAT WAS ASKED FOR, character by character, and
// any difference is an error rather than a thing to live with. Narrower means
// glyphs the catalogue draws with went back to the reader's machine, which is
// the defect this exists to end. Wider means the stylesheet now claims coverage
// the font does not have — and that claim is what `validate-content` reads, so
// a wider range does not fail loudly, it makes the checker lie.
func fetchTerminal() (face, error) {
	query := url.Values{}
	query.Set("family", terminalFamily+":wght@400")
	query.Set("text", terminalGlyphs)
	sheet, err := fetch("https://fonts.googleapis.com/css2?" + query.Encode())
	if err != nil {
		return face{}, fmt.Errorf("the %s cut: %w", terminalSubset, err)
	}

	f := face{subset: terminalSubset}
	for _, field := range fieldOf.FindAllStringSubmatch(sheet, -1) {
		switch name, value := field[1], strings.TrimSpace(field[2]); name {
		case "font-family":
			f.family = strings.Trim(value, `'"`)
		case "font-style":
			f.style = value
		case "font-weight":
			f.weight = value
		case "unicode-range":
			f.unicode = value
		case "src":
			if m := sourceOf.FindStringSubmatch(value); m != nil {
				f.url = m[1]
			}
		}
	}

	if f.family != terminalFamily || f.url == "" || f.weight == "" {
		return face{}, fmt.Errorf("the %s cut came back as %q, without a url or without a weight",
			terminalSubset, f.family)
	}
	if err := rangeCovers(f.unicode, terminalGlyphs); err != nil {
		return face{}, fmt.Errorf("the %s cut answered `unicode-range: %s`: %w",
			terminalSubset, f.unicode, err)
	}

	f.local = stemClean.ReplaceAllString(
		strings.ToLower("ibm-plex-mono-"+terminalSubset+"-"+f.weight), "-") + ".woff2"
	return f, nil
}

// rangeCovers reads a `unicode-range` value and says whether it is exactly the
// characters given — no more, no less.
func rangeCovers(declared, want string) error {
	in := map[rune]bool{}
	for _, part := range strings.Split(declared, ",") {
		part = strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(part), "U+"))
		part = strings.TrimPrefix(part, "u+")
		lo, hi, ok := strings.Cut(part, "-")
		if !ok {
			hi = lo
		}
		from, err := strconv.ParseInt(lo, 16, 32)
		if err != nil {
			return fmt.Errorf("%q is not a code point", lo)
		}
		to, err := strconv.ParseInt(hi, 16, 32)
		if err != nil {
			return fmt.Errorf("%q is not a code point", hi)
		}
		for r := from; r <= to; r++ {
			in[rune(r)] = true
		}
	}

	asked := map[rune]bool{}
	for _, r := range want {
		asked[r] = true
		if !in[r] {
			return fmt.Errorf("it does not cover %q (U+%04X), which was asked for", r, r)
		}
	}
	// THE LOWEST AND NOT THE FIRST ONE FOUND: a map has no order, and an error
	// message that names a different character on every run is one nobody can
	// compare with the last run or write a test against.
	extra := rune(-1)
	for r := range in {
		if !asked[r] && (extra < 0 || r < extra) {
			extra = r
		}
	}
	if extra >= 0 {
		return fmt.Errorf("it covers %q (U+%04X), which was not asked for — the stylesheet "+
			"would claim a glyph this font may not have, and that claim is what the "+
			"catalogue is checked against", extra, extra)
	}
	return nil
}

// The blocks come out of css2 as a comment naming the subset followed by the
// rule. Parsing a stylesheet with a regular expression is a bad idea in
// general and a fine one here: the shape is generated, it is the same every
// time, and anything unexpected has to fail rather than be guessed at — which
// is why every field is required.
var (
	blockOf   = regexp.MustCompile(`(?s)/\* *([a-z0-9-]+) *\*/\s*@font-face *\{(.*?)\}`)
	fieldOf   = regexp.MustCompile(`([a-z-]+): *([^;]+);`)
	sourceOf  = regexp.MustCompile(`url\(([^)]+)\)`)
	stemClean = regexp.MustCompile(`[^a-z0-9]+`)
)

func parse(sheet string) ([]face, error) {
	stems := map[string]string{}
	for _, f := range families {
		stems[f.name] = f.file
	}
	keep := map[string]bool{}
	for _, s := range subsets {
		keep[s] = true
	}

	var faces []face
	for _, block := range blockOf.FindAllStringSubmatch(sheet, -1) {
		subset, body := block[1], block[2]
		if !keep[subset] {
			continue
		}

		f := face{subset: subset}
		for _, field := range fieldOf.FindAllStringSubmatch(body, -1) {
			switch name, value := field[1], strings.TrimSpace(field[2]); name {
			case "font-family":
				f.family = strings.Trim(value, `'"`)
			case "font-style":
				f.style = value
			case "font-weight":
				f.weight = value
			case "font-stretch":
				f.stretch = value
			case "unicode-range":
				f.unicode = value
			case "src":
				if m := sourceOf.FindStringSubmatch(value); m != nil {
					f.url = m[1]
				}
			}
		}

		stem, known := stems[f.family]
		if !known {
			return nil, fmt.Errorf("the stylesheet offered %q, which nothing asked for", f.family)
		}
		if f.url == "" || f.weight == "" || f.unicode == "" {
			return nil, fmt.Errorf("%s %s arrived without a url, a weight or a range", f.family, subset)
		}

		// A static family gives one file per weight, so the weight is part of
		// the name; a variable one gives a range, and naming a file
		// `100-700` would be a filename that changes when the axis does.
		name := stem + "-" + subset
		if !strings.Contains(f.weight, " ") {
			name += "-" + f.weight
		}
		f.local = stemClean.ReplaceAllString(strings.ToLower(name), "-") + ".woff2"
		faces = append(faces, f)
	}

	// Stable order, so re-running the tool does not reshuffle the stylesheet
	// and produce a diff that says nothing.
	sort.Slice(faces, func(i, j int) bool { return faces[i].local < faces[j].local })
	return faces, nil
}

func download(from, to string) (int, error) {
	request, err := http.NewRequest(http.MethodGet, from, nil)
	if err != nil {
		return 0, err
	}
	request.Header.Set("User-Agent", agent)

	client := &http.Client{Timeout: 60 * time.Second}
	answer, err := client.Do(request)
	if err != nil {
		return 0, err
	}
	defer func() { _ = answer.Body.Close() }()

	if answer.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("answered %s", answer.Status)
	}
	body, err := io.ReadAll(answer.Body)
	if err != nil {
		return 0, err
	}
	return len(body), os.WriteFile(to, body, fileMode)
}

func stylesheet(faces []face) []byte {
	var b strings.Builder
	b.WriteString(`/* ==========================================================================
   Schooling — the type, served from here

   GENERATED BY tools/fonts. Do not edit: run ` + "`go run ./tools/fonts`" + ` instead.

   These faces used to come from fonts.googleapis.com on every page load. They
   are here because a student should not have to tell a third party which
   school they are reading, because the offline bundle has no network to fetch
   them over, and because two machines rendering different fonts measure
   different cards — which is a graph test that fails on one of them and
   nowhere else.

   Space Grotesk and IBM Plex are SIL Open Font License 1.1.
   ========================================================================== */

`)
	for i, f := range faces {
		if i > 0 {
			b.WriteString("\n")
		}
		fmt.Fprintf(&b, "@font-face {\n")
		fmt.Fprintf(&b, "  font-family: '%s';\n", f.family)
		fmt.Fprintf(&b, "  font-style: %s;\n", f.style)
		fmt.Fprintf(&b, "  font-weight: %s;\n", f.weight)
		if f.stretch != "" {
			fmt.Fprintf(&b, "  font-stretch: %s;\n", f.stretch)
		}
		// `swap` and not `block`: the text is readable from the first paint,
		// and the graph redraws itself when the faces land.
		fmt.Fprintf(&b, "  font-display: swap;\n")
		fmt.Fprintf(&b, "  src: url('%s') format('woff2');\n", f.local)
		fmt.Fprintf(&b, "  unicode-range: %s;\n", f.unicode)
		fmt.Fprintf(&b, "}\n")
	}
	return []byte(b.String())
}
