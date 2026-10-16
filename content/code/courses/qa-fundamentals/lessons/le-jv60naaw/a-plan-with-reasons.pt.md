---
title: Um plano com seus motivos, e suas lacunas, por escrito
version: 1
---

**As quatro respostas viram uma tabela, a tabela vira uma ordem e um orçamento de horas, e as horas que não são
gastas também ficam escritas.** Essa última parte é o que torna a priorização honesta.

## Combinando as quatro

O Cine Aurora mantém o método simples: parte da nota de risco, depois sobe uma área um lugar quando o uso ou o
histórico dizem que ela foi subestimada, e diz por quê.

| área | risco | uso | histórico | ordem | horas |
|---|---|---|---|---|---|
| regra de preço | 9 | todo pedido | 4 defeitos | 1 | 5 |
| pedidos | 6 | todo pedido | 1 defeito | 2 | 3 |
| reembolsos | 6, depois da Célia | 1% dos pedidos | nenhum ainda | 3 | 2,5 |
| cupons | 6 | 6% dos pedidos | 1 defeito | 4 | 2,5 |
| mapa de assentos | 2 | 64% dos pedidos | nenhum ainda | 5 | 2 |
| relatório noturno | 1 | lido uma vez por dia | nenhum ainda | 6 | 1 |

Dezesseis horas, gastas onde o estrago seria maior. Os motivos estão na tabela, então a ordem pode ser discutida: o
Rafael achava que os cupons deviam ficar acima dos reembolsos, porque o código é mais novo; a Joana manteve os
reembolsos acima porque um reembolso que falha acontece na frente de um cliente no balcão. Os dois motivos ficam
registrados, e a ordem é decisão da Joana.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 220\" role=\"img\" data-fig=\"l20-hours\" aria-label=\"Dezesseis horas de teste divididas entre seis áreas, como barras horizontais: regra de preço 5 horas, pedidos 3, reembolsos 2,5, cupons 2,5, mapa de assentos 2, relatório noturno 1.\"><text x=\"130.0\" y=\"27.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">regra de preço</text><rect x=\"140.0\" y=\"16.0\" width=\"350.0\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"27.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"130.0\" y=\"59.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pedidos</text><rect x=\"140.0\" y=\"48.0\" width=\"210.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><text x=\"130.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reembolsos</text><rect x=\"140.0\" y=\"80.0\" width=\"175.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,5</text><text x=\"130.0\" y=\"123.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cupons</text><rect x=\"140.0\" y=\"112.0\" width=\"175.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,5</text><text x=\"130.0\" y=\"155.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mapa de assentos</text><rect x=\"140.0\" y=\"144.0\" width=\"140.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"288.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"130.0\" y=\"187.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">relatório noturno</text><rect x=\"140.0\" y=\"176.0\" width=\"70.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"218.0\" y=\"187.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"140.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">horas</text></svg>", "caption": "As mesmas dezesseis horas de uma divisão igual, gastas onde o estrago seria maior."}
```

## O que quer dizer *testado de leve*

O relatório noturno recebe uma hora, e isso é uma decisão, não um esquecimento. A hora vai para as conferências mais
baratas e de maior alcance: o relatório roda, a coluna nova aparece, um pedido conhecido mostra o desconto que deveria.
Nada de casos de borda, nada de todos os tipos de sessão. **Prioridade baixa quer dizer menos profundidade, não teste
nenhum**, porque uma queda em algo que ninguém olhou continua sendo uma queda.

## Dizendo o que não foi testado

No fim dos dois dias, o resumo da Lia para o time é curto e tem quatro partes:

> **Testado a fundo:** a regra de preço, incluindo o esboço da aula 17, as relações da aula 19 e uma hora de
> exploração; os pedidos, incluindo os recusados; os reembolsos no balcão com a Célia.
>
> **Testado de leve:** cupons, os cenários combinados e os espaços colados; o mapa de assentos em dois navegadores; a
> coluna nova do relatório com os pedidos de uma noite.
>
> **Não testado:** o mapa de assentos em celulares; cupons combinados com a quarta, que ainda não tem resposta
> combinada.
>
> **Aberto e conhecido:** a sessão das 9:30 é cobrada pelo preço da noite.

O terceiro e o quarto parágrafos são os importantes. Transformam *acabou o tempo* numa lista que a Joana consegue ler
antes de decidir entregar, e são a entrada para os critérios de saída da próxima aula. Um time que esconde o que não
testou não está se protegendo. Está passando uma decisão de quem deveria tomá-la para o cliente que vai descobrir.

## Quando as prioridades mudam no meio da semana

Um plano feito na segunda está errado na quarta com mais frequência do que não: uma correção chega tarde, um defeito
novo aparece numa área com nota baixa, uma funcionalidade é retirada. A tabela é barata de refazer, e deve ser refeita
sempre que as entradas mudarem. A pior versão da priorização é a feita com cuidado na segunda e seguida fielmente
depois de ter deixado de ser verdade.
