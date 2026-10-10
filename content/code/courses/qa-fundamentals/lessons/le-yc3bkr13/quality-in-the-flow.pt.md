---
title: Qualidade dentro do fluxo, não no fim dele
version: 1
---

**Sem sprints não há revisão da sprint nem fim de ciclo em que testar, então a qualidade precisa ser
construída em cada etapa por que um cartão passa.** O Kanban tem duas ferramentas para isso, as duas da fábrica
de onde ele veio: políticas escritas no quadro e parar a linha.

## Políticas escritas no quadro

"Tornar as políticas explícitas" é uma das práticas centrais, e para quem testa é a importante. Uma
**política** é a regra para sair de uma coluna, escrita onde todos veem, no topo da coluna. O quadro do Cine
Aurora traz estas:

| coluna | um cartão pode sair quando |
|---|---|
| construindo | o código foi revisado e as verificações automatizadas passam |
| esperando teste | a Lia, ou quem estiver testando, o puxou |
| testando | cada exemplo do cartão passa, e ele foi explorado por meia hora |
| pronto | a Célia o viu funcionando na bilheteria |

Repare no que é isso: **a definição de pronto da aula 12, dividida por coluna**. Cada coluna tem seus próprios
critérios de saída, e um cartão que não os cumpre não anda, por mais urgente que pareça. A aula 21 dá à mesma
ideia um nome próprio, critérios de entrada e de saída, para ciclos de teste inteiros.

Uma política também resolve discussões antes de começarem. Quando o Rafael perguntou se uma correção de uma
linha podia pular "testando", a resposta estava no quadro: nenhuma coluna diz "a não ser que seja pequeno".

## Parar a linha

O sistema de produção da Toyota tem uma segunda ideia que os times Kanban emprestam: o **jidoka**, em geral
traduzido como *automação com toque humano*. Uma máquina que detecta algo errado para sozinha, e qualquer pessoa
que vê um defeito pode puxar uma corda que para a linha. O ponto é que um defeito é corrigido onde aparece, em
vez de ser passado adiante na linha para virar problema de outra pessoa, mais caro a cada estação.

Num quadro, parar a linha é assim:

- um cartão com problema recebe uma marca de **bloqueado**, um adesivo vermelho num quadro físico, e fica onde
  está;
- o cartão bloqueado conta no limite da coluna, então a coluna enche e o problema vira rápido problema de todos;
- o time faz a pergunta da retrospectiva, **por que isso foi possível?**, enquanto o cartão ainda está
  bloqueado, e não no fim de um ciclo que o Kanban não tem.

## Trabalho urgente, sem quebrar o quadro

Defeitos achados em produção não esperam em "a fazer". O Kanban lida com eles com **classes de serviço**: uma
faixa *urgente* no topo do quadro para um cartão que fura a fila. A política do Cine Aurora para ela tem duas
linhas: só um defeito que cobra o preço errado de um cliente ou impede uma venda pode usá-la, e só um cartão pode
estar nela de cada vez. Sem essa segunda linha, tudo vira urgente, e a faixa vira o quadro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 260\" role=\"img\" data-fig=\"l13-lanes\" aria-label=\"Um quadro Kanban com quatro colunas, construindo, esperando teste, testando e pronto, cada uma com a política de saída escrita sob o nome: revisado e checagens passam; alguém do teste puxou; exemplos passam e explorado; a Célia viu. Acima da faixa padrão há uma faixa urgente, um cartão no máximo, com o cartão preço errado aos domingos em testando. Na faixa padrão, o cartão lista de sessões ordenada em testando leva uma marca vermelha de bloqueado.\"><rect x=\"100.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"168.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">construindo</text><text x=\"168.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">revisado, checagens passam</text><rect x=\"245.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"313.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">esperando teste</text><text x=\"313.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">alguém do teste puxou</text><rect x=\"390.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">testando</text><text x=\"458.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">exemplos passam, explorado</text><rect x=\"535.0\" y=\"10.0\" width=\"137.0\" height=\"240.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"603.5\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">pronto</text><text x=\"603.5\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--phosphor)\">a Célia viu</text><path d=\"M10.0 56.0 L96.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M10.0 120.0 L96.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M104.0 56.0 L233.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M104.0 120.0 L233.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M249.0 56.0 L378.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M249.0 120.0 L378.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M394.0 56.0 L523.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M394.0 120.0 L523.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M539.0 56.0 L668.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M539.0 120.0 L668.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"14.0\" y=\"76.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">urgente</text><text x=\"14.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">1 cartão no máximo</text><text x=\"14.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">padrão</text><rect x=\"400.0\" y=\"70.0\" width=\"117.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">preço errado aos domingos</text><rect x=\"110.0\" y=\"134.0\" width=\"117.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"168.5\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">botão de reembolso</text><rect x=\"400.0\" y=\"134.0\" width=\"117.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">lista de sessões ordenada</text><rect x=\"545.0\" y=\"134.0\" width=\"117.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"603.5\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">assento no recibo</text><rect x=\"400.0\" y=\"172.0\" width=\"117.0\" height=\"18.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"458.5\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-weight=\"600\" fill=\"var(--amber)\">bloqueado</text></svg>", "caption": "Políticas no topo de cada coluna, uma faixa urgente para o defeito que não pode esperar, e um cartão bloqueado que fica onde está até o time cuidar dele."}
```

## Cadências em vez de eventos

O Kanban continua tendo reuniões; chama-as de cadências, e o time escolhe o ritmo. O Cine Aurora tem três: uma
conversa curta em pé diante do quadro toda manhã, que percorre o quadro da direita para a esquerda, dos cartões
mais perto do pronto até os mais novos, para terminar vir antes de começar; uma reunião semanal de
**reabastecimento**, em que a Joana escolhe o que entra em "a fazer"; e uma revisão mensal das medidas de fluxo,
em que a Lia leva o diagrama de fluxo cumulativo. A pergunta da retrospectiva também é feita ali, sobre cada
cartão que ficou bloqueado.
