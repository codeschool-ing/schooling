---
title: localhost, host e none
version: 1
---

**Dentro de um container, `localhost` é o container.** Essa frase explica a pergunta de rede mais comum
sobre o Docker, e dois modos de rede são as exceções que a confirmam.

## `localhost` não é a máquina

O `shelf` roda no `127.0.0.1:8080` do host, publicado como a aula 17 recomenda. O próprio `curl` da Ana
o alcança. De dentro de um container:

```
ana@vm:~$ docker run -d --name host-shelf -p 127.0.0.1:8080:8080 shelf:1.0.0
2f7c8145907e9578672b080aaafea667ce463db0022be1acb480128f29cca77c
ana@vm:~$ curl -s localhost:8080/version
1.0.0
ana@vm:~$ docker exec box-c wget -qO- -T 2 localhost:8080/version
wget: can't connect to remote host (127.0.0.1): Connection refused
ana@vm:~$ docker run --rm --add-host host.docker.internal:host-gateway alpine:3.22 wget -qO- -T 2 host.docker.internal:8080/version
wget: can't connect to remote host (172.17.0.1): Connection refused
ana@vm:~$ docker run --rm -p 8081:8080 -d --name pub shelf:1.0.0 >/dev/null; sleep 1; docker run --rm --add-host host.docker.internal:host-gateway alpine:3.22 wget -qO- -T 2 host.docker.internal:8081/version
1.0.0
```

Três tentativas, lidas em ordem:

1. **O `localhost` a partir do `box-c` é recusado**: ele pergunta ao loopback do próprio `box-c`, onde
   nada escuta.
2. **O `host.docker.internal`**, mapeado para `host-gateway` pelo `--add-host`, é o endereço do host
   visto da bridge, `172.17.0.1`. Ainda recusado, porque o serviço só escuta em `127.0.0.1`, que é
   exatamente o que a aula 17 fez de propósito.
3. **Um serviço publicado em todos os endereços responde** pelo mesmo nome.

Então um container que precisa alcançar um serviço no próprio host precisa de duas coisas: um nome para
o host, `host.docker.internal` com `host-gateway`, e um serviço escutando em algum lugar que a bridge
alcance. Publicar em todos os endereços faz isso e também o abre para a rede, que é o aviso da aula 17;
`-p 172.17.0.1:8081:8080` escutaria só no endereço da bridge. Essa última forma não foi executada no
laboratório. O Docker Desktop oferece o `host.docker.internal` sem a flag.

## `--network host`: nenhum namespace

```
ana@vm:~$ docker run -d --name hostnet --network host -e PORT=9090 shelf:1.0.0
61b23df2c4ef629f6bfa3368d52401df30a3ccdb0eec0ac8e90aaebb4b321553
ana@vm:~$ ss -ltn | grep -E "State|:9090"
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      4096         0.0.0.0:9090       0.0.0.0:*          
ana@vm:~$ curl -s localhost:9090/version
1.0.0
ana@vm:~$ docker inspect hostnet --format "{{json .NetworkSettings.Networks}}" | jq -c "keys"
["host"]
```

**O `shelf` escutou direto no `0.0.0.0:9090` do host, sem `-p`**, porque com `host` o container fica com
o namespace de rede do host: as interfaces, as portas e o `localhost` dele. É o caminho mais rápido, já
que não há bridge nem tradução de endereço, e abre mão de todas as paredes que esta aula descreveu: dois
containers que querem a mesma porta colidem, e tudo em que o programa escuta está escutando na máquina.
Serve para algumas ferramentas de sistema; não é um jeito de evitar aprender o `-p`.

## `--network none`: nenhuma rede

```
ana@vm:~$ docker run --rm --network none alpine:3.22 ip -o link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000\    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

**Uma interface, o loopback, e nada mais.** Um job em lote que lê arquivos e escreve arquivos, um passo
de build que não pode baixar nada, um programa sendo examinado: nenhum deles precisa de rede, e o `none`
garante que não tenham uma.
