---
title: Installing a schema registry
version: 1
---

A schema registry is a small web service with a database behind it. Producers ask it for an id
when they write, consumers ask it for a schema when they read, and the schemas themselves are
stored in it, numbered. **Kafka does not ship one**, and nothing in the broker knows a registry
exists: as far as Kafka is concerned, a message is still a key and a value of bytes.

The best-known registry is Confluent's, and its source licence does not allow it to be offered
as a service by anybody but Confluent. This course uses **Apicurio Registry**, an Apache-licensed
registry from Red Hat that also answers on Confluent's API, so the Python client you already
have talks to it unchanged. Version 3.3.3 is one archive on Maven Central, the repository Java
libraries are published to, and it runs on the Java you installed in lesson 1.

## Getting it

The archive is 159 MB, with a checksum beside it:

```sh
cd ~
curl -fsSLO https://repo.maven.apache.org/maven2/io/apicurio/apicurio-registry-app/3.3.3/apicurio-registry-app-3.3.3-all.tar.gz
curl -fsSLO https://repo.maven.apache.org/maven2/io/apicurio/apicurio-registry-app/3.3.3/apicurio-registry-app-3.3.3-all.tar.gz.sha512
```

Compare the two, as you did with Kafka:

```
ubuntu@stream:~$ sha512sum apicurio-registry-app-3.3.3-all.tar.gz | cut -d" " -f1
```

The archive has no directory of its own at the top, so make one and unpack into it. Then install
the Avro side of the Python client. `confluent-kafka[avro]` brings the registry client and the
Avro serialiser; the rest of the line pins what it pulls in, so your versions are the ones these
transcripts were made with:

```sh
mkdir -p ~/apicurio
tar -xzf apicurio-registry-app-3.3.3-all.tar.gz -C ~/apicurio
pip install "confluent-kafka[avro]==2.16.0" fastavro==1.13.1 avro==1.12.2 requests==2.34.2 httpx2==2.13.1 authlib==1.8.0 attrs==26.1.0 cachetools==7.2.1
```

## Starting it

The registry is one Java program, `quarkus-run.jar`, and with no configuration it keeps its
schemas **in memory** and listens on port 8080. Start it in the background with its output going
to a file, and wait for it to answer:

```
ubuntu@stream:~/work$ nohup java -jar ~/apicurio/quarkus-run.jar > ~/apicurio/registry.log 2>&1 &
```

The `until` line asks for the list of subjects once a second until something answers. `[]` is
an empty list: the registry is up and holds nothing yet. Your shell also prints a job number and
a process id when you start something with `&`, which are not in the transcript and differ every
time.

**In memory means that stopping it forgets every schema.** That is the right trade for a lab,
where a lesson registers what it needs, and the wrong one anywhere else: a registry that loses
its schemas has turned every message written with them into bytes nobody can read. A real
installation points it at a database, PostgreSQL or Kafka itself, with one setting each. It also
puts it behind authentication, because a registry anybody can write to is a way to change what
every consumer believes a message says.

Two things to know before the next section:

- **The address.** Apicurio answers Confluent's API under `/apis/ccompat/v7`, so every client in
  this lesson is given `http://localhost:8080/apis/ccompat/v7` where Confluent's documentation
  would write `http://localhost:8081`.
- **It does not start on its own**, like the cluster. After a restart of the virtual machine run
  the `nohup` line again; the schemas will be gone, and the lesson's commands register them
  again.

If `until` loops for more than a minute, the reason is at the end of `~/apicurio/registry.log`.
The usual one is another program on port 8080, which `ss -ltnp | grep 8080` names.
