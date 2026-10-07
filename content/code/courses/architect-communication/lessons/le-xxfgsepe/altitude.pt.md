---
title: Altitude, jargão e a maldição do conhecimento
version: 1
---

**Todo fato pode ser dito em várias altitudes, do efeito no negócio até a linha de configuração.
Uma mensagem dá errado quando é escrita na altitude de quem escreve, e não na de quem lê.** Quem
escreve costuma viver perto do chão, entre os detalhes com que acabou de trabalhar. É a altitude que
parece natural, e quase nunca é a de que o leitor precisa.

## A escada

O linguista S. I. Hayakawa desenhou isso como uma *escada de abstração*: a mesma coisa nomeada em
níveis crescentes de generalidade, cada degrau deixando de fora mais detalhe e cobrindo mais
terreno. Um fato técnico tem a mesma escada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro degraus empilhados dizendo um fato em altitude decrescente. O negócio: cerca de 180 pagamentos falham toda sexta à noite; o conselho decide aqui. O produto: o checkout falha para 2% dos clientes no pico; o produto decide aqui. O sistema: planejador e checkout disputam um banco só; o time decide aqui. O componente: as conexões do primário chegam ao limite; o time decide aqui.\"><defs><marker id=\"altitude-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"20\" width=\"520\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o negócio</text><text x=\"44\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">cerca de 180 pagamentos falham toda sexta à noite</text><text x=\"600\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o conselho</text><rect x=\"60\" y=\"86\" width=\"490\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o produto</text><text x=\"74\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o checkout falha para 2% dos clientes no pico</text><text x=\"600\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">produto</text><rect x=\"90\" y=\"152\" width=\"460\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"104\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o sistema</text><text x=\"104\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">planejador e checkout disputam um banco só</text><text x=\"600\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o time</text><rect x=\"120\" y=\"218\" width=\"430\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"134\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o componente</text><text x=\"134\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">as conexões do primário chegam ao limite</text><text x=\"600\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o time</text><text x=\"30\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um fato, quatro degraus: a decisão do leitor diz em qual começar</text><text x=\"600\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">decide aqui</text></svg>", "caption": "O mesmo fato em quatro degraus da escada. Uma mensagem começa no degrau onde o leitor decide e só desce para sustentar uma afirmação."}
```

Nenhum degrau é o certo em geral. **O degrau certo é aquele onde mora a decisão do leitor.** O
conselho decide no degrau de cima; Renata, entre o primeiro e o segundo; o time de Bruna, no
terceiro e no quarto. Uma mensagem pode se mover entre degraus, e as boas fazem isso de propósito:
começam onde o leitor decide e descem um degrau só para sustentar uma afirmação de que ele possa
duvidar.

A falha tem uma forma reconhecível: uma mensagem para o CEO que começa no degrau de baixo, com um
parâmetro de configuração, e sobe devagar em direção ao efeito. Quando chega à receita, o leitor já
foi embora.

## A maldição do conhecimento

Por que quem escreve fica no próprio degrau? Em 1990, Elizabeth Newton, estudante de psicologia em
Stanford, pediu a algumas pessoas que batucassem numa mesa o ritmo de uma música conhecida enquanto
um ouvinte tentava adivinhar qual era. Antes de começar, quem batucava previu que metade dos
ouvintes acertaria a música. De 120 músicas batucadas, os ouvintes acertaram 3.

Quem batucava ouvia a melodia na cabeça enquanto batia na mesa. Não conseguia imaginar ouvir só as
batidas. **Depois que você sabe uma coisa, é muito difícil lembrar como era não saber**, e essa
distância é o que os economistas, que lhe deram nome primeiro, chamam de *maldição do conhecimento*.

O jargão é o sintoma mais visível dela. "Atraso da réplica", "pool de conexões", "p95" parecem
palavras simples para quem as usa todo dia. Três hábitos ajudam:

- **Defina um termo na primeira vez, ou não o use.** "Uma réplica, uma cópia somente leitura do
  banco de dados mantida atualizada automaticamente" custa uma linha. Se o leitor nunca mais vai
  encontrar o termo, pule-o e diga o que a coisa faz.
- **Troque a sigla pelo que ela significa**, a não ser que o leitor use a sigla. Renata diz "SLA"
  todo dia; Caio não diz "p95".
- **Peça a alguém do público que leia.** É a passada 6 da aula 1, e é a única cura confiável,
  porque de dentro a maldição é invisível.

## Analogias, e onde elas quebram

Uma analogia permite ao leitor aproveitar a intuição de algo que ele já conhece. "O banco de dados é uma
loja com um caixa só; nas noites de sexta, o planejador de rotas entra na fila com um carrinho de
duzentos itens" deixa o problema claro para qualquer um que já foi a um supermercado.

**Toda analogia quebra em algum ponto, e o leitor vai raciocinar a partir da parte quebrada.**
Leve a imagem da loja adiante e a correção óbvia é "abrir outro caixa", o que em termos de banco de dados soa como
o servidor maior, a alternativa que a proposta de Lívia rejeitou. Uma boa analogia é usada para um
ponto e depois abandonada, ou tem o limite declarado: "a analogia para aqui: a réplica não é um
segundo caixa, é uma segunda loja com uma cópia das prateleiras, alguns segundos desatualizada".
