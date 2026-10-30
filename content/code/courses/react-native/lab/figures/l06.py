"""Lesson 6: one import, three files, three bundles."""
from fig import Fig

T = {
 "en": dict(aria="One import, ./savedWhere, resolved by Metro once per platform. The iOS bundle receives savedWhere.ios.ts, the Android bundle savedWhere.android.ts, and the web bundle the plain savedWhere.ts. Each bundle carries only its own file.",
   imp="the import, unchanged", ios="iOS bundle", and_="Android bundle", web="web bundle", by="Metro, at bundle time",
   cap="The choice is made when the bundle is built: the iPhone's sentence is not in the Android app at all."),
 "pt": dict(aria="Um import, ./savedWhere, resolvido pelo Metro uma vez por plataforma. O bundle de iOS recebe o savedWhere.ios.ts, o de Android o savedWhere.android.ts, e o bundle web o savedWhere.ts simples. Cada bundle carrega só o próprio arquivo.",
   imp="o import, sem mudança", ios="bundle de iOS", and_="bundle de Android", web="bundle web", by="o Metro, na hora do bundle",
   cap="A escolha é feita quando o bundle é construído: a frase do iPhone nem está no app Android."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l06-resolve", 720, 210, t["aria"])
    f.text(120, 24, t["imp"], size=9.5, fill="paper-dim", italic=True)
    f.box(20, 80, 200, 44, ['from "./savedWhere"'], mono=True, size=9.5, stroke="phosphor")
    f.text(290, 160, t["by"], size=9, fill="amber", italic=True)
    rows = [("savedWhere.ios.ts", t["ios"]), ("savedWhere.android.ts", t["and_"]), ("savedWhere.ts", t["web"])]
    for i, (file, b) in enumerate(rows):
        y = 30 + i * 56
        f.arrow([(220, 102), (350, y + 18)], color="amber")
        f.box(350, y, 190, 36, [file], mono=True, size=9.5)
        f.arrow([(540, y + 18), (580, y + 18)])
        f.box(580, y, 120, 36, [b], size=9.5, stroke="phosphor")
    return {"l06-resolve": f.json(caption=t["cap"])}
