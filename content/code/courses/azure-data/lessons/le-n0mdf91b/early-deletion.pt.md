---
title: Os dias mínimos, e a conta por sair cedo
version: 1
---

**Um blob em cool, cold ou archive é cobrado pelos dias mínimos do tier, fique ele ou não.** É assim
que a documentação da Microsoft descreve a cobrança por exclusão antecipada: um blob apagado,
sobrescrito ou movido para outro tier antes do mínimo é cobrado pelos dias que faltam, pelo preço do
tier que ele deixou. As pessoas leem o mínimo como uma regra que as impede de apagar. Nada impede; a
exclusão passa na hora, e os dias que faltam chegam na conta.

Esta seção foi escrita a partir dessa documentação. O Azurite não tem conta a pagar, e apaga sem dizer
nada um blob que foi para o cold poucos minutos antes; o blob que ele apaga é a exportação de setembro
que as seções anteriores puseram em cold:

```
ana@laptop:~/azure$ az storage blob delete -c orders-archive -n orders/2026-09/default.csv
ana@laptop:~/azure$ az storage blob list -c orders-archive --prefix orders/2026-09/ --query "[].[name, properties.blobTier]" -o tsv
orders/2026-09/audit.csv	Archive
orders/2026-09/cool.csv	Hot
```

A exclusão não imprimiu nada e o blob sumiu da listagem. No Azure o mesmo comando passaria do mesmo
jeito, e os 90 dias de cold seriam cobrados inteiros.

## A conta

A cobrança é proporcional: os dias que faltam, pelo preço mensal do tier. Com um preço ilustrativo de
cool de 0,010 USD por GB-mês, um número redondo para a conta e não o preço do Azure:

| o que acontece | dias guardado | dias cobrados | um GB, ilustrativo |
|---|---|---|---|
| movido para cool, apagado depois de 10 dias | 10 | 30 | 0,010 |
| movido para cool, apagado depois de 45 dias | 45 | 45 | 0,015 |
| movido para archive, movido para hot depois de 30 dias | 30 | 180 | pelo preço do archive, por 180 dias |

A primeira linha é a que surpreende: dez dias de armazenamento custam o mesmo que trinta. A segunda
não tem cobrança extra nenhuma, porque o mínimo passou. A terceira é o erro caro, porque o mínimo do
archive é de seis meses: um blob arquivado por uma regra na segunda-feira e necessário na sexta paga
meio ano de archive e ainda a reidratação por cima.

## O que isso quer dizer para um desenho

**Ponha dados num tier mais frio só quando souber quanto tempo eles vão ficar.** É uma pergunta sobre
os dados, e a Quitanda sabe responder. As exportações noturnas são lidas pelo financeiro por cerca de
um mês e guardadas sete anos pela regra de retenção da própria Quitanda; elas vão para hot no primeiro mês, cool depois disso e um tier ainda mais frio quando ninguém as lê
há um ano. Os arquivos de clique da lição 3 são reescritos em tabelas
diárias dentro de uma semana e apagados; eles nunca vão para outro lugar além do hot, porque todo tier
mais frio cobraria deles dias que nunca viveram.

Mover blobs à mão para de funcionar no segundo milhar deles. A lição 5 passa o trabalho para uma regra
de ciclo de vida, que move e apaga por idade e também não sabe nada dos dias mínimos: uma regra que
arquiva aos 30 dias e apaga aos 90 paga os 180 do archive para cada blob que toca.
