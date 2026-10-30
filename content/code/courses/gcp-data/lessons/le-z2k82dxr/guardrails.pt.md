---
title: Proteções, antes da consulta que custa uma fortuna
version: 1
---

**Nenhum dos dois modelos de preço para uma consulta ruim sozinho.** Sob demanda cobra o que a consulta
ler, e uma consulta escrita contra a tabela errada, ou sem o filtro, lê tudo. Uma reserva com
autoscaling cresce até o máximo para rodar o que receber. As proteções são configurações que alguém
precisa fazer antes de a consulta chegar, e esta seção são as três que importam para a computação.
Nenhuma delas pode ser configurada neste laboratório, e todo comando aqui aparece como você o
digitaria e não foi rodado.

## Cotas personalizadas, para sob demanda

**Uma cota personalizada limita os bytes que um projeto, ou cada usuário dele, pode ter cobrados num
dia.** A documentação do Google, "Create custom cost controls", descreve duas: **query usage per day**,
para o projeto inteiro, e **query usage per day per user**, por usuário. Elas são definidas na página de
cotas do projeto no console, ou com a API Service Usage, em TiB. Quando uma consulta levaria o total do
dia acima da cota, o BigQuery a recusa com um erro em vez de rodá-la, e a cota zera à meia-noite do
horário do Pacífico.

A página de preços as cita primeiro entre os controles de custo: "User-level and project-level custom
cost controls" e "The maximum bytes billed by a query". **A cota é a que protege o mês.** Uma cota por
usuário de 1 TiB por dia, em São Paulo, limita o que uma pessoa pode gastar sob demanda a 11,25 USD por
dia, digite ela o que digitar, e uma cota de projeto limita o total. A conta do painel da seção sob
demanda, 16.200 USD por um mês de varreduras de 2 TiB de hora em hora, precisa de 48 TiB por dia; uma
cota de projeto de 5 TiB o teria parado na primeira tarde.

**A fraqueza dela é que ela para as consultas certas também.** Uma cota não sabe qual consulta importa.
Quando os TiB do dia acabam, a última consulta das analistas falha exatamente como a desgovernada teria
falhado, e uma cota baixa demais vira a pane que devia evitar. Então ela é definida a partir do que o
projeto de fato lê num dia pesado, em `INFORMATION_SCHEMA.JOBS`, com folga acima.

## Máximo de bytes cobrados, para uma consulta

**`maximumBytesBilled` é um limite posto numa única consulta**: se a consulta for cobrar mais, ela falha
antes de ler qualquer coisa e não custa nada. É a proteção que um programa põe em toda consulta que
manda, e a linha de comando `bq` a escreve como uma flag. A aula 16 a ensina ao lado do dry run, que é
como uma consulta descobre quanto custaria antes de alguém decidir rodá-la.

## O máximo de uma reserva

**Em slots, a proteção é `--autoscale_max_slots`.** Uma reserva nunca escala acima do máximo, então o
mais que uma reserva com autoscaling pode custar numa hora são essas slot-horas. Para a reserva da seção
de edições, 200 slots de Enterprise:

```sh
bq update --reservation --location=southamerica-east1 \
  --autoscale_max_slots=200 quitanda-etl
```

200 × 0,093 são 18,60 USD por hora, e 200 × 0,093 × 730 são 13.578 USD num mês em que ela nunca para.
**O máximo limita a velocidade além do custo**: uma consulta que precisava de 400 slots roda em 200 e
demora mais, em vez de falhar. Essa é a diferença em relação à cota. Uma reserva no máximo deixa as
consultas mais lentas; um projeto na cota as faz falhar.

## Orçamentos, que só avisam

**Um orçamento do Cloud Billing manda um alerta; ele não para nada.** Ele acompanha a conta de um projeto
ou de uma conta de faturamento e manda e-mail quando o gasto passa de uma fração do valor definido.
Vale a pena ter, e ele chega depois de o dinheiro gasto, e por isso é a última linha aqui e não a
primeira. Para o BigQuery, a cota e o máximo são as configurações que agem antes da conta.
