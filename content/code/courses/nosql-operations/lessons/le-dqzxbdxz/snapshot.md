---
title: A physical backup, by copying the files
version: 1
---

The other approach skips the server's query engine and copies what it keeps on disk: the data
files, the index files, the journal, the oplog, all of `/data/db`. **The difficulty is that a
running server is changing those files while you copy them.** A copy taken file by file, over a
few seconds, can hold one file from before a write and another from after it, and the server that
later opens that copy finds a state that never existed.

A filesystem or cloud-disk snapshot solves that by freezing every file at the same instant. A
`tar` of a Docker volume is not such a snapshot, so the server has to hold still while it runs.
`db.fsyncLock()`, which lesson 9 borrowed to freeze two secondaries, is that: it flushes everything
to disk and blocks every write until `db.fsyncUnlock()`.

## Lock, copy, unlock

The copy is made by a **throwaway container** of the same image. `--rm` deletes it when `tar`
exits. The first `-v` mounts the server's volume, and the second mounts your current directory as
`/backup`, so the archive lands on the VM:

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

The server refused writes for the whole of those 2.713 seconds, and **that is the price of this
method on a server with one member**. On a replica set the lock goes on a secondary instead, the
primary keeps working, and the secondary catches up from the oplog once it is unlocked.

`mongo-data.tar.gz` is 4,687,568 bytes, nearly six times the dump's 810,350, because it carries
the index files, the oplog and the journal as well as the documents. It is owned by `root`, because
the throwaway container wrote it as root.

## Restoring a snapshot is starting a server on it

There is no restore program for files. Unpack them into a fresh volume and start a `mongod` whose
data directory is that volume:

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

The copy answered 2.212 seconds after it started, with every collection and every index already
there. Nothing was rebuilt: the indexes are files, and the files were copied.

**Two things about that copy are deliberate.** It was started with no `--replSet`, because its
replica-set configuration names `mongo:27017` as the only member, and a second server claiming that
name would not find itself in it. The last line is the server saying so in its log: the files
belong to a replica set, and it was started as a standalone server to read them. And it holds 500
payments, because the snapshot was taken after the writes of the previous section had finished.
