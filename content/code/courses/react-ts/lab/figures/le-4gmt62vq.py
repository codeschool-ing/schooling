from fig import Fig

tl = Fig("timeline", 720, 225,
         {"en": "A timeline of two renders. Render 1, commit 1, then effect 1 runs. Later monday changes: render 2, "
                "commit 2, then cleanup 1 runs with render 1's values, and only then effect 2. The page has already "
                "changed before each effect runs.",
          "pt": "Uma linha do tempo de duas renderizações. Renderização 1, commit 1, depois o efeito 1 roda. Mais "
                "tarde monday muda: renderização 2, commit 2, depois a limpeza 1 roda com os valores da "
                "renderização 1, e só então o efeito 2. A página já mudou antes de cada efeito rodar."},
         {"en": "An effect runs after its commit; its cleanup runs before the next one.",
          "pt": "Um efeito roda depois do seu commit; a limpeza dele roda antes do próximo."})
tl.line(20, 120, 700, 120, tone="wire")
steps = [(20, "render 1", "wire"), (110, "commit 1", "wire"), (200, "effect 1", "phosphor"),
         (350, "render 2", "wire"), (440, "commit 2", "wire"), (530, "cleanup 1", "amber"), (620, "effect 2", "phosphor")]
for x, label, tone in steps:
    tl.box(x, 104, 80, 32, label, mono=True, tone=tone, text_tone="paper" if tone == "wire" else tone, size=10)
tl.text(320, 160, {"en": "monday changes", "pt": "monday muda"}, anchor="middle", tone="dim", size=10.5)
tl.arrow(320, 150, 320, 124, tone="dim")
tl.path("M 240 104 C 300 40 520 40 570 104", tone="amber", dashed=True, head_at=(560, 92, 570, 104))
tl.text(405, 40, {"en": "undoes what effect 1 started", "pt": "desfaz o que o efeito 1 começou"}, anchor="middle", tone="amber", size=10.5)
tl.text(150, 212, {"en": "the page shows render 1", "pt": "a página mostra a renderização 1"}, anchor="middle", tone="dim", size=10)
tl.line(110, 198, 340, 198, tone="dim")
tl.text(560, 212, {"en": "the page shows render 2", "pt": "a página mostra a renderização 2"}, anchor="middle", tone="dim", size=10)
tl.line(440, 198, 700, 198, tone="dim")

se = Fig("strict-effects", 720, 220,
         {"en": "Strict mode on the first load: effect, cleanup, effect. With a cleanup, the listener count goes 1, 0, "
                "1, and one key press moves one week. Without one, the cleanup step does nothing and the count goes "
                "1, 1, 2, so one key press moves two weeks.",
          "pt": "Strict mode na primeira carga: efeito, limpeza, efeito. Com limpeza, a contagem de listeners vai 1, "
                "0, 1, e uma tecla anda uma semana. Sem limpeza, o passo de limpeza não faz nada e a contagem vai 1, "
                "1, 2, então uma tecla anda duas semanas."},
         {"en": "Strict mode's second run makes a missing cleanup show on the first load.",
          "pt": "A segunda execução do strict mode faz uma limpeza ausente aparecer na primeira carga."})
for row, (title, counts, result, tone) in enumerate([
        ({"en": "with the cleanup", "pt": "com a limpeza"}, ["1", "0", "1"], {"en": "→ one week per press", "pt": "→ uma semana por tecla"}, "phosphor"),
        ({"en": "without it", "pt": "sem ela"}, ["1", "1", "2"], {"en": "→ two weeks per press", "pt": "→ duas semanas por tecla"}, "amber")]):
    y = 40 + row * 90
    se.text(20, y - 12, title, tone=tone, size=11)
    for i, step in enumerate(["effect", "cleanup", "effect"]):
        x = 20 + i * 150
        se.box(x, y, 120, 34, step, mono=True, tone=tone if not (row == 1 and i == 1) else "wire",
               text_tone="paper", dashed=(row == 1 and i == 1))
        se.text(x + 60, y + 50, {"en": f"listeners: {counts[i]}", "pt": f"listeners: {counts[i]}"}, anchor="middle", tone=tone, size=10)
        if i < 2:
            se.arrow(x + 122, y + 17, x + 148, y + 17)
    se.text(480, y + 17, result, tone=tone, size=11)

FIGS = [tl, se]
