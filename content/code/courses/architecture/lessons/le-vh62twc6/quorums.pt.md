---
title: Quóruns, ou escolher por requisição
version: 1
---

O primário e o standby do PostgreSQL fazem a escolha para o servidor inteiro. Uma família de bancos que
descende do artigo do Dynamo, da Amazon, de 2007, Cassandra e Riak entre eles, e o DynamoDB do seu jeito,
mantêm **N cópias de cada item sem nenhum primário único** e deixam cada leitura e cada escrita dizer
quantas cópias precisam responder para ela valer.

| símbolo | significado |
| --- | --- |
| **N** | quantas réplicas guardam cada item |
| **W** | quantas precisam confirmar uma escrita antes de o cliente ser avisado do sucesso |
| **R** | quantas precisam responder a uma leitura; a resposta mais nova ganha |

A regra que faz isso funcionar é uma desigualdade. **Se R + W > N, todo conjunto de leitura se cruza com
todo conjunto de escrita** em pelo menos uma réplica, então pelo menos uma das réplicas que uma leitura
pergunta tem a última escrita confirmada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três réplicas de um valor, N igual a 3. Uma escrita vai para duas delas, W igual a 2: as réplicas 1 e 2. Uma leitura posterior pergunta a duas, R igual a 2: as réplicas 2 e 3. Como dois mais dois é maior que três, o conjunto de leitura e o de escrita sempre dividem pelo menos uma réplica, aqui a réplica 2, que tem o valor mais novo.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"100\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 1</text><text x=\"120\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">units = 9</text><rect x=\"260\" y=\"100\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"320\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 2</text><text x=\"320\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">units = 9</text><rect x=\"460\" y=\"100\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">réplica 3</text><text x=\"520\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">units = 10</text><rect x=\"50\" y=\"40\" width=\"340\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"220\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">escrita: W = 2</text><rect x=\"250\" y=\"176\" width=\"340\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"420\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">leitura: R = 2</text><text x=\"620\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">N = 3</text></svg>", "caption": "Com R + W > N, toda leitura se cruza com toda escrita em pelo menos uma réplica, então uma leitura sempre acha o valor mais recente entre as respostas."}
```

Com N = 3, a escolha comum é W = 2 e R = 2, um **quórum de maioria** para os dois: o sistema tolera uma
réplica fora do ar ou isolada, para leituras e escritas, e ainda devolve o valor mais recente. As outras
configurações movem a mesma troca ao longo de uma linha:

| N, W, R | R + W > N? | o que compra | o que custa |
| --- | --- | --- | --- |
| 3, 2, 2 | sim, 4 > 3 | o valor mais recente, uma réplica pode ser perdida | duas réplicas em toda requisição |
| 3, 3, 1 | sim, 4 > 3 | leituras rápidas de qualquer réplica | uma escrita falha se qualquer réplica estiver fora |
| 3, 1, 3 | sim, 4 > 3 | escritas rápidas | uma leitura falha se qualquer réplica estiver fora |
| 3, 1, 1 | não, 2 < 3 | a menor latência, o mais disponível | leituras podem perder a última escrita |

A última linha é o canto AP: durante uma partição, os dois lados aceitam escritas e respondem leituras, e
as cópias divergem até conseguirem conversar de novo. **Reconciliar duas cópias que receberam escritas cada
uma é um problema próprio**: que valor ganha, e o que se perde. A aula 9 trata disso, com última escrita
vence e as alternativas.

O Cassandra chama as configurações de níveis de consistência, `ONE`, `QUORUM`, `ALL`, escolhidos por
consulta; o DynamoDB oferece leituras eventualmente consistentes por padrão e leituras fortemente
consistentes sob pedido. Nos dois, **a escolha do CAP é um parâmetro da requisição**, que é a leitura
errada da seção anterior transformada em recurso.
