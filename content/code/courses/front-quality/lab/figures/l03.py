"""Lesson 3: what the accessibility tree holds for the form, before and after."""
from fig import Fig

T = {
    "en": dict(
        aria="Two versions of the planner's Minutes field, each shown as markup on the left and as what the accessibility tree holds on the right. Before: an input with placeholder Minutes and no label; the tree holds a spinbutton whose name is taken from the placeholder as a last resort, and getByLabelText finds nothing. After: the same input inside a label that says Minutes; the tree holds a spinbutton named Minutes, from the label, and both getByLabelText and a screen reader find it.",
        markup="the markup", tree="the accessibility tree", query="getByLabelText(\"Minutes\")",
        before="before", after="after",
        b_tree=["spinbutton", "name: \"Minutes\", from the placeholder,", "a last resort, and hidden once you type"],
        a_tree=["spinbutton", "name: \"Minutes\", from the label"],
        none="nothing found", found="the field",
        cap="The tree is what a screen reader reads and what the queries ask. A label gives the field a name that stays; a placeholder lends it one until the first key.",
    ),
    "pt": dict(
        aria="Duas versões do campo Minutes do planner, cada uma mostrada como marcação à esquerda e como o que a árvore de acessibilidade guarda à direita. Antes: um input com placeholder Minutes e sem rótulo; a árvore guarda um spinbutton cujo nome vem do placeholder como último recurso, e o getByLabelText não acha nada. Depois: o mesmo input dentro de um label que diz Minutes; a árvore guarda um spinbutton chamado Minutes, vindo do rótulo, e tanto o getByLabelText quanto um leitor de tela o acham.",
        markup="a marcação", tree="a árvore de acessibilidade", query="getByLabelText(\"Minutes\")",
        before="antes", after="depois",
        b_tree=["spinbutton", "nome: \"Minutes\", do placeholder,", "último recurso, e some da tela ao digitar"],
        a_tree=["spinbutton", "nome: \"Minutes\", do rótulo"],
        none="nada encontrado", found="o campo",
        cap="A árvore é o que um leitor de tela lê e o que as buscas perguntam. Um rótulo dá ao campo um nome que fica; um placeholder empresta um até a primeira tecla.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l03-names", 720, 260, t["aria"])
    f.text(170, 20, t["markup"], bold=True, size=9.5)
    f.text(450, 20, t["tree"], bold=True, size=9.5)
    f.text(640, 20, t["query"], mono=True, size=8.5, fill="paper-dim")
    rows = [
        (t["before"], ['<input name="minutes"', '  type="number"', '  placeholder="Minutes">'], t["b_tree"], t["none"], "amber"),
        (t["after"], ['<label>Minutes', '  <input name="minutes"', '    type="number"></label>'], t["a_tree"], t["found"], "phosphor"),
    ]
    for i, (label, code, tree, result, colour) in enumerate(rows):
        y = 40 + i * 110
        f.text(14, y + 45, label, anchor="start", bold=True, size=9.5)
        f.box(70, y, 200, 90, code, mono=True, size=9, anchor="start")
        f.box(330, y, 240, 90, tree, size=9, stroke=colour)
        f.arrow([(270, y + 45), (330, y + 45)])
        f.arrow([(570, y + 45), (595, y + 45)])
        f.box(595, y + 25, 110, 40, [result], stroke=colour, size=9.5)
    return {"l03-names": f.json(t["cap"], same=["spinbutton"] if lang == "pt" else None)}
