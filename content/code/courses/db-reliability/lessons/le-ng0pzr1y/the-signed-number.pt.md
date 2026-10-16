---
title: O número que alguém assinou
version: 1
---

Um objetivo de recuperação só vale alguma coisa se foi acordado **antes** do incidente, por alguém com
autoridade para aceitar a perda, sabendo quanto custa fazer melhor. Durante o incidente é a pior hora
possível para descobrir que o negócio contava com zero e o esquema entrega um dia.

O acordo cabe numa página. Para o shop, ele poderia ser assim:

| sistema | falha | RPO | RTO | como é cumprido | última medição | acordado por |
|---|---|---|---|---|---|---|
| pedidos | perda do disco ou do servidor | 1 min | 1 h | arquivo, `archive_timeout` 60 s; diferencial toda noite | ensaio de 10 out: replay de 55 s | gerente de operações |
| pedidos | uma alteração equivocada | 0 | 4 h | recuperação para um ponto no tempo num servidor separado, reparo a partir da cópia | procedimento da lição 6, ensaiado a cada trimestre | gerente de operações |
| lista da newsletter | qualquer uma | 24 h | 3 dias | `pg_dump` toda noite | restaurado em 2 out | responsável por marketing |

Cada coluna está lá por um motivo:

- **falha**, porque um mesmo esquema tem números diferentes para falhas diferentes, como a primeira
  seção desta lição disse;
- **como é cumprido**, porque uma promessa sem mecanismo por trás é um desejo;
- **última medição**, porque o RTO em especial se deteriora à medida que os dados crescem, e a data
  diz quanto confiar nele;
- **acordado por**, um nome, porque "o negócio" não assina nada. Uma pessoa assina, e essa pessoa
  decide, no dia, se as quatro horas de um reparo cuidadoso valem mais que os minutos de uma
  substituição rápida.

## A curva de custo

Números mais apertados custam mais, e não de forma linear. Passar de um dia de perda para uma hora é
uma configuração (`archive_timeout`, lição 4). Passar de uma hora para alguns segundos é um receptor
por streaming ou uma réplica (lições 4 e 11). Passar de segundos para **zero** exige replicação
síncrona (lição 12), que faz todo commit esperar um segundo servidor e deixa o banco mais lento para
todo usuário, todo dia, para proteger contra um tipo de falha. Um RTO segue o mesmo formato: horas é
uma restauração a partir do backup, minutos é um standby pronto para ser promovido, segundos é
failover automático com tudo o que as lições 15 a 19 trazem.

Essa curva é o que se põe na frente da pessoa que disse "nada e nada". Não um sermão: três opções,
cada uma com seu número e seu preço, e uma assinatura ao lado da escolhida.
