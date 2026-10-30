from fig import Fig

d = Fig("dialog-sync", 720, 210,
        {"en": "Two directions between React and the dialog. From React: the planning state becomes true, the effect "
               "runs and calls showModal on the element in the ref. From the browser: Escape or the Close button closes "
               "the dialog, the close event fires, onClose sets planning to false, and the effect finds the dialog "
               "already closed.",
         "pt": "Duas direções entre o React e o diálogo. Do React: o estado planning vira true, o efeito roda e chama "
               "showModal no elemento do ref. Do navegador: o Escape ou o botão Close fecham o diálogo, o evento close "
               "dispara, o onClose põe planning em false, e o efeito encontra o diálogo já fechado."},
        {"en": "The prop asks for open or closed; the close event reports what the browser did.",
         "pt": "A prop pede aberto ou fechado; o evento close relata o que o navegador fez."})
d.box(20, 70, 180, 60, ["planning", "true / false"], mono=True, tone="phosphor")
d.box(520, 70, 180, 60, ["<dialog>", "ref.current"], mono=True, tone="amber")
d.arrow(202, 86, 518, 86, tone="phosphor")
d.text(360, 74, "useEffect → showModal() / close()", mono=True, anchor="middle", tone="phosphor", size=10)
d.arrow(518, 116, 202, 116, tone="amber")
d.text(360, 134, "close event → onClose()", mono=True, anchor="middle", tone="amber", size=10)
d.text(610, 160, {"en": "Escape, Close button", "pt": "Escape, botão Close"}, anchor="middle", tone="dim", size=10.5)
d.text(110, 160, {"en": "React's state", "pt": "o estado do React"}, anchor="middle", tone="dim", size=10.5)
d.text(360, 30, {"en": "the browser owns how a modal dialog behaves", "pt": "o navegador é dono de como um diálogo modal se comporta"},
       anchor="middle", tone="dim", size=10.5)

p = Fig("portal", 720, 245,
        {"en": "Two trees side by side. In the React tree, StatusMessage is a child of CourseScreen, inside App, so it "
               "reads the same contexts and its events bubble to CourseScreen. In the DOM tree, body holds the root div, "
               "which holds the page, and the status div is a separate child of body, next to the root.",
         "pt": "Duas árvores lado a lado. Na árvore do React, StatusMessage é filho de CourseScreen, dentro do App, então "
               "lê os mesmos contextos e os eventos dele sobem até CourseScreen. Na árvore do DOM, o body tem a div raiz, "
               "que tem a página, e a div de status é outro filho do body, ao lado da raiz."},
        {"en": "A portal moves the element in the DOM and leaves it in place in React.",
         "pt": "Um portal muda o elemento de lugar no DOM e o deixa no lugar no React."})
p.text(170, 22, {"en": "the React tree", "pt": "a árvore do React"}, anchor="middle", tone="phosphor", size=11.5)
p.box(90, 36, 160, 30, "App", mono=True, tone="wire", text_tone="paper")
p.box(90, 96, 160, 30, "CourseScreen", mono=True, tone="wire", text_tone="paper")
p.box(90, 156, 160, 30, "StatusMessage", mono=True, tone="phosphor")
p.line(170, 66, 170, 96)
p.line(170, 126, 170, 156)
p.text(170, 226, {"en": "contexts, events: through its React parents", "pt": "contextos, eventos: pelos pais no React"},
       anchor="middle", tone="phosphor", size=10.5)
p.text(540, 22, {"en": "the DOM", "pt": "o DOM"}, anchor="middle", tone="amber", size=11.5)
p.box(460, 36, 160, 30, "<body>", mono=True, tone="wire", text_tone="paper")
p.box(380, 96, 150, 30, "<div id=root>", mono=True, tone="wire", text_tone="paper")
p.box(380, 156, 150, 30, "<main> …", mono=True, tone="wire", text_tone="paper")
p.box(560, 96, 150, 30, "<div role=status>", mono=True, tone="amber", size=10)
p.line(540, 66, 455, 96)
p.line(540, 66, 635, 96)
p.line(455, 126, 455, 156)
p.path("M 252 171 C 420 230 650 215 635 128", tone="amber", dashed=True, head_at=(636, 138, 635, 128))
p.text(560, 226, {"en": "position: fixed from <body>, whatever the CSS above", "pt": "position: fixed a partir do <body>, seja qual for o CSS acima"},
       anchor="middle", tone="amber", size=10.5)

FIGS = [d, p]
