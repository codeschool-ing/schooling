---
title: Quanto custa manter cada tipo de serviço
version: 1
---

Dinheiro para um modelo em produção é quase todo dinheiro para a máquina em que ele roda, e a
máquina é paga por hora, ocupada ou não. **Então a medida útil é quanto uma implantação ocupa e por
quanto tempo**, e os dois tipos construídos na lição 8 diferem em ordens de grandeza na segunda.

O serviço, enquanto roda, ocupa esta memória, em kilobytes:

```
ana@dev:~/ml$ ps -o rss=,comm= -C uvicorn
340640 uvicorn
```

Cerca de 330 MB, para um processo com uma cópia do modelo, a conexão com o armazenamento online e as
bibliotecas por trás deles. Ele ocupa isso a cada hora de cada dia, porque um serviço que não está
rodando não pode responder, e ocupa às três da manhã, quando ninguém pergunta. Quatro workers, o
remédio da seção anterior, ocupam quatro vezes mais.

O lote, cronometrado com o `time` do próprio shell:

```
ana@dev:~/ml$ time python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 3355 rows in lapse_scores

real	0m4.122s
user	0m4.482s
sys	0m0.353s
```

**Quatro segundos de um processador, uma vez por noite**, para todos os membros ativos. `real` é o
tempo de relógio; `user` e `sys` são o tempo do processador, no programa e no sistema a serviço dele,
e podem somar mais que `real` quando as bibliotecas usam vários núcleos ao mesmo tempo. Um mês de
noites dá uns dois minutos de processamento, e a memória que ele precisa é devolvida no instante em
que termina.

| | lote | serviço |
| --- | --- | --- |
| ocupado | por quatro segundos a cada noite | o dia todo, todo dia |
| um mês disso | uns 2 minutos de um processador | 720 horas de 330 MB, por worker |
| cresce com | o número de membros | o minuto mais movimentado do dia |
| custo por nota | cai conforme os membros crescem | alto quando ocioso, baixo quando ocupado |

**Um serviço é dimensionado para o seu minuto mais movimentado e pago no mais tranquilo.** Esse é o
preço real do tempo real, e é por isso que a lição 8 mandou começar pelo lote. Calcule o preço em
dinheiro com as tarifas do seu provedor para uma hora de processador e uma hora de gigabyte; a razão
entre as duas colunas não vai mudar muito, e a razão é o argumento.

**A mesma conta vale para o custo do próprio modelo.** Um modelo maior que compra um ponto de
precisão média também compra mais memória por worker e predições mais lentas, o que significa mais
workers para o mesmo p99. Se esse ponto vale a pena é uma pergunta para quem usa as notas, feita com
os dois números na mesa.
