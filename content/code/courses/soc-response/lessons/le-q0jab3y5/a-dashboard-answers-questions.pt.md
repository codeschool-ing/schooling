---
title: Um painel responde perguntas
version: 1
---

Uma ideia comum de painel de SOC é uma parede de gráficos que parecem ocupados. **Um painel que vale a pena
manter responde perguntas que alguém faz todo dia**, e cada quadro diz a sua pergunta. Se ninguém sabe dizer
qual pergunta um quadro responde, ninguém vai notar quando a resposta dele mudar.

Três perguntas que um analista da empresa do laboratório faz toda manhã, escritas como três consultas.
Salve isto em `~/week` como `dashboard.sql`:

```sql
-- dashboard.sql: three panels, each one a question somebody asks every morning
.headers on
.mode column
-- 1. failed SSH logins per day, local time
SELECT date(timestamp, '-3 hours') AS day, count(*) AS failures
FROM logs WHERE product = 'sshd' AND action = 'failure' GROUP BY day;
-- 2. the five addresses that tried the most different accounts
SELECT src_ip, count(DISTINCT user) AS accounts, count(*) AS failures
FROM logs WHERE action = 'failure' GROUP BY src_ip ORDER BY accounts DESC LIMIT 5;
-- 3. megabytes leaving the company, per destination
SELECT dst_ip, count(*) AS transfers, sum(bytes) / 1000000 AS mb
FROM logs WHERE product = 'flow' GROUP BY dst_ip ORDER BY mb DESC;
```

```
ana@soc:~/week$ sqlite3 siem.db < dashboard.sql
day         failures
----------  --------
2026-09-14  12      
2026-09-15  14      
2026-09-16  8       
2026-09-17  70      
2026-09-18  17      
2026-09-19  12      
2026-09-20  17      
src_ip         accounts  failures
-------------  --------  --------
203.0.113.66   19        57      
203.0.113.174  6         6       
203.0.113.192  5         6       
203.0.113.157  4         4       
203.0.113.180  3         3       
dst_ip         transfers  mb  
-------------  ---------  ----
203.0.113.150  7          2494
203.0.113.200  1          612 
```

Leia na ordem, como uma pessoa passando os olhos por uma tela leria. O primeiro quadro diz que **a quinta
foi diferente**: 70 falhas contra 8 a 17 de costume. O segundo diz que um endereço tentou **19 contas**
enquanto o seguinte mais ativo tentou 6, numa semana inteira. O terceiro diz que, além do provedor de
backup, **612 MB foram para outro lugar uma vez**. Nenhum dos três diz o que aconteceu. Juntos, dizem onde
olhar, que é para isso que serve um painel.

O primeiro quadro como figura:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um gráfico de barras dos logins SSH falhos por dia, horário local, de segunda, 14, a domingo, 20 de setembro: 12, 14, 8, 70, 17, 12 e 17. A barra de quinta tem de quatro a oito vezes as outras.\"><path d=\"M40 190 L700 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"60\" y=\"162.57142857142858\" width=\"60\" height=\"27.428571428571427\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"152.57142857142858\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><text x=\"90\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seg 14</text><rect x=\"150\" y=\"158.0\" width=\"60\" height=\"32.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ter 15</text><rect x=\"240\" y=\"171.71428571428572\" width=\"60\" height=\"18.285714285714285\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"161.71428571428572\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"270\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qua 16</text><rect x=\"330\" y=\"30.0\" width=\"60\" height=\"160.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">70</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qui 17</text><rect x=\"420\" y=\"151.14285714285714\" width=\"60\" height=\"38.857142857142854\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"141.14285714285714\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">17</text><text x=\"450\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sex 18</text><rect x=\"510\" y=\"162.57142857142858\" width=\"60\" height=\"27.428571428571427\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"152.57142857142858\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sáb 19</text><rect x=\"600\" y=\"151.14285714285714\" width=\"60\" height=\"38.857142857142854\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"141.14285714285714\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">17</text><text x=\"630\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dom 20</text></svg>", "caption": "O painel 1 desenhado. Uma contagem diária mostra que a quinta foi diferente; não consegue dizer por quê."}
```

Três hábitos fazem um painel durar. **Uma referência ao lado de cada número**, porque 70 não quer dizer
nada sem o 8 a 17 ao lado. **O mesmo fuso em todo quadro**, dito no próprio quadro; aqui é o horário local,
enquanto a tabela guarda UTC. E **tão poucos quadros quanto as perguntas pedem**: um quadro que ninguém olha
há um mês é ruído que torna os outros mais difíceis de ler, e deve sair.
