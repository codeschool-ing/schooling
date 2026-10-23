"""The course exam: six questions per written lesson, drafted in three parts
(lessons 1-4, 8-13, 15-20, and then 5-7 and 14) and built here in course order."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__)); sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from exgen import build
from examA import QA
from examB import QB
from examC import QC
from examD import QD5_7, QD14
build("/home/user/schooling/content/code/courses/secure-code", QA + QD5_7 + QC + QD14 + QB, exam=True)
