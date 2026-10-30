---
title: Quanto custa, como uma empresa chega lá, e quando é a resposta
version: 1
---

**Uma Managed Instance é cobrada como o modelo vCore da lição 8, no tamanho de uma instância**: vCores
por hora, armazenamento por GB reservado, backups além de uma franquia, e a licença, a não ser que o
Hybrid Benefit a tire. Não há serverless nem DTU. O que a torna uma decisão diferente é o piso: a menor
instância são vários vCores rodando o mês inteiro, onde o menor banco são uns poucos DTUs.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado.** As contas
usam o preço ilustrativo da lição 8, 0,25 USD por vCore-hora, e dizem isso.

## A forma da conta

A instância da Quitanda da seção anterior, 8 vCores no General Purpose, dá 8 × 0,25 × 730 = 1.460,00
por mês de computação a esse preço ilustrativo, antes do armazenamento, esteja um banco ocupado nela ou
vinte. Duas coisas baixam esse número, e as duas são documentadas:

- **instance pools**, que deixam várias instâncias pequenas dividirem as máquinas de um pool, para que
  uma empresa com muitas cargas pequenas não pague o piso uma vez por instância;
- **parar uma instância General Purpose**, o que para a conta de computação enquanto o armazenamento, e
  a conta dele, continuam; útil para uma instância usada no horário comercial ou para testes, e, como
  na pausa da lição 8, nada responde até ela ser ligada de novo.

**A licença é a linha que decide a maioria das mudanças.** Com `LicenseIncluded`, o preço por hora
carrega a licença do SQL Server da Microsoft; com `BasePrice`, a empresa traz licenças que já tem com
Software Assurance e paga só a computação. Uma empresa que sai de um armário de SQL Servers licenciados
em geral já pagou por essas licenças, e o Hybrid Benefit é como esse pagamento continua valendo.

## Chegando lá

Um banco num armário chega à Managed Instance por um de três caminhos, cada um documentado pela
Microsoft:

| caminho | como funciona | a virada |
|---|---|---|
| backup e restauração | `BACKUP DATABASE` no servidor antigo, o `.bak` copiado para o Blob Storage, `RESTORE ... FROM URL` na instância | o banco antigo para de aceitar escritas durante toda a cópia e a restauração |
| Log Replay Service | backups completos, diferenciais e de log deixados num contêiner de blobs, reaplicados na instância conforme chegam | uma curta, depois que o último backup de log é aplicado |
| o Managed Instance link | um grupo de disponibilidade distribuído do SQL Server antigo para a instância, replicando continuamente | uma curta, e o link pode ser mantido como cópia para leitura no Azure |

**Os três levam o banco com os jobs, os logins e os nomes de três partes funcionando**, que é o motivo
de escolher uma instância: a aplicação muda de lugar, e nada nela é reescrito naquele dia. O Azure
Database Migration Service embrulha os dois primeiros num processo guiado. A cópia para um contêiner de
blobs é o passo que este curso já praticou, na lição 2.

## Quando é a resposta

**A Managed Instance é a resposta quando o banco depende da sua instância**: jobs no SQL Agent,
consultas entre bancos, linked servers, CLR, Service Broker, Database Mail, ou a aplicação de um
fornecedor que foi certificada contra o SQL Server e mais nada. **O Azure SQL Database é a resposta
para trabalho novo**, e para bancos que não usam nada disso, porque o piso dele é mais baixo, ele escala
um banco por vez e oferece serverless e pools. **O SQL Server numa máquina virtual sua** é o que sobra
quando nem uma instância basta: um recurso que a Managed Instance não tem, ou a necessidade de chegar ao
sistema operacional, ao preço de voltar a aplicar os patches você mesmo.

O banco de pedidos da Quitanda usava o SQL Agent para os totais noturnos e um nome de três partes para
a tela de atendimento. Os dois podiam ser reescritos, o job como elastic job e as entregas levadas para
um banco só, e o banco único dela sairia então mais barato no Azure SQL Database. Se essa reescrita vale
a pena é a decisão, e o preço dela é a conta da lição 8 contra esta.
