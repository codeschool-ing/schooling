---
title: A fatura que ninguém lê
version: 1
---

A fatura da nuvem da Coreto chega no primeiro dia útil de cada mês. Vai para o time do Otávio,
alguém confere o total contra o contrato, e ela é paga. **Ninguém na engenharia a abre.** E cada
linha dela é resultado de uma decisão de engenharia: uma máquina dimensionada para um teste de carga
que ninguém lembra, um ambiente de homologação ligado o fim de semana inteiro, logs guardados por
mais tempo do que alguém os lê, uma réplica de banco criada durante um incidente e nunca removida.

Quem gasta o dinheiro nunca vê a fatura, e quem vê a fatura não consegue mudar o que está nela. É
essa distância que o FinOps existe para fechar, e ela é problema de um líder antes de ser problema de
qualquer outra pessoa.

## A imagem errada

A imagem comum do FinOps é um projeto de corte de custos: o financeiro se assusta com um número,
compra-se uma ferramenta, um consultor produz uma lista, e a fatura cai por um trimestre antes de
voltar a subir. Falha pelo mesmo motivo pelo qual a fatura não era lida. **A economia foi feita por
quem não toma as decisões**, e então as decisões seguem como antes.

A FinOps Foundation, que publica o modelo de referência da prática, a descreve de outro jeito: um
ciclo de três fases que a organização percorre sem parar:

| fase | a pergunta | na Coreto |
|---|---|---|
| informar | quem está gastando o quê, em unidades que os times reconhecem? | cada time vê sua parte da fatura todo mês, e o custo de um ingresso vendido |
| otimizar | pelo que podemos parar de pagar? | os ambientes de homologação ligados noites e fins de semana; máquinas maiores que a carga |
| operar | como evitar que volte? | homologação desligada por padrão; uma revisão mensal da fatura com os líderes de time |

**A ordem importa.** Otimizar antes de informar produz economias que ninguém entende, e é por isso
que elas se desfazem. Informar sem operar produz um relatório lido uma vez e depois arquivado. As
três seções seguintes seguem as fases na ordem: custo unitário e showback são a fase de informar, e
as economias de sempre são as outras duas.

## Por que a fatura é ilegível

Uma fatura de nuvem é organizada do jeito que o provedor vende, não do jeito que a empresa trabalha.
A da Coreto tem milhares de linhas, nomeadas por produto, região e identificador de recurso: horas
de computação numa zona, requisições de armazenamento em outra, dados saindo da rede, um banco
gerenciado por classe de instância. Nenhuma dessas linhas diz "Checkout" ou "o teste de carga da
abertura de vendas". **Lê-la exige uma tradução do vocabulário do provedor para o da empresa**, e até
alguém fazer essa tradução a fatura é um número só, que sobe.

Duas traduções fazem a maior parte do trabalho. Uma divide a fatura por algo que o negócio vende,
para que o número possa ser comparado mês a mês; a próxima seção faz isso. A outra a divide por
time, para que cada líder veja a parte que as decisões dele produziram; a seção seguinte faz isso.

## O que um líder faz a respeito

Um líder não precisa de um time de FinOps para começar. A Coreto não tem um, e o primeiro passo do
Davi foi uma reunião: pediu ao Otávio acesso de leitura à fatura e a Rafaela Nunes, que lidera a
Plataforma, uma hora para lê-la com ele. A meta do primeiro mês é modesta — **pôr a parte de cada
time na fatura diante do próprio time** — e é o passo de que toda economia posterior depende.

A outra metade do trabalho é a que a aula 11 preparou. Uma economia custa tempo de engenharia, e esse
tempo vale R$ 150 a hora como qualquer outro. Um líder que conhece os dois números distingue uma
economia que vale uma sprint de uma que custa mais para achar do que devolve.

**Um aviso sobre o que envelhece.** Os provedores mudam a forma de cobrar de tempos em tempos: os
nomes dos programas de desconto, o que é cobrado por segundo ou por hora, quais serviços são cobrados
por requisição. Os detalhes desta aula foram escritos para sobreviver a isso, e onde mencionam um
mecanismo de preço o descrevem de forma genérica. O que não envelhece são as perguntas por baixo: quanto custa
atender uma unidade do negócio, quem gastou o dinheiro, e se alguém usa aquilo pelo que se pagou.
Confira os termos atuais do seu provedor antes de agir com base em qualquer mecanismo citado aqui.
