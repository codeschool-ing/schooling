package main

// THE PALETTE, AND WHY A SECOND COPY OF IT IS HERE AT ALL.
//
// `ui/assets/terminal.css` is where these values live and it stays that way:
// the browser resolves `var(--term-green)` per theme, and nothing in this file
// can do that. What this file needs is not the values to WRITE but the values
// to MEASURE — whether the colour a program chose can be read against the
// ground it lands on, in both themes, before the figure is written out.
//
// A copy that drifts is worse than no copy, so `TestThePaletteMatchesTheCSS`
// parses `terminal.css` and fails on any difference in either direction. That
// is the same arrangement `check-css` and the console's `check-shared` use, and
// it is the only one that makes a duplicate safe.
//
// THE `-bg` VALUES DO NOT FLIP AND THE FOREGROUNDS DO. That is the whole shape
// of the problem this file exists to measure: a background is a fixed value in
// both themes, because it has to hold its contrast against the text on it; a
// foreground moves with the panel behind it. Put a moving foreground on a fixed
// background and the pair reads in one theme and not the other, which is what
// `fill` below is about.
type palette struct {
	dark  map[string]string // the foreground tokens, as `:root` defines them
	light map[string]string // and as `html[data-theme="light"]` redefines them
	bg    map[string]string // the grounds, which are the same in both
}

var term = palette{
	dark: map[string]string{
		"black": "#0a0e14", "red": "#ff6b7a", "green": "#3ddc84", "yellow": "#d3e561",
		"blue": "#5b8cff", "magenta": "#ed61d7", "cyan": "#22d3d3", "white": "#e8e6df",
		"grey": "#9aa0a8",
	},
	light: map[string]string{
		"black": "#20263c", "red": "#c0271f", "green": "#12794a", "yellow": "#8a6a0a",
		"blue": "#2b52c9", "magenta": "#9b1fa8", "cyan": "#0b6f7a", "white": "#20263c",
		"grey": "#5a6274",
	},
	bg: map[string]string{
		"black": "#0a0e14", "red": "#e05260", "green": "#31bb71", "yellow": "#d3c161",
		"blue": "#5b8cff", "magenta": "#ed61d7", "cyan": "#22c3d3", "white": "#e8e6df",
		"grey": "#747c8b",
	},
}

// The two grounds a figure is drawn on when the program set no background of
// its own. They are `--panel` from `base.css`, and they are the reason a
// foreground has to be a token: no single colour reads against both.
const (
	panelDark  = "#111721"
	panelLight = "#ffffff"
)

// WCAG AA for body text, which is what a figure's text is. `ui/assets/accent.js`
// holds itself to the same number for a school's own colour and says why: here
// accessibility is a rule rather than a preference.
const aa = 4.5
