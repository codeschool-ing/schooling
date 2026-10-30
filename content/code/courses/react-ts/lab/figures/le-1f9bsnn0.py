from fig import Fig

rows = [
    ({"en": "drawing the screen", "pt": "desenhar a tela"}, "react", "@angular/core"),
    ({"en": "state in a component", "pt": "estado num componente"}, "react", "@angular/core"),
    ({"en": "which address, which screen", "pt": "qual endereço, qual tela"}, "react-router · 17", "@angular/router"),
    ({"en": "data from a server", "pt": "dados de um servidor"}, "@tanstack/react-query · 11", "@angular/common/http"),
    ({"en": "forms and validation", "pt": "formulários e validação"}, "react-hook-form · 10", "@angular/forms"),
    ({"en": "build and dev server", "pt": "build e servidor de dev"}, "vite · 20", "@angular/cli"),
    ({"en": "tests", "pt": "testes"}, "vitest · 22", "@angular/cli"),
]

f = Fig("who-decides", 720, 340,
        {"en": "Seven jobs an app needs, from drawing the screen to running tests. In a React project only the first two "
               "come from the react package, and the other five are packages chosen separately, each with the lesson of "
               "this course that adds it. In an Angular project all seven come from Angular's own packages, inside one boundary.",
         "pt": "Sete tarefas de que um app precisa, de desenhar a tela a rodar testes. Num projeto React só as duas primeiras "
               "vêm do pacote react, e as outras cinco são pacotes escolhidos à parte, cada um com a aula deste curso que o "
               "acrescenta. Num projeto Angular as sete vêm dos pacotes do próprio Angular, dentro de uma fronteira só."},
        {"en": "Who decides each job. The numbers are the lessons of this course that add each piece.",
         "pt": "Quem decide cada tarefa. Os números são as aulas deste curso que acrescentam cada peça."})

f.text(330, 26, {"en": "a React project", "pt": "um projeto React"}, anchor="middle", tone="phosphor", size=12)
f.text(600, 26, {"en": "an Angular project", "pt": "um projeto Angular"}, anchor="middle", tone="amber", size=12)
top = 50
step = 38
# React: the react package holds the first two rows; the rest are separate choices.
f.box(222, top - 6, 216, step * 2 + 2, (), tone="phosphor", fill=None, stroke=1.6)
f.box(482, top - 6, 236, step * len(rows) + 2, (), tone="amber", fill=None, stroke=1.6)
for i, (label, react, angular) in enumerate(rows):
    y = top + i * step
    f.text(12, y + 13, label)
    if i < 2:
        f.box(230, y, 200, 26, react, mono=True, tone="phosphor")
    else:
        f.box(230, y, 200, 26, react, mono=True, tone="wire", dashed=True, text_tone="paper")
    f.box(490, y, 220, 26, angular, mono=True, tone="amber")
f.text(330, top + step * len(rows) + 12, {"en": "dashed: a package you choose", "pt": "tracejado: um pacote que você escolhe"},
       anchor="middle", tone="dim", size=10.5)

FIGS = [f]

# The planner's two screens. What the app itself says is English in both
# languages, because the app is written in English; only the notes around the
# screens are translated.
s = Fig("screens", 720, 330,
        {"en": "The planner's two screens. On the left, the list of courses: the heading Study planner, the week of "
               "19 October 2026 with 80 of 195 minutes done, and three courses with their sessions and minutes that "
               "week. Choosing Statistics opens the screen on the right: a link back to the courses, the Statistics "
               "heading, its two sessions with a box to tick each, and a form with a date, minutes and an Add session button.",
         "pt": "As duas telas do planejador. À esquerda, a lista de cursos: o título Study planner, a semana de 19 de "
               "outubro de 2026 com 80 de 195 minutos feitos, e três cursos com suas sessões e minutos naquela semana. "
               "Escolher Statistics abre a tela da direita: um link de volta aos cursos, o título Statistics, as duas "
               "sessões com uma caixa para marcar cada uma, e um formulário com data, minutos e um botão Add session."},
        {"en": "What the planner shows, in every course of the fork. The app's own words are English in both languages.",
         "pt": "O que o planejador mostra, em todos os cursos da bifurcação. As palavras do próprio app são em inglês nas duas línguas."})
# screen 1
s.box(10, 40, 330, 250, (), tone="wire", fill="panel")
s.text(20, 22, {"en": "1 · the courses", "pt": "1 · os cursos"}, tone="dim", size=10.5)
s.text(26, 64, "Study planner", tone="phosphor", size=13, weight="600")
s.text(26, 88, "Week of 19 Oct 2026", tone="paper", size=11)
s.text(26, 106, "80 of 195 minutes done", tone="paper", size=11)
rows = [("Statistics", "2 sessions · 90 min"), ("Spanish", "2 sessions · 60 min"),
        ("Organic chemistry", "1 session · 45 min")]
for i, (name, info) in enumerate(rows):
    y = 128 + i * 48
    s.box(22, y, 306, 38, (), tone="phosphor" if i == 0 else "wire", fill="ink")
    s.text(34, y + 13, name, tone="phosphor", size=11.5)
    s.text(34, y + 28, info, tone="dim", size=10.5)
# screen 2
s.box(380, 40, 330, 250, (), tone="wire", fill="panel")
s.text(390, 22, {"en": "2 · one course", "pt": "2 · um curso"}, tone="dim", size=10.5)
s.text(396, 64, "Back to courses", tone="phosphor", size=11)
s.text(396, 90, "Statistics", tone="paper", size=13, weight="600")
for i, (box, txt) in enumerate([("[x]", "Mon 19 Oct · 50 min"), ("[ ]", "Wed 21 Oct · 40 min")]):
    y = 116 + i * 26
    s.text(396, y, box, mono=True, tone="phosphor")
    s.text(424, y, txt, tone="paper", size=11)
s.line(392, 170, 698, 170, tone="wire")
s.text(396, 190, "Add a session", tone="paper", size=11, weight="600")
s.text(396, 214, "Date", tone="dim", size=10.5)
s.box(450, 203, 110, 22, "2026-10-24", mono=True, tone="wire", text_tone="paper")
s.text(396, 242, "Minutes", tone="dim", size=10.5)
s.box(450, 231, 60, 22, "30", mono=True, tone="wire", text_tone="paper")
s.box(396, 260, 104, 22, "Add session", tone="phosphor", fill="ink")
s.arrow(330, 147, 380, 147, tone="phosphor")

FIGS.append(s)
