---
title: "A conta: execuções, DIU-horas e as horas de um runtime"
version: 1
---

**A conta do Data Factory não tem linha para a própria factory; ela cobra pelo que a factory faz.**
Os medidores abaixo vêm da documentação da Microsoft, e os preços que vêm depois são **ilustrativos**,
números redondos para fazer a conta e não os preços do Azure; a tabela de preços da lição 1 dá os
reais para `brazilsouth`. Nada nesta seção foi cobrado.

## Os medidores

| medidor | o que ele conta |
|---|---|
| orquestração | execuções de atividade, de gatilho e de depuração, por mil |
| movimentação de dados | DIU-horas de atividades de cópia no runtime do Azure |
| atividades de pipeline | horas de atividades como `Lookup` e `Get Metadata` que rodam num runtime |
| atividades externas | horas de atividades que esperam enquanto outro serviço trabalha: uma stored procedure, um notebook do Databricks |
| data flows | vCore-horas dos clusters Spark em que os mapping data flows rodam, assunto da lição 20 |
| self-hosted | as mesmas atividades a outros preços, e a máquina, que é sua |
| Azure-SSIS | nó-horas enquanto o runtime SSIS está ligado |

**A linha das atividades externas é a que surpreende.** Uma atividade que inicia um job do Databricks
e espera uma hora por ele é cobrada pela hora, um valor pequeno por hora, além do que o Databricks
cobra para rodá-lo. Um pipeline cujo único trabalho é esperar outros serviços paga pela espera.

## O mês da Quitanda, a preços ilustrativos

A carga noturna roda uma vez por dia: uma execução de gatilho, uma cópia, uma stored procedure que
atualiza uma tabela de resumo, e uma atividade web que posta no canal do time quando termina. Quatro
execuções de atividade e uma de gatilho por noite, 31 noites:

- **orquestração**: 5 × 31 = 155 execuções. A um preço ilustrativo de 1,00 USD por mil execuções,
  0,16 USD;
- **movimentação de dados**: uma cópia do export de um dia, digamos com 4 DIUs por 2 minutos, dá 4 × 2
  / 60 = 0,13 DIU-hora por noite, 4,13 por mês. A um preço ilustrativo de 0,25 USD por DIU-hora, 1,03
  USD;
- **atividade externa**: a stored procedure espera 3 minutos por noite, 1,55 hora por mês. A um preço
  ilustrativo de 0,0003 USD por hora, 0,0005 USD: quase nada, porque o medidor é de espera e a espera
  foi curta.

**Cerca de 1,19 USD por mês com esses números, para um pipeline que roda toda noite.** A conta está
aqui para mostrar que linha cresce. A orquestração cresce com o número de execuções, então um pipeline
disparado a cada minuto em vez de toda noite custa 1.440 vezes mais nessa linha, e um `ForEach` sobre
mil arquivos são mil execuções de atividade a cada vez. A movimentação de dados cresce com as DIUs e
os minutos, então uma cópia que é lenta porque a origem é lenta paga por DIUs que esperaram. O resto é
pequeno até um data flow ou um serviço externo entrar na noite, e aí a conta desse serviço é a que se
deve ler.

## O que a conta deixa de fora

**A máquina de um runtime self-hosted, que é cobrada como máquina**: um servidor Windows ligado o mês
todo para uma cópia que leva quatro minutos por noite. E os serviços que o pipeline chama, que cobram
cada um por si: as operações da conta de armazenamento da lição 7 para cada arquivo que a cópia lê e
escreve, a computação do próprio banco enquanto a stored procedure roda, as DBUs do Databricks
enquanto o job dele roda. A linha do próprio Data Factory costuma ser a menor da fatura de uma
plataforma de dados, e é a orquestração que decide o tamanho das outras.
