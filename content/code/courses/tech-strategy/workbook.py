#!/usr/bin/env python3
"""The course's spreadsheet, built and recalculated by LibreOffice Calc.

Lesson 1 asks the student to set up a spreadsheet of their own — LibreOffice
Calc, Google Sheets or Excel — and the lessons after it show formulas with the
value beside each one. Those values are not typed. This file lays the course's
data (from sheet.py) into one sheet per lesson, exactly as the lesson tells the
student to lay it out, writes the formulas the lesson shows, opens the result in
LibreOffice headless, lets Calc recalculate, and prints every formula with what
Calc returned:

    python3 workbook.py          # every lesson's sheet
    python3 workbook.py 5        # lesson 5's sheet only
    python3 workbook.py 1 1t     # lesson 1's first sheet, and its broken copy

`1t` is lesson 1's trouble section: the four mistakes it makes on purpose.

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


def lesson1():
    rows = [['People', 'Hours', 'Rate', 'Cost'],
            [8, 1, S.HOUR, '=A2*B2*C2']]
    show = ['=1+1', '=D2*4*12']
    return rows, show, ['D2']


def lesson1_trouble():
    """The four mistakes lesson 1's trouble section shows, made on purpose."""
    rows = [['Debt', 'Interest', 'Rate', 'Cost'],
            ['Seat-hold', 31, S.HOUR, '=B2*C2'],
            ['PDF tickets', 6, "'R$ 150", '=B3*C3'],
            ['Switching', 210000, 10, '=B4*C4']]
    show = ['=SOMA(D2:D2)', '=SUM(D2:D3)', '=B4*10%', '=B4*0,10']
    return rows, show, ['D2', 'D3', 'D4']


def lesson5():
    rows = [['Debt', 'Principal', 'Interest', 'Payback', 'Per year']]
    for k, (name, pr, it) in enumerate(S.DEBTS, start=2):
        rows.append([name, pr, it, f'=ROUND(B{k}/C{k},1)', f'=C{k}*{S.SPRINTS_A_YEAR}*{S.HOUR}'])
    last = len(rows)
    show = [f'=SUM(C2:C{last})*{S.HOUR}',
            f'=INDEX(A2:A{last},MATCH(MIN(D2:D{last}),D2:D{last},0))',
            f'=SUM(E2:E{last})']
    return rows, show, ['D2', 'D3', 'D4', 'D5', 'E2']


def lesson8():
    rows = [['Option', 'Year 1', 'Year 2', 'Year 3', 'Three years']]
    for k, (name, f) in enumerate((('Build', S.build_search), ('Buy', S.buy_search),
                                   ('Adopt', S.adopt_search)), start=2):
        rows.append([name] + [round(y) for y in f()] + [f'=SUM(B{k}:D{k})'])
    show = ['=INDEX(A2:A4,MATCH(MIN(E2:E4),E2:E4,0))',
            '=INDEX(A2:A4,MATCH(MIN(B2:B4),B2:B4,0))',
            '=E2-E3']
    return rows, show, ['E2', 'E3', 'E4']


def lesson9():
    h, s = S.hosted_obs(), S.selfhosted_obs()
    rows = [['Line', 'Hosted', 'Self-hosted']]
    for k, key in enumerate(('licence', 'integration', 'operation', 'exit'), start=2):
        rows.append([key.capitalize(), round(h[key]), round(s[key])])
    rows.append(['TCO', '=SUM(B2:B5)', '=SUM(C2:C5)'])
    show = ['=B2-C2', '=C6-B6', '=ROUND(C4/C6*100,0)']
    return rows, show, ['B6', 'C6']


def lesson10():
    rows = [['Lock-in', 'Switching', 'Probability', 'Expected', 'Portability']]
    for k, (name, sw, p, up, yr) in enumerate(S.LOCKINS, start=2):
        rows.append([name, sw * S.HOUR, p, f'=B{k}*C{k}', (up + 3 * yr) * S.HOUR])
    show = ['=IF(E2<D2,"pay for portability","accept the lock-in")',
            '=IF(E3<D3,"pay for portability","accept the lock-in")']
    return rows, show, ['D2', 'D3']


def lesson11():
    rows = [['Line', 'Amount', 'Share']]
    for k, (name, v) in enumerate(S.BUDGET, start=2):
        rows.append([name, v, f'=ROUND(B{k}/SUM($B$2:$B$5)*100,1)'])
    show = ['=SUM(B2:B5)', '=SUM(B2:B5)*10%', f'=ROUND(SUM(B2:B5)*10%/{S.FTE_YEAR},1)',
            '=ROUND(SUM(B2:B5)*10%/B3*100,0)']
    return rows, show, ['C2', 'C3', 'C4', 'C5']


def lesson12():
    rows = [['Team', 'Tagged', 'With share']]
    tagged = [(n, v) for n, v in S.SHOWBACK if n != 'Untagged']
    untagged = dict(S.SHOWBACK)['Untagged']
    for k, (name, v) in enumerate(tagged, start=2):
        rows.append([name, v, f'=ROUND(B{k}+$B$8*B{k}/SUM($B$2:$B$6),0)'])
    rows.append([])
    rows.append(['Untagged', untagged])
    show = ['=ROUND(B8/SUM(B2:B8)*100,1)', '=SUM(C2:C6)',
            f'=ROUND({S.CLOUD_A_MONTH}/{S.TICKETS_A_MONTH},3)',
            f'=ROUND({S.NEXT_CLOUD}/{S.NEXT_TICKETS},3)']
    return rows, show, ['C2', 'C3', 'C4', 'C5', 'C6']


def lesson13():
    rows = [['Candidate', 'CoD a week', 'Weeks', 'CD3']]
    for k, (name, cod, d) in enumerate(S.CANDIDATES, start=2):
        rows.append([name, cod, d, f'=B{k}/C{k}'])
    show = ['=INDEX(A2:A5,MATCH(LARGE(D2:D5,1),D2:D5,0))',
            '=INDEX(A2:A5,MATCH(LARGE(D2:D5,2),D2:D5,0))',
            '=INDEX(A2:A5,MATCH(LARGE(D2:D5,3),D2:D5,0))',
            '=INDEX(A2:A5,MATCH(LARGE(D2:D5,4),D2:D5,0))']
    return rows, show, ['D2', 'D3', 'D4', 'D5']


SHEETS = {'1': lesson1, '1t': lesson1_trouble, '5': lesson5, '8': lesson8, '9': lesson9,
          '10': lesson10, '11': lesson11, '12': lesson12, '13': lesson13}
NAMES = {'1t': 'lesson 1, the trouble section'}


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
    print('--- ' + NAMES.get(n, f'lesson {n}'))
    for c in cells:
        ci, ri = ord(c[0]) - ord('A'), int(c[1:]) - 1
        print(f'  {c:<6} {str(rows[ri][ci]):<44} {got[ri][ci]}')
    for k, f in enumerate(show):
        print(f'  {f:<62} {got[k][out_col]}')


if __name__ == '__main__':
    if not shutil.which('soffice'):
        sys.exit('workbook.py needs LibreOffice: soffice is not on the PATH')
    want = sys.argv[1:] or list(SHEETS)
    tmp = tempfile.mkdtemp(prefix='ts-workbook-')
    try:
        for n in want:
            run(n, tmp)
    finally:
        shutil.rmtree(tmp)
