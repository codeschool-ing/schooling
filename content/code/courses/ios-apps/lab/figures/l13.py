"""Lesson 13 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-8b7jat5b"

f = Fig("l13-two-shapes", 720, 300,
        "Two columns. On the left, inside the app target, which builds only on a Mac: CourseRecord and SessionRecord, classes with the Model macro, joined by a relationship, stored by SwiftData in a file on the device. On the right, inside the PlannerCore package, which builds anywhere: the values Course and StudySession, joined by courseID. An arrow labelled value goes from the records to the values, and another labelled insert goes back.",
        "Duas colunas. À esquerda, dentro do target do app, que só compila num Mac: CourseRecord e SessionRecord, classes com a macro Model, ligadas por uma relação, guardadas pelo SwiftData num arquivo no aparelho. À direita, dentro do pacote PlannerCore, que compila em qualquer lugar: os valores Course e StudySession, ligados por courseID. Uma seta chamada value vai dos registros aos valores, e outra chamada insert volta.")
f.box(20, 20, 300, 260, stroke="wire", fill="ink")
f.text(170, 40, "the app target: a Mac only", "o target do app: só num Mac", size=11, fill="paper-dim")
f.box(50, 64, 240, 44, stroke="amber")
f.text(170, 86, "@Model CourseRecord", mono=True, size=11, fill="amber")
f.box(50, 160, 240, 44, stroke="amber")
f.text(170, 182, "@Model SessionRecord", mono=True, size=11, fill="amber")
f.line(170, 110, 170, 156, color="amber", arrow=True)
f.text(180, 134, "a relationship", "uma relação", size=10, fill="paper-dim", anchor="start")
f.text(170, 236, "stored by SwiftData,", "guardados pelo SwiftData,", size=10, fill="paper-dim")
f.text(170, 252, "in a file on the device", "num arquivo no aparelho", size=10, fill="paper-dim")
f.box(400, 20, 300, 260, stroke="phosphor", fill="ink")
f.text(550, 40, "PlannerCore: anywhere", "PlannerCore: em qualquer lugar", size=11, fill="paper-dim")
f.box(430, 64, 240, 44, stroke="phosphor")
f.text(550, 86, "struct Course", mono=True, size=11, fill="phosphor")
f.box(430, 160, 240, 44, stroke="phosphor")
f.text(550, 182, "struct StudySession", mono=True, size=11, fill="phosphor")
f.line(550, 156, 550, 110, color="phosphor", arrow=True)
f.text(560, 134, "courseID, text", "courseID, texto", size=10, fill="paper-dim", anchor="start")
f.text(550, 236, "tested by swift test,", "testados pelo swift test,", size=10, fill="paper-dim")
f.text(550, 252, "shown by the screens", "mostrados pelas telas", size=10, fill="paper-dim")
f.line(322, 172, 398, 172, color="paper-dim", arrow=True)
f.text(360, 160, ".value", mono=True, size=10, fill="paper")
f.line(398, 196, 322, 196, color="paper-dim", arrow=True)
f.text(360, 212, "insert", mono=True, size=10, fill="paper")
f.write(lesson(L, "model-macro"),
        "Two shapes of the same sessions. The records are how the app stores them; the values are how it reasons about them, and only the values build on Linux.",
        "Duas formas das mesmas sessões. Os registros são como o app as guarda; os valores são como ele raciocina sobre elas, e só os valores compilam no Linux.")
