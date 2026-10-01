---
title: Uma planilha de acompanhamento
version: 1
---

A planilha é uma planilha de verdade, ou um arquivo CSV, com uma linha por candidatura e seis colunas: **a
data, a empresa, a vaga, onde você a achou, a etapa em que está e a próxima coisa a fazer**. Aqui está o topo
da inventada:

```
$ head -4 applications.csv
date,company,role,source,stage,next
2026-06-01,Colégio Horizonte,Suporte N1,site,rejected,
2026-06-01,Rede Saúde Sul,Service desk júnior,LinkedIn,screening,call 06-15
2026-06-02,TecnoAlocação,Suporte júnior (alocado),LinkedIn,applied,follow up 06-09
```

Como são dados simples, ela responde a perguntas. Quantas candidaturas estão em cada etapa:

```
$ cut -d, -f5 applications.csv | tail -n +2 | sort | uniq -c | sort -rn
      6 applied
      2 screening
      2 rejected
      1 offer
      1 interview
```

Que origem leva a algum lugar. Neste arquivo, as três indicações avançaram e nenhuma das cinco candidaturas
feitas por páginas de carreira avançou:

```
$ awk -F, 'NR > 1 { n[$4]++; if ($5 != "applied" && $5 != "rejected") r[$4]++ } END { for (s in n) printf "%-9s %2d sent, %d moved on\n", s, n[s], r[s] }' applications.csv | sort
LinkedIn   4 sent, 1 moved on
referral   3 sent, 3 moved on
site       5 sent, 0 moved on
```

Um arquivo inventado não prova nada sobre o mercado. Mostra **para que serve a planilha**: depois de um mês
da sua própria busca, a mesma pergunta sobre as suas linhas diz onde gastar o mês seguinte. A aula 9 trata de
indicações, e se elas funcionam para você é algo que a sua planilha responde.

A última coluna é a que transforma a planilha numa ferramenta, e não num registro. Cada candidatura que está
esperando tem uma data de seguimento (aula 10), e uma vez por semana a planilha diz a quem escrever:

```
$ awk -F, 'NR > 1 && $6 ~ /follow up/ { print $6 " — " $2 }' applications.csv | sort
follow up 06-09 — TecnoAlocação
follow up 06-10 — Fintech Aurora
follow up 06-12 — Hospital Central
follow up 06-15 — Agência Pixel
follow up 06-15 — Distribuidora Leste
```
