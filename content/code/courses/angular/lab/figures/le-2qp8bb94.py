from fig import Canvas


def outlets(T):
    c = Canvas(720, 300, T(
        "Two nested boxes for the address /courses/javascript/add. The outer box is App, with its heading, its "
        "navigation and a router-outlet. Inside that outlet is CoursePage, drawn for courses/:courseId, with the "
        "course's name, its minutes this week, its own navigation and a router-outlet. Inside that one is "
        "AddSession, drawn for the child path add. Beside each outlet, the part of the address that chose what "
        "fills it.",
        "Duas caixas aninhadas para o endereço /courses/javascript/add. A caixa de fora é o App, com o título, a "
        "navegação e um router-outlet. Dentro desse outlet está o CoursePage, desenhado para courses/:courseId, "
        "com o nome do curso, os minutos da semana, a própria navegação e um router-outlet. Dentro desse está o "
        "AddSession, desenhado para o caminho filho add. Ao lado de cada outlet, a parte do endereço que escolheu "
        "o que o preenche."))
    c.text(360, 18, "/courses/javascript/add", size=11, mono=True)
    c.rect(30, 34, 460, 254, stroke="var(--wire)")
    c.text(44, 50, "App", size=10.5, mono=True, anchor="start")
    c.text(44, 68, T("heading, navigation", "título, navegação"), size=9, anchor="start", fill="var(--paper-dim)")
    c.rect(50, 84, 420, 192, stroke="var(--phosphor)", dash="4 3")
    c.text(62, 98, "<router-outlet>", size=9, mono=True, anchor="start", fill="var(--paper-dim)")
    c.text(62, 116, "CoursePage", size=10.5, mono=True, anchor="start")
    c.text(62, 134, T("name, minutes this week, Sessions | Add sessions", "nome, minutos da semana, Sessions | Add sessions"), size=9, anchor="start", fill="var(--paper-dim)")
    c.rect(72, 150, 376, 110, stroke="var(--amber)", dash="4 3")
    c.text(84, 164, "<router-outlet>", size=9, mono=True, anchor="start", fill="var(--paper-dim)")
    c.text(84, 184, "AddSession", size=10.5, mono=True, anchor="start")
    c.text(84, 202, T("the form", "o formulário"), size=9, anchor="start", fill="var(--paper-dim)")
    # labels to the right
    c.line(470, 116, 520, 116, stroke="var(--phosphor)")
    c.text(528, 112, "courses/:courseId", size=10, mono=True, anchor="start", fill="var(--phosphor)")
    c.text(528, 128, T("javascript → the input", "javascript → o input"), size=9, anchor="start", fill="var(--paper-dim)")
    c.line(448, 184, 520, 184, stroke="var(--amber)")
    c.text(528, 180, "add", size=10, mono=True, anchor="start", fill="var(--amber)")
    c.text(528, 196, T("a child route", "uma rota filha"), size=9, anchor="start", fill="var(--paper-dim)")
    c.caption = T("Each outlet is filled by the route that matched its part of the address; a child route's component sits in its parent's outlet.",
                  "Cada outlet é preenchido pela rota que casou com a parte dele do endereço; o componente de uma rota filha fica no outlet do pai.")
    return c


FIGURES = [("child-routes", outlets)]
