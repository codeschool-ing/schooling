---
title: A mesma máquina com quatro nomes
version: 1
---

É fácil pensar que trocar de motor é aprender um ofício novo. Os produtos não se parecem: o SQL
Server tem um estúdio gráfico, o Oracle tem um vocabulário inteiro só dele, o MySQL e o PostgreSQL se
configuram com arquivos de texto. Por baixo, **todo servidor relacional é feito das mesmas seis
partes**, e cuidar de um é cuidar dessas seis.

| parte | o que é | PostgreSQL | MySQL (InnoDB) | SQL Server | Oracle |
|---|---|---|---|---|---|
| o servidor | o programa dono dos arquivos | `postgres`, um processo por conexão | `mysqld`, uma thread por conexão | `sqlservr`, threads | um conjunto de processos de fundo |
| os arquivos de dados | onde ficam as linhas, em páginas | o diretório de dados, páginas de 8 kB | o diretório de dados, páginas de 16 kB | arquivos `.mdf` e `.ndf`, páginas de 8 kB | datafiles em tablespaces, blocos de 8 kB por padrão |
| o log de mudanças | toda mudança, escrita antes dos dados | write-ahead log, `pg_wal` | redo log | transaction log, `.ldf` | online redo logs |
| o cache | páginas guardadas na memória | shared buffers | buffer pool | buffer pool | buffer cache, parte da SGA |
| o log de erros | o que o servidor diz de si mesmo | `/var/log/postgresql` no Ubuntu | `error.log` | `ERRORLOG` | o alert log |
| quem pode o quê | contas e privilégios | papéis | usuários, e papéis desde a 8.0 | logins no servidor, usuários em cada banco | usuários, que também são esquemas, e papéis |

Leia a tabela por linhas, não por colunas. **O log de mudanças** é o caso mais claro: os quatro
escrevem uma mudança primeiro num log sequencial e depois nos arquivos de dados, porque uma escrita
sequencial é rápida e uma queda pode ser reparada reaplicando o log. A lição 7 explica essa ideia
para o PostgreSQL, e cada palavra dela vale para o redo log do InnoDB e para o transaction log do SQL
Server. Os nomes mudam; o raciocínio, os modos de falha e os ajustes que trocam segurança por
velocidade são os mesmos.

Duas diferenças são reais e vale levá-las consigo. **O PostgreSQL inicia um processo para cada
conexão** onde os outros iniciam uma thread, e é por isso que a lição 10 diz o que diz sobre o número
máximo de conexões, e que o conselho para o MySQL não é o mesmo número. E **o MySQL escreve um
segundo log**, o binary log, para replicação e recuperação, ao lado do redo log do InnoDB; os outros
três usam o log de mudanças para as duas coisas.

Todo o resto deste curso — o que é um parâmetro de configuração, por que uma tabela incha, para que
serve uma estatística, como um esquema muda sem indisponibilidade — tem equivalente em cada um dos
quatro. O curso ensina no PostgreSQL e diz onde outro motor é notoriamente diferente.
