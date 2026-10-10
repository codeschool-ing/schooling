---
title: Quando o resultado de uma janela é final
version: 1
---

**O `windows.py` viu as dez vendas antes de imprimir uma linha, e um processador de stream nunca tem
isso.** Ele precisa decidir quando contar a alguém o que uma janela tem, e toda escolha é cedo demais
ou errada.

A opção `--updates` faz o programa se comportar como um processador que vai contando. Ele lê as vendas
na ordem em que chegaram e imprime uma janela cada vez que uma venda a muda:

```
ubuntu@stream:~/work$ python windows.py tumbling 5 --updates
```

Leia a janela das 09:05 às 09:10 coluna abaixo. Depois da venda 5 ela tem duas vendas e 12.390
centavos. Então chegam as vendas 6 e 7, das 09:12 e 09:13, e pelo relógio dos eventos a janela das
09:05 já está dois minutos inteiros no passado. Um processador que fechasse as janelas assim que
aparecesse um evento posterior teria informado "duas vendas, 12.390" como final. **Aí chega a venda 8,
e a janela passa a ter três vendas e 21.380 centavos.**

## Dois jeitos de emitir

**Emitir a cada atualização.** A saída é um stream de correções: cada linha substitui a anterior
daquela janela. Nada se perde, e todo resultado é tão recente quanto pode ser. O custo cai em quem lê
a saída: tem de tratá-la como atualizações de uma linha identificada pela janela, não como linhas
novas, ou a janela das 09:05 é contada três vezes. Uma tabela num banco, escrita com upsert como a
lição 8 descreveu, lê corretamente esse tipo de saída; um log de anexos ou um e-mail não.

**Emitir uma vez, quando a janela é final.** A saída é uma linha por janela, e quem lê pode tratá-la
como um anexo. O custo cai no processador: ele precisa saber quando uma janela é final, e espera até
lá, então os resultados chegam tarde. O Kafka Streams oferece isso com `suppress`, ou com a estratégia
de emissão `onWindowClose`; o Spark chama as duas escolhas de modos de saída, update e append, que a
lição 12 roda.

| | emitir a cada atualização | emitir uma vez, quando final |
|---|---|---|
| frescor | assim que um evento cai | depois que a janela é declarada completa |
| saída | correções de uma linha por janela | uma linha por janela |
| um evento atrasado | mais uma correção | descartado, ou tratado à parte |
| quem lê precisa de | upserts, pela janela | nada especial |

## A pergunta que as duas deixam aberta

Emitir uma vez precisa de uma regra para "final", e mais cedo ou mais tarde emitir a cada atualização
também: um processador não pode manter toda janela aberta para sempre esperando correções, porque
cada janela aberta é estado. As duas precisam, portanto, da mesma resposta para a mesma pergunta:
**como um processador decide que não vão chegar mais eventos para uma janela?** Ele não tem como
saber; só pode estimar, pelos tempos de evento que já viu, até onde o tempo chegou, e aceitar que
alguns eventos vão chegar depois da estimativa. Essa estimativa se chama watermark, e a lição 11
constrói um e passa por ele as dez vendas desta lição e as atrasadas da lição 9.
