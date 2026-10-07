---
title: Building the machine
version: 1
---

These are the commands, in order. Run them on the fresh Ubuntu 24.04 machine from the last
section, as a user who can use `sudo`.

**1. The packages.** PostgreSQL 16 with the `pgaudit` extension, OpenSSL for lesson 3's
certificates, `cryptsetup` for its encrypted volume, Python for the data generator and the small
programs later lessons write, and `curl` for lesson 4's download:

```sh
sudo apt-get update
sudo apt-get install -y postgresql-16 postgresql-16-pgaudit openssl cryptsetup python3 curl
```

Installing PostgreSQL creates a cluster called `main` on port 5432. The lab leaves it alone and
builds its own beside it, so nothing you do in this course touches a database you already had.

**2. Ana.** Every transcript is typed by Ana, Ipê's data engineer, in a directory called `gov`.
She is an administrator of this machine, as you are of yours:

```sh
sudo useradd -m -s /bin/bash ana
echo 'ana ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ana
sudo chmod 0440 /etc/sudoers.d/ana
sudo -iu ana
mkdir ~/gov && cd ~/gov
```

From here on you are Ana, and every command in the course runs in `~/gov`.

**3. The cluster.** Ubuntu's `pg_createcluster` makes a cluster with its files where Ubuntu puts
them, `/etc/postgresql/16/gov` and `/var/lib/postgresql/16/gov`. Three settings are added to its
configuration: the time zone Ipê works in, twice, so that timestamps read as they do in the
transcripts, and the `pgaudit` library. The second command opens an editor; add the four lines at
the end of the file, save and leave:

```sh
sudo pg_createcluster 16 gov --port 5433 --locale C.UTF-8
sudo nano /etc/postgresql/16/gov/postgresql.conf
```

```ini
# --- the lab ---
timezone = 'America/Sao_Paulo'
log_timezone = 'America/Sao_Paulo'
shared_preload_libraries = 'pgaudit'
```

```sh
sudo pg_ctlcluster 16 gov start
```

**4. Telling `psql` where to go.** Ubuntu's `psql` asks a small wrapper which cluster to talk to.
This line tells it `gov` and the database `ipe`, for every user:

```sh
echo '* * 16 gov ipe' | sudo tee /etc/postgresql-common/user_clusters
```

A connection by host name does not ask the wrapper, so the port has to be in Ana's environment as
well, together with the database and the time zone:

```sh
echo 'export PGPORT=5433 PGDATABASE=ipe TZ=America/Sao_Paulo' >> ~/.bashrc
source ~/.bashrc
```

**5. Two names for the machine.** Lesson 3 checks a certificate against a name rather than an
address, so the lab maps two names to the machine itself:

```sh
echo '127.0.0.1 db.ipe.example bao.ipe.example' | sudo tee -a /etc/hosts
```

That is the machine. Asked what it has, it answers:

```
ana@lab:~/gov$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@lab:~/gov$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  gov     5433 online postgres /var/lib/postgresql/16/gov  /var/log/postgresql/postgresql-16-gov.log
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

`gov` is online on 5433. On the machine these transcripts were recorded on, `main` was stopped; on
yours it is probably online, and it does not matter either way. The database `ipe` does not exist
yet. The next section creates it and fills it.
