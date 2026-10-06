---
title: Two containers by hand
version: 1
---

**`shelf` with a real database is two containers that have to find each other, start in the right
order and keep their data.** Each piece is something earlier lessons did; together, by hand, they
look like this:

```
ana@vm:~/shelf$ docker network create shelfnet
3ca58f4d539bce1ca0ce6d315e92dbf8cc658669448aa646665d11bf03717415
ana@vm:~/shelf$ docker run -d --name db --network shelfnet -e POSTGRES_USER=shelf -e POSTGRES_PASSWORD=lab-only-secret -e POSTGRES_DB=shelf postgres:17
b9a88b7db427e3fe1d748c9aecdc41539160285ad52410ac719e6ee95e1538b1
ana@vm:~/shelf$ docker run -d --name web --network shelfnet -p 127.0.0.1:8080:8080 -e DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf shelf:1.5.0
5707d575fe31820afea04956e985beceea6c8efd0065bb40661074a3ac414f52
ana@vm:~/shelf$ docker logs web
2026/10/06 18:12:12 database: failed to connect to `user=shelf database=shelf`:
	172.18.0.2:5432 (db): dial error: dial tcp 172.18.0.2:5432: connect: connection refused
	172.18.0.2:5432 (db): dial error: dial tcp 172.18.0.2:5432: connect: connection refused
ana@vm:~/shelf$ docker start web
web
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
```

Three commands, and the third failed. **`connection refused`: `shelf` started while Postgres was still
initialising its database**, and lesson 17 showed that `shelf` exits when it cannot reach its
database. A few seconds later, `docker start web` worked and the catalogue came from Postgres, which
created and filled the table on first use.

The first command made a **network**, `shelfnet`, and the two containers joined it. On a network that
somebody created, containers find each other by name: that is why `db` in `DATABASE_URL` works.
Lesson 23 explains how. Note what is missing, too: no `-p` on the database, so nothing outside the
network reaches it.

## What is wrong with doing it this way

- **The order is luck.** Waiting a few seconds worked on Ana's machine today. On a slower disk, or a
  database restoring a backup, it will not.
- **The setup lives in someone's shell history.** The next person to run `shelf` has to find those
  three commands, with their flags, and type them the same way.
- **The password is on the command line**, in the history file and in the process list, which
  lesson 17 warned about.
- **Taking it down is four more commands**, and forgetting one leaves a network or a volume behind.

**Docker Compose is the fix for all four**: the containers, the network, the volumes and the order
written in one file, kept in the repository next to the Dockerfile, and one command to bring it all
up or down.
