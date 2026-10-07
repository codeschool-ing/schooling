---
title: A resposta primeiro, depois os motivos
version: 1
---

**Ponha a conclusão no topo, depois os motivos dela, depois a evidência de cada motivo.** É o
contrário de como o trabalho aconteceu, e é exatamente por isso que precisa ser feito de propósito.

O padrão é contar a história da investigação. "Na segunda notamos timeouts. Olhamos os logs da
aplicação, que não mostravam nada fora do normal. Depois conferimos o banco de dados…" Quatro
parágrafos adiante, o leitor descobre o que está errado e o que se espera dele. Quem escreve está
revivendo o trabalho; quem lê está esperando chegar ao que interessa, e um leitor ocupado para antes de chegar lá.

## Bottom line up front

O nome militar para o hábito é **BLUF**, *bottom line up front*, a conclusão na frente: as primeiras
linhas de uma mensagem dizem o que o leitor precisa saber ou fazer, e tudo abaixo é apoio. Um bom
teste é ver se a mensagem ainda funciona caso o leitor pare depois de duas frases. Esta é uma
mensagem que Lívia quase mandou para Renata, a diretora de produto:

> Passei o dia de ontem olhando o problema do checkout de sexta com a Bruna. Revisamos os logs das
> últimas seis sextas e comparamos com as métricas do banco, e há um padrão claro entre 18:00 e
> 21:00. Parece que o planejador de rotas disputa conexões com o checkout. Há algumas formas de
> resolver, com custos diferentes. Acho que provavelmente deveríamos conversar sobre isso.

E a versão que ela mandou:

> As falhas do checkout de sexta vêm do planejador de rotas e do checkout dividirem um banco de
> dados; quero propor separar os dois, o que exige seis semanas-engenheiro do time de plataforma em
> abril. Podemos tirar trinta minutos na quinta para combinar se abril é possível? Evidências abaixo.

A segunda mensagem é mais curta, e o tamanho não é a diferença importante. **O pedido está na
primeira frase e o custo na segunda**, então Renata consegue responder pelo celular. As evidências
continuam lá para quando ela quiser.

## A pirâmide

Barbara Minto, que ensinava escrita aos consultores da McKinsey, transformou o hábito numa
estrutura que funciona para documentos mais longos: o princípio da pirâmide. **Uma ideia central no
topo, alguns argumentos logo abaixo dela e a evidência sob cada argumento.** Cada nível responde à
pergunta que o nível de cima levanta na cabeça do leitor, que em geral é "por quê?" ou "como?".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma pirâmide de caixas. No topo, a ideia principal: separar o planejador de rotas do banco de dados do checkout. Abaixo, três argumentos: faz perder vendas toda sexta-feira; pode parar o checkout para todo mundo; a correção é pequena e reversível. Abaixo de cada argumento, sua evidência: 180 checkouts com falha por semana entre 18h e 21h; as conexões chegam ao limite no pico; seis semanas-engenheiro, e a réplica pode ser removida.\"><defs><marker id=\"pyramid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"16\" width=\"340\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Separar o planejador de rotas</text><text x=\"360\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">do banco de dados do checkout</text><rect x=\"30\" y=\"120\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Faz perder vendas</text><text x=\"135\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">toda sexta-feira</text><rect x=\"30\" y=\"222\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"135\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">180 checkouts com falha</text><text x=\"135\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por semana, das 18h às 21h</text><path d=\"M360 66 L135 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><path d=\"M135 170 L135 220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><rect x=\"255\" y=\"120\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pode parar o checkout</text><text x=\"360\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">para todo mundo</text><rect x=\"255\" y=\"222\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as conexões chegam ao</text><text x=\"360\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">limite no pico</text><path d=\"M360 66 L360 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><path d=\"M360 170 L360 220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><rect x=\"480\" y=\"120\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">A correção é pequena</text><text x=\"585\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">e reversível</text><rect x=\"480\" y=\"222\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"585\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 semanas-engenheiro; a</text><text x=\"585\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">réplica pode ser removida</text><path d=\"M360 66 L585 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><path d=\"M585 170 L585 220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pyramid-ah)\"></path><text x=\"372\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">por quê?</text><text x=\"147\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">como sabemos?</text></svg>", "caption": "Cada nível responde à pergunta que o nível de cima levanta: os argumentos respondem \"por quê?\", as evidências respondem \"como sabemos?\". O leitor pode parar em qualquer nível e ainda leva a conclusão."}
```

Duas regras fazem a pirâmide funcionar, e as duas são fáceis de quebrar:

- **Cada argumento sob uma ideia precisa sustentá-la sozinho.** Se tirar um deles deixa a conclusão
  tão firme quanto antes, ele era enfeite.
- **Os argumentos de um mesmo nível são do mesmo tipo.** Três motivos, ou três passos, ou três
  opções, mas não dois motivos e um passo. Uma lista misturada obriga o leitor a fazer o
  agrupamento que você pulou.

Três argumentos é um número comum, não uma regra. Dois fortes valem mais que três em que o terceiro
é enchimento, e sete é sinal de que alguns deles deveriam ficar sob outros.

## O assunto e o título são a primeira frase

O assunto de um e-mail, o título de um ticket ou o de um documento é lido por muito mais gente do
que o corpo. "Checkout de sexta" diz do que a mensagem trata. "**Decisão necessária até 19 de
março: separar a carga do planejador de rotas no banco de dados (6 semanas-engenheiro)**" diz para
que ela serve, até quando e a que custo. O segundo é mais longo e permite agir muito mais rápido, porque
o leitor nunca precisa abrir a mensagem para saber se ela é com ele.

## Quando a resposta não pode vir primeiro

Às vezes o leitor vai rejeitar uma conclusão que encontrar antes dos motivos: uma má notícia para
quem apostou no contrário, ou uma recomendação que derruba uma decisão que ele tomou. Mesmo assim,
**as primeiras linhas dizem para que serve o documento**: "Esta nota explica por que a data da
migração precisa mudar e propõe duas novas datas." O leitor continua sabendo aonde vai; você só
escolheu conduzi-lo pelos motivos antes do destino. A aula 5 volta a isso quando o documento vira
uma apresentação.
