#!/usr/bin/env python3
"""The course's spreadsheet, built and recalculated by LibreOffice Calc.

Lesson 3 asks the student to set up a workbook of their own — LibreOffice Calc,
Google Sheets or Excel — and the lessons after it show formulas with the value
beside each one. Those values are not typed. This file lays the course's data
(from sheet.py) into one sheet per lesson, exactly as the lesson tells the
student to lay it out, writes the formulas the lesson shows, opens the result in
LibreOffice headless, lets Calc recalculate, and prints every formula with what
Calc returned:

    python3 workbook.py          # every lesson's sheet
    python3 workbook.py 9        # lesson 9's sheet only
    python3 workbook.py 30       # lesson 3's broken sheet, for its trouble section

It was last run with LibreOffice 24.2.7.2, in English (en-US), so the function
names and the decimal point are the English ones. A Portuguese spreadsheet spells
the same functions differently and uses a comma; the lessons show both, and the
values are the same numbers.

Needs `soffice` on the PATH. Nothing else.
"""
import csv
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True
import sheet as S  # noqa: E402

# Import: comma-separated, UTF-8, from line 1, and token 13 — evaluate formulas.
IMPORT = 'CSV:44,34,76,1,,1033,false,false,false,false,false,-1,true'
EXPORT = 'csv:Text - txt - csv (StarCalc):44,34,76,1,,1033,false,true,false'


def col(i):
    return chr(ord('A') + i)


def lesson3():
    rows = [['Item', 'Started', 'Finished', 'Days']]
    for k, (item, s, f) in enumerate(S.FINISHED, start=2):
        rows.append([item, s, f, f'=C{k}-B{k}+1'])
    last = len(rows)
    show = [f'=AVERAGE(D2:D{last})', f'=MEDIAN(D2:D{last})',
            f'=PERCENTILE.INC(D2:D{last},0.85)', f'=MAX(D2:D{last})',
            f'=COUNTIF(D2:D{last},"<=12")', f'=COUNTIF(C2:C{last},"<2026-03-09")']
    return rows, show, ['D2', f'D{last}']


def lesson3_trouble():
    """The three mistakes lesson 3's trouble section shows, made on purpose."""
    rows = [['Item', 'Started', 'Finished', 'Days'],
            ['AG-101', '2026-03-02', '2026-03-03', '=C2-B2+1'],
            ['AG-104', '2026-02-26', "'2026-03-04", '=C3-B3+1'],
            ['AG-108', '2026-03-04', '2026-03-06', '=C4-B4']]
    show = ['=PERCENTIL.INC(D2:D4,0.85)', '=MEDIAN(D2:D4)', '=MEDIAN(D2,D4)']
    return rows, show, ['D2', 'D3', 'D4']


def lesson9():
    rows = [['Task', 'O', 'M', 'P', 'Mean', 'SD', 'Variance']]
    for k, (name, (o, m, p)) in enumerate(S.TASKS.items(), start=2):
        rows.append([name, o, m, p, f'=(B{k}+4*C{k}+D{k})/6', f'=(D{k}-B{k})/6', f'=F{k}^2'])
    last = len(rows)
    show = [f'=SUM(E2:E{last})', f'=SUM(G2:G{last})', f'=SQRT(SUM(G2:G{last}))',
            f'=SUM(E2:E{last})+1.04*SQRT(SUM(G2:G{last}))', f'=SUM(C2:C{last})',
            f'=SUM(D2:D{last})']
    return rows, show, ['E2', 'F4']


def lesson10():
    rows = [['Sprint', 'Points']]
    for k, v in enumerate(S.VELOCITY, start=1):
        rows.append([k, v])
    last = len(rows)
    first6 = last - 5
    show = [f'=AVERAGE(B2:B{last})', f'=MIN(B{first6}:B{last})', f'=MAX(B{first6}:B{last})',
            f'=ROUNDUP({S.BACKLOG_POINTS}/MAX(B{first6}:B{last}),0)',
            f'=ROUNDUP({S.BACKLOG_POINTS}/MIN(B{first6}:B{last}),0)']
    return rows, show, []


def lesson11():
    rows = [['Risk', 'Probability', 'Impact', 'EMV']]
    for k, (name, p, i) in enumerate(S.RISKS, start=2):
        rows.append([name, p, i, f'=B{k}*C{k}'])
    last = len(rows)
    show = [f'=SUMIF(C2:C{last},">0",D2:D{last})', f'=SUM(D2:D{last})',
            f'=SUMPRODUCT(B2:B{last},C2:C{last})']
    return rows, show, ['D2', 'D6']


def lesson12():
    rows = [['Feature', 'Value', 'Time', 'Risk', 'Size', 'CoD', 'WSJF']]
    for k, (name, (bv, tc, rr, size)) in enumerate(S.WSJF.items(), start=2):
        rows.append([name, bv, tc, rr, size, f'=B{k}+C{k}+D{k}', f'=ROUND(F{k}/E{k},2)'])
    last = len(rows)
    show = [f'=INDEX(A2:A{last},MATCH(MAX(G2:G{last}),G2:G{last},0))']
    return rows, show, ['G2', 'G3', 'G4', 'G5']


def lesson13():
    rows = [['Deploy', 'Lead hours', 'Failed', 'Restore minutes']]
    for k, h in enumerate(S.LEAD_HOURS):
        failed = k in S.FAILED
        rows.append([k + 1, h, 1 if failed else 0, S.FAILED.get(k, '')])
    last = len(rows)
    show = [f'=COUNT(B2:B{last})/{S.WORKING_DAYS}', f'=MEDIAN(B2:B{last})',
            f'=SUM(C2:C{last})/COUNT(B2:B{last})', f'=MEDIAN(D2:D{last})',
            f'=COUNTIF(B2:B{last},">24")']
    return rows, show, []


SHEETS = {3: lesson3, 30: lesson3_trouble, 9: lesson9, 10: lesson10, 11: lesson11, 12: lesson12, 13: lesson13}


def run(n, tmp):
    rows, show, cells = SHEETS[n]()
    width = max(len(r) for r in rows)
    out_col = width + 1                      # leave one empty column
    for k, f in enumerate(show):
        r = k + 1
        while len(rows) < r:
            rows.append([])
        row = rows[r - 1]
        row += [''] * (out_col - len(row))
        row.append(f)
    src = os.path.join(tmp, f'lesson{n}.csv')
    with open(src, 'w', newline='') as fh:
        csv.writer(fh).writerows(rows)
    outdir = os.path.join(tmp, f'out{n}')
    subprocess.run(['soffice', '--headless', f'--infilter={IMPORT}', '--convert-to', EXPORT,
                    '--outdir', outdir, src], check=True, capture_output=True)
    with open(os.path.join(outdir, f'lesson{n}.csv')) as fh:
        got = list(csv.reader(fh))
    print(f'--- lesson {n}' if n < 30 else '--- lesson 3, the trouble section')
    for c in cells:
        ci, ri = ord(c[0]) - ord('A'), int(c[1:]) - 1
        print(f'  {c:<6} {rows[ri][ci]:<44} {got[ri][ci]}')
    for k, f in enumerate(show):
        print(f'  {f:<52} {got[k][out_col]}')


if __name__ == '__main__':
    if not shutil.which('soffice'):
        sys.exit('workbook.py needs LibreOffice: soffice is not on the PATH')
    want = [int(a) for a in sys.argv[1:]] or sorted(SHEETS)
    tmp = tempfile.mkdtemp(prefix='pm-workbook-')
    try:
        for n in want:
            run(n, tmp)
    finally:
        shutil.rmtree(tmp)
