#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of first-job, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   bash captures.sh
#
# WHAT IS STAGED: the tracker itself. applications.csv below is invented data
# for an invented job search, written for this lesson; the companies, the dates
# and the outcomes are examples, not a sample of anybody's real search, and the
# numbers the lesson quotes from it describe this file and nothing else.
# Every line after a prompt is what the command printed.
#
# Recorded on Ubuntu 24.04 with GNU coreutils and gawk, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
work=$(mktemp -d); cd "$work"
run() { printf '$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }

cat > applications.csv <<'CSV'
date,company,role,source,stage,next
2026-06-01,Colégio Horizonte,Suporte N1,site,rejected,
2026-06-01,Rede Saúde Sul,Service desk júnior,LinkedIn,screening,call 06-15
2026-06-02,TecnoAlocação,Suporte júnior (alocado),LinkedIn,applied,follow up 06-09
2026-06-02,Loja Norte,Suporte TI,referral,interview,tech 06-18
2026-06-03,Fintech Aurora,IT support junior,site,applied,follow up 06-10
2026-06-03,Prefeitura (temporário),Técnico de TI,site,applied,
2026-06-04,Consultoria Vale,Infra júnior,LinkedIn,rejected,
2026-06-05,Escola Nova Era,Suporte N1,referral,screening,call 06-12
2026-06-05,Hospital Central,Técnico de suporte,site,applied,follow up 06-12
2026-06-08,Distribuidora Leste,Help desk,LinkedIn,applied,follow up 06-15
2026-06-08,Agência Pixel,Suporte júnior,site,applied,follow up 06-15
2026-06-09,Cooperativa Sol,Analista de suporte jr,referral,offer,reply by 06-20
CSV

echo '##### table'
run "head -4 applications.csv"

echo '##### funnel'
run "cut -d, -f5 applications.csv | tail -n +2 | sort | uniq -c | sort -rn"

echo '##### by-source'
run "awk -F, 'NR > 1 { n[\$4]++; if (\$5 != \"applied\" && \$5 != \"rejected\") r[\$4]++ } END { for (s in n) printf \"%-9s %2d sent, %d moved on\n\", s, n[s], r[s] }' applications.csv | sort"

echo '##### due'
run "awk -F, 'NR > 1 && \$6 ~ /follow up/ { print \$6 \" — \" \$2 }' applications.csv | sort"

rm -rf "$work"
