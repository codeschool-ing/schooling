from fig import Fig

a = Fig("anatomy", 720, 200,
        {"en": "The four steps of a component test. Arrange: render the component into jsdom's document, with fake "
               "functions for what it calls. Act: a user, from user-event, clicks and types. Find: queries by role, "
               "label or text, as a person or a screen reader would. Assert: expect what is on the page, or what the "
               "fake functions were called with.",
         "pt": "Os quatro passos de um teste de componente. Preparar: renderizar o componente no documento do jsdom, "
               "com funções falsas para o que ele chama. Agir: um usuário, do user-event, clica e digita. Achar: "
               "consultas por papel, rótulo ou texto, como uma pessoa ou um leitor de tela faria. Afirmar: esperar o "
               "que está na página, ou com que as funções falsas foram chamadas."},
        {"en": "Draw it, use it, find what a person would see, check it.",
         "pt": "Desenhe, use, ache o que uma pessoa veria, confira."})
steps = [({"en": "arrange", "pt": "preparar"}, ["render(…)", "vi.fn()"]),
         ({"en": "act", "pt": "agir"}, ["user.click(…)", "user.type(…)"]),
         ({"en": "find", "pt": "achar"}, ["getByRole(…)", "findByText(…)"]),
         ({"en": "assert", "pt": "afirmar"}, ["toBeInTheDocument()", "toHaveBeenCalledWith"])]
for i, (title, lines) in enumerate(steps):
    x = 14 + i * 176
    a.text(x + 80, 36, title, anchor="middle", tone="phosphor", size=11.5)
    a.box(x, 50, 160, 64, lines, mono=True, tone="phosphor", size=9.5)
    if i < 3:
        a.arrow(x + 162, 82, x + 174, 82)
a.text(360, 150, {"en": "in jsdom: a document with no screen, inside Node.js",
                  "pt": "no jsdom: um documento sem tela, dentro do Node.js"}, anchor="middle", tone="dim", size=10.5)
a.text(360, 176, {"en": "queries by role and name fail when a user would notice", "pt": "consultas por papel e nome falham quando um usuário notaria"},
       anchor="middle", tone="dim", size=10.5)
FIGS = [a]
