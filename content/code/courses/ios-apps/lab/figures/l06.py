"""Lesson 6 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-8t3xr9ay"
f = Fig("l06-truth", 720, 330,
        "One plan, kept as @State by CourseListView, is the source of truth. CourseDetailView receives a binding to it, $plan; each SessionRow receives a binding to one session, $session; and each Toggle receives a binding to that session's done field. A write from a Toggle travels back up the bindings into the one plan. Beside them, the week's total is drawn dashed: it is computed from the plan in body and never stored.",
        "Um plano, guardado como @State pela CourseListView, é a fonte da verdade. A CourseDetailView recebe um binding para ele, $plan; cada SessionRow recebe um binding para uma sessão, $session; e cada Toggle recebe um binding para o campo done dessa sessão. Uma escrita vinda de um Toggle volta pelos bindings até o único plano. Ao lado, o total da semana aparece tracejado: ele é calculado a partir do plano no body e nunca guardado.")
rows = [("CourseListView", "@State private var plan", "owns the value", "é dono do valor", "phosphor"),
        ("CourseDetailView", "@Binding var plan", "is handed $plan", "recebe $plan", "wire"),
        ("SessionRow", "@Binding var session", "is handed $session", "recebe $session", "wire"),
        ("Toggle", "isOn: Binding<Bool>", "is handed $session.done", "recebe $session.done", "wire")]
for i, (name, code, en, pt, col) in enumerate(rows):
    y = 20 + i * 76
    f.box(30, y, 300, 54, stroke=col)
    f.text(180, y + 18, name, mono=True, size=12, fill="paper", weight="600")
    f.text(180, y + 38, code, mono=True, size=10, fill="phosphor" if i == 0 else "paper-dim")
    f.text(345, y + 27, en, pt, size=11, fill="paper-dim", anchor="start")
    if i:
        f.line(130, y, 130, y - 20, color="amber")
f.text(122, 86, "write", "escrita", size=10, fill="amber", anchor="end")
f.box(520, 20, 180, 120, stroke="paper-dim", fill="ink", dashed=True)
f.text(610, 50, "week's total", "total da semana", size=11, fill="paper", weight="600")
f.text(610, 76, "weekTotal(today:)", mono=True, size=10, fill="paper-dim")
f.text(610, 100, "computed in body,", "calculado no body,", size=10, fill="paper-dim")
f.text(610, 118, "never stored", "nunca guardado", size=10, fill="paper-dim")
f.line(450, 47, 516, 70, color="paper-dim", dashed=True)
f.write(lesson(L, "source-of-truth"),
        "One owner keeps the plan. Every view below it is handed a binding, a way to write to the owner's value, and the total is computed from that value rather than kept beside it.",
        "Um dono guarda o plano. Cada view abaixo dele recebe um binding, um jeito de escrever no valor do dono, e o total é calculado a partir desse valor em vez de ficar guardado ao lado.")
