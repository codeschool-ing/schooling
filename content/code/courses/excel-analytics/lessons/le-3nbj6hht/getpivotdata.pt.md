---
title: INFODADOSTABELADINÂMICA, uma referência pelo nome
version: 1
---

**Clique numa célula de uma tabela dinâmica enquanto digita uma fórmula e o Excel não escreve `=B4`.
Ele escreve uma fórmula que acha o número pelos nomes do campo e do item, onde quer que a tabela
dinâmica o tenha posto.** Essa fórmula, `INFODADOSTABELADINÂMICA` (`GETPIVOTDATA` no Excel em
inglês), surpreende todo mundo na primeira vez, e quase todos a desligam antes de aprender do que
ela protege.

## O que o Excel escreve

Na planilha `Report`, com todos os botões da segmentação acesos, clique em F4, digite `=` e clique em
B4, a receita de `CER1K`. O Excel escreve isto e responde 21.356:

```localised
=INFODADOSTABELADINÂMICA("Revenue";$A$3;"Product";"CER1K")
```

Os argumentos, na ordem:

| argumento | aqui | o que diz |
|---|---|---|
| o campo de valor | `"Revenue"` | qual número: o nome do próprio campo, não `Soma de Revenue` |
| uma célula da tabela dinâmica | `$A$3` | qual tabela dinâmica: qualquer célula dela serve, e o Excel usa o canto superior esquerdo |
| campo e item, aos pares | `"Product";"CER1K"` | qual célula: tantos pares quantos forem precisos para apontar exatamente uma |

Sem par nenhum, ela aponta o total geral, e responde 51.494:

```localised
=INFODADOSTABELADINÂMICA("Revenue";$A$3)
```

## Por que um nome é mais seguro que uma posição

Digite `=B5` em F5 em vez disso. B5 é a célula ao lado de `CER250`, então mostra 837. Agora clique
em `Wholesale` na segmentação. `CER250` não tem vendas de atacado e sai da tabela, cada linha abaixo
dele sobe uma, e B5 passa a ter a receita de atacado de `DEC250`. `=B5` mostra 1.330, e nada na
planilha diz que deixou de ser `CER250`.

Peça o mesmo produto pelo nome:

```localised
=INFODADOSTABELADINÂMICA("Revenue";$A$3;"Product";"CER250")
```

Com `Wholesale` aceso ela responde `#REF!`: não há `CER250` na tabela dinâmica para ler. Um número
errado com cara de certo é a pior coisa que um relatório pode conter, e um erro dizendo que algo
mudou de lugar é o melhor jeito de falhar.

A fórmula de `CER1K` em F4 agora mostra 17.168, o número do atacado.
**`INFODADOSTABELADINÂMICA` devolve o que a tabela dinâmica mostra**, então uma segmentação ou uma
linha do tempo muda a resposta dela exatamente como muda a célula. Para guardar um número que ignore
as segmentações, use um `SOMASES` (`SUMIFS`) sobre a tabela, como a aula 5 faz.

## Uma célula no lugar do item

O item não precisa estar digitado na fórmula. Acenda todos os botões da segmentação, digite `SUL1K`
em F3 e, em G3:

```localised
=INFODADOSTABELADINÂMICA("Revenue";$A$3;"Product";F3)
```

Ela responde 21.082, e digitar outro código de produto em F3 muda a resposta. A fórmula virou uma
busca dentro da tabela dinâmica, e as células de indicadores do painel da aula 17 são feitas assim.

## Desligando, e quando

`INFODADOSTABELADINÂMICA` atrapalha quando você quer uma fórmula para arrastar para baixo ao lado da
tabela dinâmica: a cópia arrastada continua apontando `"CER1K"` em toda linha, onde `=B4` teria
virado `B5`, `B6` e assim por diante. Para isso, desligue o comportamento em **Análise da Tabela
Dinâmica › Opções**, na seta ao lado, e **Gerar InfoDadosTabelaDinâmica** (*Generate GetPivotData*),
um interruptor que inverte a cada clique. O mesmo interruptor está em **Arquivo › Opções ›
Fórmulas**, como *Use GetPivotData functions for PivotTable references* no Excel em inglês. É uma
configuração do Excel no seu computador, não da pasta de trabalho, então fica desligada em todo
arquivo até você religá-la.

Clicar numa célula da tabela dinâmica passa então a digitar uma referência simples. Religue quando
terminar: o resto do curso supõe que está ligada.
