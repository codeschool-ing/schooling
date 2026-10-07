#!/bin/sh
# lab.sh — the workbench lesson 1 tells the student to build, built here, and
# every spreadsheet formula the course quotes typed into it and recalculated.
#
#   sh lab.sh [directory]      # default: ./workbench, created and refilled
#
# WHAT IS STAGED. The data is the course's own and invented: `faro.csv` is
# printed by `sheet.py --csv` from a seeded generator, so it is the same file
# every time. Nothing else is staged. The student copies the same table out of
# lesson 1 and types the same formulas into their own spreadsheet.
#
# HOW THE FORMULAS ARE RUN. Each formula below is the text a student types into
# a cell of LibreOffice Calc in English (United States), commas and all. The
# script writes it into a copy of `faro.csv` beside the data, opens that copy
# with Calc's CSV filter told to EVALUATE formulas (the thirteenth filter token),
# saves it as a flat ODF spreadsheet and reads back the value Calc computed. So
# the number printed is Calc's, not Python's.
#
# Captured with LibreOffice 24.2.7.2 headless, on 2026-10-07, TZ=America/Sao_Paulo.
#
# THE PORTUGUESE SPELLINGS ARE NOT RUN HERE. The lessons give each formula in a
# `localised` block, and the Portuguese one uses the Portuguese (Brazil) names
# of the same functions — SOMASES for SUMIFS, SE for IF — with `;` between the
# arguments, which is how Calc, Excel and Google Sheets spell them in that
# locale. They are the same functions; this script evaluates the English text.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
DIR=${1:-./workbench}
mkdir -p "$DIR"
DIR=$(cd "$DIR" && pwd)
export TZ=America/Sao_Paulo

python3 -B "$HERE/sheet.py" --csv > "$DIR/faro.csv"
echo "$DIR/faro.csv: $(wc -l < "$DIR/faro.csv") lines"

# label|formula, in the order the lessons use them
cat > "$DIR/formulas.txt" <<'EOF'
l01 cancel rate, late first delivery|=SUMIFS(E2:E25,C2:C25,"late")/SUMIFS(D2:D25,C2:C25,"late")
l01 cancel rate, on-time first delivery|=SUMIFS(E2:E25,C2:C25,"on time")/SUMIFS(D2:D25,C2:C25,"on time")
l01 share of first deliveries late|=SUMIFS(D2:D25,C2:C25,"late")/SUM(D2:D25)
l01 new subscribers|=SUM(D2:D25)
l09 customers kept a year at 8% late|=2*6113*(1058/6113-0.08)*(439/1058-881/5055)
l09 margin kept a year, whole effect|=ROUND(2*6113*(1058/6113-0.08)*(439/1058-881/5055),0)*1554.14
l09 express for every first box, a year|=2*6113*9
l10 capital, late|=SUMIFS(E2:E25,B2:B25,"capital",C2:C25,"late")/SUMIFS(D2:D25,B2:B25,"capital",C2:C25,"late")
l10 capital, on time|=SUMIFS(E2:E25,B2:B25,"capital",C2:C25,"on time")/SUMIFS(D2:D25,B2:B25,"capital",C2:C25,"on time")
l10 interior, late|=SUMIFS(E2:E25,B2:B25,"interior",C2:C25,"late")/SUMIFS(D2:D25,B2:B25,"interior",C2:C25,"late")
l10 interior, on time|=SUMIFS(E2:E25,B2:B25,"interior",C2:C25,"on time")/SUMIFS(D2:D25,B2:B25,"interior",C2:C25,"on time")
l11 margin per box|=189.9*0.31
l11 months a survivor stays|=3+1/0.04
l11 lifetime margin, survivor|=189.9*0.31*(3+1/0.04)
l11 lifetime margin, early canceller|=189.9*0.31*1.6
l11 LTV to CAC|=189.9*0.31*(3+1/0.04)/152
l11 boxes to pay back acquisition|=152/(189.9*0.31)
l11 margin lost per early cancellation|=189.9*0.31*(3+1/0.04)-189.9*0.31*1.6
l11 extra early cancellations, half-year|=ROUND(1058*(439/1058-881/5055),0)
l11 margin lost a year|=2*255*1554.14
l11 acquisition spent on them a year|=2*255*152
EOF

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
python3 - "$DIR" "$WORK" <<'PY'
import csv, io, re, subprocess, sys, os
d, work = sys.argv[1], sys.argv[2]
data = open(os.path.join(d, 'faro.csv')).read().rstrip('\n')
pairs = [l.split('|', 1) for l in open(os.path.join(d, 'formulas.txt')).read().splitlines() if l]
buf = io.StringIO()
w = csv.writer(buf, lineterminator='\n')
for _, formula in pairs:
    w.writerow(['', '', '', '', '', '', formula])
src = os.path.join(work, 'calc.csv')
open(src, 'w').write(data + '\n' + buf.getvalue())
subprocess.run(['soffice', '--headless',
                '--infilter=CSV:44,34,76,1,,1033,false,false,false,false,false,-1,true',
                '--convert-to', 'fods', '--outdir', work, src],
               check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
xml = open(os.path.join(work, 'calc.fods')).read()
cells = re.findall(r'<table:table-cell table:formula="[^"]*" office:value-type="float" '
                   r'office:value="([^"]+)"', xml)
if len(cells) != len(pairs):
    sys.exit(f'{len(pairs)} formulas and {len(cells)} values came back')
for (label, formula), value in zip(pairs, cells):
    print(f'{label}\n    {formula}\n    = {value}')
PY
