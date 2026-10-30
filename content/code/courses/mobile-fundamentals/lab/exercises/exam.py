"""The course exam: exam_l01 ... exam_l20, in lesson order, numbered from the
ids in exam.ids (handed out once by ids.py, so a question keeps its id when
the file is rebuilt)."""
import sys, os, pathlib, importlib
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, "..")); sys.path.insert(0, here)
from exgen import build

QS = []
for n in range(1, 21):
    QS += importlib.import_module(f"exam_l{n:02d}").QS
ids = pathlib.Path(here, "exam.ids").read_text().split()
assert len(ids) >= len(QS), (len(ids), len(QS))
for q, i in zip(QS, ids):
    q["id"] = i
build("/home/user/schooling/content/code/courses/mobile-fundamentals", QS, exam=True, spread_keys=True)
print(len(QS), "questions")
