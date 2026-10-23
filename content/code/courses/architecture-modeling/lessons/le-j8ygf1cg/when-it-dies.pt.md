---
title: Quando um documento morre, e como deixá-lo morrer
version: 1
---

**Toda página um dia deixa de ser verdadeira, e a única pergunta é se a morte dela fica visível.**
Uma página que morre em silêncio continua sendo lida e acreditada; uma página que morre de forma
visível diz ao leitor para onde ir. Planejar a segunda faz parte de escrever a página.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l11-page-life\" aria-label=\"A vida de uma página de descrição como máquina de estados. Começa como Rascunho, vira Vigente quando revisada, e continua Vigente num laço rotulado conferida pelo dono na sua cadência. De Vigente, três saídas: Apagada, quando ninguém precisa dela; Arquivada, com um aviso, quando explica um estado passado; Lápide, uma única linha apontando para a substituta, quando muitas páginas apontam para ela. Uma transição tracejada de Vigente rotulada ninguém decidiu leva ao estado a evitar: morta e sem marca.\"><defs><marker id=\"l11-page-life-am-fill-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-page-life-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><circle cx=\"30.0\" cy=\"110.0\" r=\"7\" fill=\"var(--paper)\"></circle><path d=\"M37.0 110.0 L68.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><rect x=\"70.0\" y=\"90.0\" width=\"100.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Rascunho</text><path d=\"M170.0 110.0 L248.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"209.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">revisada</text><rect x=\"250.0\" y=\"88.0\" width=\"120.0\" height=\"44.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Vigente</text><path d=\"M280 88 C280 48, 340 48, 340 88\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"310.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">conferida na cadência</text><rect x=\"520.0\" y=\"20.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Apagada</text><path d=\"M370.0 99.5 L518.0 40.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"448.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">ninguém precisa</text><rect x=\"520.0\" y=\"90.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Arquivada</text><path d=\"M370.0 110.0 L518.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"448.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">explica o passado</text><rect x=\"520.0\" y=\"160.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Lápide</text><path d=\"M370.0 120.5 L518.0 180.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-page-life-am-fill-paper)\"></path><text x=\"448.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">muitos links apontam</text><rect x=\"230.0\" y=\"205.0\" width=\"160.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Morta, sem marca</text><path d=\"M310.0 132.0 L310.0 203.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-page-life-am-fill-amber)\"></path><text x=\"318.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">ninguém decidiu</text></svg>", "caption": "Três fins deliberados, e um que acontece por omissão. O de omissão é aquele em que o leitor acredita."}
```

## Três jeitos de encerrar uma página

| | o que acontece | quando serve |
| --- | --- | --- |
| **apagar** | a página é removida; o histórico do controle de versão a guarda | estava errada, foi substituída e ninguém aponta para ela |
| **arquivar** | ela vai para uma pasta de arquivo com um aviso: *arquivada em 2025-11-03, sem manutenção* | explica um estado passado que alguém pode precisar entender, como o back office das rodoviárias antes de ser aposentado |
| **lápide** | a página é esvaziada, ficando só uma linha que diz o que a substituiu e onde | ela é apontada de muitos lugares, e apagá-la deixaria links quebrados |

O que nunca é aceitável é a quarta opção, a de omissão: **deixar uma página morta no lugar, sem
marca**, porque ninguém decidiu. Era nesse estado que estavam 109 das 140 páginas da Carcará.

## Decidir quais páginas morrem

A Carcará passou pelas 140 páginas em quatro sessões de uma hora, com o dono de cada área na sala,
fazendo três perguntas a cada página:

1. **Alguém precisa dela?** Se ninguém conseguia nomear um leitor, ela era apagada.
2. **Ela é verdadeira?** Se não, e o dono não fosse corrigi-la naquele mês, era arquivada ou apagada.
3. **Ela é a única cópia de alguma coisa?** Se a página guardava a única descrição, digamos, da
   exportação noturna da Frota, ela ficava e era corrigida primeiro, qualquer que fosse o estado.

Sessenta e quatro sobreviveram. Trinta e uma foram arquivadas, quase todas descrições de sistemas
aposentados que explicam por que os atuais são como são. Quarenta e cinco foram apagadas, e
**ninguém pediu nenhuma delas de volta desde então**.

## Registros são diferentes

Registros de decisão, postmortems e atas de reunião são **registros**: verdadeiros a partir de uma
data, nunca atualizados, nunca transformados em lápide. Eles não morrem; envelhecem, e o status deles
diz isso. Um registro de decisão substituído fica exatamente onde está, e foi com isso que a aula 5
contou. As regras de exclusão desta seção valem para as **descrições**, as páginas que dizem como as
coisas são agora.

## Posse quando as pessoas saem

A causa de morte mais comum não é a mudança, e sim a saída: o dono vai embora, a página fica,
ninguém a herda. A regra da Carcará é que **uma página pertence a um time, com uma pessoa nomeada
como contato**, e quando essa pessoa sai, as páginas dela entram na lista do time de coisas a
redistribuir na mesma semana que o notebook. A documentação só sobrevive ao projeto se sobreviver às
pessoas, e isso depende de quem está escrito no topo.
