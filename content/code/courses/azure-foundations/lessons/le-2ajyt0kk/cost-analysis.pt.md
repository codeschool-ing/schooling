---
title: A análise de custos, e as perguntas que ela responde
version: 1
---

**Um orçamento diz que alguma coisa está errada; a análise de custos é onde você descobre o quê.** É a
parte do Cost Management que desenha a fatura como gráficos e tabelas que você corta por qualquer
dimensão: assinatura, grupo de recursos, recurso, serviço, região, tag. **Nada nesta seção foi
executado**: a análise de custos lê os custos de uma conta de cobrança de verdade, e o laboratório não
tem nenhuma. Também não há capturas de tela, já que as telas são da Microsoft e mudam. O que segue é
como ela funciona, segundo a documentação da Microsoft, e a ordem em que fazer perguntas a ela.

## Um escopo, um período, um agrupamento

Toda visão da análise de custos são as mesmas três escolhas, e errar a primeira é o erro comum:

- **o escopo**, que é uma das caixas da lição 2: um grupo de gerenciamento, uma assinatura, um grupo
  de recursos, ou uma conta de cobrança acima deles. A visão mostra só os custos dentro dele, e você só
  vê os escopos em que tem um papel. Um desenvolvedor com acesso a um grupo de recursos que abre a
  análise de custos vê o custo desse grupo e acredita que é o da empresa;
- **o período**, por padrão o mês corrente, com granularidade diária ou mensal;
- **o agrupamento e os filtros**: agrupe por serviço para ver *que tipo* de coisa custa dinheiro, por
  recurso para ver *qual*, por uma tag para ver *de quem*, que é a lição 15.

A Microsoft entrega um conjunto de visões para começar. As **visões inteligentes**, como *Services* e
*Resources*, abrem com o custo do mês e a sua previsão no topo e uma tabela dos maiores contribuintes
embaixo, e cada linha se abre: de uma assinatura para os seus grupos, de um grupo para os seus
recursos, de um recurso para os seus medidores. As **visões personalizáveis**, entre elas
*Accumulated costs* e *Daily costs*, são gráficos que você muda e salva.

## A ordem em que perguntar

Quando o alerta de previsão das seções anteriores dispara, as mesmas quatro perguntas acham a causa
quase sempre:

1. **Custos diários do mês.** Um custo que cresceu aos poucos é uma carga de trabalho crescendo. Um
   degrau num dia é alguma coisa que foi criada, ou mudada, naquele dia, e a data é a primeira pista.
2. **Agrupe o dia do degrau por serviço.** Isso dá o tipo de coisa: máquinas virtuais, banda, um banco
   de dados, um gateway.
3. **Agrupe por recurso, filtrando aquele serviço.** Isso dá a coisa, com o seu id de recurso, que a
   lição 2 ensinou a ler: a assinatura e o grupo de recursos estão nele, e costumam dizer de quem é.
4. **Abra o histórico do próprio recurso**, o activity log, para achar quem o criou ou mudou.
   O curso `azure-operations` cobre o activity log na sua lição 21; aqui basta saber que toda escrita
   no Resource Manager fica registrada ali com a identidade que a fez.

**Os dados diários chegam com um dia de atraso, como os do orçamento.** A análise de custos lê os
mesmos dados que o orçamento, então um degrau que começou hoje de manhã ainda não está no gráfico. A
documentação da Microsoft também aconselha olhar as visões toda semana, por hábito, e todo dia na
primeira ou nas duas primeiras semanas depois de uma mudança.

## Anomalias, achadas para você

Para uma assinatura, a análise de custos também procura **anomalias**: dias cujo custo foge do padrão
recente da própria assinatura. As visões inteligentes as relatam entre os seus insights, ou dizem
*No anomalies detected*, e um **alerta de anomalia** pode mandar e-mail a alguém quando uma é
encontrada. É um alarme de outro tipo: um orçamento compara o mês com um número que alguém escolheu,
uma anomalia compara um dia com a história da própria assinatura. Uma máquina esquecida que custa um
pouco todo dia nunca parece anômala, e o orçamento a pega; um pico súbito bem abaixo do orçamento
parece, e o orçamento fica quieto. A loja mantém os dois.

## Custo real e custo amortizado

Toda visão pode mostrar o custo de dois jeitos, e a diferença é o assunto da lição 14:

- **custo real** é o que foi cobrado, no dia em que foi cobrado. Uma reserva comprada para um ano,
  paga adiantada, é uma linha grande no dia da compra;
- **custo amortizado** espalha essa compra pelos dias que ela cobre, e cobra a parte de cada dia dos
  recursos que a usaram.

Os orçamentos avaliam o custo real. Para a pergunta *quem gastou o quê*, o amortizado é o honesto,
porque o recurso que se beneficia de uma reserva é cobrado pela sua parte, e o dia da compra não
parece um desastre. Escolha antes de comparar dois meses, e diga qual dos dois um gráfico mostra.
