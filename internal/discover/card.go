package discover

import (
	"bytes"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"math"
	"net/http"
	"strconv"
	"strings"
	"sync"

	"golang.org/x/image/font"
	"golang.org/x/image/font/gofont/gobold"
	"golang.org/x/image/font/gofont/goregular"
	"golang.org/x/image/font/opentype"
	"golang.org/x/image/math/fixed"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
The picture a shared link shows.

	# WHY THERE HAS TO BE ONE AT ALL

	Without `og:image`, this platform's address pasted into a message is a line
	of blue text. Every page here already carries a title and a description, and
	a card with no picture is the one that gets scrolled past. This is the
	smallest thing that is not that: the page's own words, large, on the
	school's own colour.

	AND ON A DEPLOYMENT THAT MAY NOT BE INDEXED, NONE OF IT RENDERS — which is
	worth knowing here, because this is the file somebody opens when a paste
	comes out bare. Meta's crawler reads `X-Robots-Tag: noindex` as "no preview
	either", so a laboratory shows the host and nothing else however good the
	card is. It is a cost that was measured rather than a defect; `web.NoIndex`
	carries the argument. The card itself is still checkable at its own address,
	which is the reason it has one.

	# WHY IT IS DRAWN AND NOT A FILE

	There is one image in the entire catalogue and it is a diagram inside a
	lesson. A card per course would be 244 files nobody has made, going stale
	the moment a name is edited — and the name is the whole content of the card.
	So it is drawn from the same row the page is drawn from, and it cannot
	disagree with the page.

	# THE TYPEFACE IS NOT THE SCHOOL'S, AND THAT IS SAID RATHER THAN HIDDEN

	The interface is set in IBM Plex, which ships here as `woff2` — a format no
	Go rasteriser reads. The honest options were to commit a second copy of the
	family as TTF, or to use a face that arrives as a Go module and is therefore
	versioned, checksummed and never fetched at runtime. This takes the second:
	the Go family, in `golang.org/x/image/font/gofont`.

	It is a card in a message rather than a page of the site, so the cost is one
	step removed from the identity — and `face` below is the one place to change
	if a Plex TTF is ever committed.

	# IT IS CHEAP, BOUNDED AND CACHED, WHICH IT HAS TO BE

	This is an unauthenticated endpoint that allocates a 1200x630 image. The
	work is fixed per request — one image, at most six lines of text, no input
	that can make it bigger — and the answer is cacheable for a day, because the
	only thing that changes it is a catalogue that is republished rather than
	edited.
*/

/*
THE ADDRESS CARRIES NO `.png`, AND THAT IS THE MUX'S RULE RATHER THAN A CHOICE.

	`GET /card/{what}/{slug}.png` does not parse: a wildcard has to be the whole
	segment. The extension could have been bolted on as another segment and the
	address would read worse for it. What a fetcher goes by is the
	`Content-Type`, which this sets, and every platform that renders one of these
	reads that rather than the spelling.
*/
const (
	cardWide = 1200
	cardHigh = 630
	cardPad  = 72
)

type faces struct {
	title, under font.Face
}

// face builds the two faces a card uses, once. It is a function and not a pair
// of globals because `opentype.NewFace` returns an error, and a package that
// panicked at init because a font moved would take the whole binary with it.
var face = sync.OnceValues(func() (faces, error) {
	big, err := opentype.Parse(gobold.TTF)
	if err != nil {
		return faces{}, err
	}
	small, err := opentype.Parse(goregular.TTF)
	if err != nil {
		return faces{}, err
	}
	title, err := opentype.NewFace(big, &opentype.FaceOptions{Size: 64, DPI: 72, Hinting: font.HintingFull})
	if err != nil {
		return faces{}, err
	}
	under, err := opentype.NewFace(small, &opentype.FaceOptions{Size: 30, DPI: 72, Hinting: font.HintingFull})
	if err != nil {
		return faces{}, err
	}
	return faces{title: title, under: under}, nil
})

func (h *Handler) card(w http.ResponseWriter, r *http.Request, code string) {
	what, name := r.PathValue("what"), ""
	switch what {
	case "course":
		course, err := h.one(r.Context(), r.PathValue("slug"), code)
		if err != nil {
			http.NotFound(w, r)
			return
		}
		name = course.Name
	case "track":
		track, err := h.route(r.Context(), r.PathValue("slug"), code)
		if err != nil {
			http.NotFound(w, r)
			return
		}
		name = track.Name
	/* THE TWO LISTS, WHICH HAVE NO SLUG AND SO LOOK LIKE THEY NEED A ROUTE OF
	   THEIR OWN. They do not: `list` is the `what`, and which list is the
	   `slug` — `/card/list/courses`. A separate `GET /card/{what}` would be a
	   second pattern, a second entry in `Patterns`, and a mux deciding between
	   two wildcards, all to address two fixed things.

	   The name is the heading the page itself shows, so the card and the page
	   say the same words, which is the rule every other card here follows. */
	case "list":
		switch r.PathValue("slug") {
		case "courses":
			name = words[code]["everyCourse"]
		case "tracks":
			name = words[code]["everyTrack"]
		default:
			http.NotFound(w, r)
			return
		}
	default:
		http.NotFound(w, r)
		return
	}

	school, accent := "", ""
	if s, a, ok := h.brand(r.Context()); ok {
		school, accent = s, a
	}

	body, err := drawCard(name, school, accent)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("drawing a card", "error", err)
		http.NotFound(w, r)
		return
	}

	w.Header().Set("Content-Type", "image/png")
	w.Header().Set("Content-Length", strconv.Itoa(len(body)))
	// A day. The only thing that changes a card is a catalogue that is
	// republished, and a link already shared keeps whatever the platform it was
	// shared on cached anyway.
	w.Header().Set("Cache-Control", "public, max-age=86400")
	_, _ = w.Write(body)
}

// drawCard is the card itself: the school's colour, the page's name, the school's
// name under it.
func drawCard(name, school, accent string) ([]byte, error) {
	set, err := face()
	if err != nil {
		return nil, err
	}

	ground := hexColour(accent, color.RGBA{R: 0x11, G: 0x17, B: 0x21, A: 0xff})
	ink := readableOn(ground)

	card := image.NewRGBA(image.Rect(0, 0, cardWide, cardHigh))
	draw.Draw(card, card.Bounds(), &image.Uniform{C: ground}, image.Point{}, draw.Src)

	pen := &font.Drawer{Dst: card, Src: &image.Uniform{C: ink}, Face: set.title}

	/* THE NAME IS WRAPPED TO THE CARD RATHER THAN CUT AT IT. A course called
	   "Git and Teamwork: Versioning, Review and Process" is not a card that
	   says "Git and Teamwo" — and it is not a card with six point type either,
	   so the lines are counted and the tail is elided. */
	lines := wrap(pen, name, cardWide-cardPad*2, 5)
	y := cardPad + 96
	for _, line := range lines {
		pen.Dot = fixed.P(cardPad, y)
		pen.DrawString(line)
		y += 84
	}

	if school != "" {
		pen.Face = set.under
		pen.Dot = fixed.P(cardPad, cardHigh-cardPad)
		pen.DrawString(school)
	}

	var out bytes.Buffer
	if err := png.Encode(&out, card); err != nil {
		return nil, err
	}
	return out.Bytes(), nil
}

// wrap breaks a name into lines that fit, and elides what will not fit in the
// lines there are.
func wrap(pen *font.Drawer, s string, width, most int) []string {
	fits := func(line string) bool {
		return pen.MeasureString(line).Round() <= width
	}
	var lines []string
	line := ""
	for _, word := range strings.Fields(s) {
		try := word
		if line != "" {
			try = line + " " + word
		}
		if fits(try) {
			line = try
			continue
		}
		if line != "" {
			lines = append(lines, line)
		}
		line = word
		if len(lines) == most {
			break
		}
	}
	if line != "" && len(lines) < most {
		lines = append(lines, line)
	}
	if len(lines) == most && !fits(s) {
		last := lines[most-1]
		for last != "" && !fits(last+" …") {
			last = strings.TrimRight(last[:len(last)-1], " ")
		}
		lines[most-1] = last + " …"
	}
	return lines
}

// hexColour reads `#rrggbb`, and falls back rather than failing: a school with
// a malformed accent gets the platform's own dark ground and a card, instead of
// no card at all.
func hexColour(s string, fallback color.RGBA) color.RGBA {
	if len(s) != 7 || s[0] != '#' {
		return fallback
	}
	var out color.RGBA
	for i, at := range []*uint8{&out.R, &out.G, &out.B} {
		v, err := strconv.ParseUint(s[1+i*2:3+i*2], 16, 8)
		if err != nil {
			return fallback
		}
		*at = uint8(v)
	}
	out.A = 0xff
	return out
}

/*
Black or white, whichever can be read on this ground.

	A school picks its own accent and some of them are pale. White on a pale
	yellow is a card nobody can read, and the school chose the yellow — so the
	INK moves, not the ground. The same decision `ui/assets/accent.js` makes for
	the interface, and the same arithmetic: relative luminance, and the side of
	0.45 it falls on.
*/
func readableOn(ground color.RGBA) color.RGBA {
	channel := func(v uint8) float64 {
		f := float64(v) / 255
		if f <= 0.03928 {
			return f / 12.92
		}
		return math.Pow((f+0.055)/1.055, 2.4)
	}
	lum := 0.2126*channel(ground.R) + 0.7152*channel(ground.G) + 0.0722*channel(ground.B)
	if lum > 0.45 {
		return color.RGBA{R: 0x0a, G: 0x0e, B: 0x14, A: 0xff}
	}
	return color.RGBA{R: 0xff, G: 0xff, B: 0xff, A: 0xff}
}
