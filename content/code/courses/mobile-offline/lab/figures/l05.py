"""Lesson 5: every path to the latest version."""
from fig import Fig

T = {
    "en": dict(
        aria="Four versions of the planner's database, v1 to v4, joined by steps 2, 3 and 4. A phone found at v1 runs steps 2, 3 and 4; one at v2 runs steps 3 and 4; one at v3 runs step 4; a new install runs every step from an empty file. An update that runs only step 4 fails from v1 and v2, because step 4 needs the synced column step 3 made.",
        new="new install", p1="phone at v1", p2="phone at v2", p3="phone at v3",
        step="step", naive="only step 4, from v1 or v2: no such column: synced",
        cap="Every version that shipped is a starting point. The test builds each one and migrates it; the shortcut that runs only the newest step fails on every phone that skipped one.",
    ),
    "pt": dict(
        aria="Quatro versões do banco do planner, de v1 a v4, ligadas pelos passos 2, 3 e 4. Um celular encontrado em v1 roda os passos 2, 3 e 4; um em v2 roda os passos 3 e 4; um em v3 roda o passo 4; uma instalação nova roda todos os passos a partir de um arquivo vazio. Uma atualização que roda só o passo 4 falha a partir de v1 e de v2, porque o passo 4 precisa da coluna synced que o passo 3 criou.",
        new="instalação nova", p1="celular em v1", p2="celular em v2", p3="celular em v3",
        step="passo", naive="só o passo 4, de v1 ou v2: no such column: synced",
        cap="Toda versão publicada é um ponto de partida. O teste constrói cada uma e a migra; o atalho que roda só o passo mais novo falha em todo celular que pulou um.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l05-paths", 720, 270, t["aria"])
    xs = [150, 290, 430, 570]
    f.box(20, 30, 100, 36, ["0"], stroke="wire", mono=True, dashed=True)
    for i, x in enumerate(xs):
        f.box(x, 30, 100, 36, [f"v{i + 1}"], stroke="phosphor" if i == 3 else "wire", mono=True, bold=True)
    starts = [20] + xs
    for i in range(4):
        a = starts[i] + 100
        b = xs[i]
        f.arrow([(a, 48), (b, 48)])
        f.text(round((a + b) / 2, 1), 22, f"{t['step']} {i + 1}", size=9, fill="paper-dim")
    rows = [(t["new"], 0), (t["p1"], 1), (t["p2"], 2), (t["p3"], 3)]
    for n, (label, start) in enumerate(rows):
        y = 100 + n * 30
        f.text(20, y, label, anchor="start", size=9.5, fill="paper")
        x_from = max(starts[start] + 50, 130)
        f.arrow([(x_from, y), (620, y)], color="phosphor")
    f.text(20, 236, t["naive"], anchor="start", size=9.5, fill="amber", italic=True)
    return {"l05-paths": f.json(t["cap"])}
