from fig import Fig

d = Fig("drilling", 720, 230,
        {"en": "The planner's tree before this lesson. toggleDone travels from usePlanner to App and from App to "
               "CourseScreen as onToggle, where a checkbox uses it. onOpen travels from App through CourseList, which "
               "does not use it, to CourseCard, which does. The components that only pass a prop on are marked.",
         "pt": "A árvore do planejador antes desta aula. O toggleDone vai do usePlanner ao App, e do App ao "
               "CourseScreen como onToggle, onde uma caixa de marcação o usa. O onOpen vai do App pelo CourseList, que "
               "não o usa, até o CourseCard, que usa. Os componentes que só repassam uma prop estão marcados."},
        {"en": "Prop drilling: a value passed through components that only hand it on.",
         "pt": "Prop drilling: um valor passado por componentes que só o repassam."})
d.box(290, 14, 140, 30, "App", mono=True, tone="phosphor")
d.box(90, 90, 170, 30, "CourseScreen", mono=True, tone="phosphor")
d.box(460, 90, 170, 30, "CourseList", mono=True, tone="amber", dashed=True)
d.box(90, 170, 170, 30, "<input checkbox>", mono=True, tone="phosphor")
d.box(460, 170, 170, 30, "CourseCard", mono=True, tone="phosphor")
d.arrow(330, 44, 175, 90, tone="phosphor")
d.text(200, 62, "onToggle", mono=True, tone="phosphor", anchor="end", size=10)
d.arrow(175, 120, 175, 170, tone="phosphor")
d.arrow(390, 44, 545, 90, tone="amber")
d.text(520, 62, "onOpen", mono=True, tone="amber", size=10)
d.arrow(545, 120, 545, 170, tone="amber")
d.text(640, 105, {"en": "only passes it on", "pt": "só repassa"}, tone="amber", size=10.5)
d.text(360, 222, {"en": "solid: uses the prop · dashed: only hands it down", "pt": "contínuo: usa a prop · tracejado: só passa adiante"},
       anchor="middle", tone="dim", size=10.5)

c = Fig("context-cost", 720, 230,
        {"en": "PlannerProvider holds one value with status, courses, sessions and toggleDone. App reads status, courses "
               "and sessions; CourseScreen reads sessions and toggleDone. When sessions change, a new value is made and "
               "both readers render again. A store with selectors lets each reader subscribe to its own slice.",
         "pt": "O PlannerProvider guarda um valor com status, courses, sessions e toggleDone. O App lê status, courses e "
               "sessions; o CourseScreen lê sessions e toggleDone. Quando as sessões mudam, um valor novo é criado e "
               "os dois leitores renderizam de novo. Um store com seletores deixa cada leitor se inscrever na própria fatia."},
        {"en": "Context has one value; every reader renders when it changes.",
         "pt": "O context tem um valor só; todo leitor renderiza quando ele muda."})
c.box(200, 14, 320, 56, ["PlannerProvider", "{ status, courses, sessions, toggleDone }"], mono=True, tone="phosphor", size=10)
c.box(60, 140, 220, 44, ["App", "status · courses · sessions"], mono=True, tone="amber", size=10)
c.box(440, 140, 220, 44, ["CourseScreen", "sessions · toggleDone"], mono=True, tone="amber", size=10)
c.arrow(300, 70, 170, 140, tone="amber")
c.arrow(420, 70, 550, 140, tone="amber")
c.text(360, 112, {"en": "sessions changed: both render", "pt": "sessions mudou: os dois renderizam"}, anchor="middle", tone="amber", size=10.5)
c.text(360, 214, {"en": "with a store, each reader subscribes to its own slice", "pt": "com um store, cada leitor se inscreve na própria fatia"},
       anchor="middle", tone="dim", size=10.5)

FIGS = [d, c]
