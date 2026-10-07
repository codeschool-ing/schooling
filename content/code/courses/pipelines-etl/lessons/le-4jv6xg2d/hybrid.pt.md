---
title: Híbrido, e como escolher
version: 1
---

**A escolha não é entre batch e streaming. É quão velha uma resposta pode estar quando alguém a
lê.** Ponha esse número em cada pergunta primeiro, e o tipo de ingestão vem atrás.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l01-freshness\" aria-label=\"Uma linha de segundos a um dia, medindo quão velha uma resposta pode ser quando é lida. Três perguntas estão sobre ela: se um livro tem estoque agora, em segundos; quais livros venderam hoje de manhã, em uma hora; vendas por loja no mês passado, em um dia. Abaixo da linha, três faixas: um stream cobre de segundos a um minuto, um micro-batch de minutos a uma hora, e um batch de horas a um dia.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70.0 120.0 L670.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M70.0 115.0 L70.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 segundo</text><path d=\"M263.3 115.0 L263.3 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"263.3\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 minuto</text><path d=\"M456.7 115.0 L456.7 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"456.7\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 hora</text><path d=\"M650.0 115.0 L650.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 dia</text><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quão velha a resposta pode estar quando alguém a lê</text><circle cx=\"78.0\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M78.0 114.0 L78.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"78.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">este livro tem estoque agora?</text><circle cx=\"456.7\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M456.7 114.0 L456.7 80.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"456.7\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">que livros venderam hoje de manhã?</text><circle cx=\"650.0\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M650.0 114.0 L650.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"650.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">vendas por loja no mês passado</text><rect x=\"70.0\" y=\"150.0\" width=\"193.3\" height=\"22.0\" rx=\"11\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"166.7\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stream</text><rect x=\"233.3\" y=\"180.0\" width=\"223.3\" height=\"22.0\" rx=\"11\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">micro-batch</text><rect x=\"426.7\" y=\"150.0\" width=\"223.3\" height=\"22.0\" rx=\"11\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"538.3\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">batch</text></svg>", "caption": "Ponha uma idade em cada pergunta primeiro. O tipo de ingestão é a faixa onde a idade cai, e ganha a mais barata que chega lá."}
```

A maior parte do espaço entre as duas pontas é ocupada pelos meios-termos:

- **Micro-batch.** Um batch com período curto — a cada cinco minutos, a cada minuto. Cada execução
  é um pedaço delimitado que pode ser rodado de novo, e a resposta tem alguns minutos de idade. O
  Spark Structured Streaming, no seu modo padrão, funciona assim por dentro.
- **Um stream para agora, um batch para o registro.** Os eventos do site alimentam um contador ao
  vivo numa tela, e os mesmos eventos são carregados de novo toda noite, completos e sem
  duplicatas, no warehouse. A arquitetura com dois caminhos tem nome, *lambda*, e o seu custo é a
  mesma lógica escrita duas vezes, que precisa concordar.
- **Um stream só, reproduzido para o histórico.** Guarde cada evento num log por tempo suficiente
  para lê-lo de novo, e o "batch" vira o mesmo código de streaming rodado sobre eventos antigos. Essa
  se chama *kappa*, e ela troca o custo de escrever a lógica duas vezes pelo de guardar o log.

## Escolhendo, para a Ponto Final

| pergunta | quão velha a resposta pode estar | o que a alimenta |
|---|---|---|
| vendas por loja no mês passado | um dia | o batch noturno |
| que livros venderam hoje de manhã | uma hora | um micro-batch a cada hora |
| este livro tem estoque agora | segundos | um stream, ou pipeline nenhum — pergunte à origem |

A última linha é a que as pessoas esquecem: **quando uma resposta precisa estar atual no segundo, o
pipeline certo muitas vezes é nenhum.** O caixa já sabe o estoque, e uma cópia dele com um segundo
de idade está só um segundo errada sobre algo que o caixa poderia ter dito exatamente. Pipelines são
para perguntas que a origem não sabe responder, ou que não devem ser feitas a ela: entre lojas,
entre meses, entre sistemas.

**O warehouse da Ponto Final é alimentado por batch** no resto deste curso, e esse é o caso comum,
não o simples. O consumidor de streaming volta na lição 3, onde eventos são um tipo de origem, e na
lição 15, onde ler um duas vezes não pode fazer mal.
