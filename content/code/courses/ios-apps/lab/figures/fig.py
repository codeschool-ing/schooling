"""Drawing helper for the ios-apps figures. THE STUDENT NEVER SEES THIS (C-40).

A figure is drawn once and written twice, English and Portuguese, into the
section's .md and .pt.md: a `schooling-figure` fence whose svg carries
data-fig="<id>" is replaced, or else the line `@@fig <id>@@`. Only the words
differ between the two languages; every coordinate is shared, so the two
drawings cannot drift apart. A label drawn in the prose face whose Portuguese
is the same word is put in the translation's `same` list automatically.

    python3 lab/figures/l01.py      # from the course directory
"""
import html, json, re, os

PALETTE = {"amber", "ink", "panel", "paper", "paper-dim", "phosphor", "phosphor-dim", "scan", "wire"}
SANS = "'IBM Plex Sans', sans-serif"
MONO = "'IBM Plex Mono', monospace"


def c(name):
    assert name in PALETTE, name
    return f"var(--{name})"


class Fig:
    def __init__(self, fid, w, h, label_en, label_pt):
        self.fid, self.w, self.h = fid, w, h
        self.label = (label_en, label_pt)
        self.items = []          # (kind, data)
        self.same = set()

    def box(self, x, y, w, h, stroke="wire", fill="panel", dashed=False, sw=1.4):
        d = ' stroke-dasharray="5 4"' if dashed else ""
        self.items.append(("raw", f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{c(fill)}" stroke="{c(stroke)}" stroke-width="{sw}"{d}></rect>'))

    def text(self, x, y, en, pt=None, mono=False, size=11, fill="paper", weight=None, anchor="middle"):
        pt = en if pt is None else pt
        if not mono and re.search(r"[A-Za-zÀ-ÿ]", en) and pt == en:
            self.same.add(en)
        wt = f' font-weight="{weight}"' if weight else ""
        def one(s):
            return (f'<text x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="middle" '
                    f'font-family="{MONO if mono else SANS}" font-size="{size}"{wt} fill="{c(fill)}">'
                    f'{html.escape(s, quote=False)}</text>')
        self.items.append(("text", (one(en), one(pt))))

    def line(self, x1, y1, x2, y2, color="wire", dashed=False, arrow=True, sw=1.3):
        d = ' stroke-dasharray="5 4"' if dashed else ""
        m = f' marker-end="url(#{self.fid}-ah-{color})"' if arrow else ""
        self.items.append(("raw", f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{c(color)}" stroke-width="{sw}" fill="none"{d}{m}></path>'))

    def path(self, d, color="wire", dashed=False, arrow=True, sw=1.3):
        da = ' stroke-dasharray="5 4"' if dashed else ""
        m = f' marker-end="url(#{self.fid}-ah-{color})"' if arrow else ""
        self.items.append(("raw", f'<path d="{d}" stroke="{c(color)}" stroke-width="{sw}" fill="none"{da}{m}></path>'))

    def svg(self, lang):
        i = 0 if lang == "en" else 1
        defs = "".join(
            f'<marker id="{self.fid}-ah-{k}" viewBox="0 0 10 8" refX="9" refY="4" markerWidth="8" markerHeight="7" '
            f'orient="auto-start-reverse"><path d="M0 0 L10 4 L0 8 z" fill="{c(k)}"></path></marker>'
            for k in ("wire", "amber", "phosphor", "paper-dim"))
        body = "".join(d if k == "raw" else d[i] for k, d in self.items)
        lab = html.escape(self.label[i], quote=True)
        return (f'<svg viewBox="0 0 {self.w} {self.h}" role="img" data-fig="{self.fid}" aria-label="{lab}">'
                f'<defs>{defs}</defs>{body}</svg>')

    def write(self, md, caption_en, caption_pt):
        en = {"svg": self.svg("en"), "caption": caption_en}
        pt = {"svg": self.svg("pt"), "caption": caption_pt}
        if self.same:
            pt["same"] = sorted(self.same)
        for path, data in ((md, en), (md.replace(".md", ".pt.md"), pt)):
            text = open(path, encoding="utf-8").read()
            fence = "```schooling-figure\n" + json.dumps(data, ensure_ascii=False) + "\n```"
            pat = re.compile(r'```schooling-figure\n[^\n]*data-fig=\\?"' + re.escape(self.fid) + r'\\?"[^\n]*\n```')
            if pat.search(text):
                text = pat.sub(lambda _: fence, text, count=1)
            elif f"@@fig {self.fid}@@" in text:
                text = text.replace(f"@@fig {self.fid}@@", fence, 1)
            else:
                raise SystemExit(f"{path}: no place for figure {self.fid}")
            open(path, "w", encoding="utf-8").write(text)
            print(f"{path}: {self.fid}")


def lesson(lid, slug):
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(here, "..", "..", "lessons", lid, slug + ".md")
