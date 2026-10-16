---
title: Uma correção por vez
version: 1
---

**Mude uma coisa, meça, mantenha ou desfaça.** Mudar quatro coisas de uma vez e achar o job mais
rápido não diz nada sobre qual delas importou, e o próximo job vai ter outra mistura. O mesmo
relatório, com um erro tirado por execução:

```
ana@lab:~/big$ spark-submit report.py --udf --partitions 2000 --no-broadcast 2>/dev/null
120 rows in 105.7 s; top of January: [('poetry', 997352), ('science', 877502)]
ana@lab:~/big$ spark-submit report.py --partitions 2000 --no-broadcast 2>/dev/null
120 rows in 75.4 s; top of January: [('poetry', 997352), ('science', 877502)]
ana@lab:~/big$ spark-submit report.py --no-broadcast 2>/dev/null
120 rows in 18.0 s; top of January: [('poetry', 997352), ('science', 877502)]
ana@lab:~/big$ spark-submit report.py 2>/dev/null
120 rows in 15.9 s; top of January: [('poetry', 997352), ('science', 877502)]
```

| execução | mudança | tempo | economia |
|---|---|---|---|
| 1 | os quatro erros | 131,1 s | |
| 2 | Parquet da silver em vez de CSV | 105,7 s | 25,4 s |
| 3 | `date_trunc` em vez de uma função Python | 75,4 s | 30,3 s |
| 4 | execução adaptativa e o seu próprio número de partições | 18,0 s | 57,4 s |
| 5 | broadcast permitido | 15,9 s | 2,1 s |

**Oito vezes mais rápido, e nenhuma mudança na resposta.** Cada correção é a lição de uma aula. O CSV
custava interpretar cada linha de texto e ler todas as colunas; o Parquet leu três. A função Python
custava uma ida a um worker Python para cada uma das 960.000 compras. As 2.000 partições custavam
2.000 tarefas lendo quase nada cada uma, a sobrecarga que a aula 7 mediu, onde a execução adaptativa
as juntou num punhado.

**A última correção economizou dois segundos**, e isso também é um resultado. Com a execução
adaptativa ligada, o shuffle do join era pequeno, só as compras, e um sort-merge join de partições
pequenas custa pouco mais que um broadcast. Uma correção que importa num job é ruído em outro, e é por
isso que cada uma é medida sozinha.

E o history server, para a versão rápida:

```
ana@lab:~/big$ python3 history.py report
app-20261016062256-0017 40.6 s
stage  tasks  wall s  task s  input MiB  shuffle MiB  spill MiB  name
    4     15    10.4    26.5       26.3          0.0        0.0  collect at /home/ana/big/rep
    0    365    10.2     3.4        0.0          0.0        0.0  parquet at NativeMethodAcces
    3      1     1.2     1.0        0.0          0.0        0.0  collect at /home/ana/big/rep
    1      1     0.8     0.7        0.0          0.0        0.0  parquet at NativeMethodAcces
    2      1     0.8     0.6        0.0          0.0        0.0  parquet at NativeMethodAcces
    8      1     0.4     0.3        0.0          0.1        0.0  collect at /home/ana/big/rep
```

**O estágio mais lento agora lê Parquet e não faz nada lento por linha.** O que sobra é quase tudo a
leitura de três colunas de 24 milhões de linhas em 365 arquivos, e as escolhas da aula 10 são o que a
cortaria mais.
