"""Lesson 9 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-ge3nxacc"
f = Fig("l09-path", 720, 300,
        "On the left, a stack of three screens drawn as overlapping cards: the root, CourseListView, which is not in the path; above it the SQL course; on top, session s3. On the right, the path array, model.path, with two elements, .course(id: \"sql\") at index 0 and .session(id: \"s3\") at index 1, each joined by a line to the screen it pushes. Below, the operations: a tap appends, back removes the last element, and a deep link assigns the whole array.",
        "À esquerda, uma pilha de três telas desenhadas como cartões sobrepostos: a raiz, CourseListView, que não está no path; acima dela o curso de SQL; no topo, a sessão s3. À direita, o array do path, model.path, com dois elementos, .course(id: \"sql\") no índice 0 e .session(id: \"s3\") no índice 1, cada um ligado por uma linha à tela que empilha. Embaixo, as operações: um toque acrescenta, voltar remove o último elemento, e um deep link atribui o array inteiro.")
cards = [(40, 150, "CourseListView", "the root, not in the path", "a raiz, fora do path", "wire"),
         (70, 100, "CourseDetailView", "course sql", "curso sql", "wire"),
         (100, 50, "SessionDetailView", "session s3, on top", "sessão s3, no topo", "phosphor")]
for x, y, name, en, pt, col in cards:
    f.box(x, y, 250, 44, stroke=col)
    f.text(x + 125, y + 15, name, mono=True, size=11, fill="paper", weight="600")
    f.text(x + 125, y + 32, en, pt, size=10, fill="paper-dim")
f.text(560, 30, "model.path", mono=True, size=12, fill="amber", weight="600")
f.box(440, 50, 240, 40, stroke="amber")
f.text(452, 70, "1", mono=True, size=10, fill="paper-dim", anchor="start")
f.text(570, 70, ".session(id: \"s3\")", mono=True, size=11, fill="paper")
f.box(440, 100, 240, 40, stroke="amber")
f.text(452, 120, "0", mono=True, size=10, fill="paper-dim", anchor="start")
f.text(570, 120, ".course(id: \"sql\")", mono=True, size=11, fill="paper")
f.line(440, 70, 354, 72, color="amber")
f.line(440, 120, 324, 122, color="amber")
ops = [("tap a link", "tocar num link", "path.append(…)"),
       ("back", "voltar", "path.removeLast()"),
       ("deep link", "deep link", "path = […]")]
for i, (en, pt, code) in enumerate(ops):
    y = 182 + i * 36
    f.text(440, y, en, pt, size=10, fill="paper-dim", anchor="start")
    f.text(540, y, code, mono=True, size=10, fill="phosphor", anchor="start")
f.write(lesson(L, "the-path"),
        "The path holds one value per pushed screen, the root excluded. Navigating is changing the array: append to push, remove the last to go back, assign it to jump.",
        "O path guarda um valor por tela empilhada, sem contar a raiz. Navegar é mudar o array: acrescentar para empilhar, remover o último para voltar, atribuir para pular.")
