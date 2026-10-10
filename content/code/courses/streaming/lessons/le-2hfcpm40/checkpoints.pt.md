---
title: O checkpoint, e o que um reinício lê
version: 1
---

O seu consumidor da lição 4 guardava a posição no Kafka, fazendo commit de offsets para o grupo de
consumidores. **O Spark não faz isso. Ele guarda a posição no diretório de checkpoint**, junto com
as janelas abertas, e uma consulta que recomeça lê esse diretório para saber o que já fez. Perca o
diretório e a consulta recomeça do zero; mantenha-o e uma queda custa no máximo um batch.

Olhe dentro do que a execução em update escreveu:

```
ubuntu@stream:~/work$ ls ~/spark/ckpt/update ~/spark/ckpt/update/state/0
```

| entrada | o que tem dentro |
|---|---|
| `metadata` | o id da consulta, escrito uma vez, para um reinício saber que é a mesma consulta |
| `offsets` | um arquivo por batch, escrito **antes** de o batch rodar: quais offsets ele vai ler |
| `commits` | um arquivo por batch, escrito **depois** de a saída do batch chegar ao sink |
| `sources` | o que a fonte Kafka encontrou quando a consulta começou pela primeira vez |
| `state` | as janelas abertas, um diretório por partição de shuffle, duas aqui |

Os dois logs são o coração da coisa. Um batch é planejado, o plano vai para `offsets`, o batch
roda, as linhas dele são entregues ao sink, e só então ele é escrito em `commits`. **Um batch em
`offsets` sem arquivo correspondente em `commits` é um batch que não terminou**, e a primeira coisa
que um reinício faz é rodá-lo de novo, exatamente com os offsets que ele tinha, e não com o que
chegou depois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A vida de um micro-batch, N, em relação ao checkpoint. Primeiro o Spark escreve offsets/N, o plano de quais offsets o batch vai ler. Depois o batch roda, lendo esses offsets e o estado. Depois as linhas dele são escritas no sink. Por último, commits/N é escrito. Se o processo morre depois de offsets/N e antes de commits/N, um reinício encontra o plano sem o commit e roda o batch N de novo com os mesmos offsets, então o sink pode receber o batch N duas vezes.\" data-fig=\"l12-checkpoint\"><defs><marker id=\"l12-checkpoint-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-checkpoint-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">escreve offsets/N</text><text x=\"100\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o plano</text><rect x=\"205\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">roda o batch N</text><text x=\"275\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offsets + estado</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">escreve no sink</text><text x=\"450\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linhas saem</text><rect x=\"555\" y=\"50\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">escreve commits/N</text><text x=\"625\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">batch concluído</text><path d=\"M 172 75 L 202 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-checkpoint-ah-8343)\"></path><path d=\"M 347 75 L 377 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-checkpoint-ah-8343)\"></path><path d=\"M 522 75 L 552 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-checkpoint-ah-8343)\"></path><line x1=\"530\" y1=\"112\" x2=\"544\" y2=\"126\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"544\" y1=\"112\" x2=\"530\" y2=\"126\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"537\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">queda aqui</text><path d=\"M 537 150 Q 537 185 406.0 185 Q 275 185 275 106\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12-checkpoint-ah-83)\"></path><text x=\"360\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">reinício: offsets/N não tem commit, então o batch N roda de novo, mesmos offsets</text></svg>", "caption": "O plano é escrito antes do batch e o commit depois; uma queda no meio significa que o mesmo batch roda de novo."}
```

O plano do último batch é um arquivo de texto pequeno. A segunda linha guarda o watermark e a hora
em que o batch rodou, e a terceira, os offsets por partição até onde o batch leu:

```
ubuntu@stream:~/work$ tail -1 ~/spark/ckpt/update/offsets/5
```

Partição 0 até 41, partição 1 até 159, e a partição 2, onde não cai a chave de nenhuma loja, em 0.
São as 200 vendas, todas.

## Rodando de novo

Rode a mesma consulta, com o mesmo checkpoint, sobre um tópico que não mudou:

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

**Ela não imprimiu nada.** `startingOffsets` dizia `earliest`, e o Spark ignorou: essa opção só é
lida na primeira vez que uma consulta roda, e depois disso quem manda é o checkpoint. Não havia
nada depois do offset 159 para ler, então nenhum batch rodou.

Agora chegam mais duas vendas, digitadas no produtor de console do Kafka em vez de virem do caixa:
uma do Recife às 09:38, que pertence à janela de 09:35, e uma de Natal às 09:21, que está dezessete
minutos atrás da venda mais recente que o Spark já viu:

```
ubuntu@stream:~/work$ printf '%s\n' 'recife|{"sale": "rec-000201", "shop": "recife", "book": "bk-03", "qty": 1, "cents": 2990, "at": "2026-03-02T09:38:00-03:00"}' 'natal|{"sale": "nat-000202", "shop": "natal", "book": "bk-01", "qty": 1, "cents": 3990, "at": "2026-03-02T09:21:00-03:00"}' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property 'key.separator=|'
```

`parse.key=true` e o separador fazem o produtor dividir cada linha em chave e valor, como o
`tills.py` faz. Rode a consulta pela terceira vez:

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

A numeração continua do batch 6, porque o checkpoint lembra os batches de 0 a 5. **A janela de
09:35 passou de 13 vendas para 14**, o que só é possível porque a contagem de 13 voltou do
diretório `state`: o processo que contou aquelas 13 tinha terminado minutos antes.

E a venda de Natal não está em saída nenhuma. O watermark era 09:34:41 quando esta execução
começou, a janela de 09:20 termina às 09:25, e o Spark já a tinha esquecido. **Uma venda atrás do
watermark é descartada sem uma palavra**, que é exatamente o que a lição 11 disse que um watermark
compra e custa.

## Nenhum grupo de consumidores

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

A lista está vazia. O Spark leu o tópico três vezes e o Kafka não guarda registro nenhum de até
onde ele chegou, porque o Spark atribui a si mesmo as partições e nunca faz commit. **Ferramentas
que medem o atraso a partir de um grupo de consumidores, que a lição 16 usa, não veem nada de uma
consulta Spark**; o Spark informa o próprio progresso, pelo status da consulta e pela página web na
porta 4040.

Duas consequências valem levar daqui. Um checkpoint pertence a uma consulta: apontar uma consulta
alterada para um checkpoint antigo é um jeito de restaurar um estado que já não serve, e o guia do
Spark lista quais mudanças ele aceita. E um checkpoint é a única cópia da posição e do estado da
consulta, então **num cluster de verdade ele mora num armazenamento que sobrevive à máquina**, como
o HDFS ou um object store, nunca no disco local de um nó que pode sumir.
