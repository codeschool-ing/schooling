package main

import (
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
)

/*
What colour a run of text is drawn in, which is two questions and not one.

# THE GROUND DECIDES WHICH KIND OF ANSWER IS EVEN POSSIBLE

	on the panel        the ground FLIPS between themes — #111721 and #ffffff —
	                    and no single colour reads against both. That is
	                    arithmetic rather than caution: a colour clearing 4.5:1
	                    against the dark panel needs a relative luminance above
	                    0.228, one clearing it against the light panel needs
	                    below 0.184, and there is nothing in between. So the
	                    text HAS to be a token, which flips with the ground.

	on a captured ground  the ground is a fixed value in both themes, so the
	                    text has to be fixed too. A token here is the defect
	                    this file was written for: it flips out from under a
	                    ground that does not, and the pair that reads in the
	                    dark theme is dark-on-dark in the light one.

# WHAT WAS THERE BEFORE, AND WHAT IT COST

The rule used to be "the program chose that colour and it is not ours to
reinterpret", written into `terminal.css`. It is good for fidelity and it
shipped text at 1.24:1 — `Press ENTER or type command to continue`, in vim's
pale green on the panel, in a figure this repository had just reviewed. Across
every figure in the catalogue it was 44 runs, in both themes, none of them
visible to any check because nothing reads inside an SVG.

So a colour that cannot be read is moved until it can. `ui/assets/accent.js`
already decided this for a school's own colour and the argument is the same
one: keep the hue, keep the saturation, move the lightness, and say so.

# AND THE TWO WAYS OF MOVING, WHICH ARE NOT INTERCHANGEABLE

On a captured ground the answer is a value, so the colour is walked along its
own lightness until it clears. On the panel the answer has to be a token, so
there is nothing to walk: the colour is matched to the nearest of the nine BY
HUE, among those that read. A pale green becomes `--term-green`, which is a
green in both themes and readable in both — not the same green, and the figure
no longer claims it is.
*/

// fill answers what a run's text colour should be, given what the program
// asked for and the ground it lands on. Both arguments are already resolved to
// what `colour` would write: a `#rrggbb`, a `var(--term-*)`, or "" for the
// terminal's own default.
func fill(fg, bg string) string {
	if bg == "" {
		return onThePanel(fg)
	}
	return onAGround(fg, resolve(bg, true))
}

// THE PANEL IS TWO GROUNDS, so the answer is a token or nothing.
func onThePanel(fg string) string {
	// The terminal's own foreground, which `--paper` already is in both themes.
	if fg == "" {
		return "var(--paper)"
	}
	if name, ok := tokenName(fg); ok {
		if readsOnThePanel(name) {
			return "var(--term-" + name + ")"
		}
		return "var(--term-" + nearestReadable(term.dark[name]) + ")"
	}
	// A colour the program chose for itself. Kept when it reads against both
	// panels — which almost nothing does — and otherwise matched by hue.
	if within(fg, panelDark) >= aa && within(fg, panelLight) >= aa {
		return fg
	}
	return "var(--term-" + nearestReadable(fg) + ")"
}

// A CAPTURED GROUND IS ONE GROUND, so the answer is a value.
func onAGround(fg, ground string) string {
	want := fg
	if name, ok := tokenName(fg); ok {
		// The token's dark-theme value is what the program meant by it; the
		// light-theme one exists to survive a flipping panel, and there is no
		// flipping panel here.
		want = term.dark[name]
	}
	if want == "" {
		// No colour asked for: the terminal paints its own foreground, and on
		// a coloured ground the honest fixed stand-in is whichever end reads.
		if within("#0a0e14", ground) >= within("#e8e6df", ground) {
			want = "#0a0e14"
		} else {
			want = "#e8e6df"
		}
	}
	return walkLightness(want, ground)
}

// A token is kept when it reads against the panel it belongs to, in its own
// theme. All nine do today; the check is here so that moving one is caught.
func readsOnThePanel(name string) bool {
	return within(term.dark[name], panelDark) >= aa && within(term.light[name], panelLight) >= aa
}

/*
The nearest of the nine BY HUE, among those that read against both panels.

	Distance is on the hue circle and nothing else, because that is the part of
	a colour a reader recognises across a theme change: htop's sienna keywords
	are still the warm ones, vim's pale green message is still the green one.
	Lightness and saturation are exactly what this is allowed to lose.

	Grey and black have no hue to speak of, so anything close to unsaturated
	goes to `grey` — which is the token that means "dimmer than the rest" and
	is what an unsaturated colour on a panel was being used for.
*/
func nearestReadable(value string) string {
	h, s, _ := toHSL(value)
	var names []string
	for name := range term.dark {
		if readsOnThePanel(name) {
			names = append(names, name)
		}
	}
	sort.Strings(names) // a map's order is not an answer
	if s < 0.15 {
		for _, name := range names {
			if name == "grey" {
				return name
			}
		}
	}
	best, bestAway := names[0], math.MaxFloat64
	for _, name := range names {
		th, ts, _ := toHSL(term.dark[name])
		if ts < 0.15 {
			continue // grey and black are not answers to a hue
		}
		away := math.Abs(h - th)
		if away > 180 {
			away = 360 - away
		}
		if away < bestAway {
			best, bestAway = name, away
		}
	}
	return best
}

/*
The same colour, moved along its lightness until it reads against one ground.

	It is `accent.js`'s rule in Go and for the same reason: a colour that has to
	change should change as little as a reader can notice, and hue is what a
	reader notices. Both directions are tried and the nearer winner is taken,
	so a mid-grey on a mid-grey goes whichever way is shorter rather than always
	down.

	It cannot fail: black and white are the ends of the walk, and every ground
	in `terminal.css` reads against one of them — `--term-grey-bg` was moved for
	exactly that reason.
*/
func walkLightness(value, ground string) string {
	if within(value, ground) >= aa {
		return value
	}
	h, s, l := toHSL(value)
	for step := 1; step <= 100; step++ {
		for _, candidate := range []float64{l - float64(step)/100, l + float64(step)/100} {
			if candidate < 0 || candidate > 1 {
				continue
			}
			moved := fromHSL(h, s, candidate)
			if within(moved, ground) >= aa {
				return moved
			}
		}
	}
	// Unreachable while every ground reads against one end, and an answer
	// rather than a panic if a future palette stops being true.
	if within("#0a0e14", ground) >= within("#e8e6df", ground) {
		return "#0a0e14"
	}
	return "#e8e6df"
}

// `var(--term-green)` -> "green". Anything else is not a token.
func tokenName(v string) (string, bool) {
	if !strings.HasPrefix(v, "var(--term-") || !strings.HasSuffix(v, ")") {
		return "", false
	}
	name := strings.TrimSuffix(strings.TrimPrefix(v, "var(--term-"), ")")
	if _, ok := term.dark[name]; !ok {
		return "", false
	}
	return name, true
}

// What `colour` wrote, turned back into the value it stands for. Only the dark
// half is ever needed: a `-bg` token is the same in both themes.
func resolve(v string, background bool) string {
	if strings.HasPrefix(v, "#") {
		return v
	}
	if name := strings.TrimSuffix(strings.TrimPrefix(v, "var(--term-"), "-bg)"); background {
		if value, ok := term.bg[name]; ok {
			return value
		}
	}
	if name, ok := tokenName(v); ok {
		return term.dark[name]
	}
	return v
}

// WCAG's contrast ratio, on two `#rrggbb` values.
func within(a, b string) float64 {
	la, lb := relative(a), relative(b)
	if la < lb {
		la, lb = lb, la
	}
	return (la + 0.05) / (lb + 0.05)
}

func relative(hex string) float64 {
	c := channels(hex)
	for i, v := range c {
		if v <= 0.03928 {
			c[i] = v / 12.92
		} else {
			c[i] = math.Pow((v+0.055)/1.055, 2.4)
		}
	}
	return 0.2126*c[0] + 0.7152*c[1] + 0.0722*c[2]
}

func channels(hex string) [3]float64 {
	var out [3]float64
	if len(hex) != 7 || hex[0] != '#' {
		return out
	}
	for i := range out {
		v, err := strconv.ParseUint(hex[1+i*2:3+i*2], 16, 8)
		if err != nil {
			return [3]float64{}
		}
		out[i] = float64(v) / 255
	}
	return out
}

func toHSL(hex string) (h, s, l float64) {
	c := channels(hex)
	high := math.Max(c[0], math.Max(c[1], c[2]))
	low := math.Min(c[0], math.Min(c[1], c[2]))
	l = (high + low) / 2
	if high == low {
		return 0, 0, l
	}
	d := high - low
	if l > 0.5 {
		s = d / (2 - high - low)
	} else {
		s = d / (high + low)
	}
	switch high {
	case c[0]:
		h = (c[1] - c[2]) / d
		if c[1] < c[2] {
			h += 6
		}
	case c[1]:
		h = (c[2]-c[0])/d + 2
	default:
		h = (c[0]-c[1])/d + 4
	}
	return h * 60, s, l
}

func fromHSL(h, s, l float64) string {
	if s == 0 {
		v := int(math.Round(l * 255))
		return fmt.Sprintf("#%02x%02x%02x", v, v, v)
	}
	var q float64
	if l < 0.5 {
		q = l * (1 + s)
	} else {
		q = l + s - l*s
	}
	p := 2*l - q
	at := func(t float64) int {
		if t < 0 {
			t++
		}
		if t > 1 {
			t--
		}
		switch {
		case t < 1.0/6:
			return int(math.Round((p + (q-p)*6*t) * 255))
		case t < 1.0/2:
			return int(math.Round(q * 255))
		case t < 2.0/3:
			return int(math.Round((p + (q-p)*(2.0/3-t)*6) * 255))
		default:
			return int(math.Round(p * 255))
		}
	}
	hue := h / 360
	return fmt.Sprintf("#%02x%02x%02x", at(hue+1.0/3), at(hue), at(hue-1.0/3))
}
