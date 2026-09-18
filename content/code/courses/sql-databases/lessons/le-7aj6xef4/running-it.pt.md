---
title: O que de fato decide em produção
version: 1
---

Tudo até aqui foi sobre SQL. Numa empresa, um motor raramente é escolhido por SQL. Ele é escolhido
pelo que acontece às três da manhã, e as perguntas são as mesmas quatro seja qual for o motor na
resposta.

## Onde mora a segunda cópia

Um servidor de banco único é um ponto único de falha, então os três servidores conseguem manter uma
cópia em outro lugar. O que muda é a forma.

**O PostgreSQL** entrega **replicação por streaming**: um primário manda seu log de escrita
antecipada para uma ou mais réplicas, que o reproduzem. Réplicas são somente-leitura e podem servir
leituras; o failover — promover uma réplica quando o primário morre — **não** vem embutido, e é
feito com uma ferramenta externa como Patroni ou repmgr. Essa lacuna surpreende as pessoas e vale
saber antes de um incidente, não durante um.

**MySQL e MariaDB** entregam uma replicação mais antiga que a do PostgreSQL e de forma diferente: o
primário escreve um log binário de instruções ou de mudanças de linha e as réplicas o aplicam.
Sempre foi fácil de montar e historicamente foi fácil de deixar derivar, porque uma réplica pode
atrasar ou divergir sem que nada pare. O MySQL acrescenta Group Replication e o MariaDB acrescenta
Galera, os dois multi-primários e os dois mudando o que sua aplicação pode supor.

**O SQLite** não tem nada disso, porque não há servidor de onde replicar. O arquivo é copiado, ou
um projeto à parte como o Litestream leva o WAL para algum lugar. Essa é uma resposta de verdade
para algumas implantações e não é a mesma resposta.

## O que um backup significa

Os três servidores têm um dump lógico — `pg_dump`, `mysqldump` — que produz texto SQL e é lento de
restaurar mas é portátil e legível. Os três têm um backup físico dos arquivos de dados —
`pg_basebackup`, Percona XtraBackup — que é rápido e é preso à versão e à plataforma.

Duas coisas são verdadeiras em todo motor e valem mais que a escolha entre eles. **Recuperação a um
ponto no tempo** precisa que o log de escrita antecipada ou o log binário seja guardado junto do
backup de base, para que a recuperação possa avançar até um momento escolhido; sem isso um backup
te devolve à hora em que foi tirado. E **um backup que ninguém restaurou não é um backup** — é um
arquivo com um nome esperançoso. Restaurar um num servidor de rascunho, com regularidade, é o único
teste dele que existe.

O backup do SQLite é copiar o arquivo, o que não pode ser feito com `cp` enquanto há um escritor
ativo. `sqlite3 shop.db ".backup out.db"` ou a API de backup tira uma cópia consistente de um banco
vivo, e esse é o procedimento inteiro.

## O que acontece numa atualização

**O PostgreSQL** muda o formato em disco entre versões maiores, então ir da 15 para a 16 é
`pg_upgrade` — um passo com indisponibilidade, ou uma dança de replicação lógica para evitá-la.
Versões menores são um restart. O projeto mantém cada versão maior por cinco anos, e há um modo de
falha conhecido: rodar uma delas dois anos depois do fim porque a atualização nunca foi agendada.

**MySQL e MariaDB** atualizam no lugar na maior parte das vezes, com o `mysql_upgrade` ou seu
sucessor arrumando as tabelas de sistema. Versões de suporte longo são mantidas por cerca de cinco
anos.

**O SQLite** mantém o formato de arquivo compatível para trás desde 2004 e pretende manter assim
até 2050. Atualizar é trocar uma biblioteca.

## Quem está de plantão, e onde isso roda

Esta é a pergunta que decide na prática.

**Um serviço gerenciado remove a maior parte do que está acima.** Amazon RDS e Aurora, Google Cloud
SQL e AlloyDB, Azure Database, e uma longa lista de provedores menores rodam PostgreSQL e MySQL —
MariaDB em menos deles, e em alguns que o oferecem o suporte é mais fino. Se a empresa não tem
administrador de banco, o motor com uma oferta gerenciada na nuvem que você já paga é uma resposta
muito melhor que o motor que pontua melhor nesta aula.

**As pessoas que você tem importam mais que o motor.** Um time que operou MySQL por dez anos vai
rodar um sistema MySQL melhor do que um PostgreSQL sobre o qual leu. Isso não é um argumento contra
mudar algum dia; é um argumento para contar o custo da mudança honestamente, em pessoas e não em
recursos.

**E a resposta muitas vezes é "nenhum deles ainda".** Para uma ferramenta, um protótipo, uma
aplicação de desktop ou um serviço com um processo, o SQLite não precisa de servidor, nem de rotina
de backup, nem de plano de atualização, nem de ninguém de plantão — e a seção sobre ele diz
exatamente quando isso deixa de ser verdade.

## A parte que não muda

A aula 10 disse: ache a consulta com um número preso nela, leia o plano, meça, mude uma coisa, meça
de novo. Todo motor desta lista guarda os contadores que respondem a primeira pergunta e imprime um
plano que responde a segunda. **O vocabulário muda e o método não** — que é também a resposta à
pergunta de que trata a próxima seção.
