from fig import Canvas


def workshop(T):
    c = Canvas(720, 220, T(
        "Left: the app at one moment shows the session row in one state, not done, light theme. Right: the "
        "workshop shows the same row in every written state, to do, done and long, each in the light and the dark "
        "theme, six frames side by side.",
        "À esquerda: o app num momento mostra a linha de sessão num estado, não feita, tema claro. À direita: a "
        "oficina mostra a mesma linha em todo estado escrito, to do, done e long, cada um no tema claro e no "
        "escuro, seis quadros lado a lado."))
    c.text(20, 20, T("the app, this week", "o app, nesta semana"), anchor="start", size=10.5, weight="600")
    c.rect(20, 34, 200, 150, fill="var(--panel)")
    c.text(32, 56, "JavaScript", size=11, anchor="start", weight="600")
    c.text(32, 84, "10-15 · 45 min", mono=True, size=9.5, anchor="start")
    c.rect(132, 74, 76, 20, fill="var(--ink)", stroke="var(--phosphor)", rx=3)
    c.text(170, 84, "Mark done", size=9, fill="var(--phosphor)")
    c.text(32, 120, T("one state,", "um estado,"), size=10, anchor="start", fill="var(--paper-dim)")
    c.text(32, 136, T("whatever the data holds", "o que os dados tiverem"), size=10, anchor="start", fill="var(--paper-dim)")
    c.text(260, 20, T("the workshop", "a oficina"), anchor="start", size=10.5, weight="600")
    states = [("To Do", "45 min", True), ("Done", "45 min · done", False), ("Long", "2 h 15 min", True)]
    for i, (name, text, button) in enumerate(states):
        for j, theme in enumerate(["light", "dark"]):
            x = 260 + i * 150
            y = 34 + j * 80
            dark = theme == "dark"
            c.rect(x, y, 140, 66, fill="var(--ink)" if dark else "var(--panel)", stroke="var(--phosphor)" if dark else "var(--wire)")
            c.text(x + 10, y + 14, f"{name} · {theme}", mono=True, size=9, anchor="start", fill="var(--paper-dim)")
            c.text(x + 10, y + 40, text, mono=True, size=9.5, anchor="start")
    c.text(260, 200, T("every state written down, in every theme", "todo estado por escrito, em todo tema"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("The app shows the states its data happens to hold; the workshop shows every state somebody wrote down.",
                  "O app mostra os estados que os dados dele por acaso têm; a oficina mostra todo estado que alguém escreveu.")
    return c


def grid(T):
    c = Canvas(720, 230, T(
        "Five stories down the side and two themes across the top make ten tests. Each test opens the story's frame, "
        "compares a screenshot with the approved picture, and runs axe on it.",
        "Cinco stories na lateral e dois temas no topo fazem dez testes. Cada teste abre o quadro da story, compara "
        "uma captura de tela com a imagem aprovada e roda o axe nela."))
    stories = ["session-row--to-do", "session-row--done", "session-row--long", "week-summary--in-progress", "week-summary--empty"]
    c.text(270, 18, "light", mono=True, size=10)
    c.text(400, 18, "dark", mono=True, size=10)
    for i, s in enumerate(stories):
        y = 40 + i * 34
        c.text(20, y + 11, s, mono=True, size=9.5, anchor="start")
        for j in range(2):
            x = 215 + j * 130
            c.rect(x, y, 110, 24, fill="var(--panel)")
            c.text(x + 30, y + 12, T("picture", "foto"), size=9, fill="var(--phosphor)")
            c.text(x + 80, y + 12, "axe", mono=True, size=9, fill="var(--phosphor)")
    c.rect(500, 50, 200, 130, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(600, 76, T("each test", "cada teste"), size=10.5, weight="600")
    c.text(515, 104, T("1. open the frame", "1. abrir o quadro"), size=10, anchor="start")
    c.text(515, 128, T("2. compare the picture", "2. comparar a foto"), size=10, anchor="start")
    c.text(515, 152, T("3. run axe, expect none", "3. rodar o axe, nenhuma falha"), size=10, anchor="start")
    c.text(20, 222, T("5 stories × 2 themes = 10 tests", "5 stories × 2 temas = 10 testes"), size=10, anchor="start", fill="var(--paper-dim)")
    c.caption = T("Every story in every theme is a test that already knows what it should look like.",
                  "Toda story em todo tema é um teste que já sabe como deve parecer.")
    return c


FIGURES = [("why-a-workshop", workshop), ("stories-as-tests", grid)]
