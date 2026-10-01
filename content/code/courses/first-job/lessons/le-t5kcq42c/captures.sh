#!/usr/bin/env bash
# The terminal session quoted in lesson 17 of first-job, as a script that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   bash captures.sh
#
# WHAT IS STAGED: nothing but the file. clt_pj.py below is the program shown in
# the lesson, byte for byte; the monthly figure in it is an example chosen for
# the arithmetic, not a salary anybody was offered.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
work=$(mktemp -d); cd "$work"
cat > clt_pj.py <<'PY'
# What a CLT salary is worth in a year, and the PJ invoice that matches it.
# The monthly figure is an example, not a market rate. Taxes are left out on
# purpose: INSS and income tax change with each year's tables.
monthly = 3000.00
thirteenth = monthly             # 13º salário: one extra month a year
holiday_third = monthly / 3      # férias: a month paid, plus one third
fgts = 0.08 * (12 * monthly + thirteenth + holiday_third)
clt_year = 12 * monthly + thirteenth + holiday_third + fgts
print(f"CLT, a year before tax: R$ {clt_year:10,.2f}")
print(f"  that is {clt_year / monthly:.2f} monthly salaries")
for months_invoiced in (12, 11):
    pj = clt_year / months_invoiced
    print(f"PJ invoice to match it, {months_invoiced} months billed: R$ {pj:9,.2f}")
PY

echo '##### run'
printf '$ %s\n' 'python3 clt_pj.py'
python3 clt_pj.py 2>&1
rm -rf "$work"
