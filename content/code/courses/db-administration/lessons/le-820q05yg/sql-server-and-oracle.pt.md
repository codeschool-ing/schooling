---
title: SQL Server e Oracle, da cadeira de um administrador de PostgreSQL
version: 1
---

**Nada nesta seção foi rodado para o curso.** Os dois são produtos comerciais com licenças que os
tornam incômodos numa máquina de prática, e os dois existem sobretudo dentro de empresas que já os
rodam. O que segue é o que um administrador que conhece o PostgreSQL precisa reconhecer no primeiro
dia diante de um deles.

## SQL Server

O motor da Microsoft, no Windows durante a maior parte da vida e no Linux desde 2017. A administração
dele acontece sobretudo no **SQL Server Management Studio**, uma ferramenta gráfica, e em T-SQL, o
dialeto de SQL dele — e muito do que o PostgreSQL põe num arquivo de texto é um ajuste do servidor
mudado com `sp_configure` ou com um clique.

O que corresponde diretamente a este curso: o **transaction log** é o write-ahead log, e um log que
cresce até encher o disco é a versão do SQL Server do problema da lição 7. O **recovery model**
(`SIMPLE` ou `FULL`) decide se esse log é guardado para restauração a um ponto no tempo, a decisão que
o PostgreSQL toma com o arquivamento do WAL. As **estatísticas** envelhecem exatamente como a lição 16
descreve, e a **fragmentação de índice** é o bloat da lição 15 com outro nome. A separação entre login
e user é a única coisa sem equivalente no PostgreSQL: um login entra na instância, e um user em cada
banco decide o que ele pode tocar ali.

## Oracle

O mais antigo dos quatro como produto comercial, e o de vocabulário maior. Uma **instância** Oracle é
a memória e os processos; o **banco** são os arquivos; os dois têm nomes separados porque um pode
existir sem o outro enquanto o servidor sobe. A memória é a **SGA**, compartilhada por todos, e a
**PGA**, privada de cada sessão — a mesma divisão que a lição 6 faz entre shared buffers e memória de
trabalho.

O Oracle guarda o **undo** num tablespace próprio e lê dele as versões antigas das linhas, onde o
PostgreSQL guarda as versões antigas na própria tabela até o vacuum removê-las. Essa única diferença
de projeto é o motivo de o Oracle não ter autovacuum e o PostgreSQL ter as lições 14 e 15, e de o
Oracle ter o erro "snapshot too old" que o PostgreSQL não tem. A administração é feita no
**SQL\*Plus** ou no **SQL Developer**, e boa parte dela pelo **RMAN**, a ferramenta de backup do
Oracle.

## O que se leva, e o que não

Leva-se: as seis partes da primeira seção, o hábito de ler o log antes de qualquer coisa, a lógica
dos privilégios e do privilégio mínimo, os motivos pelos quais as estatísticas importam e o perigo de
uma mudança de esquema numa tabela grande. **Não se leva**: caminhos de arquivos, nomes de
parâmetros, as ferramentas, e o significado exato de `database`, `schema` e `user`. A lição 13 de
`sql-databases` diz mais sobre onde o Oracle é usado e por que as empresas ficam nele; a lição 21
deste curso é sobre o dia em que alguém decide mover um banco de um motor para outro.
