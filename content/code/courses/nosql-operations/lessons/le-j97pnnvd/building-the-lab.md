---
title: Building the lab
version: 1
---

```sh
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name redis --network nosql redis:7.4
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```
