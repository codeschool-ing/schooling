---
title: A camada de armazenamento, seis cópias e um quórum
version: 1
---

**O Aurora é PostgreSQL ou MySQL em cima de um sistema de armazenamento que a AWS construiu para ele, e o
armazenamento é toda a diferença.** O engine que interpreta o seu SQL é o conhecido, com os mesmos drivers
e quase o mesmo comportamento. Por baixo, onde o RDS dá a uma instância um volume só dela, o Aurora dá ao
cluster inteiro um volume compartilhado e distribuído, espalhado por três zonas e gravado seis vezes. Tudo o
que faz o Aurora ter failover mais rápido, replicar com menos atraso e custar diferente vem dessa única
mudança.

**A ideia errada é que o Aurora é "RDS com discos mais rápidos".** Uma instância RDS grava páginas de dados
no volume dela, e o Multi-AZ copia essas páginas para um segundo volume. As instâncias do Aurora não gravam
página de dados nenhuma. O que vem a seguir é o projeto publicado pela AWS, do artigo que os engenheiros
dela apresentaram no SIGMOD em 2017 e da documentação do Aurora; nada disso pode ser rodado no moto nem num
notebook, e esta seção não mostra transcrição nenhuma.

## Seis cópias em três zonas

**O volume é cortado em segmentos de 10 GB, e cada segmento é guardado seis vezes: duas cópias em cada uma
de três zonas.** As seis cópias de um segmento são um **protection group**. Um banco de 500 GB são cinquenta
protection groups e trezentos segmentos, espalhados por centenas de nós de armazenamento, e o volume cresce
acrescentando protection groups conforme os dados crescem, sem ninguém escolher um tamanho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um protection group do Aurora: um segmento de 10 GB guardado seis vezes, duas cópias em cada uma de três zonas de disponibilidade, sa-east-1a, sa-east-1b e sa-east-1c. A instância writer envia registros de log às seis cópias; uma escrita dá certo quando 4 das 6 a têm, e uma leitura precisa de 3 das 6. Com uma zona inteira perdida, sobram quatro cópias, e as escritas continuam.\" data-fig=\"l08-quorum\"><defs><marker id=\"arr-l08-quorum\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260.0\" y=\"18.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">instância writer</text><text x=\"360.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">envia só registros de log</text><rect x=\"40.0\" y=\"100.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"60.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia 1</text><text x=\"95.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"95.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"150.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia 2</text><text x=\"185.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"185.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"260.0\" y=\"100.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"280.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia 3</text><text x=\"315.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"315.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"370.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia 4</text><text x=\"405.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"405.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"480.0\" y=\"100.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sa-east-1c</text><rect x=\"500.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"535.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia 5</text><text x=\"535.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"535.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"590.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"625.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia 6</text><text x=\"625.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"625.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><text x=\"590.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma zona perdida: sobram 4 cópias</text><text x=\"40.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">escrita: 4 de 6 cópias</text><text x=\"40.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">leitura: 3 de 6 cópias</text><text x=\"250.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 + 3 &gt; 6: toda leitura encontra uma cópia com a última escrita</text></svg>", "caption": "Um protection group: seis cópias de um segmento de 10 GB, duas por zona, gravadas por quórum."}
```

**Uma escrita dá certo quando quatro das seis cópias a têm; uma leitura precisa de três.** Isso é um quórum:
4 + 3 é mais que 6, então todo conjunto de leitura cruza todo conjunto de escrita em pelo menos uma cópia que
tem a última escrita. Os números são escolhidos contra as falhas que acontecem de fato:

| o que se perde | cópias que sobram | escritas | leituras |
|---|---|---|---|
| um nó de armazenamento | 5 | sim, 4 de 5 | sim |
| uma zona inteira | 4 | sim, exatamente 4 | sim |
| uma zona inteira e mais um nó | 3 | não | sim, e nada se perde |

**Perder uma zona não impede o banco de escrever.** Esse é o alvo do projeto: uma zona é a unidade que a AWS
espera que falhe, e com duas cópias em cada zona, uma zona fora deixa quatro. Perder uma zona e um nó em
outro lugar ao mesmo tempo para as escritas e mantém legível todo byte confirmado, e as cópias que faltam são
reconstruídas a partir das sobreviventes. Um segmento de 10 GB é pequeno o bastante para ser copiado de novo
depressa, e é por isso que os segmentos têm esse tamanho: a janela em que uma segunda falha encontraria um
grupo já desfalcado é curta.

## O log é o banco

**Um writer do Aurora manda para a camada de armazenamento só os registros de log**: a descrição de cada
mudança, não as páginas que ela mudou. Os nós de armazenamento aplicam esses registros às suas cópias das
páginas em segundo plano, e montam uma página sob demanda quando alguém a lê. No engine que você conhece da
lição 8 do `sql-databases`, uma escrita vai para o write-ahead log e as páginas alteradas são gravadas
depois, por um checkpoint; no Aurora o segundo passo nunca sai do engine, porque o armazenamento o faz.

Duas consequências, as duas do projeto e nenhuma rodada aqui. **Um commit é uma escrita pequena pela rede**,
registros de log para seis nós, esperando quatro, em vez de páginas para um disco e para o espelho do disco.
E **as réplicas compartilham o volume.** Uma réplica do Aurora não guarda cópia dos dados; ela lê os mesmos
protection groups que o writer grava, e recebe o fluxo de log do writer só para atualizar as páginas na
própria memória. É por isso que o atraso de réplica no Aurora é documentado em milissegundos e não em
segundos, e por isso acrescentar uma réplica não acrescenta armazenamento à conta.

**E o armazenamento é cobrado pelo que é usado.** Uma instância RDS paga pelos 100 GiB que alocou; um
cluster Aurora paga pelos gigabytes que o volume guarda, uma vez, não importa quantas instâncias o leiam, e
as seis cópias são custo da AWS, não uma linha na sua conta. A última seção desta lição põe preço nisso.
