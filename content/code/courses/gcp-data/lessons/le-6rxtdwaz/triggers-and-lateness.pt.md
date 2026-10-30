---
title: Gatilhos, atraso permitido e acumulação
version: 1
---

**Uma janela diz quais elementos andam juntos; um gatilho diz quando emitir o que a janela guarda, e
pode dizer isso mais de uma vez.** Cada emissão é um **painel** (pane). O gatilho padrão dispara um
painel, quando a marca d'água passa do fim da janela, e foi só isso que a seção anterior viu. Três
ajustes mudam isso, e entre eles decidem se um pedido atrasado conta, quando um resultado aparece
pela primeira vez, e o que um consumidor tem de fazer com um segundo resultado para a mesma janela:

| ajuste | no `late.py` | o que decide |
|---|---|---|
| **atraso permitido** | `--lateness 300` | por quanto tempo depois de a marca d'água passar uma janela o estado dela é guardado, para que dados atrasados ainda contem |
| **um gatilho atrasado** | `AfterCount(1)` | quando uma chegada atrasada é emitida: aqui, um painel novo para cada uma |
| **um gatilho antecipado** | `--early`, `AfterProcessingTime(60)` | um painel antes de a marca d'água chegar: aqui, um minuto de tempo de processamento depois do primeiro elemento |
| **modo de acumulação** | `--mode` | se cada painel traz tudo até ali, ou só o que é novo desde o anterior |

## Cinco minutos de atraso permitido

```
ana@laptop:~/gcp$ python3 late.py --lateness 300
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   151.50  LATE     pane 1
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    80.00  LATE     pane 1
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 0
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 0
```

**Dois dos três pedidos atrasados voltaram, cada um como um painel `LATE`.** A janela das 19:00 de
Pinheiros disparou no horário com 128,00, como antes, e de novo com 151,50 quando o `o-504` chegou,
que é o total certo. A janela das 19:05 fez o mesmo para o `o-510`: 72,00 no horário, 80,00
atrasado. O índice do painel conta as emissões de uma janela e chave, 0 e depois 1.

**O `o-507` continua faltando.** O atraso permitido é medido contra a marca d'água, não contra o
relógio da parede: a janela das 19:00 termina às 19:05, então com 300 segundos permitidos ela é
guardada até a marca d'água chegar às 19:10, e então some de vez. O `o-508` chegou às 19:11:16 e
moveu a marca d'água para 19:10:16. O `o-507` chegou às 19:12:30, um minuto e catorze segundos
depois de o estado da janela dele ter sido jogado fora, e foi descartado, tão em silêncio quanto
antes. **O atraso permitido é um limite que você escolhe para quanto estado o pipeline guarda**, e
sempre fica alguma coisa de fora: aqui, um pedido que passou 7 minutos e 40 segundos no caminho
contra uma folga de 5 mais o minuto da marca d'água.

## Painéis antecipados, acumulando

```
ana@laptop:~/gcp$ python3 late.py --lateness 300 --early
19:00:00-19:05:00  Moema        45.90  EARLY    pane 0
19:00:00-19:05:00  Pinheiros   128.00  EARLY    pane 0
19:00:00-19:05:00  Moema        55.80  EARLY    pane 1
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 2
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 1
19:05:00-19:10:00  Moema        15.00  EARLY    pane 0
19:00:00-19:05:00  Pinheiros   151.50  LATE     pane 2
19:05:00-19:10:00  Pinheiros    72.00  EARLY    pane 0
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 1
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros    56.00  EARLY    pane 0
19:05:00-19:10:00  Pinheiros    80.00  LATE     pane 2
19:10:00-19:15:00  Moema        22.00  EARLY    pane 0
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 1
```

**Agora cada janela fala antes de estar completa.** A janela das 19:00 de Moema disse primeiro
45,90, um minuto de tempo de processamento depois de o `o-501` chegar, quando tinha só esse pedido.
Disse 55,80 quando o `o-503` completou um minuto lá dentro, e então 55,80 de novo no horário, porque
nada novo tinha vindo. É essa a troca que um gatilho antecipado faz: uma tela no depósito vê um
número em um minuto em vez de às 19:06, e o primeiro número que vê está errado para menos.

**No modo acumulativo cada painel é a janela inteira até ali**, então o último painel de uma janela e
chave é a resposta, e um consumidor que guarda só o painel mais recente por janela está sempre
certo. É isso que deixa a tabela do BigQuery ou a tela mais adiante ser gravada substituindo uma
linha, com a janela e o bairro como chave.

## Painéis antecipados, descartando

```
ana@laptop:~/gcp$ python3 late.py --lateness 300 --early --mode discarding
19:00:00-19:05:00  Moema        45.90  EARLY    pane 0
19:00:00-19:05:00  Pinheiros   128.00  EARLY    pane 0
19:00:00-19:05:00  Moema         9.90  EARLY    pane 1
19:00:00-19:05:00  Moema         0.00  ON_TIME  pane 2
19:00:00-19:05:00  Pinheiros     0.00  ON_TIME  pane 1
19:05:00-19:10:00  Moema        15.00  EARLY    pane 0
19:00:00-19:05:00  Pinheiros    23.50  LATE     pane 2
19:05:00-19:10:00  Pinheiros    72.00  EARLY    pane 0
19:05:00-19:10:00  Moema         0.00  ON_TIME  pane 1
19:05:00-19:10:00  Pinheiros     0.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros    56.00  EARLY    pane 0
19:05:00-19:10:00  Pinheiros     8.00  LATE     pane 2
19:10:00-19:15:00  Moema        22.00  EARLY    pane 0
19:10:00-19:15:00  Moema         0.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros     0.00  ON_TIME  pane 1
```

**No modo de descarte cada painel é só o que chegou desde o anterior.** A janela das 19:00 de Moema
disse 45,90, depois 9,90, que é o `o-503` sozinho, depois 0,00 no horário: o painel no horário
disparou embora nada tivesse chegado desde o último antecipado, e a soma de nada é zero. O painel
atrasado de Pinheiros para as 19:00 é 23,50, o `o-504` sozinho, onde o modo acumulativo disse 151,50.
**Aqui a resposta é a soma de todos os painéis**, e um consumidor tem de somá-los: substituir uma
linha a cada painel, como fez o consumidor acumulativo, deixaria a primeira janela de Pinheiros em
23,50.

Então o modo não é questão de gosto. É um contrato com quem lê a saída:

- **acumulativo** serve para um destino que sobrescreve por chave, uma linha por janela numa tabela
  ou uma entrada num cache; um painel entregue em dobro não faz mal, e é a idempotência da aula 20
  outra vez;
- **descarte** serve para um destino que soma, como um contador ou um fluxo que outro pipeline soma,
  e emite menos; mas um painel entregue em dobro é contado em dobro.

## A segunda saída do erro da aula 21

A aula 21 recusou agrupar um fluxo ilimitado na janela global com o gatilho padrão, e citou duas
saídas. As janelas foram a primeira. A segunda é manter a janela global e dar a ela um gatilho que
dispara pelo tempo de processamento, o que transforma o pipeline em totais correntes do fluxo
inteiro, renovados a cada minuto:

```python
beam.WindowInto(GlobalWindows(),
                trigger=trigger.Repeatedly(trigger.AfterProcessingTime(60)),
                accumulation_mode=trigger.AccumulationMode.ACCUMULATING)
```

**Essa linha é mostrada e não rodada nesta aula.** Serve para um total desde o começo, como os
pedidos de hoje quando o pipeline é reiniciado toda meia-noite. Não serve para uma pergunta sobre um
intervalo, porque a janela global não tem intervalo: um pedido atrasado nunca está atrasado, já que
a janela nunca termina, e nada nunca diz que um total é final.
