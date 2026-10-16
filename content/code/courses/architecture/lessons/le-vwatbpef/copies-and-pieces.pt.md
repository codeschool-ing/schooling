---
title: Cópias e pedaços
version: 1
---

Um único servidor de banco tem dois limites, e eles são problemas diferentes. Ele pode **falhar**: um
disco, uma fonte, uma atualização do kernel, uma região. E pode ser **pequeno demais**: mais dados do que
os discos comportam, mais escritas do que uma máquina aguenta, mais leituras do que os processadores
conseguem responder. Os dois têm respostas diferentes, e confundi-los é um jeito comum de comprar a
errada.

A **replicação** guarda os mesmos dados em várias máquinas. Se uma falha, outra tem tudo. As leituras
podem ser espalhadas pelas cópias, então ela também ajuda quando as leituras são o gargalo. O que ela
não faz é abrir espaço para mais dados, porque toda cópia guarda tudo, nem aguentar mais escritas, porque
toda escrita ainda tem de chegar a toda cópia.

O **sharding**, também chamado de particionamento, divide os dados para cada máquina guardar uma parte:
os pedidos dos clientes de A a H aqui, de I a Q ali. Cada máquina recebe as escritas da sua parte, então
escritas e armazenamento crescem com o número de máquinas. O que ele não faz é sobreviver a uma falha:
perca a máquina com os clientes de A a H e esses clientes somem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois jeitos de usar três máquinas para uma tabela de pedidos. Replicação, à esquerda: cada máquina guarda todos os pedidos, de A a Z, uma delas recebe as escritas e as outras duas a copiam. Sharding, à direita: cada máquina guarda um terço dos pedidos, de A a H, de I a Q e de R a Z, e cada uma recebe as escritas da sua parte.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">replicação: cópias</text><text x=\"535\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">sharding: pedaços</text><rect x=\"40\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–Z</text><text x=\"85\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">líder</text><rect x=\"140\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–Z</text><text x=\"185\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cópia</text><rect x=\"240\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–Z</text><text x=\"285\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cópia</text><rect x=\"390\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–H</text><text x=\"435\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escritas próprias</text><rect x=\"490\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">I–Q</text><text x=\"535\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escritas próprias</text><rect x=\"590\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R–Z</text><text x=\"635\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escritas próprias</text><text x=\"185\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sobrevive a uma falha; mais leitores</text><text x=\"535\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais dados; mais escritas</text><path d=\"M360 50 L360 230\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path></svg>", "caption": "Replicação guarda os mesmos dados em vários lugares, para falhas e para leituras. Sharding põe dados diferentes em cada lugar, para tamanho e para escritas. Sistemas de verdade costumam fazer as duas coisas."}
```

Então sistemas de verdade fazem as duas coisas: os dados são divididos em shards, e **cada shard é
replicado**. O Kafka faz isso dentro de um produto só, como a aula 6 mostrou: um tópico é dividido em
partições, que é sharding, e cada partição tem réplicas, que é replicação. Esta aula pega um de cada vez,
e depois junta os dois.

## Antes de qualquer um: uma máquina maior

Nenhum dos dois é a primeira coisa a buscar. Um único servidor PostgreSQL numa máquina grande dá conta
de mais do que a maioria das empresas jamais pede a ele: terabytes de dados e dezenas de milhares de
transações por segundo estão ao alcance de um servidor bem ajustado. Escalar **para cima**, para uma
máquina maior, mantém toda consulta, join, restrição e transação exatamente como era. Escalar **para os
lados**, para muitas máquinas, muda algumas delas, como mostra a segunda metade da aula.

A ordem de costume é: replicar cedo, porque falhas não esperam você ficar grande; escalar para cima
enquanto der; e fazer sharding quando uma máquina, a maior que você consegue comprar ou alugar, não
basta mais para as escritas ou para os dados.
