"""The course exam: five questions a lesson, gathered from lab/ex/exam_lNN.py.
THE STUDENT NEVER SEES THIS (C-40). python3 lab/ex/exam.py"""
import glob, importlib.util, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ex import write

qs = []
for f in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "exam_l*.py"))):
    spec = importlib.util.spec_from_file_location(os.path.basename(f)[:-3], f)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    qs += m.qs
write("exam", qs)
