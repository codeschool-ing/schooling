from fig import Fig

# JSX, the call it becomes, and the object the call returns.
j = Fig("jsx-call", 720, 200,
        {"en": "Three stages of one paragraph. On the left the JSX as written, a p element containing the text Week of "
               "and an expression. In the middle the call Vite turns it into, with the type p and a props object "
               "whose children are the text and the expression. On the right the plain object the call returns, "
               "with a type and props, and nothing on the page yet.",
         "pt": "Três etapas de um parágrafo. À esquerda o JSX como escrito, um elemento p com o texto Week of e uma "
               "expressão. No meio a chamada em que o Vite o transforma, com o tipo p e um objeto de props cujos "
               "children são o texto e a expressão. À direita o objeto simples que a chamada devolve, com um tipo e "
               "props, e nada na página ainda."},
        {"en": "JSX is written, the call is what runs, and the object is what React receives.",
         "pt": "O JSX é o que se escreve, a chamada é o que roda, e o objeto é o que o React recebe."})
j.text(110, 24, {"en": "what you write", "pt": "o que você escreve"}, anchor="middle", tone="dim", size=10.5)
j.text(360, 24, {"en": "what runs", "pt": "o que roda"}, anchor="middle", tone="dim", size=10.5)
j.text(610, 24, {"en": "what it returns", "pt": "o que devolve"}, anchor="middle", tone="dim", size=10.5)
j.box(10, 40, 200, 120, (), tone="phosphor")
j.text(22, 70, "<p>", mono=True, tone="phosphor")
j.text(34, 92, "Week of", mono=True, tone="paper")
j.text(34, 114, "{formatWeek(monday)}", mono=True, tone="amber")
j.text(22, 136, "</p>", mono=True, tone="phosphor")
j.arrow(212, 100, 248, 100, tone="wire")
j.box(250, 40, 220, 120, (), tone="wire")
j.text(262, 66, "_jsxDEV(\"p\", {", mono=True, tone="paper")
j.text(274, 88, "children: [", mono=True, tone="paper")
j.text(286, 108, "\"Week of \",", mono=True, tone="paper")
j.text(286, 128, "formatWeek(monday)", mono=True, tone="amber")
j.text(274, 148, "] })", mono=True, tone="paper")
j.arrow(472, 100, 508, 100, tone="wire")
j.box(510, 40, 200, 120, (), tone="wire", dashed=True)
j.text(522, 66, "{ type: \"p\",", mono=True, tone="paper")
j.text(534, 88, "props: {", mono=True, tone="paper")
j.text(546, 108, "children: [", mono=True, tone="paper")
j.text(558, 128, "\"Week of \", \"19 Oct 2026\"", mono=True, tone="amber", size=9.5)
j.text(534, 148, "] } }", mono=True, tone="paper")
j.text(610, 180, {"en": "not on the page yet", "pt": "ainda não está na página"}, anchor="middle", tone="dim", size=10.5)

# The planner's tree of components, with the props each one receives.
t = Fig("tree", 720, 300,
        {"en": "The first screen as a tree. App at the top passes monday and sessions to WeekSummary, and courses and "
               "sessions to CourseList. CourseList draws three CourseCards, each given one course and its sessions. "
               "Each CourseCard draws a Card with a title and children. Arrows point down only.",
         "pt": "A primeira tela como uma árvore. App, no topo, passa monday e sessions para WeekSummary, e courses e "
               "sessions para CourseList. CourseList desenha três CourseCards, cada um com um curso e as sessões dele. "
               "Cada CourseCard desenha um Card com um title e children. As setas só apontam para baixo."},
        {"en": "Props travel down the tree, from the component that has the data to the ones that draw it.",
         "pt": "As props descem pela árvore, do componente que tem os dados para os que os desenham."})
t.box(300, 14, 120, 30, "App", mono=True, tone="phosphor")
t.box(80, 100, 160, 30, "WeekSummary", mono=True, tone="phosphor")
t.box(470, 100, 160, 30, "CourseList", mono=True, tone="phosphor")
t.arrow(330, 44, 170, 100)
t.arrow(390, 44, 550, 100)
t.text(150, 72, "monday, sessions", mono=True, tone="amber", anchor="middle", size=10)
t.text(570, 72, "courses, sessions", mono=True, tone="amber", anchor="middle", size=10)
for i, x in enumerate((330, 470, 610)):
    t.box(x - 60, 186, 120, 30, "CourseCard", mono=True, tone="phosphor")
    t.arrow(550, 130, x, 186)
    t.box(x - 40, 256, 80, 28, "Card", mono=True, tone="wire", text_tone="paper")
    t.arrow(x, 216, x, 256)
t.text(380, 160, "course, sessions", mono=True, tone="amber", anchor="middle", size=10)
t.text(258, 238, "title, children", mono=True, tone="amber", anchor="middle", size=10)
t.text(60, 200, {"en": "one per course", "pt": "um por curso"}, tone="dim", size=10.5)
t.line(150, 200, 262, 200, tone="wire", dashed=True)

# Card's hole, filled by the parent.
s = Fig("slot", 720, 210,
        {"en": "Card drawn as a frame with a heading and an empty slot labelled children. On the right, CourseCard "
               "writes a paragraph between Card's tags, and an arrow shows the paragraph landing in the slot. Card "
               "decides where the slot is; the parent decides what fills it.",
         "pt": "Card desenhado como uma moldura com um título e um espaço vazio chamado children. À direita, "
               "CourseCard escreve um parágrafo entre as tags de Card, e uma seta mostra o parágrafo caindo no "
               "espaço. Card decide onde fica o espaço; o pai decide o que o preenche."},
        {"en": "The child decides where; the parent decides what.", "pt": "O filho decide onde; o pai decide o quê."})
s.text(150, 22, {"en": "Card: the frame", "pt": "Card: a moldura"}, anchor="middle", tone="dim", size=10.5)
s.box(30, 36, 240, 150, (), tone="phosphor", fill="panel")
s.text(46, 60, "<article>", mono=True, tone="phosphor")
s.text(58, 84, "<h2>{title}</h2>", mono=True, tone="paper")
s.box(58, 100, 190, 52, "{children}", mono=True, tone="amber", dashed=True, fill=None)
s.text(46, 172, "</article>", mono=True, tone="phosphor")
s.text(520, 22, {"en": "CourseCard: what goes in", "pt": "CourseCard: o que vai dentro"}, anchor="middle", tone="dim", size=10.5)
s.box(380, 36, 300, 150, (), tone="wire")
s.text(396, 64, "<Card title={course.name}>", mono=True, tone="paper")
s.box(408, 84, 250, 54, (), tone="amber", fill="ink")
s.text(420, 104, "<p>2 sessions · 90 min</p>", mono=True, tone="amber")
s.text(396, 162, "</Card>", mono=True, tone="paper")
s.path("M 408 111 C 330 111 330 126 250 126", tone="amber", head_at=(330, 120, 250, 126))

FIGS = [j, t, s]
