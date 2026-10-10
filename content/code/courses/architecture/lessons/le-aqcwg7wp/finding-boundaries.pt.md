---
title: Onde traçar a linha
version: 1
---

O corte tentador é por substantivo: um serviço de produto, um de cliente, um de pedido, um por
tabela. Fica arrumado num diagrama e costuma estar errado, porque **um substantivo significa coisas
diferentes para partes diferentes do negócio**, e um serviço construído em volta do substantivo tem de
guardar todos os significados ao mesmo tempo.

Pergunte a três partes da Quitanda o que é um produto:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três contextos delimitados lado a lado: catálogo, estoque e entrega. Cada um tem o seu próprio modelo de produto. No catálogo um produto tem nome, foto e preço. No estoque tem uma contagem de unidades e uma prateleira. Na entrega tem um peso e se precisa viajar refrigerado. A única coisa que os três dividem é o identificador, sku.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"30\" width=\"200\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"130\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">catálogo</text><text x=\"130\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">produto</text><rect x=\"60\" y=\"88\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sku</text><rect x=\"60\" y=\"114\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><rect x=\"60\" y=\"140\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">photo</text><rect x=\"60\" y=\"166\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price_cents</text><rect x=\"260\" y=\"30\" width=\"200\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">estoque</text><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">produto</text><rect x=\"290\" y=\"88\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sku</text><rect x=\"290\" y=\"114\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">units</text><rect x=\"290\" y=\"140\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf</text><rect x=\"290\" y=\"166\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reorder_at</text><rect x=\"490\" y=\"30\" width=\"200\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"590\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">entrega</text><text x=\"590\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">produto</text><rect x=\"520\" y=\"88\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sku</text><rect x=\"520\" y=\"114\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">weight_g</text><rect x=\"520\" y=\"140\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cold_chain</text><rect x=\"520\" y=\"166\" width=\"140\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fragile</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">só o sku atravessa uma fronteira</text></svg>", "caption": "Uma palavra, três modelos. Uma fronteira em volta de cada significado deixa cada contexto mudar o seu modelo sem perguntar aos outros dois; o que atravessa a linha é só o identificador."}
```

Para o catálogo, um produto é um nome, uma foto e um preço. Para o estoque, é uma contagem e uma
prateleira. Para a entrega, é um peso e se precisa viajar refrigerado. Um único "serviço de produto"
carregaria tudo isso, e qualquer mudança em qualquer um dos três significados seria uma mudança nele.
Três serviços, cada um dono do seu significado, mudam de forma independente, e **só o identificador
atravessa a linha**.

## Contextos delimitados

Eric Evans deu nome a isso em *Domain-Driven Design*, em 2003: um **contexto delimitado** (*bounded
context*) é a área dentro da qual uma palavra tem um significado preciso e um modelo. Dentro do
contexto de estoque, "produto" quer dizer a contagem na prateleira e mais nada. Uma fronteira entre
serviços que segue as fronteiras entre contextos é uma que o próprio negócio já mantém, e ela
costuma ficar no lugar quando o produto muda.

Três perguntas ajudam a encontrá-los:

| pergunta | um sinal de fronteira |
| --- | --- |
| quem no negócio fala disso, e com que palavras? | um grupo diferente de pessoas usando a mesma palavra de outro jeito |
| o que muda junto? | duas coisas que sempre mudam no mesmo pull request pertencem juntas |
| o que precisa estar consistente no mesmo instante? | dados que nunca podem discordar, nem por um segundo, ficam numa transação, então num serviço |

A terceira pergunta é a que as pessoas pulam. Se o pedido e o estoque nunca podem discordar, uma
fronteira entre eles significa pagar pela discordância em código: a aula 14, a saga, é esse código.
Às vezes vale a pena. Nunca devia ser uma surpresa.

## A lei de Conway

Melvin Conway observou em 1968 que organizações projetam sistemas cuja estrutura copia a sua própria
estrutura de comunicação. Uma empresa com três equipes tende a construir um sistema em três partes,
onde quer que estejam as fronteiras naturais do problema. **A fronteira entre serviços e a fronteira
entre equipes acabam sendo a mesma linha**, então a versão honesta da pergunta é "que equipe vai ser
dona disso?".

A **manobra inversa de Conway** usa a lei de propósito: organize as equipes do jeito que você quer
que o sistema seja dividido, e deixe o sistema seguir. A equipe de estoque da Quitanda, de duas
pessoas, com o seu próprio ritmo de releases, é exatamente o formato que faz de um serviço de estoque
o corte certo.

## Os sinais de uma linha errada

- Dois serviços que se chamam em quase toda requisição, nos dois sentidos.
- Uma mudança que exige uma release coordenada dos dois lados.
- Um serviço que precisa dos dados do outro com tanta frequência que guarda uma cópia, e as cópias
  discordam.
- Uma transação que precisa cobrir os dois, coisa que nenhum deles consegue dar.

Cada sinal quer dizer que a linha corta algo que pertence junto. Movê-la é caro, e é por isso que a
aula 1 aconselhou traçá-la primeiro dentro de um monólito.
