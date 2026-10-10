---
title: Installing PostgreSQL, Kafka Connect and Debezium
version: 1
---

DRAFT

```sh
sudo apt-get install -y postgresql
echo "wal_level = logical" | sudo tee /etc/postgresql/16/main/conf.d/cdc.conf
```

```
$ sudo systemctl restart postgresql
```

```sh
cd ~
curl -fsSLO https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/3.7.0.Final/debezium-connector-postgres-3.7.0.Final-plugin.tar.gz
curl -fsSLO https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/3.7.0.Final/debezium-connector-postgres-3.7.0.Final-plugin.tar.gz.sha512
```

```sh
mkdir -p ~/connect-plugins
tar -xzf debezium-connector-postgres-3.7.0.Final-plugin.tar.gz -C ~/connect-plugins
```
