---
title: O formato
version: 1
---

Todo runbook tem os mesmos títulos na mesma ordem, seja qual for o sintoma. **O formato fixo é o
ponto.** Às três da manhã você acha a seção de que precisa sem ler as anteriores, e quando falta uma
seção num runbook, a lacuna fica visível na página, em vez de ser descoberta durante o incidente.

Um cabeçalho e depois sete seções. Os títulos ficam em inglês no runbook deste curso, como os
comandos; entre parênteses, o que cada um quer dizer:

| seção | o que ela guarda |
|---|---|
| cabeçalho | para que serve o runbook, a quais servidores se aplica, o dono e a data do último ensaio |
| **Symptom** (sintoma) | como você chega aqui: o texto exato do alerta, ou o que os usuários relatam |
| **Impact** (impacto) | o que está quebrado agora e o que quebra em seguida se nada for feito, para você saber com que pressa agir |
| **Check** (conferir) | comandos que só leem, cada um com o que a resposta quer dizer |
| **Act** (agir) | para cada achado do Check, o comando que lida com ele |
| **Verify** (verificar) | como saber que cada ação funcionou, e o que você vai ver se não funcionou |
| **Roll back** (desfazer) | como desfazer cada ação, ou a frase clara de que ela não pode ser desfeita |
| **Escalate** (escalar) | quem chamar, a partir de que limite ou depois de quanto tempo, e o que entregar |

Quatro regras fazem esses títulos funcionarem.

**O Check só lê.** Todo comando ali é seguro para qualquer pessoa rodar, a qualquer hora, quantas
vezes quiser — `df`, `du`, um `SELECT`. Assim quem segue a página nunca precisa decidir se um passo
é seguro enquanto ainda está descobrindo o que deu errado.

**Toda ação cita o achado que leva a ela.** "Se um slot está inativo e retendo WAL" é uma ação.
"Liberar espaço" é um desejo. A condição é o que impede alguém de rodar o comando certo para o
problema errado.

**Toda ação tem o seu verify e o seu roll back, escritos antes de serem necessários.** Se uma ação
não pode ser desfeita, o runbook diz isso com essas palavras, ao lado da ação, com o que se perde.
Essa frase é o que faz uma pessoa cansada parar e perguntar antes.

**A escalada tem um número.** "Chame o segundo nível se piorar" deixa a decisão para a pessoa menos
capaz de tomá-la. "Acima de 95%, ou ainda subindo trinta minutos depois da ação" não deixa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 244\" role=\"img\" aria-label=\"O runbook como um ciclo. O sintoma leva a Conferir, que só lê; Conferir leva a Agir, onde cada ação cita o achado que leva a ela; Agir leva a Verificar, um por ação; uma verificação que passa termina em Resolvido. Uma verificação que falha volta a Conferir com uma coisa a mais sabida, ou, se a ação piorou as coisas, vai para Desfazer. Sob todos os passos corre Escalar: de qualquer passo, no número que a página dá.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Sintoma</text><rect x=\"160\" y=\"70\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Conferir</text><text x=\"225.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só lê</text><rect x=\"330\" y=\"70\" width=\"130\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Agir</text><text x=\"395.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cita o que achou</text><rect x=\"500\" y=\"70\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Verificar</text><text x=\"560.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um por ação</text><rect x=\"660\" y=\"70\" width=\"90\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"705.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Resolvido</text><line x1=\"130\" y1=\"94.0\" x2=\"157\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"290\" y1=\"94.0\" x2=\"327\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"460\" y1=\"94.0\" x2=\"497\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"620\" y1=\"94.0\" x2=\"657\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><path d=\"M560 70 C560 22 225 22 225 66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><text x=\"392\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não resolveu: volta a Conferir, sabendo mais</text><rect x=\"430\" y=\"150\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Desfazer</text><line x1=\"545\" y1=\"118\" x2=\"512\" y2=\"147\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"552\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">piorou</text><rect x=\"10\" y=\"204\" width=\"740\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"380\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Escalar: de qualquer passo, no número que a página dá</text></svg>", "caption": "O formato de um runbook é um ciclo, com uma saída em cada passo."}
```

A ordem é mais um ciclo do que uma lista. Uma verificação que falha manda você de volta ao Check
com uma coisa a mais sabida, ou ao Roll back se a ação piorou tudo. A escalada fica sob todos os
passos, porque a hora de chamar alguém é sempre que a página acabou, em qualquer ponto dela que
isso aconteça.
