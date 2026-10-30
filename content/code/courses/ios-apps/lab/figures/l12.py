"""Lesson 12 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-sqxtw0zb"

f = Fig("l12-stages", 720, 270,
        "A request goes through three checks from left to right. First: was there an answer at all? If not, the error is offline, or cancelled if the caller stopped waiting. Second: is the status between 200 and 299? If not, the error is status with the code and the server's message. Third: does the body decode as the expected type? If not, the error is unreadable. Only a request that passes all three becomes a value.",
        "Um pedido passa por três conferências da esquerda para a direita. Primeira: houve resposta? Se não, o erro é offline, ou cancelled se quem chamou parou de esperar. Segunda: o status está entre 200 e 299? Se não, o erro é status com o código e a mensagem do servidor. Terceira: o corpo decodifica como o tipo esperado? Se não, o erro é unreadable. Só um pedido que passa pelas três vira um valor.")
f.box(16, 40, 96, 50, stroke="wire")
f.text(64, 65, "request", "pedido", size=12)
gates = [("an answer?", "houve resposta?", ".offline / .cancelled"),
         ("200 to 299?", "200 a 299?", ".status(code, msg)"),
         ("decodes as T?", "decodifica como T?", ".unreadable")]
for i, (en, pt, err) in enumerate(gates):
    x = 150 + i * 150
    f.box(x, 40, 120, 50, stroke="amber")
    f.text(x + 60, 58, en, pt, size=11, fill="paper", weight="600")
    f.text(x + 60, 76, f"stage {i + 1}", f"estágio {i + 1}", size=10, fill="paper-dim")
    f.line(x - (38 if i == 0 else 30), 65, x - 2, 65, color="wire")
    f.line(x + 60, 92, x + 60, 158, color="amber")
    f.text(x + 74, 124, "no", "não", size=10, fill="amber", anchor="start")
    f.box(x - 12, 160, 144, 40, stroke="amber", fill="ink")
    f.text(x + 60, 180, err, mono=True, size=10, fill="amber")
f.line(570, 65, 608, 65, color="phosphor")
f.box(610, 40, 94, 50, stroke="phosphor")
f.text(657, 58, "a value", "um valor", size=11, fill="phosphor", weight="600")
f.text(657, 76, "of type T", "do tipo T", size=10, fill="paper-dim")
f.text(360, 236, "every outcome leaves as exactly one of these", "todo resultado sai como exatamente um destes", size=11, fill="paper-dim")
f.write(lesson(L, "status-codes"),
        "The order is the design: an answer before a status, a status before a decoding. A request reaches the value on the right only by passing all three.",
        "A ordem é o projeto: resposta antes de status, status antes de decodificação. Um pedido só chega ao valor da direita passando pelas três.")

g = Fig("l12-states", 720, 230,
        "Three states of a screen. It starts in loading. From loading it goes either to loaded, with the courses, or to failed, with an APIError. From failed, an arrow labelled try again goes back to loading, and it is drawn only when the error can be retried.",
        "Três estados de uma tela. Ela começa em loading. De loading vai para loaded, com os cursos, ou para failed, com um APIError. De failed, uma seta com o rótulo tentar de novo volta para loading, e ela só é desenhada quando o erro pode ser tentado de novo.")
g.box(60, 80, 150, 60, stroke="wire")
g.text(135, 102, ".loading", mono=True, size=12, fill="paper", weight="600")
g.text(135, 122, "the request is out", "o pedido saiu", size=10, fill="paper-dim")
g.box(470, 20, 190, 60, stroke="phosphor")
g.text(565, 42, ".loaded(courses)", mono=True, size=12, fill="phosphor", weight="600")
g.text(565, 62, "draw the list", "desenhe a lista", size=10, fill="paper-dim")
g.box(470, 140, 190, 60, stroke="amber")
g.text(565, 162, ".failed(error)", mono=True, size=12, fill="amber", weight="600")
g.text(565, 182, "draw the message", "desenhe a mensagem", size=10, fill="paper-dim")
g.line(212, 98, 466, 52, color="phosphor")
g.line(212, 122, 466, 168, color="amber")
g.path("M470 192 C 330 228, 200 214, 140 144", color="paper-dim", dashed=True)
g.text(320, 188, "try again, if canRetry", "tentar de novo, se canRetry", size=10, fill="paper-dim")
g.write(lesson(L, "the-error-state"),
        "One value, three states that exclude each other. The way back from an error exists only where trying again can give a different answer.",
        "Um valor, três estados que se excluem. O caminho de volta de um erro só existe onde tentar de novo pode dar outra resposta.")
