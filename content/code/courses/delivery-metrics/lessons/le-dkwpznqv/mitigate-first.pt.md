---
title: Mitigar antes de diagnosticar
version: 1
---

Às 18:02 de 30 de setembro, dezesseis minutos depois de o incidente ser declarado, o time de Billing tinha uma escolha. Rafa, o líder técnico, tinha quase certeza de que as cobranças duplicadas vinham de uma das quatro mudanças do release `D047`, e quase certeza de qual: a nova lógica de nova tentativa para pagamentos com cartão lentos. Ele podia achar o bug e corrigi-lo, ou podia fazer rollback do release inteiro e investigar depois.

Bia, como comandante do incidente, decidiu pelo rollback. O rollback começou às 18:04 e terminou às 18:15, e nenhuma cobrança duplicada aconteceu depois dele. Achar e corrigir o bug direito levou o dia seguinte.

## Por que desfazer antes de entender

**A prioridade num incidente é parar o estrago, não explicá-lo.** Cada minuto gasto diagnosticando enquanto o sistema ainda cobra as lojas em dobro é um minuto de mais cobranças duplicadas. O diagnóstico pode levar uma hora, ou um dia, e pode estar errado; um rollback para o release anterior leva minutos e muito provavelmente para o que quer que o release tenha começado.

O hábito a desaprender é o instinto do engenheiro, que normalmente é uma virtude: entender o problema, depois corrigir. Num incidente essa ordem se inverte. **Mitigar, depois diagnosticar, depois corrigir.** O postmortem, aula 15, é onde o entendimento acontece, com as evidências preservadas e sem nenhum cliente de ninguém sendo prejudicado enquanto isso.

## As mitigações de sempre

| movimento | quando cabe | o que custa |
|---|---|---|
| **fazer rollback** do último release | o estrago começou com um deploy | as outras mudanças do release saem de novo mais tarde |
| **desligar uma feature flag** | a mudança foi lançada atrás de uma flag | a funcionalidade fica indisponível até a correção |
| **fazer failover** para outra região ou provedor | o estrago está num lugar que dá para contornar | capacidade ou custo do outro lado |
| **descartar carga** ou limitar a taxa | o sistema está sobrecarregado | algumas requisições são recusadas, de propósito |
| **bloquear a entrada ruim** | um tipo de requisição dispara a falha | os usuários que a enviam são afetados |

Cada uma é uma decisão que o comandante do incidente toma com informação incompleta, e cada uma deveria ser **barata de tomar porque foi preparada com antecedência**: um rollback que leva um comando, flags em volta de mudanças arriscadas, um runbook que diz como fazer failover. Um time que precisa descobrir como fazer rollback durante o incidente deixou a mitigação tão lenta quanto o diagnóstico.

## Quando não dá para fazer rollback

Algumas mudanças não se desfazem revertendo o código: uma migração de banco de dados que apagou uma coluna, uma mensagem já enviada a dez mil lojas, dinheiro já cobrado. O incidente de 30 de setembro teve uma versão disso. O rollback parou as novas cobranças duplicadas às 18:15; não fez nada pelas 212 duplicatas já feitas, que precisaram ser estornadas uma a uma até as 21:10.

É por isso que a linha do tempo do time de Billing separa **restaurado**, quando o estrago parou, de **resolvido**, quando as consequências dele foram reparadas. O tempo para restaurar da DORA é o primeiro. A experiência das lojas inclui o segundo.

## Lotes pequenos facilitam a mitigação

A aula 5 mostrou que os deploys com falha do time de Billing levavam mais de duas horas para ser desfeitos em junho e julho, quando cada um carregava de seis a oito mudanças, e menos de uma hora depois disso. O `D047` carregava quatro mudanças e um rollback levou onze minutos. **Um release pequeno é um rollback barato**, o que é mais uma forma de o tamanho de lote das aulas 5 e 7 chegar a uma parte do trabalho com a qual parece não ter nada a ver.
