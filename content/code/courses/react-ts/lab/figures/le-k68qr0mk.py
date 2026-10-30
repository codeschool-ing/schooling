from fig import Fig

c = Fig("check", 720, 200,
        {"en": "npm run check runs four steps in order, each stopping the rest when it fails: prettier --check for "
               "layout, oxlint for likely mistakes, tsc -b for types, vitest run for behaviour. Git's pre-commit hook "
               "runs it before every commit, and CI runs the same command for every push.",
         "pt": "O npm run check roda quatro passos em ordem, cada um parando o resto quando falha: prettier --check "
               "para o layout, oxlint para erros prováveis, tsc -b para os tipos, vitest run para o comportamento. O "
               "hook pre-commit do git o roda antes de todo commit, e a CI roda o mesmo comando a cada push."},
        {"en": "Fastest first; the first failure stops the rest.",
         "pt": "O mais rápido primeiro; a primeira falha para o resto."})
steps = [("prettier --check", {"en": "layout", "pt": "layout"}),
         ("oxlint", {"en": "likely mistakes", "pt": "erros prováveis"}),
         ("tsc -b", {"en": "types", "pt": "tipos"}),
         ("vitest run", {"en": "behaviour", "pt": "comportamento"})]
for i, (cmd, what) in enumerate(steps):
    x = 14 + i * 176
    c.box(x, 40, 160, 50, [cmd], mono=True, tone="phosphor", size=10.5)
    c.text(x + 80, 108, what, anchor="middle", tone="dim", size=10.5)
    if i < 3:
        c.arrow(x + 162, 65, x + 174, 65)
        c.text(x + 168, 54, "&&", mono=True, anchor="middle", tone="dim", size=9)
c.text(360, 22, "npm run check", mono=True, anchor="middle", tone="phosphor", size=11)
c.text(200, 160, {"en": "before every commit: .git/hooks/pre-commit", "pt": "antes de todo commit: .git/hooks/pre-commit"},
       anchor="middle", tone="amber", size=10.5)
c.text(540, 160, {"en": "on every push: CI, which nobody can skip", "pt": "a cada push: a CI, que ninguém pula"},
       anchor="middle", tone="amber", size=10.5)
FIGS = [c]
