# build.py: the course exam, from the four question files, into the course's exam.json and exam.pt.json.
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here); sys.path.insert(0, os.path.join(here, ".."))
from exgen import build
import a, b, c, d
QS = a.QS + b.QS + c.QS + d.QS
build(os.path.join(here, "..", ".."), QS, exam=True, spread_keys=True)
print(len(QS), "questions")
