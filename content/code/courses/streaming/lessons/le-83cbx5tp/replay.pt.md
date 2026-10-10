---
title: Replay: voltando um grupo no log
version: 1
---

**Uma fila esquece o que entregou; um log não, e é isso que torna o replay possível.** Ler uma
mensagem só move a posição do leitor, então mover a posição para trás faz o leitor ver as mesmas
mensagens de novo. O motivo mais comum é um bug: o programa de estoque contou errado as devoluções de
segunda às nove até a correção entrar na quarta, e o estoque que ele escreveu nesse meio-tempo está
errado. Com as vendas ainda no tópico, a cura é corrigir o programa, voltar o grupo dele para segunda
às nove e deixá-lo ler tudo de novo.

Isso vem com duas condições. **As mensagens precisam ainda estar lá**, então o replay só volta até
onde vai a retenção do tópico, que a lição 3 configurou e a lição 17 põe preço. E **o programa
precisa ser seguro para rodar duas vezes sobre a mesma entrada**: replay é at-least-once de
propósito, então um consumidor que soma a um total em vez de defini-lo dobra tudo o que reprocessa. A
lição 8 é sobre fazer um consumidor assim.

## O grupo precisa estar parado antes

`kafka-consumer-groups.sh --reset-offsets` move as posições confirmadas de um grupo. O consumidor da
primeira seção ainda está rodando no segundo shell, como membro de `stock`. Tente mesmo assim:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-earliest --execute

Error: Assignments can only be reset if the group 'stock' is inactive, but the current state is Stable.

GROUP           TOPIC           PARTITION  NEW-OFFSET
```

**Recusado, e com razão.** Um membro rodando guarda a posição em memória e a confirma a cada segundo;
qualquer coisa escrita por baixo dele seria sobrescrita um instante depois, ou pior, só metade seria.
Pare o consumidor com Ctrl+C. A tela dele, desde o começo da seção de lag:

```
ubuntu@stream:~/work$ python slow_consumer.py --delay 0.1
16:36:53 assigned [0, 1, 2]
16:36:59 50 done, last rec-000050 from partition 1 offset 41
16:37:04 100 done, last car-000100 from partition 0 offset 17
16:37:09 150 done, last car-000150 from partition 0 offset 30
16:37:14 200 done, last rec-000200 from partition 1 offset 158
16:37:19 250 done, last oli-000250 from partition 1 offset 200
16:37:24 300 done, last rec-000300 from partition 1 offset 238
16:37:29 350 done, last nat-000350 from partition 1 offset 276
16:37:34 400 done, last rec-000400 from partition 1 offset 318
16:37:39 450 done, last rec-000450 from partition 1 offset 354
16:37:44 500 done, last oli-000500 from partition 1 offset 392
16:37:49 550 done, last nat-000550 from partition 1 offset 429
16:37:54 600 done, last car-000600 from partition 0 offset 134
16:38:05 revoked [0, 1, 2]
```

## Olhe antes de mover

Todo reset tem dois modos. Sem `--execute` ele é um dry run, que imprime para onde cada partição iria
e não muda nada, e **é o que se roda primeiro, toda vez**:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-earliest --dry-run

GROUP           TOPIC           PARTITION  NEW-OFFSET
stock           sales           2          0
stock           sales           1          0
stock           sales           0          0
```

`--to-earliest` manda cada partição para a mensagem mais antiga ainda guardada, e o grupo leria o
tópico inteiro de novo. Raramente é isso que um bug pede. **`--to-datetime` move cada partição para a
primeira mensagem escrita naquele instante ou depois**, que é como se diz "a partir de segunda às
nove". O instante aqui é quinze segundos depois de os caixas começarem na seção de lag, no meio das
600 vendas. O seu é um instante do seu próprio relógio, no mesmo formato; o `-03:00` é a diferença de
São Paulo para o UTC, e sem ele a ferramenta lê o horário como UTC:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-datetime 2026-10-10T16:37:09.000-03:00 --execute

Warn: Partition 2 from topic sales is empty. Falling back to latest known offset.

GROUP           TOPIC           PARTITION  NEW-OFFSET
stock           sales           2          0
stock           sales           1          233
stock           sales           0          59
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock

Consumer group 'stock' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock           sales           0          59              135             76              -               -               -
stock           sales           1          233             465             232             -               -               -
stock           sales           2          0               0               0               -               -               -
```

Cada partição foi para a primeira venda escrita depois daquele instante, e o grupo agora tem mais ou
menos metade do tópico para ler de novo. Da próxima vez que `slow_consumer.py --delay 0.1` iniciar,
ele começa dali.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas partições desenhadas ao longo de um relógio, cada mensagem posta na hora em que foi escrita. Uma linha vertical marca o datetime dado ao reset. Em cada partição, a nova posição do grupo é a primeira mensagem escrita naquele instante ou depois, então as duas partições vão para offsets diferentes que pertencem ao mesmo momento.\" data-fig=\"l16-reset\"><defs><marker id=\"l16-reset-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">partição 0</text><line x1=\"120\" y1=\"70\" x2=\"680\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"136.8\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"187.2\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"232.0\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"304.8\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"411.2\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"456.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"517.5999999999999\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"596.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"652.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"411.2\" cy=\"70\" r=\"9\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"425.2\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nova posição: offset 4</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">partição 1</text><line x1=\"120\" y1=\"150\" x2=\"680\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"131.2\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"159.2\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"181.6\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"209.60000000000002\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"243.2\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"271.20000000000005\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"293.6\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"332.8\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"366.4\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"400.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"428.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"467.2\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"489.6\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"528.8\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"562.4000000000001\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"590.4\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"624.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"657.6\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"400.0\" cy=\"150\" r=\"9\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"414.0\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nova posição: offset 9</text><line x1=\"388.8\" y1=\"30\" x2=\"388.8\" y2=\"185\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></line><text x=\"388.8\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--to-datetime</text><path d=\"M 120 200 L 680 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-reset-ah-8343)\"></path><text x=\"680\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timestamp do registro</text></svg>", "caption": "Um reset por datetime escolhe um offset por partição; os offsets diferem, o momento é o mesmo."}
```

**O datetime é comparado com o timestamp do registro, não com nada dentro da mensagem.** As vendas
carregam `"at": "2026-03-02T09:..."`, o relógio do próprio caixa, e o reset não sabe nada disso: ele
pediu ao broker os offsets pela hora em que cada registro foi escrito. Quando os dois relógios
discordam, como discordam quando um caixa manda um acúmulo, o reset vai pelo do broker, e a lição 9
diz por que isso importa.

## Os outros jeitos de dizer onde

| opção | move cada partição para |
|---|---|
| `--to-earliest`, `--to-latest` | a mensagem mais antiga guardada, ou o fim (pula tudo o que espera) |
| `--to-datetime 2026-03-02T09:00:00.000` | a primeira mensagem escrita naquele instante ou depois |
| `--by-duration PT2H` | o mesmo, para um instante duas horas atrás |
| `--shift-by -100` | 100 mensagens antes de onde está, por partição |
| `--to-offset 1234` | exatamente aquele offset (útil com `--topic sales:1` para uma partição) |
| `--from-file plan.csv` | o que um CSV diz, escrito antes por `--export` |

`--to-latest` merece um aviso só para ele. É o jeito rápido de sair de um lag que ninguém consegue
esvaziar, e **toda mensagem que ele pula nunca é tratada**. Às vezes é o certo, uma visão ao vivo das
lojas que só se importa com o agora; para o estoque, é uma contagem errada para sempre.
