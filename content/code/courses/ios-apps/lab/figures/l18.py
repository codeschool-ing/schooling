"""Lesson 18 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-3te3nemz"
f = Fig("l18-states", 720, 290,
        "The four states of a permission. It starts as notDetermined. The app's request shows the system alert, once; Allow leads to authorized and Don't Allow to denied. From denied, only the person can go back, by turning the switch on in the Settings app. A fourth state, restricted, is set by someone else, a parent's Screen Time or a device manager, and the app cannot lead the person out of it.",
        "Os quatro estados de uma permissão. Ela começa como notDetermined. O pedido do app mostra o alerta do sistema, uma vez; Permitir leva a authorized e Não Permitir a denied. De denied, só a pessoa volta, ligando a chave no app Ajustes. Um quarto estado, restricted, é definido por outra pessoa, o Tempo de Uso de um responsável ou um gerenciador do aparelho, e o app não tem como tirar a pessoa dele.")
f.box(20, 110, 150, 50, stroke="amber")
f.text(95, 128, "notDetermined", mono=True, size=11, fill="amber", weight="600")
f.text(95, 146, "nobody has asked", "ninguém perguntou", size=10, fill="paper-dim")
f.box(250, 95, 170, 80, stroke="wire", fill="ink")
f.text(335, 115, "the system alert", "o alerta do sistema", size=11, fill="paper", weight="600")
f.text(335, 135, "your usage string", "a sua frase de uso", size=10, fill="paper-dim")
f.text(335, 153, "shown once", "mostrado uma vez", size=10, fill="paper-dim")
f.line(170, 135, 248, 135, color="amber")
f.text(209, 122, "request", "pedido", size=10, fill="amber")
f.box(510, 30, 180, 50, stroke="phosphor")
f.text(600, 48, "authorized", mono=True, size=11, fill="phosphor", weight="600")
f.text(600, 66, "the camera opens", "a câmera abre", size=10, fill="paper-dim")
f.box(510, 190, 180, 50, stroke="wire")
f.text(600, 208, "denied", mono=True, size=11, fill="paper", weight="600")
f.text(600, 226, "a sentence and Settings", "uma frase e os Ajustes", size=10, fill="paper-dim")
f.path("M420 115 L508 60", color="phosphor")
f.text(455, 76, "Allow", "Permitir", size=10, fill="phosphor")
f.path("M420 155 L508 210", color="wire")
f.text(448, 198, "Don't Allow", "Não Permitir", size=10, fill="paper-dim")
f.path("M690 205 C 715 160, 715 110, 692 70", color="paper-dim", dashed=True)
f.text(640, 138, "the person, in Settings", "a pessoa, nos Ajustes", size=10, fill="paper-dim")
f.box(20, 220, 300, 50, stroke="wire", dashed=True)
f.text(170, 238, "restricted", mono=True, size=11, fill="paper", weight="600")
f.text(170, 256, "set by somebody else; no way out from the app", "definido por outra pessoa; o app não tira dele", size=10, fill="paper-dim")
f.write(lesson(L, "the-denied-path"),
        "The app can move a permission out of notDetermined once. After that, only the person can change it, and only in Settings.",
        "O app tira uma permissão de notDetermined uma vez. Depois disso, só a pessoa a muda, e só nos Ajustes.")
