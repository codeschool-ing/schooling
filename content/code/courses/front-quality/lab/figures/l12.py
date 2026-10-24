"""Lesson 12: the page and its accessibility tree side by side, and how an image's alt is decided."""
from fig import Fig

T = {
    "en": dict(
        tree_aria="Two columns. On the left, the top of the planner's course page as it is drawn: an arrow, the heading JavaScript, a session row with a Done button. On the right, the same elements as the accessibility tree describes them, each as a role, a name and a state: a link named with the arrow, a heading named JavaScript at level 1, a list item holding the text 2026-10-22 · 30 min and a button named Done. Arrows join each drawn element to its line in the tree. A note says that a screen reader reads only the right-hand column.",
        seen="what is drawn", told="what the tree says",
        rows=[("link", "\"←\"", ""), ("heading", "\"JavaScript\"", "level 1"), ("button", "\"Done\"", "")],
        cols=["role", "name", "state"],
        note="a screen reader reads only this column",
        tree_cap="The page and its accessibility tree. The tree is built by the browser from the HTML, and it is all a screen reader has: here it names the back link with a symbol.",
        alt_aria="A decision diagram for an image's alt text. First question: does the image say something the text around it does not? If no, it is decorative: alt is empty. If yes, second question: is it the only thing inside a link or a button? If yes, alt says what the control does or where it goes. If no, third question: is it text? If yes, alt is that text. If no, fourth question: is it a chart or a diagram? If yes, alt is a short summary, with the full content in text nearby. If no, alt says what the image tells the reader, briefly.",
        q=["Does it say something the text does not?", "Is it alone inside a link or a button?", "Is it text?", "Is it a chart or a diagram?"],
        a=["alt=\"\": decorative", "what the control does", "the text itself", "a summary, and the data nearby", "what it tells, briefly"],
        yes="yes", no="no",
        alt_cap="One question at a time, asked of the image where it is. The same picture can be informative on one page and decorative on another.",
    ),
    "pt": dict(
        tree_aria="Duas colunas. À esquerda, o alto da página de curso do planner como ele é desenhado: uma seta, o título JavaScript, uma linha de sessão com um botão Done. À direita, os mesmos elementos como a árvore de acessibilidade os descreve, cada um como um papel, um nome e um estado: um link chamado pela seta, um título chamado JavaScript no nível 1, um item de lista com o texto 2026-10-22 · 30 min e um botão chamado Done. Setas ligam cada elemento desenhado à sua linha na árvore. Uma nota diz que um leitor de tela lê só a coluna da direita.",
        seen="o que é desenhado", told="o que a árvore diz",
        rows=[("link", "\"←\"", ""), ("heading", "\"JavaScript\"", "level 1"), ("button", "\"Done\"", "")],
        cols=["papel", "nome", "estado"],
        note="um leitor de tela lê só esta coluna",
        tree_cap="A página e a sua árvore de acessibilidade. A árvore é construída pelo navegador a partir do HTML, e é tudo o que um leitor de tela tem: aqui ela nomeia o link de voltar com um símbolo.",
        alt_aria="Um diagrama de decisão para o texto alternativo de uma imagem. Primeira pergunta: a imagem diz algo que o texto em volta não diz? Se não, ela é decorativa: o alt é vazio. Se sim, segunda pergunta: ela é a única coisa dentro de um link ou de um botão? Se sim, o alt diz o que o controle faz ou para onde vai. Se não, terceira pergunta: ela é texto? Se sim, o alt é esse texto. Se não, quarta pergunta: ela é um gráfico ou um diagrama? Se sim, o alt é um resumo curto, com o conteúdo completo em texto ali perto. Se não, o alt diz o que a imagem conta a quem lê, em poucas palavras.",
        q=["Ela diz algo que o texto não diz?", "Está sozinha num link ou num botão?", "Ela é texto?", "É um gráfico ou um diagrama?"],
        a=["alt=\"\": decorativa", "o que o controle faz", "o próprio texto", "um resumo, e os dados perto", "o que ela conta, curto"],
        yes="sim", no="não",
        alt_cap="Uma pergunta de cada vez, feita à imagem onde ela está. A mesma figura pode ser informativa numa página e decorativa em outra.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l12-tree", 720, 230, t["tree_aria"])
    f.text(150, 20, t["seen"], size=10, italic=True, fill="paper-dim")
    f.text(520, 20, t["told"], size=10, italic=True, fill="phosphor")
    f.rect(30, 34, 240, 170, stroke="wire", fill="ink")
    f.text(50, 62, "←", size=14, anchor="start")
    f.text(50, 106, "JavaScript", size=15, bold=True, anchor="start")
    f.text(50, 158, "2026-10-22 · 30 min", size=10, anchor="start")
    f.box(185, 146, 56, 24, ["Done"], size=10)
    for i, c in enumerate(t["cols"]):
        f.text(390 + i * 110, 38, c, size=9, italic=True, fill="paper-dim", anchor="start")
    ys = [62, 106, 158]
    for (role, name, state), y in zip(t["rows"], ys):
        f.rect(380, y - 14, 320, 28, stroke="phosphor", fill="panel")
        f.text(390, y, role, mono=True, size=10, anchor="start")
        f.text(500, y, name, mono=True, size=10, anchor="start")
        f.text(610, y, state, mono=True, size=10, anchor="start")
    for y in ys:
        f.arrow([(278, y), (372, y)], dashed=True)
    f.text(540, 200, t["note"], size=9, italic=True, fill="phosphor")
    tree = f.json(t["tree_cap"], same=["JavaScript", "2026-10-22 · 30 min", "Done"] if lang == "pt" else None)

    g = Fig("l12-alt", 720, 320, t["alt_aria"])
    qx, qw, qh = 20, 300, 40
    ax, aw = 430, 270
    for i, q in enumerate(t["q"]):
        y = 16 + i * 66
        g.box(qx, y, qw, qh, [q], stroke="wire", size=10)
        g.arrow([(qx + qw, y + qh / 2), (ax, y + qh / 2)])
        yes_no = t["no"] if i == 0 else t["yes"]
        g.text((qx + qw + ax) / 2, y + qh / 2 - 9, yes_no, size=9, italic=True, fill="paper-dim")
        g.box(ax, y, aw, qh, [t["a"][i]], stroke="phosphor" if i else "amber", mono=(i == 0), size=10)
        if i < 3:
            g.arrow([(qx + qw / 2, y + qh), (qx + qw / 2, y + 66)])
            g.text(qx + qw / 2 + 10, y + qh + 13, t["yes"] if i == 0 else t["no"], size=9, italic=True, fill="paper-dim", anchor="start")
    y = 16 + 3 * 66
    g.arrow([(qx + qw / 2, y + qh), (qx + qw / 2, y + qh + 22)])
    g.text(qx + qw / 2 + 10, y + qh + 11, t["no"], size=9, italic=True, fill="paper-dim", anchor="start")
    g.box(qx, y + qh + 22, qw, 34, [t["a"][4]], stroke="phosphor", size=10)
    return {"l12-tree": tree, "l12-alt": g.json(t["alt_cap"])}
