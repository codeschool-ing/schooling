#!/usr/bin/env python3
import importlib.util, json, re, sys, os
sys.path.insert(0, "/var/tmp/lab/bin")
import fig
mod_path, mds = sys.argv[1], sys.argv[2:]
spec = importlib.util.spec_from_file_location("f", mod_path); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
used = set()
def build(lang):
    pt = getattr(m, "PT", {})
    def t(s):
        if lang == "en": return s
        if s not in pt: raise SystemExit(f"{m.NAME}: no PT for {s!r}")
        used.add(s); return pt[s]
    s = fig.S(m.W, m.H, m.LABEL[0 if lang == "en" else 1], m.NAME)
    m.draw(s, t)
    d = {"svg": s.svg(), "caption": m.CAPTION[0 if lang == "en" else 1]}
    if lang == "pt" and getattr(m, "SAME", None): d["same"] = m.SAME
    return "```schooling-figure\n" + json.dumps(d, ensure_ascii=False) + "\n```"
for md in mds:
    lang = "pt" if md.endswith(".pt.md") else "en"
    text = open(md, encoding="utf-8").read()
    block = build(lang)
    ph = f"@@fig:{m.NAME}@@"
    if ph in text:
        text = text.replace(ph, block)
    else:
        pat = re.compile(r"^```schooling-figure\n[^\n]*data-fig=\\\"" + re.escape(m.NAME) + r"\\\"[^\n]*\n```$", re.M)
        text, n = pat.subn(lambda _: block, text)
        if n != 1: raise SystemExit(f"{md}: {n} places for {m.NAME}")
    open(md, "w", encoding="utf-8").write(text)
    print("figure", m.NAME, "->", os.path.basename(md))
