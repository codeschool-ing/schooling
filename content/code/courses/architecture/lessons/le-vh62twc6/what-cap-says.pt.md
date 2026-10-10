---
title: O que o teorema CAP diz
version: 1
---

Eric Brewer apresentou a ideia como conjectura numa palestra em 2000; Seth Gilbert e Nancy Lynch
provaram uma versão precisa dela em 2002. Ela costuma ser citada como "consistência, disponibilidade,
tolerância a partições: escolha duas", e essa formulação é a fonte da maior parte da confusão em torno
dela. **O teorema é sobre o que um sistema consegue fazer enquanto a rede está dividida**, e as três
letras têm significados estreitos.

| letra | o que significa no teorema | o que não significa |
| --- | --- | --- |
| **C**, consistência | toda leitura vê a escrita mais recente, como se houvesse uma cópia só do dado; o nome formal é linearizabilidade | o C do ACID, que é sobre uma transação manter as regras do banco |
| **A**, disponibilidade | toda requisição a um nó que está de pé recebe uma resposta que não é erro, em algum momento | respostas rápidas, ou 99,9% de qualquer coisa |
| **P**, tolerância a partições | o sistema continua funcionando quando mensagens entre os nós se perdem | algo que um sistema distribuído pode decidir não ter |

Com esses significados o teorema é curto. **Se a rede se parte, um nó que não alcança os outros precisa
ou recusar as requisições que não consegue responder corretamente, abrindo mão do A, ou respondê-las com
o que tem, abrindo mão do C.** Ele não consegue as duas coisas, porque a informação de que precisaria
está do outro lado da quebra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois nós de banco, A e B, cada um com uma cópia da contagem de estoque. A ligação entre eles está cortada. Um cliente do lado de A escreve units igual a 9 em A. Um cliente do lado de B lê de B. B precisa ou se recusar a responder, porque não tem como saber o valor mais recente, ou responder 10, que está desatualizado.\"><defs><marker id=\"l8-partition-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"60\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">nó A</text><text x=\"145\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">units = 9</text><rect x=\"490\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">nó B</text><text x=\"575\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">units = 10</text><path d=\"M232 115 L330 115\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M390 115 L488 115\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"360\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" fill=\"var(--amber)\">×</text><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">partição</text><rect x=\"60\" y=\"190\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente escreve 9</text><rect x=\"470\" y=\"190\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente lê: recusa, ou 10?</text><path d=\"M145 188 L145 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-partition-ah-phosphor)\"></path><path d=\"M575 152 L575 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-partition-ah-phosphor)\"></path></svg>", "caption": "Durante uma partição, um nó que não alcança o outro precisa escolher: recusar, e continuar consistente, ou responder, e talvez estar errado."}
```

## Do que o teorema não trata

Ele não diz nada sobre um sistema sem partição; as próximas seções e o PACELC tratam disso. Não diz nada
sobre velocidade, sobre quão prováveis são as partições, nem sobre quanto tempo uma dura. E é sobre um
dado de cada vez: um sistema pode fazer uma escolha diferente para cada tipo de dado que guarda, que é
onde esta aula termina.

O resto da aula faz as duas escolhas acontecerem na sua máquina, com os dois tipos de replicação que um
servidor PostgreSQL oferece.
