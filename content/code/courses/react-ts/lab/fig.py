"""fig.py: the course's diagrams, written as Python and drawn as the SVG the
lessons carry.

A figure is defined once, with its words in both languages, in
lab/figures/<lesson id>.py, and drawn into the lesson's .md and .pt.md by

    python3 lab/fig.py lessons/<lesson id>

which replaces a line `@@fig:NAME@@` the first time, and the fence whose svg
carries data-fig="NAME" every time after. Nothing here is read by the loader;
the lesson files are the source of what a student sees, and this is how they
were drawn.

A text is either a plain string, the same in both languages, or a dict with
"en" and "pt". A plain string drawn in the prose face goes into the
translation's "same" list, because it is the same word on purpose.
"""
import importlib.util
import json
import re
import sys
from pathlib import Path

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"
TONES = {
    "paper": "var(--paper)",
    "dim": "var(--paper-dim)",
    "phosphor": "var(--phosphor)",
    "phos-dim": "var(--phosphor-dim)",
    "amber": "var(--amber)",
    "wire": "var(--wire)",
    "ink": "var(--ink)",
    "panel": "var(--panel)",
    "scan": "var(--scan)",
}


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def pick(t, lang):
    if isinstance(t, dict):
        return t[lang]
    return t


class Fig:
    def __init__(self, name, w, h, aria, caption):
        self.name, self.w, self.h = name, w, h
        self.aria, self.caption = aria, caption
        self.items = []

    # A rectangle, with optional lines of text centred in it.
    def box(self, x, y, w, h, lines=(), mono=False, tone="phosphor", fill="ink",
            dashed=False, size=None, text_tone=None, rx=4, stroke=1.2):
        self.items.append(("rect", dict(x=x, y=y, w=w, h=h, tone=tone, fill=fill,
                                        dashed=dashed, rx=rx, stroke=stroke)))
        if isinstance(lines, (str, dict)):
            lines = [lines]
        size = size or (10.5 if mono else 11)
        n = len(lines)
        gap = size + 4
        top = y + h / 2 - gap * (n - 1) / 2
        for i, t in enumerate(lines):
            self.text(x + w / 2, top + i * gap, t, mono=mono, tone=text_tone or ("paper" if not mono else tone),
                      anchor="middle", size=size)
        return self

    def text(self, x, y, t, mono=False, tone="paper", anchor="start", size=None, weight=None):
        self.items.append(("text", dict(x=x, y=y, t=t, mono=mono, tone=tone, anchor=anchor,
                                        size=size or (10.5 if mono else 11), weight=weight)))
        return self

    def arrow(self, x1, y1, x2, y2, tone="wire", dashed=False, head=True, width=1.2):
        self.items.append(("arrow", dict(x1=x1, y1=y1, x2=x2, y2=y2, tone=tone, dashed=dashed,
                                         head=head, width=width)))
        return self

    def line(self, x1, y1, x2, y2, tone="wire", dashed=False, width=1.2):
        return self.arrow(x1, y1, x2, y2, tone=tone, dashed=dashed, head=False, width=width)

    def path(self, d, tone="wire", dashed=False, width=1.2, head_at=None):
        self.items.append(("path", dict(d=d, tone=tone, dashed=dashed, width=width, head_at=head_at)))
        return self

    def svg(self, lang):
        out = [f'<svg data-fig="{self.name}" viewBox="0 0 {self.w} {self.h}" role="img" '
               f'aria-label="{esc(pick(self.aria, lang))}">']
        for kind, a in self.items:
            if kind == "rect":
                dash = ' stroke-dasharray="4 3"' if a["dashed"] else ""
                fill = "none" if a["fill"] is None else TONES[a["fill"]]
                out.append(f'<rect x="{a["x"]}" y="{a["y"]}" width="{a["w"]}" height="{a["h"]}" '
                           f'rx="{a["rx"]}" fill="{fill}" stroke="{TONES[a["tone"]]}" '
                           f'stroke-width="{a["stroke"]}"{dash}></rect>')
            elif kind == "text":
                fam = MONO if a["mono"] else SANS
                wt = f' font-weight="{a["weight"]}"' if a["weight"] else ""
                out.append(f'<text x="{a["x"]}" y="{a["y"]}" text-anchor="{a["anchor"]}" '
                           f'dominant-baseline="middle" font-family="{fam}" font-size="{a["size"]}"'
                           f'{wt} fill="{TONES[a["tone"]]}">{esc(pick(a["t"], lang))}</text>')
            elif kind == "arrow":
                dash = ' stroke-dasharray="4 3"' if a["dashed"] else ""
                x1, y1, x2, y2 = a["x1"], a["y1"], a["x2"], a["y2"]
                out.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{TONES[a["tone"]]}" '
                           f'stroke-width="{a["width"]}"{dash}></line>')
                if a["head"]:
                    out.append(head(x1, y1, x2, y2, a["tone"]))
            elif kind == "path":
                dash = ' stroke-dasharray="4 3"' if a["dashed"] else ""
                out.append(f'<path d="{a["d"]}" fill="none" stroke="{TONES[a["tone"]]}" '
                           f'stroke-width="{a["width"]}"{dash}></path>')
                if a["head_at"]:
                    out.append(head(*a["head_at"], a["tone"]))
        out.append("</svg>")
        return "".join(out)

    def same(self):
        s = []
        for kind, a in self.items:
            t = a.get("t")
            if isinstance(t, dict) and t["en"] == t["pt"]:
                t = t["en"]
            if kind == "text" and not a["mono"] and isinstance(t, str) and re.search(r"[A-Za-z]", t):
                if t not in s:
                    s.append(t)
        return s

    def fence(self, lang):
        block = {"svg": self.svg(lang), "caption": pick(self.caption, lang)}
        if lang == "pt" and self.same():
            block["same"] = self.same()
        return "```schooling-figure\n" + json.dumps(block, ensure_ascii=False) + "\n```"


def head(x1, y1, x2, y2, tone):
    import math
    ang = math.atan2(y2 - y1, x2 - x1)
    L, W = 7.5, 3.2
    bx, by = x2 - L * math.cos(ang), y2 - L * math.sin(ang)
    px, py = -math.sin(ang) * W, math.cos(ang) * W
    pts = f"{x2:.1f},{y2:.1f} {bx + px:.1f},{by + py:.1f} {bx - px:.1f},{by - py:.1f}"
    return f'<polygon points="{pts}" fill="{TONES[tone]}"></polygon>'


def load(lesson_dir):
    lesson = Path(lesson_dir).resolve()
    src = lesson.parent.parent / "lab" / "figures" / f"{lesson.name}.py"
    spec = importlib.util.spec_from_file_location("figs", src)
    mod = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(Path(__file__).parent))
    spec.loader.exec_module(mod)
    return {f.name: f for f in mod.FIGS}


def draw(lesson_dir):
    figs = load(lesson_dir)
    used = set()
    for md in sorted(Path(lesson_dir).glob("*.md")):
        lang = "pt" if md.name.endswith(".pt.md") else "en"
        text = md.read_text()
        orig = text

        def place(m):
            used.add(m.group(1))
            return figs[m.group(1)].fence(lang)
        text = re.sub(r"^@@fig:([a-z0-9-]+)@@$", place, text, flags=re.M)

        def again(m):
            name = re.search(r'data-fig=\\"([a-z0-9-]+)\\"', m.group(0)).group(1)
            used.add(name)
            return figs[name].fence(lang)
        text = re.sub(r'^```schooling-figure\n\{"svg": "<svg data-fig=.*\n```$', again, text, flags=re.M)
        if text != orig:
            md.write_text(text)
    missing = set(figs) - used
    if missing:
        print("fig: defined and drawn nowhere: " + ", ".join(sorted(missing)), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    draw(sys.argv[1])
