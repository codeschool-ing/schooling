---
title: Rode o experimento você mesmo
version: 1
---

Um time real tem um só histórico. Ele mudou as regras numa data, e nunca vai saber como teria sido o seu setembro sem a mudança. O time de Billing é uma simulação, então você pode **rodar o mesmo time com as regras mudadas em outro dia** e comparar. O `billing.py` recebe a data como único argumento.

## O limite desde o primeiro dia

```
ana@laptop:~/delivery$ python3 billing.py 2026-06-01
128 items merged, 27 not yet, 74 deploys
ana@laptop:~/delivery$ python3 compare.py 2026-06-01:2026-07-31 2026-09-01:2026-09-30 2026-06-01:2026-09-30
                        06-01..07-31  09-01..09-30  06-01..09-30
items finished                    66            34           128
work in progress                 7.4           5.9           6.7
finished per week                7.6           7.9           7.3
cycle time, median                 4             5             5
cycle time, 85th                   7             8             8
```

## O limite nunca

Uma data depois do fim do histórico significa as regras antigas nos quatro meses.

```
ana@laptop:~/delivery$ python3 billing.py 2026-10-01
122 items merged, 30 not yet, 17 deploys
ana@laptop:~/delivery$ python3 compare.py 2026-06-01:2026-07-31 2026-09-01:2026-09-30 2026-06-01:2026-09-30
                        06-01..07-31  09-01..09-30  06-01..09-30
items finished                    52            39           122
work in progress                21.6          19.7          21.6
finished per week                6.0           9.1           7.0
cycle time, median                18            17            18
cycle time, 85th                  29            29            29
```

## Lendo os três históricos

Ponha a última coluna de cada execução lado a lado: os quatro meses inteiros sob cada política.

| política | itens terminados | trabalho em andamento | tempo de ciclo mediano | percentil 85 |
|---|---|---|---|---|
| limite desde 1º de junho | 128 | 6,7 | 5 dias | 8 dias |
| limite desde 3 de agosto (o que aconteceu) | 123 | 14,9 | 11 dias | 26 dias |
| sem limite | 122 | 21,6 | 18 dias | 29 dias |

**As mesmas pessoas terminaram quase o mesmo número de itens sob as três políticas**: de 122 a 128 em quatro meses. O que mudou foi quanto tempo cada item levou, por um fator de três a quatro. Essa é a lição do limite numa tabela, e você a produziu no seu próprio computador.

Dois detalhes mantêm o experimento honesto.

- **A vazão de setembro na execução sem limite é 9,1 por semana**, a maior de todas as colunas. Não porque as regras antigas sejam mais rápidas: a fila de revisão por acaso esvaziou depressa naquele mês. Em quatro meses, a mesma execução foi a que menos terminou. Um mês é ruído; é o aviso da seção anterior, medido.
- **As execuções não são os mesmos itens em outra ordem.** Os números aleatórios são os mesmos, mas regras diferentes os consomem em ordem diferente, então cada execução é um histórico plausível próprio. Compare os resumos, não itens individuais.

## Volte ao original

Todas as aulas seguintes usam o histórico real, então rode o programa mais uma vez sem argumento:

```
ana@laptop:~/delivery$ python3 billing.py
123 items merged, 19 not yet, 47 deploys
```

Experimente outras datas também. Um limite desde 1º de julho, ou desde 1º de setembro, mostra quanto tempo a fila antiga leva para esvaziar, que é o agosto que a aula 1 achou difícil de ler.
