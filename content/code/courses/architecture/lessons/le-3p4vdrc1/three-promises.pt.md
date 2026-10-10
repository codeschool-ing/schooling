---
title: No máximo uma vez, pelo menos uma vez, exatamente uma vez
version: 1
---

Um consumidor recebe uma mensagem, faz um trabalho e diz ao broker que terminou. Cada um desses três
passos pode ser interrompido por uma queda, uma falha de rede ou um timeout. **Depois de que passo fica
a confirmação decide quanto custa uma queda**, e as três garantias de entrega são as três respostas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Duas linhas do tempo para uma mensagem. Na primeira, o consumidor confirma antes de fazer o trabalho; cai durante o trabalho, e a mensagem some sem ser processada: no máximo uma vez. Na segunda, o consumidor faz o trabalho e depois confirma; cai depois do trabalho e antes da confirmação, e o broker entrega a mensagem de novo, então o trabalho acontece duas vezes: pelo menos uma vez.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">no máximo uma vez: confirma antes</text><rect x=\"40\" y=\"48\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">receber</text><rect x=\"170\" y=\"48\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">confirmar</text><rect x=\"270\" y=\"48\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">trabalho…  queda</text><rect x=\"470\" y=\"48\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mensagem some, nunca feita</text><text x=\"26\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">pelo menos uma vez: trabalha, depois confirma</text><rect x=\"40\" y=\"148\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">receber</text><rect x=\"170\" y=\"148\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">trabalho: feito</text><rect x=\"300\" y=\"148\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">queda</text><rect x=\"400\" y=\"148\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reentregue</text><rect x=\"530\" y=\"148\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">trabalho feito duas vezes</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">exatamente uma vez exige que o próprio trabalho reconheça a repetição</text></svg>", "caption": "Onde fica a confirmação decide que falha você recebe. Antes do trabalho, uma queda perde a mensagem; depois dele, uma queda repete o trabalho."}
```

| garantia | como é construída | o que uma queda custa |
| --- | --- | --- |
| **no máximo uma vez** | confirma ao receber, depois trabalha | uma mensagem que nunca é processada |
| **pelo menos uma vez** | trabalha, depois confirma | uma mensagem processada duas vezes |
| **exatamente uma vez** | pelo menos uma vez, mais um jeito de reconhecer e ignorar uma repetição | só a contabilidade |

No máximo uma vez é o certo quando perder uma mensagem é mais barato do que tratá-la duas vezes: uma
amostra de métrica, um aviso de "usuário digitando". Para qualquer coisa que mude dinheiro, estoque ou a
visão que um cliente tem do pedido, é o padrão errado, porque a perda é silenciosa.

Pelo menos uma vez é o que o RabbitMQ, o Kafka e toda fila gerenciada dão quando um consumidor confirma
depois do trabalho. **É o padrão honesto**, e o preço são as duplicatas, que chegam no curso normal das
coisas: um consumidor que cai antes da confirmação, uma rede que perde a confirmação no caminho, um tempo
de visibilidade menor que um tratamento lento, uma releitura como a da aula 6.

## Exatamente uma vez se constrói, não se compra

A crença comum é que alguns brokers entregam exatamente uma vez. **Nenhum broker consegue, de ponta a
ponta**, porque a ponta é o seu código: entre "a cobrança está gravada" e "o broker fica sabendo" sempre
há um momento em que uma queda deixa os dois discordando, e o broker não enxerga dentro da sua transação
para saber de que lado desse momento ela estava.

O que os brokers oferecem é mais estreito e ainda útil. A **semântica exatamente uma vez** do Kafka deixa
sem duplicatas as retentativas de um produtor e um laço de ler, processar e escrever que fica dentro do
Kafka. As filas FIFO da SQS descartam um id de mensagem repetido dentro de cinco minutos. As duas coisas
são reais, e **nenhuma cobre o banco em que o seu consumidor escreve**, que é onde está o dinheiro. Um
processamento efetivamente único é montado com entrega pelo menos uma vez e um consumidor idempotente, e
o resto desta aula o constrói.
