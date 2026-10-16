---
title: On-demand ou provisionado, em dólares
version: 1
---

**Um stream provisionado é cobrado pelos shards, escreva-se nele ou não; um stream on-demand é
cobrado pelo stream e por cada gigabyte que passa por ele.** O primeiro sai barato quando você conhece
a carga e dimensiona os shards para ela. O segundo custa mais por gigabyte e compra o direito de não
saber: a AWS acrescenta e tira shards por trás dele conforme o tráfego muda. Nenhum é mais barato em
geral, e o jeito de decidir é passar uma carga pelos dois. Os preços, da tabela da lição 1:

```
ana@laptop:~/aws$ python3 prices.py kinesis
AWS public price list, sa-east-1, USD, excluding tax

Kinesis Data Streams, USD
  provisioned, per shard-hour                           0.03000  hour
  provisioned, per million PUT payload units            0.02800  million
  provisioned, extended retention, per shard-hour       0.04000  hour
  on demand, per stream-hour                            0.08000  hour
  on demand, data written                               0.16000  GB
  on demand, data read                                  0.08000  GB

Data Firehose, USD per GB
  ingested, first 500 TB                                0.05800  GB
  format conversion                                     0.03500  GB
  dynamic partitioning                                  0.03100  GB
```

**Duas linhas da metade provisionada pedem leitura cuidadosa.** Um shard-hora é um shard por uma hora,
então um mês de um shard são 730 deles. E uma **PUT payload unit** são 25 KB de um registro: um
registro de 1 KB custa uma unidade, o mesmo que um de 25 KB, e um de 30 KB custa duas. A metade
on-demand cobra por gigabyte, escrito e lido separadamente, e cada consumidor que lê o stream paga a
linha de leitura de novo.

O moto mantém os dois modos separados nas respostas, e não cobra por nenhum, como nunca cobra. O
stream desta lição ao lado de um on-demand novo:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders-od --stream-mode-details StreamMode=ON_DEMAND
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders --query 'StreamDescriptionSummary.[StreamName,StreamModeDetails.StreamMode,OpenShardCount]' --output text
orders	PROVISIONED	4
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders-od --query 'StreamDescriptionSummary.[StreamName,StreamModeDetails.StreamMode,OpenShardCount]' --output text
orders-od	ON_DEMAND	4
```

## Um mês estável

Os eventos de pedido da Quitanda, todos eles: 20 milhões de registros por dia, de cerca de 1 KB cada,
o que dá 20 GB por dia, lidos por dois consumidores, uma checagem de fraude e a cópia para o S3 da
lição 21. O tráfego não é plano: no almoço e no jantar ele corre a cinco vezes a média do dia. Um mês
aqui tem 30 dias e 730 horas.

**Dimensionar o stream provisionado vem primeiro.** A média é de 20 milhões de registros em 86.400
segundos, cerca de 231 por segundo; o pico é cinco vezes isso, cerca de 1.157 registros por segundo,
mais que os 1.000 de um shard. Em bytes o pico é de cerca de 1,2 MB por segundo, também acima de um
shard. Dois shards ficariam exatamente cheios no pico; três deixam folga.

| provisionado, 3 shards | conta | USD por mês |
|---|---|---|
| shard-horas | 3 × 730 × 0,03000 | 65,70 |
| PUT payload units | 20 milhões × 30 dias = 600 milhões, × 0,02800 por milhão | 16,80 |
| **total** | | **82,50** |

| on-demand | conta | USD por mês |
|---|---|---|
| o stream | 730 × 0,08000 | 58,40 |
| dados escritos | 20 GB × 30 = 600 GB, × 0,16000 | 96,00 |
| dados lidos, dois consumidores | 2 × 600 GB × 0,08000 | 96,00 |
| **total** | | **250,40** |

**Três vezes o preço pelos mesmos registros**, e a diferença cresce a cada consumidor acrescentado,
já que no on-demand cada um paga a linha de leitura e num stream provisionado não paga nada a mais até
acabarem os 2 MB por segundo de leitura dos shards. Para uma carga conhecida e estável, o provisionado
ganha no preço, e o custo de ganhar é que alguém vigia o tráfego e faz o reshard quando ele cresce.

**Guardar uma semana em vez de um dia** é a linha de retenção estendida, paga por shard-hora em cima
do próprio shard: 3 × 730 × 0,04000 = 87,60 por mês, o que mais que dobra a conta do provisionado, para
170,10. No on-demand, a mesma retenção é cobrada por gigabyte guardado, uma linha que a tabela não
imprime, então não tem preço aqui.

## Um mês com uma promoção

Agora dê ao mesmo mês uma sexta-feira em que uma promoção manda 30 MB por segundo durante uma hora.
**Um stream provisionado precisa ser dimensionado para o pico ou passar por reshard a tempo dele.**
Dimensionado para o pico, precisa de 30 shards no mês inteiro, 30 × 730 × 0,03000 = 657,00 só em
shard-horas, oito vezes a conta estável, por uma capacidade usada uma hora em 730. Fazer o reshard
para 30 antes da promoção e voltar depois mantém a conta perto de 82,50, e faz a promoção depender de
alguém lembrar de fazê-lo, e de o reshard terminar a tempo.

O stream on-demand não precisa de decisão nenhuma sobre capacidade. A hora da promoção é 30 MB × 3.600
segundos, 108 GB, que custam 108 × 0,16000 = 17,28 escritos e 2 × 108 × 0,08000 = 17,28 lidos, e o mês
passa a 250,40 + 34,56 = 284,96, menos da metade do stream dimensionado para o pico. **O que o
on-demand vende não é um preço menor; é não precisar saber o pico de antemão.**

Ele também não sabe o pico de antemão, e esta parte vem da documentação da AWS e não de uma execução:
um stream on-demand absorve de uma vez até o dobro da maior taxa de escrita que viu nos 30 dias
anteriores, e cresce além disso ao longo de alguns minutos. Um salto para vinte e cinco vezes o pico
de costume é estrangulado enquanto ele cresce, a não ser que o stream já tenha visto um pico assim. Um
stream novo cujo tráfego ninguém consegue prever começa no on-demand; um stream cujo tráfego foi
vigiado por alguns meses costuma ir para o provisionado, e um stream pode trocar de um modo para o
outro enquanto roda.
