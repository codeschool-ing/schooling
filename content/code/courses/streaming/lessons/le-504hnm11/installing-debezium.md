---
title: Installing PostgreSQL, Kafka Connect and Debezium
version: 1
---

Three things are needed, and only two of them are new. **PostgreSQL** is the database; it comes
from Ubuntu's archive. **Kafka Connect** is already on your machine: it is a program that ships
inside Kafka, in `~/kafka/bin`, whose job is to run connectors that move data between Kafka and
other systems. **Debezium's PostgreSQL connector** is one of those connectors, a directory of
Java libraries that Connect loads when it starts.

## PostgreSQL, with a log that carries rows

Install the server, and tell it to write logical WAL. Ubuntu's PostgreSQL reads every file in
`conf.d` beside its main configuration, so the setting goes into a file of its own, where it is
easy to find and to remove:

```sh
sudo apt-get install -y postgresql
echo "wal_level = logical" | sudo tee /etc/postgresql/16/main/conf.d/cdc.conf
```

Ubuntu 24.04's archive has PostgreSQL 16, and on a virtual machine the install creates a cluster
called `main` and starts it straight away, under systemd. `wal_level` is only read at start-up, so
restart it:

```
$ sudo systemctl restart postgresql
```

**That command was not run for this course.** The machine the transcripts were recorded on has no
systemd, so PostgreSQL there was started and restarted with `pg_ctlcluster 16 main restart`, which
is what the systemd unit runs underneath. On your virtual machine, use `systemctl`, and PostgreSQL
also starts by itself every time the machine boots — unlike the Kafka cluster, which you start with
`cluster.sh`. Then ask the server what it is running with:

```
ubuntu@stream:~$ sudo -u postgres psql -c "SHOW wal_level"
```

`sudo -u postgres` runs `psql` as the operating-system user `postgres`, which the server trusts as
its administrator without a password. That is the only thing it is used for here.

## Debezium, as a Connect plugin

Debezium publishes each connector on Maven Central as a `tar.gz` with a checksum beside it. Version
3.7.0.Final is the one this course was recorded with:

```sh
cd ~
curl -fsSLO https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/3.7.0.Final/debezium-connector-postgres-3.7.0.Final-plugin.tar.gz
curl -fsSLO https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/3.7.0.Final/debezium-connector-postgres-3.7.0.Final-plugin.tar.gz.sha512
```

Check it the way lesson 1 checked Kafka. Maven's `.sha512` file holds the hash alone, with no file
name and no line ending, so the second command adds one:

```
ubuntu@stream:~$ sha512sum debezium-connector-postgres-3.7.0.Final-plugin.tar.gz | cut -d" " -f1
```

Then unpack it into a directory that will hold Connect's plugins. **Connect loads every plugin
under the directories in its `plugin.path`, each in its own class loader**, so two connectors that
bring different versions of the same library do not trip over each other:

```sh
mkdir -p ~/connect-plugins
tar -xzf debezium-connector-postgres-3.7.0.Final-plugin.tar.gz -C ~/connect-plugins
```

```
ubuntu@stream:~$ ls ~/connect-plugins/debezium-connector-postgres/*.jar | xargs -n1 basename
```

The connector itself is `debezium-connector-postgres-3.7.0.Final.jar`; the rest are Debezium's own
libraries and PostgreSQL's JDBC driver, which the connector uses for everything except the
replication stream. Nothing has been started yet. The next section gives Connect its two
configuration files and runs it.
