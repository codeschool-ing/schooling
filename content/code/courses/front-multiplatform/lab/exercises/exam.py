"""The course exam: exam_a to exam_d, numbered from the ids in exam.ids, in order."""
import sys, os, pathlib
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, "..")); sys.path.insert(0, here)
from exgen import build
import exam_a, exam_b, exam_c, exam_d

QS = exam_a.QS + exam_b.QS + exam_c.QS + exam_d.QS
ids = pathlib.Path(here, "exam.ids").read_text().split()
assert len(ids) >= len(QS), (len(ids), len(QS))
for q, i in zip(QS, ids):
    q["id"] = i
build("/home/user/schooling/content/code/courses/front-multiplatform", QS, exam=True, spread_keys=True)
print(len(QS), "questions")
