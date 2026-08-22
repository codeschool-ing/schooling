/* ==========================================================================
   The school's own colour.

   `tenants.accent` has been a column since the first migration, and its comment
   says what it is for: "One colour per school, applied as a custom property. It
   is the whole of the visual difference between them: one design system, one
   accent, so a student knows where they are without the brand fragmenting."

   It was never applied. Every school came out in codeschool.ing's blue.

   # A COLOUR SOMEBODY ELSE CHOSE STILL HAS TO BE READABLE

   `--phosphor` is not decoration. It is the track a student is on, the count
   beside a course, the button they press — text and controls, at small sizes.
   WCAG AA asks 4.5:1 for that, and here accessibility is a rule rather than a
   preference (X-05). A school could pick a yellow that is 1.6:1 on the dark
   page, and applying it because it was in a column would be this codebase
   breaking its own rule on somebody else's behalf.

   So the colour is measured before it is used, ONCE PER THEME.

   # AND NO COLOUR PASSES BOTH THEMES

   This is not a caution, it is arithmetic. The two page backgrounds are
   #0a0e14 and #f2f4f9, and for a colour to clear 4.5:1 on both it would have to
   be far from each — which, across the whole of RGB, the best any colour
   manages is 4.17:1. There is no accent that is readable on the dark page and
   the light one at the same value. Not the school's, and not the palette's:
   #5b8cff is 6.12:1 on the dark page and 2.87:1 on the light.

   Which is exactly why the palette carries TWO blues rather than one, and it is
   the answer here too. A school's colour is its HUE, not its six digits: the
   accent is used as it was given where it reads, and where it does not it is
   moved along its own lightness until it does — same hue, same saturation,
   readable. A school that picks green gets a lighter green on the dark page and
   a deeper green on the light one, rather than green on one page and
   codeschool.ing's blue on the other.

   THE FIRST VERSION OF THIS DID DROP IT, per theme, and would have shipped
   every school a blue light theme without that ever looking like a bug — the
   page would simply have been the colour it always was.

   AND IT SAYS SO. A colour that had to be moved is written to the console with
   what it scored, what it needed, and what was used instead. Silence would
   leave somebody wondering why the school does not look like its brand guide.

   # THE SECOND BLUE

   `app.css` defines `--phosphor-mid`, a step between `--phosphor` and the
   background, so that a finished course and an available one are not the same
   colour. Derived from the palette it would stay blue while the accent turned
   green, so it is derived from the ACCENT instead: the same hue, quieter, and
   still over the threshold. If nothing on that hue is both, the accent is used
   for each — one dull pair of states beats an unreadable one.
   ========================================================================== */

/* ---------- colour, enough of it ---------- */

const hex = (c) => {
  const m = /^#([0-9a-f]{6})$/i.exec(String(c || '').trim());
  if (!m) return null;
  const n = parseInt(m[1], 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
};

const toHex = ({ r, g, b }) =>
  '#' + [r, g, b].map((v) => Math.round(Math.max(0, Math.min(255, v)))
    .toString(16).padStart(2, '0')).join('');

/* Relative luminance, WCAG's definition. */
function luminance({ r, g, b }) {
  const f = (v) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}

export function contrast(a, b) {
  const [x, y] = [luminance(a), luminance(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
}

/* RGB↔HSL, so that "the same colour, lighter" means the same hue rather than a
   fade towards grey. */
function toHSL({ r, g, b }) {
  const [R, G, B] = [r / 255, g / 255, b / 255];
  const max = Math.max(R, G, B), min = Math.min(R, G, B);
  const l = (max + min) / 2;
  if (max === min) return { h: 0, s: 0, l };
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === R) h = ((G - B) / d + (G < B ? 6 : 0)) / 6;
  else if (max === G) h = ((B - R) / d + 2) / 6;
  else h = ((R - G) / d + 4) / 6;
  return { h, s, l };
}

function fromHSL({ h, s, l }) {
  if (s === 0) return { r: l * 255, g: l * 255, b: l * 255 };
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const channel = (t) => {
    let v = t;
    if (v < 0) v += 1;
    if (v > 1) v -= 1;
    if (v < 1 / 6) return p + (q - p) * 6 * v;
    if (v < 1 / 2) return q;
    if (v < 2 / 3) return p + (q - p) * (2 / 3 - v) * 6;
    return p;
  };
  return { r: channel(h + 1 / 3) * 255, g: channel(h) * 255, b: channel(h - 1 / 3) * 255 };
}

const AA = 4.5;

/* How well a colour reads in a theme: ITS WORST SURFACE, not the page.

   A theme is not one background. `--ink` is the page and `--panel` is every
   card, panel, menu and certificate sheet on it, and accent-coloured text sits
   on both — the lesson number and the section count are on a card, the track
   name is on the page. In the dark theme the card is the LIGHTER of the two, so
   a colour measured against the page alone is measured against the easier one.

   That shipped for exactly one test run: an accent measured at 5.77:1 on
   #0a0e14 produced a companion at 4.19:1 on #111721, and axe found it on three
   screens. Measuring the page was measuring a surface half of this text is not
   on.

   So a candidate scores its minimum over every surface the token can land on,
   and one number then means "readable in this theme" everywhere. */
const scoreOn = (colour, surfaces) =>
  surfaces.reduce((worst, s) => Math.min(worst, contrast(colour, s)), Infinity);

/* The same colour, readable in this theme.

   The accent as it was given, if it clears AA. Otherwise the nearest value on
   ITS OWN HUE AND SATURATION that does — nearest so that a colour needing a
   small correction gets a small one, and the school's brand is recognisably
   itself rather than the darkest thing on that hue.

   Both directions, and the closer one wins: in a dark theme the fix is almost
   always lighter and in a light one darker, but "almost always" is not a thing
   to hard-code — the search finds out rather than assuming.

   `null` if the hue has none. Every hue in RGB has one against both of this
   palette's themes, which was checked; it is still handled, because a palette
   is a thing somebody changes.

   EVERY CANDIDATE IS ROUNDED BEFORE IT IS MEASURED. What goes into the
   stylesheet is six hex digits, and a colour that scores 4.501:1 as three
   floats can score 4.497:1 once it is one of the sixteen million a browser can
   actually paint. Measuring the float would be measuring a colour nobody
   sees. */
function readable(accent, surfaces) {
  if (scoreOn(accent, surfaces) >= AA) return accent;

  const base = toHSL(accent);
  for (let d = 0.005; d <= 1; d += 0.005) {
    for (const l of [base.l + d, base.l - d]) {
      if (l < 0.02 || l > 0.98) continue;
      const candidate = hex(toHex(fromHSL({ h: base.h, s: base.s, l })));
      if (scoreOn(candidate, surfaces) >= AA) return candidate;
    }
  }
  return null;
}

/* The dimmer companion: the accent's own hue, quieter, and still readable.

   QUIETER IS NOT DARKER. In the dark theme, darker means less contrast, so a
   companion found by walking the lightness down is a colour that stops reading
   before it stops shouting — the first attempt at this searched in exactly that
   direction and found nothing for any accent that was not already very bright.

   So the search is two-dimensional and it is judged by CONTRAST rather than by
   lightness: every candidate on the accent's hue, at a few saturations and a
   few lightnesses, and the winner is the one that reads the LEAST while still
   clearing the threshold on every surface. That is what "dimmer" means on a
   screen — closer to the background — and it is the same answer in both themes
   without either being special-cased.

   If nothing on that hue passes, the accent is returned unchanged: one colour
   family with two states that look alike beats two colour families, and a state
   nobody can read is not a state. */
function companion(accent, surfaces) {
  const base = toHSL(accent);
  const strong = scoreOn(accent, surfaces);

  let best = null;
  let bestScore = Infinity;

  for (const s of [1, 0.8, 0.6, 0.45]) {
    for (let d = 0; d <= 0.4; d += 0.02) {
      for (const l of [base.l - d, base.l + d]) {
        if (l < 0.08 || l > 0.92) continue;
        // Rounded before it is measured, for the reason `readable` is.
        const candidate = hex(toHex(fromHSL({ h: base.h, s: base.s * s, l })));
        const score = scoreOn(candidate, surfaces);
        // It has to read, and it has to be quieter than the accent by enough
        // to be a different state rather than a rendering artefact.
        if (score < AA || score > strong - 0.35) continue;
        if (score < bestScore) {
          bestScore = score;
          best = candidate;
        }
      }
    }
  }
  return toHex(best || accent);
}

/* ---------- applying it ---------- */

/* Every background accent-coloured text lands on, in one theme.

   READ FROM THE STYLESHEET RATHER THAN WRITTEN HERE. `--ink` is the page and
   `--panel` is every card; a palette that changes should not leave this file
   measuring against colours nobody uses any more.

   MEASURED ON THE ROOT, by putting the theme on it for the length of one
   synchronous read. A probe element with `data-theme="light"` on it does not
   work and looks as though it does: the palette is declared under
   `html[data-theme="light"]`, so a div carrying that attribute inherits the
   DARK values and every colour scores its dark contrast twice. That is exactly
   how a colour rejected for one theme gets rejected for both — or worse,
   accepted for both.

   No paint happens in between: the attribute goes back before this function
   returns, and the browser has had no chance to lay out. */
/* AND ONE OF THEM IS TRANSLUCENT. `--tint-accent` is the wash behind a verdict
   and behind anything else that is tinted with the accent's own colour; over
   the page it composites to a surface slightly darker than the page in the
   light theme, which is precisely where a colour that just cleared 4.5:1
   against `--ink` lands at 4.32:1.

   That is not hypothetical: axe found it, intermittently, on the drill — and
   intermittently because the state it lives on is the one where the answer
   happened to be right. A check that only sometimes reaches a screen is a check
   that only sometimes holds it.

   A translucent surface is composited over `--ink` before it is measured, which
   is what the browser does to draw it. */
const SURFACES = ['--ink', '--panel', '--tint-accent'];

function parse(value) {
  const v = String(value || '').trim();
  if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(v)) {
    return hex(v.length === 4 ? '#' + v[1] + v[1] + v[2] + v[2] + v[3] + v[3] : v);
  }
  const parts = v.match(/[\d.]+/g);
  if (!parts || parts.length < 3) return null;
  const out = { r: +parts[0], g: +parts[1], b: +parts[2] };
  if (parts.length > 3) out.a = +parts[3];
  return out;
}

// A translucent colour, as it is actually drawn: over the page.
const over = (colour, page) => (colour.a === undefined || colour.a >= 1 ? colour : {
  r: colour.r * colour.a + page.r * (1 - colour.a),
  g: colour.g * colour.a + page.g * (1 - colour.a),
  b: colour.b * colour.a + page.b * (1 - colour.a),
});

function surfacesOf(theme) {
  const root = document.documentElement;
  const before = root.dataset.theme;

  root.dataset.theme = theme;
  const style = getComputedStyle(root);
  const read = SURFACES.map((name) => style.getPropertyValue(name));
  if (before === undefined) delete root.dataset.theme;
  else root.dataset.theme = before;

  const surfaces = read.map(parse).filter(Boolean);
  const page = surfaces[0];
  return page ? surfaces.map((c) => over(c, page)) : surfaces;
}

/* `html[data-theme="light"]` is what the palette overrides under, so the rule
   written here has to be at least as specific to win — and it has to be a rule
   rather than an inline style, because an inline `--phosphor` on <html> would
   apply to BOTH themes and the whole point is that they are measured
   separately. */
function stylesheet() {
  let el = document.getElementById('school-accent');
  if (!el) {
    el = document.createElement('style');
    el.id = 'school-accent';
    document.head.appendChild(el);
  }
  return el;
}

export function applyAccent(accent) {
  const colour = hex(accent);
  if (!colour) return;   // no colour, or not a colour: the palette stands

  const rules = [];
  for (const theme of ['dark', 'light']) {
    const surfaces = surfacesOf(theme);
    if (!surfaces.length) continue;

    const score = scoreOn(colour, surfaces);
    const used = readable(colour, surfaces);
    if (!used) {
      // eslint-disable-next-line no-console
      console.warn(`the school's accent ${toHex(colour)} reads at ${score.toFixed(2)}:1 in the `
        + `${theme} theme, and nothing on its hue reaches ${AA}:1 on every surface, so that `
        + `theme keeps the palette's own colour`);
      continue;
    }
    if (toHex(used) !== toHex(colour)) {
      // eslint-disable-next-line no-console
      console.info(`the school's accent ${toHex(colour)} reads at ${score.toFixed(2)}:1 in the `
        + `${theme} theme and needs ${AA}:1, so that theme uses ${toHex(used)} — the same `
        + `colour, moved until it can be read`);
    }

    const where = theme === 'light'
      ? 'html[data-theme="light"]'
      : ':root, html[data-theme="dark"]';
    rules.push(`${where}{--phosphor:${toHex(used)};`
      + `--phosphor-mid:${companion(used, surfaces)};}`);
  }

  stylesheet().textContent = rules.join('\n');
}
