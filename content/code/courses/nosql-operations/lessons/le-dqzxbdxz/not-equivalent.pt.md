---
title: Por que os dois não são equivalentes
version: 1
---

As duas cópias restauraram os mesmos 100.000 pedidos, então é tentador tratá-las como dois formatos
de um mesmo backup e ficar com o menor. **Elas respondem a perguntas diferentes.** Um dump é uma
lista de documentos e as instruções para reconstruir todo o resto; um snapshot é o próprio estado do
servidor, congelado. Cada um guarda algo que o outro reconstrói ou perde.

## O que cada um guarda

| | `mongodump --oplog` | snapshot de arquivos |
|---|---|---|
| o que copia | documentos, mais as definições dos índices | todo arquivo: documentos, índices, oplog, journal |
| tamanho nesta aula | 810.350 bytes, comprimido | 4.687.568 bytes, comprimido |
| tempo para fazer | 0,463 s | 2,713 s, com escritas bloqueadas o tempo todo |
| índices no restore | **construídos de novo** a partir dos documentos | já estão lá |
| restore | `mongorestore` em qualquer servidor rodando | iniciar um `mongod` sobre os arquivos |
| momento que representa | o fim do dump, depois de reaplicar o oplog | o instante da trava |
| restaura uma coleção só | sim, `--nsInclude` | não, o diretório de dados inteiro ou nada |
| versão para a qual pode ir | outra versão do MongoDB, dentro do suporte das ferramentas | a mesma versão, com o mesmo mecanismo de armazenamento |

As duas últimas linhas não foram executadas nesta aula. Elas decorrem do que cada cópia é:
documentos podem ser inseridos em qualquer servidor que os aceite, e arquivos de dados só podem ser
abertos por um servidor que lê aquele formato.

## Tamanho e tempo crescem de jeitos diferentes

Com 100.000 pedidos todo número aqui é um ou dois segundos, e no laboratório o restore do dump levou
1,924 segundo enquanto o servidor iniciado sobre o snapshot respondeu depois de 2,212. **Os dois
escalam de jeitos diferentes.** A cópia e o restore de um snapshot são limitados pela velocidade com
que o disco move bytes, e iniciar o servidor custa o mesmo em qualquer tamanho. Um restore de dump
insere cada documento de novo e depois constrói cada índice do zero, trabalho proporcional aos dados
vezes o número de índices. Numa coleção de centenas de gigabytes com meia dúzia de índices, essa
diferença é a diferença entre minutos e um dia de trabalho, e é o número contra o qual uma promessa
de tempo de recuperação precisa ser medida, numa cópia dos dados reais.

## O cluster shardeado, onde um dump deixa de ser um momento

O cluster da aula 10 alarga a distância. **O `mongodump` pelo `mongos` copia cada shard no seu
próprio ritmo, e o `--oplog` não está disponível ali**, porque não existe um oplog único para ler:
cada shard tem o seu. O resultado tem todos os documentos, e nenhum momento único em que todos
fossem verdadeiros ao mesmo tempo. Um pedido gravado no `shard2` durante o dump pode estar nele
enquanto o pagamento desse pedido, gravado um milissegundo depois no `shard1`, não está.

Isso não foi executado nesta aula; decorre de como o cluster é montado. Um backup consistente de um
cluster shardeado precisa de todos os shards e do config server capturados no mesmo ponto. Os
snapshots coordenados fazem isso, e os serviços de backup das ofertas gerenciadas também; a aula 21
volta ao que muda quando outra pessoa opera o cluster.
