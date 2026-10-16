"""The course exam: the three parts written lesson group by lesson group, as one pool.

    python3 build.py exam.py ../exam exam
"""
from exam_a import EXAM_A
from exam_b import EXAM_B
from exam_c import EXAM_C

EXERCISES = EXAM_A + EXAM_B + EXAM_C
