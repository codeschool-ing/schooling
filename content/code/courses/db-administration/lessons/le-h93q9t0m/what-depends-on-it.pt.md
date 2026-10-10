---
title: O que depende do log
version: 1
---

É fácil arquivar o WAL na cabeça como uma rede de segurança para quedas, uma área de rascunho de que
o servidor precisa e você não. **O log é o único registro completo de toda alteração que o cluster
já fez**, em ordem, e três outras coisas pelas quais um DBA responde são construídas lendo esse log
de novo em outro lugar.

| leitor | o que faz com o log | onde é ensinado |
| --- | --- | --- |
| recuperação de queda | refaz os registros escritos desde o último checkpoint, no mesmo servidor, na subida | lição 8 |
| uma réplica | recebe os registros à medida que são escritos e os refaz para sempre, continuando uma cópia do primário | db-reliability, lições 11 a 13 |
| arquivamento e recuperação para um ponto no tempo | guarda uma cópia de cada segmento terminado, para que um backup mais os segmentos depois dele possam ser refeitos até um momento escolhido | db-reliability, lições 1 a 10 |
| decodificação lógica | transforma os registros de volta em alterações de linha (esta linha inserida, aquela atualizada) para a replicação lógica e ferramentas de captura de mudanças | db-reliability, lição 14 |

São um mecanismo usado de quatro jeitos. **Uma réplica é um servidor em recuperação de queda
permanente**, refazendo um log que não para de chegar. Uma restauração para a terça passada às 14h05
é uma recuperação de queda que começa de uma cópia mais antiga dos arquivos e para num registro
escolhido. Entender o primeiro caso, que a lição 8 faz provocando um, é quase todo o caminho para
entender os outros três.

## Quanto o log registra

O que os registros carregam é escolhido por uma configuração, `wal_level`, e outras duas dizem se
alguém está lendo:

```
shop=# SELECT name, setting FROM pg_settings
shop-#  WHERE name IN ('wal_level', 'archive_mode', 'max_wal_senders');
      name       | setting 
-----------------+---------
 archive_mode    | off
 max_wal_senders | 10
 wal_level       | replica
(3 rows)
```

O `wal_level` tem três valores. `replica`, o padrão, registra o bastante para recuperação de queda,
réplicas e arquivos. `logical` acrescenta o que a decodificação precisa para reconstruir linhas, ao
custo de um pouco mais de log. `minimal` registra só o que a recuperação de queda precisa, o que
deixa algumas operações em massa pularem o log por completo, e em troca nenhuma réplica e nenhum
arquivo podem ser construídos a partir dele. **Mudar o `wal_level` exige reiniciar**, então ele é
escolhido quando o servidor é montado e não no dia em que alguém quer uma réplica, e o padrão é o
lugar certo para começar.

`archive_mode` está `off`: nenhum segmento está sendo copiado para lugar nenhum, então este servidor
ainda não tem recuperação para um ponto no tempo. `max_wal_senders` é quantas réplicas ou
ferramentas de backup podem receber o log ao mesmo tempo, e 10 é espaço que ninguém está usando.

## A única coisa que nunca se faz

Quando um disco enche, o `pg_wal` muitas vezes é o maior diretório nele, cheio de arquivos com nomes
sem sentido, e apagar os mais antigos parece uma saída. **Nunca apague nada em `pg_wal` à mão.**
Esses registros são a única cópia de alterações que talvez ainda não tenham chegado aos arquivos das
tabelas, e o servidor os lê na próxima subida. Apague o arquivo errado e um cluster que teria se
recuperado sozinho vai se recusar a subir, ou vai subir com dados silenciosamente inconsistentes.

O servidor remove segmentos sozinho quando nada mais precisa deles. A próxima seção é sobre quando
isso acontece, e o que pode impedir.
