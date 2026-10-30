---
title: Marcas d'água, e o que acontece com os atrasados
version: 1
---

**Uma janela pela hora do evento não pode ser publicada no instante em que o minuto dela acaba, e
não pode esperar para sempre.** Às 20:01:00 pelo relógio dos clientes, cliques das 20:00 ainda estão
em celulares, em túneis e em laços de nova tentativa. Espere pouco e a janela sai sem eles; espere
demais e a tela de operações mostra um número de cinco minutos atrás. A **marca d'água (watermark)**
é como um processador de stream diz quanto esperou: uma linha móvel na hora dos eventos que quer dizer
"tudo o que é mais velho que isto já chegou, no que me diz respeito". Uma janela é definitiva quando
a marca d'água passa do fim dela, e um evento mais velho que a marca d'água está **atrasado**.

O programa de duas seções atrás traçou a marca d'água na maior hora de evento vista menos uma
tolerância. Os mesmos dez checkouts, agora mantendo o atrasado em vez de descartá-lo:

```
ana@laptop:~/azure$ python windows.py adjust 20
10 events, enqueued from 18:40:31.980000 to 18:40:31.980000 UTC
window 20:00-20:01  4 checkouts  closed by #6
#7  at 20:00:55  15 s behind the watermark: adjusted to 20:01:10
window 20:01-20:02  4 checkouts  closed by #10
window 20:02-20:03  1 checkouts  still open
window 20:03-20:04  1 checkouts  still open
```

**O checkout 7 foi contado, no minuto errado.** Ele aconteceu às 20:00:55, chegou quando a marca
d'água estava em 20:01:10, e o `adjust` adiantou a hora dele até a marca d'água, então a janela das
20:01 tem quatro checkouts e a das 20:00 continua com quatro. O total da noite agora está certo e o
retrato minuto a minuto não. **Nenhuma das escolhas é a correta; elas erram em direções
diferentes.** O `drop` mantém cada janela publicada fiel aos cliques que contou e perde um evento. O
`adjust` não perde evento nenhum e põe um numa janela em que ele não aconteceu. Uma contagem de
receita por dia prefere o `adjust`; um gráfico de quando as pessoas compram prefere o `drop`.

O terceiro jeito é esperar mais. Os mesmos eventos, descartando de novo, com sessenta segundos de
tolerância:

```
ana@laptop:~/azure$ python windows.py drop 60
10 events, enqueued from 18:40:31.980000 to 18:40:31.980000 UTC
window 20:00-20:01  5 checkouts  closed by #8
window 20:01-20:02  3 checkouts  closed by #10
window 20:02-20:03  1 checkouts  still open
window 20:03-20:04  1 checkouts  still open
```

**Nada se atrasou e a janela das 20:00 tem os cinco checkouts, mas fechou mais tarde**: com vinte
segundos ela foi fechada pelo checkout 6, com sessenta ficou aberta até o checkout 8, das 20:02:05,
mais de um minuto de hora de evento depois do fim dela. Numa tela ao vivo, isso é um minuto a mais
antes de o número aparecer. **A tolerância é uma troca entre completude e atraso, e só o uso do
número pode defini-la.**

## Como o Stream Analytics faz

O Stream Analytics tem as mesmas três escolhas, em duas configurações do job e uma política, que ele
chama de ordenação de eventos:

| configuração | o que ela tolera | o nome no Terraform |
|---|---|---|
| tolerância a fora de ordem | eventos que chegam atrás de eventos com hora posterior, até tantos segundos | `events_out_of_order_max_delay_in_seconds` |
| tolerância a chegada tardia | eventos cuja hora própria é mais velha que a hora de chegada em até tanto | `events_late_arrival_max_delay_in_seconds` |
| a política | o que acontece com eventos além de qualquer das tolerâncias: `Adjust` ou `Drop` | `events_out_of_order_policy` |

O programa desta lição só tinha a primeira, porque o emulador entregou tudo de uma vez e a hora de
chegada não lhe dizia nada. **A tolerância a chegada tardia compara dois relógios, o do app e o do
Azure**, e é ela que pega o celular no túnel mesmo quando nenhum evento posterior chegou para mover
uma marca d'água. A documentação da Microsoft descreve o `Adjust` como mover a hora desse evento para
a borda da tolerância, o mesmo movimento que o programa fez. E **uma tolerância a fora de ordem se
paga em latência**: o serviço segura os eventos de tantos segundos para ordená-los antes que qualquer
janela possa fechar, que é o atraso que a execução com sessenta segundos mostrou.

O provider do Terraform conhece os limites das duas, e o `validate` recusa um valor fora deles. No
diretório do job, com o arquivo da primeira seção, três mudanças, uma de cada vez:

```
ana@laptop:~/azure/tf/asa$ cp main.tf.orig main.tf && sed -i 's/_out_of_order_max_delay_in_seconds = 20/_out_of_order_max_delay_in_seconds = 600/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected events_out_of_order_max_delay_in_seconds to be in the range (0 - 599), got 600
ana@laptop:~/azure/tf/asa$ cp main.tf.orig main.tf && sed -i 's/_late_arrival_max_delay_in_seconds = 60/_late_arrival_max_delay_in_seconds = 1814400/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected events_late_arrival_max_delay_in_seconds to be in the range (-1 - 1814399), got 1814400
ana@laptop:~/azure/tf/asa$ cp main.tf.orig main.tf && sed -i 's/"Adjust"/"Keep"/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected events_out_of_order_policy to be one of ["Adjust" "Drop"], got Keep
```

**A tolerância a fora de ordem para em 599 segundos**, pouco menos de dez minutos, e a de chegada
tardia em 1.814.399 segundos, um segundo a menos que 21 dias; `-1` quer dizer esperar
indefinidamente. A política é `Adjust` ou `Drop` e nada mais. Essas são as verificações do provider,
lidas do esquema dele; o serviço aplica as suas quando o job é criado.

**Uma pergunta que a marca d'água não responde é se o relógio do app está certo.** O `TIMESTAMP BY
at` confia no campo; um celular com o relógio uma hora adiantado envia cliques do futuro, empurra a
marca d'água uma hora para a frente e faz de todo clique honesto daquela hora um atrasado. Um job que
conta pela hora de um app faz bem em compará-la com a hora de chegada e em tratar uma diferença grande
em qualquer direção como um relógio ruim e não como um evento, que é o que a tolerância a chegada
tardia faz numa direção.
