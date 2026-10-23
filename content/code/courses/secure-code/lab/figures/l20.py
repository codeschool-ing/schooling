"""Lesson 20: the figures."""
from fig import Fig

T = {
    "en": dict(
        lv_aria="The three levels of ASVS 5.0.0 as nested boxes, counted from the standard's own file. Level 1 holds 70 requirements, the minimum for any application. Level 2 adds 183, for 253 in all, the level most applications handling personal data should aim at. Level 3 adds 92, for all 345, for applications where a failure would be most severe. Each level includes everything in the levels inside it.",
        l1="level 1", l1b="70 requirements: the floor for any application",
        l2="level 2", l2b="+183, 253 in all: personal data, Vereda's portal",
        l3="level 3", l3b="+92, all 345: where failure costs most",
        lv_cap="Levels are cumulative. A portal holding health data aims at level 2 and meets level 1 first.",
    ),
    "pt": dict(
        lv_aria="Os três níveis do ASVS 5.0.0 como caixas aninhadas, contados a partir do próprio arquivo do padrão. O nível 1 tem 70 requisitos, o mínimo para qualquer aplicação. O nível 2 acrescenta 183, num total de 253, o nível que a maioria das aplicações com dados pessoais deveria buscar. O nível 3 acrescenta 92, num total de 345, para aplicações em que uma falha seria das mais graves. Cada nível inclui tudo dos níveis dentro dele.",
        l1="nível 1", l1b="70 requisitos: o piso de qualquer aplicação",
        l2="nível 2", l2b="+183, 253 no total: dados pessoais, o portal da Vereda",
        l3="nível 3", l3b="+92, todos os 345: onde a falha custa mais",
        lv_cap="Os níveis são cumulativos. Um portal com dados de saúde busca o nível 2 e cumpre o nível 1 primeiro.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l20-levels", 720, 250, t["lv_aria"])
    f.rect(20, 14, 680, 222, stroke="paper-dim")
    f.text(40, 34, t["l3"], anchor="start", bold=True)
    f.text(40, 52, t["l3b"], anchor="start", fill="paper-dim", size=9.5)
    f.rect(60, 70, 600, 150, stroke="phosphor")
    f.text(80, 90, t["l2"], anchor="start", bold=True)
    f.text(80, 108, t["l2b"], anchor="start", fill="paper-dim", size=9.5)
    f.rect(100, 126, 520, 80, stroke="amber")
    f.text(120, 150, t["l1"], anchor="start", bold=True)
    f.text(120, 172, t["l1b"], anchor="start", fill="paper-dim", size=9.5)
    out["l20-levels"] = f.json(t["lv_cap"])
    return out
