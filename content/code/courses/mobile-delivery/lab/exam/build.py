import sys, os
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here); sys.path.insert(0, os.path.dirname(here))
from exgen import build, simulate
import part1, part2, part3
L = "/home/user/schooling/content/code/courses/mobile-delivery"
build(L, part1.QS + part2.QS + part3.QS, exam=True, name="exam", spread_keys=True)
simulate(L + "/exam.json")
