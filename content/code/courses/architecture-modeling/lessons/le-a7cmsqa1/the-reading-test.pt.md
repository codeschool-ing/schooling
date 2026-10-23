---
title: O teste de leitura: conferir um diagrama antes que outra pessoa confira
version: 1
---

**Um diagrama está pronto quando um leitor que não estava lá consegue responder à pergunta dele só
com a página.** Tudo nesta seção é um jeito de descobrir, antes de entregar, se isso é verdade.

## A anatomia de um diagrama que dá para ler

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l01-anatomy\" aria-label=\"A anatomia de um diagrama legível. No alto, um título dizendo o que é mostrado, Vendas da Carcará: containers, e embaixo dele a data em que foi conferido e a dona. Uma fronteira âmbar tracejada chamada Conta de nuvem da Carcará. Dentro dela, dois elementos, cada um com nome e tipo entre colchetes: API de passagens, um serviço Kotlin, e Banco de reservas, PostgreSQL. Uma linha entre eles com o rótulo SQL: grava reservas. À direita, uma legenda explicando a caixa contínua, a caixa tracejada, a linha contínua e a fronteira tracejada.\"><defs><marker id=\"l01-anatomy-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"300.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Vendas da Carcará: containers</text><text x=\"46.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conferido em 2 de março de 2026 · dona: Tainá</text><rect x=\"60.0\" y=\"90.0\" width=\"420.0\" height=\"200.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"70.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">Conta de nuvem da Carcará</text><rect x=\"90.0\" y=\"130.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">API de passagens</text><text x=\"165.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[serviço Kotlin]</text><rect x=\"300.0\" y=\"220.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"375.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Banco de reservas</text><text x=\"375.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><path d=\"M240.0 165.0 L330.0 218.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-anatomy-am-fill-paper)\"></path><text x=\"292.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">SQL: grava reservas</text><rect x=\"520.0\" y=\"90.0\" width=\"160.0\" height=\"120.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Legenda</text><rect x=\"532.0\" y=\"116.0\" width=\"22.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"562.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">container nosso</text><rect x=\"532.0\" y=\"140.0\" width=\"22.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"562.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">sistema externo</text><path d=\"M532.0 170.0 L554.0 170.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"562.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">chamada, espera</text><path d=\"M532.0 192.0 L554.0 192.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"562.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">nossa rede</text><circle cx=\"28.0\" cy=\"42.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"28.0\" y=\"42.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">1</text><circle cx=\"165.0\" cy=\"196.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"165.0\" y=\"196.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">2</text><circle cx=\"300.0\" cy=\"198.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"300.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">3</text><circle cx=\"700.0\" cy=\"150.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"700.0\" y=\"150.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">4</text><circle cx=\"28.0\" cy=\"60.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"28.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">5</text></svg>", "caption": "1 um título com o escopo, 2 um tipo em cada elemento, 3 um rótulo em cada linha, 4 uma legenda para cada tipo de marca, 5 uma data e um dono.", "same": ["[PostgreSQL]"]}
```

Cinco partes carregam o contrato, e quem lê procura cada uma delas, mais ou menos nesta ordem:

1. **Um título que diz o que é mostrado e em que escopo.** *Vendas da Carcará: containers*, e não
   *Arquitetura*. Se o diagrama faz parte de um conjunto, o título diz de qual.
2. **Um tipo em cada elemento**, além do nome. O leitor nunca deveria ter de deduzir pela forma se
   algo é uma pessoa, um serviço ou um banco de dados.
3. **Um rótulo em cada linha**, um verbo no sentido da seta, com o protocolo quando o leitor é
   técnico.
4. **Uma legenda** para cada forma, cor e estilo de linha que carrega sentido.
5. **Uma data ou uma versão**, e de preferência um dono. A aula 11 trata de por que um diagrama sem
   data não merece confiança um ano depois.

## Oito perguntas, feitas a todo diagrama

Leia o seu próprio diagrama como se você fosse o leitor nomeado no alto. Estas são as perguntas;
qualquer "não" é algo para corrigir.

| | pergunta | a falha que ela pega |
| --- | --- | --- |
| 1 | O título diz o que é mostrado? | um desenho cujo escopo o leitor precisa adivinhar |
| 2 | A pergunta do alto pode ser respondida só com esta página? | o diagrama derivou para outra pergunta enquanto era desenhado |
| 3 | Todo elemento tem nome e tipo? | a caixa chamada `Booking` que pode ser cinco coisas |
| 4 | Toda linha tem rótulo e sentido que concordam? | setas que querem dizer chamadas num lugar e dados em outro |
| 5 | Toda forma, cor e estilo de linha está na legenda? | cor que o leitor decifra num sentido que ninguém quis dar |
| 6 | Há um tipo só de fronteira, e ele tem nome? | uma caixa em volta de coisas implantadas juntas, do mesmo time e de mesma confiança, que são três afirmações diferentes |
| 7 | Há algo na página de que a pergunta não precisa? | o app de embarque num desenho sobre compra |
| 8 | A data está nele, e ele ainda é verdade? | o impresso colado na parede em 2023 |

A lista é curta de propósito. O C4, na aula 3, tem uma mais longa, e a aula 13 transforma esse tipo
de pergunta numa revisão de um projeto inteiro.

## O teste que nenhuma lista substitui

**Entregue o diagrama a uma pessoa parecida com o leitor pretendido e peça que ela o explique de
volta para você**, sem ajuda. Não explique antes, e não corrija enquanto ela fala. Cada ponto em que
a explicação dela difere do que você quis dizer é uma marca na página que fez uma afirmação
diferente da que você pretendia.

Quando Tainá fez isso com o diagrama da direita, do começo desta aula, Bento leu a seta da API de
passagens para o gateway de pagamento como *o gateway nos chama de volta quando o pagamento é
confirmado*. Isso também é verdade, por um webhook, e não estava no diagrama. A correção foi uma
segunda linha, tracejada, no sentido oposto, com o rótulo *envia confirmações de pagamento para
(webhook)*, e uma entrada na legenda para linhas tracejadas. Um leitor, cinco minutos, um defeito
real.
