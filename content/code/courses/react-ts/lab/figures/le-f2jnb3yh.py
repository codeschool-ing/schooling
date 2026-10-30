from fig import Fig

sp = Fig("split", 720, 220,
         {"en": "Two builds side by side. Before: one JavaScript file of 371 kB, loaded before the first screen. After: "
                "a main file of 262 kB, loaded at once, and a CourseScreen file of 111 kB holding the course screen, "
                "React Hook Form and Zod, loaded when a course is opened.",
          "pt": "Dois builds lado a lado. Antes: um arquivo JavaScript de 371 kB, carregado antes da primeira tela. "
                "Depois: um arquivo principal de 262 kB, carregado na hora, e um arquivo CourseScreen de 111 kB com a "
                "tela do curso, o React Hook Form e o Zod, carregado quando um curso é aberto."},
         {"en": "The form's libraries leave the first download.", "pt": "As bibliotecas do formulário saem do primeiro download."})
sp.text(150, 22, {"en": "before", "pt": "antes"}, anchor="middle", tone="amber", size=11.5)
sp.box(20, 36, 260, 120, ["index-CkcBpHKM.js", "371 kB"], mono=True, tone="amber")
sp.text(150, 176, {"en": "all of it before the first screen", "pt": "tudo antes da primeira tela"}, anchor="middle", tone="dim", size=10.5)
sp.text(520, 22, {"en": "after", "pt": "depois"}, anchor="middle", tone="phosphor", size=11.5)
sp.box(360, 36, 190, 120, ["index-BDKi8Zd8.js", "262 kB"], mono=True, tone="phosphor")
sp.box(570, 36, 130, 54, ["CourseScreen-…js", "111 kB"], mono=True, tone="amber", dashed=True, size=10)
sp.text(635, 108, {"en": "the course screen,", "pt": "a tela do curso,"}, anchor="middle", tone="dim", size=10)
sp.text(635, 124, "react-hook-form, zod", mono=True, anchor="middle", tone="dim", size=9.5)
sp.text(455, 176, {"en": "at once", "pt": "na hora"}, anchor="middle", tone="phosphor", size=10.5)
sp.text(635, 176, {"en": "on the first click", "pt": "no primeiro clique"}, anchor="middle", tone="amber", size=10.5)

su = Fig("suspend", 720, 200,
         {"en": "A timeline of opening a course. The click sets openId; React renders the lazy CourseScreen, whose code "
                "is not there, so it suspends and the nearest Suspense draws its fallback, Loading the course. The file "
                "arrives; React renders again, and the course screen replaces the fallback.",
          "pt": "Uma linha do tempo de abrir um curso. O clique muda o openId; o React renderiza o CourseScreen lazy, cujo "
                "código não está lá, então ele suspende e o Suspense mais próximo desenha a reserva, Loading the course. "
                "O arquivo chega; o React renderiza de novo, e a tela do curso substitui a reserva."},
         {"en": "Not ready means the nearest Suspense draws its fallback until it is.",
          "pt": "Não estar pronto faz o Suspense mais próximo desenhar a reserva até estar."})
steps = [(["click", "setOpenId"], "phosphor", True),
         ([{"en": "lazy part", "pt": "parte lazy"}, {"en": "not loaded", "pt": "não carregada"}], "amber", False),
         ([{"en": "fallback", "pt": "reserva"}, "Loading the course…"], "amber", False),
         (["GET", "CourseScreen-…js"], "dim", True),
         ([{"en": "render again", "pt": "renderiza de novo"}, {"en": "the course", "pt": "o curso"}], "phosphor", False)]
for i, (lines, tone, mono) in enumerate(steps):
    x = 10 + i * 142
    t = "wire" if tone == "dim" else tone
    su.box(x, 40, 130, 54, lines, mono=mono, tone=t, text_tone="paper" if tone == "dim" else None, size=10)
    if i < len(steps) - 1:
        su.arrow(x + 131, 67, x + 141, 67)
su.line(152, 120, 566, 120, tone="amber", dashed=True)
su.text(359, 140, {"en": "the student sees the fallback", "pt": "o estudante vê a reserva"}, anchor="middle", tone="amber", size=10.5)
su.text(643, 140, {"en": "the screen", "pt": "a tela"}, anchor="middle", tone="phosphor", size=10.5)
su.text(360, 180, {"en": "an error on the way goes past Suspense, to the nearest error boundary",
                   "pt": "um erro no caminho passa pelo Suspense e vai ao error boundary mais próximo"},
        anchor="middle", tone="dim", size=10.5)

FIGS = [sp, su]
