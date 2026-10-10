#!/usr/bin/env python3
"""Every number bi-business quotes, recalculated by LibreOffice Calc, and every figure, redrawn.

    python3 sheet.py          # every lesson
    python3 sheet.py 7 12     # lessons 7 and 12 only

Each lesson that computes or draws has a file in `sheets/`, named for its
number (`l07.py`). Running one prints the table the lesson tells the student to
type, every formula the lesson shows and what Calc returned, and rewrites the
lesson's figures in both languages from the same numbers. `book.py` says what is
shared and why. Needs `soffice` on the PATH.
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True


def lesson(n):
    p = os.path.join(HERE, 'sheets', f'l{n:02d}.py')
    if not os.path.exists(p):
        return None
    spec = importlib.util.spec_from_file_location(f'l{n:02d}', p)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


if __name__ == '__main__':
    want = [int(a) for a in sys.argv[1:]] or range(1, 22)
    for n in want:
        m = lesson(n)
        if m is None:
            continue
        print(f'=== lesson {n}')
        m.main()
