---
title: Testar os dados, e testar o código
version: 1
---

As lições 12 e 16 testaram **os dados**: toda noite, o que chegou é conferido contra o que deveria
ser verdade sobre ele. Essas conferências rodam em produção, sobre linhas de verdade, e respondem *os
dados de hoje estão certos?* Elas não conseguem responder uma outra pergunta que importa tanto
quanto: *o código está certo?* Uma transformação com um bug produz dados que passam em todo teste
escrito pela mesma pessoa com o mesmo mal-entendido, noite após noite.

Testar o código quer dizer rodá-lo sobre entradas cuja resposta certa é conhecida de antemão, antes
de chegar à produção, e isso pede três tipos de teste:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-pyramid\" aria-label=\"Três tipos de teste para um pipeline, em camadas. Embaixo, muitos testes de unidade: uma função ou um modelo, sobre linhas inventadas, rápidos. No meio, poucos testes de integração: o pipeline inteiro em bancos próprios, mais lentos. Ao lado, a fixture sobre a qual rodam: um dia de verdade da loja. E à parte dos três, os testes de dados das lições 12 e 16, que rodam toda noite sobre dados reais.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"230.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">testar o código, antes de uma mudança</text><rect x=\"20.0\" y=\"46.0\" width=\"230.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">testes de integração</text><text x=\"135.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a carga noturna inteira · poucos, mais lentos</text><rect x=\"290.0\" y=\"46.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma fixture de dados reais</text><text x=\"370.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um dia da loja</text><path d=\"M288.0 76.0 L252.0 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"126.0\" width=\"430.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">testes de unidade</text><text x=\"235.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma regra, linhas inventadas · muitos, rápidos</text><path d=\"M480.0 16.0 L480.0 210.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">testar os dados, toda noite</text><rect x=\"505.0\" y=\"86.0\" width=\"195.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">testes de dados</text><text x=\"602.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">toda noite, sobre dados reais</text></svg>", "caption": "Testes do código rodam sobre entradas conhecidas antes de uma mudança; testes dos dados rodam sobre o que chegou, toda noite."}
```

- **Testes de unidade** rodam uma peça — uma função, um modelo — sobre um punhado de entradas
  inventadas para exercitar uma regra cada. São rápidos, são muitos, e quando um falha aponta para
  uma linha.
- **Testes de integração** rodam o pipeline de ponta a ponta, num banco próprio, e conferem o que sai
  contra respostas calculadas de outro jeito. São mais lentos, são poucos, e acham os bugs que moram
  entre as peças: uma coluna renomeada num lugar e não em outro, uma string de conexão, um lock.
- **A fixture** sobre a qual os testes de integração rodam. Dados inventados testam o que o autor
  pensou. **Um recorte de dados reais** — um dia da loja, cortado e guardado — testa o que a loja de
  fato faz, inclusive o que ninguém pensou: os clientes de balcão da lição 12, os apagados, os
  reembolsos atrasados.

Esta lição escreve os três para o pipeline da Ana, e cada um acha alguma coisa.
