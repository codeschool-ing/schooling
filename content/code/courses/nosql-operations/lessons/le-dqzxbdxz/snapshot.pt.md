---
title: Um backup físico, copiando os arquivos
version: 1
---

A outra abordagem pula o mecanismo de consultas do servidor e copia o que ele guarda em disco: os
arquivos de dados, os arquivos de índice, o journal, o oplog, todo o `/data/db`. **A dificuldade é
que um servidor rodando está mudando esses arquivos enquanto você os copia.** Uma cópia feita
arquivo por arquivo, ao longo de alguns segundos, pode ter um arquivo de antes de uma escrita e
outro de depois dela, e o servidor que mais tarde abrir essa cópia encontra um estado que nunca
existiu.

Um snapshot de sistema de arquivos ou de disco na nuvem resolve isso congelando todos os arquivos
no mesmo instante. Um `tar` de um volume do Docker não é um snapshot assim, então o servidor precisa
ficar parado enquanto ele roda. O `db.fsyncLock()`, que a aula 9 emprestou para congelar dois
secundários, é isso: descarrega tudo no disco e bloqueia toda escrita até o `db.fsyncUnlock()`.

## Travar, copiar, destravar

A cópia é feita por um **contêiner descartável** da mesma imagem. `--rm` o apaga quando o `tar`
termina. O primeiro `-v` monta o volume do servidor, e o segundo monta o seu diretório atual como
`/backup`, para que o arquivo caia na VM:

```
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ time docker run --rm -v mongo-data:/data/db -v "$PWD":/backup mongo:8.0 tar -czf /backup/mongo-data.tar.gz -C /data/db .

real	0m2.713s
user	0m0.015s
sys	0m0.030s
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ ls -l mongo-data.tar.gz
-rw-r--r-- 1 root root 4687568 Oct 10 17:15 mongo-data.tar.gz
```

O servidor recusou escritas durante todos esses 2,713 segundos, e **esse é o preço deste método
num servidor de um membro só**. Num replica set a trava vai num secundário, o primário continua
trabalhando, e o secundário se atualiza pelo oplog quando é destravado.

O `mongo-data.tar.gz` tem 4.687.568 bytes, quase seis vezes os 810.350 do dump, porque carrega os
arquivos de índice, o oplog e o journal além dos documentos. O dono dele é `root`, porque o
contêiner descartável o gravou como root.

## Restaurar um snapshot é iniciar um servidor sobre ele

Não existe programa de restore para arquivos. Desempacote-os num volume novo e inicie um `mongod`
cujo diretório de dados seja esse volume:

```
ana@vm:~$ docker volume create mongo-copy
mongo-copy
ana@vm:~$ docker run --rm -v mongo-copy:/data/db -v "$PWD":/backup mongo:8.0 tar -xzf /backup/mongo-data.tar.gz -C /data/db
ana@vm:~$ docker run -d --name mongo-copy --network nosql -v mongo-copy:/data/db mongo:8.0
3a642fb3c0c0d9f7b4ff7a0049f13011f5cbc91067d6ecbef4b143ba919f68e3
ana@vm:~$ time sh -c 'until docker exec mongo-copy mongosh --quiet --eval "db.runCommand({ ping: 1 })" >/dev/null 2>&1; do sleep 1; done'

real	0m2.212s
user	0m0.063s
sys	0m0.031s
ana@vm:~$ docker exec mongo-copy mongosh --quiet shop --eval 'for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(" "))'
customers 5 _id_ email_1
orders 100000 _id_ customer_1_placedAt_-1 sku_1
payments 500 _id_
products 4 _id_
ana@vm:~$ docker logs mongo-copy 2>&1 | grep -o 'Document(s) exist in .system.replset., but started without --replSet'
Document(s) exist in 'system.replset', but started without --replSet
```

A cópia respondeu 2,212 segundos depois de iniciar, com todas as coleções e todos os índices já lá.
Nada foi reconstruído: os índices são arquivos, e os arquivos foram copiados.

**Duas coisas nessa cópia são de propósito.** Ela foi iniciada sem `--replSet`, porque a
configuração de replica set dela cita `mongo:27017` como único membro, e um segundo servidor que
reivindicasse esse nome não se encontraria nela. A última linha é o servidor dizendo isso no log: os
arquivos pertencem a um replica set, e ele foi iniciado como servidor avulso para lê-los. E ela tem
500 pagamentos, porque o snapshot foi tirado depois de as escritas da seção anterior terminarem.
