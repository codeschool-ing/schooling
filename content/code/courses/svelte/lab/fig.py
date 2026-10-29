"""fig.py: the course's diagrams, drawn once and written in both languages.

Each lesson's figures are a Python file in lab/figures/, named for the lesson
id. It defines FIGURES, a list of (section slug, function); each function takes
T, which picks the English or the Portuguese of a label, and returns
(svg, caption, alt). Running

    python3 lab/fig.py le-xxxxxxxx

puts the k-th figure of a section into the k-th schooling-figure fence of its
.md and .pt.md (a fence whose body is "@fig" is a place kept for one). Labels in
the mono face are code and are the same in both; a sans label the Portuguese
leaves in English is listed in that figure's "same".
"""
import html, importlib.util, json, os, re, sys

SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


class Canvas:
    def __init__(self, w, h, alt):
        self.w, self.h, self.alt, self.items, self.sans = w, h, alt, [], []

    def rect(self, x, y, w, h, fill="var(--panel)", stroke="var(--wire)", dash=None, sw=1.2, rx=4):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.items.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}></rect>')

    def text(self, x, y, s, size=11, fill="var(--paper)", mono=False, anchor="middle", weight=None):
        if not mono:
            self.sans.append(s)
        w = f' font-weight="{weight}"' if weight else ""
        self.items.append(
            f'<text x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="middle" font-family="{MONO if mono else SANS}" '
            f'font-size="{size}"{w} fill="{fill}">{html.escape(s, quote=False)}</text>')

    def line(self, x1, y1, x2, y2, stroke="var(--wire)", sw=1.2, dash=None, arrow=False):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.items.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{sw}"{d}></line>')
        if arrow:
            import math
            a = math.atan2(y2 - y1, x2 - x1)
            p = [(x2, y2), (x2 - 8 * math.cos(a - 0.4), y2 - 8 * math.sin(a - 0.4)), (x2 - 8 * math.cos(a + 0.4), y2 - 8 * math.sin(a + 0.4))]
            self.items.append('<polygon points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in p) + f'" fill="{stroke}"></polygon>')

    def path(self, d, stroke="var(--wire)", sw=1.2, fill="none", dash=None):
        dd = f' stroke-dasharray="{dash}"' if dash else ""
        self.items.append(f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{dd}></path>')

    def svg(self):
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" aria-label="{html.escape(self.alt)}">'
                + "".join(self.items) + "</svg>")


def run(lesson):
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location("f", os.path.join(here, "figures", lesson + ".py"))
    mod = importlib.util.module_from_spec(spec)
    sys.modules["fig"] = sys.modules[__name__]
    spec.loader.exec_module(mod)
    ldir = os.path.join(here, "..", "lessons", lesson)
    per = {}
    for slug, fn in mod.FIGURES:
        per.setdefault(slug, []).append(fn)
    for slug, fns in per.items():
        for lang, suffix in (("en", ".md"), ("pt", ".pt.md")):
            path = os.path.join(ldir, slug + suffix)
            if not os.path.exists(path):
                continue
            blocks = []
            for fn in fns:
                en_c = Canvas(0, 0, "")
                T = (lambda en, pt: en) if lang == "en" else (lambda en, pt: pt)
                c = fn(T)
                block = {"svg": c.svg(), "caption": c.caption}
                if lang == "pt":
                    en = fn(lambda en, pt: en)
                    same = sorted({s for s in c.sans if s in en.sans and re.search(r"[A-Za-z]", s)})
                    if same:
                        block["same"] = same
                blocks.append(json.dumps(block, ensure_ascii=False))
            text = open(path, encoding="utf-8").read()
            spots = list(re.finditer(r"^```schooling-figure\n(.*?)\n```$", text, re.S | re.M))
            if len(spots) != len(blocks):
                sys.exit(f"{path}: {len(spots)} figure fences for {len(blocks)} figures")
            for m, b in reversed(list(zip(spots, blocks))):
                text = text[:m.start(1)] + b + text[m.end(1):]
            open(path, "w", encoding="utf-8").write(text)
            print(f"{path}: {len(blocks)} figure(s)")


if __name__ == "__main__":
    for l in sys.argv[1:]:
        run(l)
