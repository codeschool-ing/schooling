---
title: Montando o laboratório
version: 1
---

Quatro passos: uma máquina Linux, o Docker Engine nela, as três imagens e três contêineres que
respondem. Se você veio do curso `docker`, os dois primeiros estão feitos; confira com os comandos de
"O Docker está pronto?" e siga dali.

## A máquina

Instale o Multipass pelo site da Canonical e então, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name vm --cpus 2 --memory 4G --disk 30G
multipass shell vm
```

O primeiro comando cria uma máquina virtual Ubuntu 24.04 chamada `vm`; o segundo abre um shell dentro
dela. **Estes dois não foram rodados para este curso**, porque o laboratório já é uma máquina virtual
e não consegue iniciar outra. Tudo daqui em diante é digitado no shell que o segundo comando abriu.

## Docker Engine

Dentro da VM, o Docker Engine vem do repositório de pacotes do próprio Docker. Estes são os comandos
das instruções de instalação do Docker para Ubuntu, e a aula 6 do `docker` os explica linha a linha.
Confira a documentação do Docker antes de rodá-los, porque os detalhes mudam; eles também não foram
rodados para este curso, porque o laboratório já tinha o Docker instalado:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

A última linha deixa o seu usuário rodar `docker` sem `sudo`. **Ela só vale a partir do próximo
login**, então saia do shell com `exit` e abra de novo com `multipass shell vm`.

## O Docker está pronto?

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
ana@vm:~$ id -nG
ana docker
```

Dois números de versão significam que o comando chegou ao servidor, o daemon que roda os contêineres.
`docker` na sua lista de grupos significa que o novo login pegou. Se faltar um dos dois, a próxima
seção tem a mensagem que você vai ver no lugar.

## As três imagens, e a rede entre elas

Baixe as imagens uma vez. Cada uma tem algumas centenas de megabytes, e só o primeiro pull baixa
alguma coisa; o laboratório já as tinha, e por isso o pull dele responde `up to date`:

```sh
docker pull mongo:8.0
docker pull redis:7.4
docker pull cassandra:5.0
```

```
ana@vm:~$ docker pull mongo:8.0
8.0: Pulling from library/mongo
Digest: sha256:d0d926f94df099bff534b7ee5b5986458131a22489dfff8664509af0c1e2ca9c
Status: Image is up to date for mongo:8.0
docker.io/library/mongo:8.0
```

A tag depois dos dois-pontos é uma **linha de versões**, não uma versão: `mongo:8.0` é a 8.0.x mais
nova no momento do pull, então o seu número de patch pode ser maior que o do laboratório.

Os contêineres ficam numa rede só deles, chamada `nosql`. Numa rede definida pelo usuário, um
contêiner alcança outro **pelo nome**, e é isso que permite à aula 9 subir três servidores MongoDB que
se encontram como `mongo1`, `mongo2` e `mongo3`:

```
ana@vm:~$ docker network create nosql
3fe5cc3a3bd354a18067b6dfed5ded5f17121d1724dfd7cbf40829b2c4e26628
```

## Três contêineres

```sh
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name redis --network nosql redis:7.4
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

`-d` roda cada um em segundo plano, e `--name` é como todo comando seguinte se refere a ele. Nenhuma
porta é publicada na VM: você sempre vai falar com um servidor pelo cliente que vem dentro da própria
imagem, com `docker exec`, então nada mais na sua máquina pode colidir com ele.

**As duas configurações `-e` são a parte importante da terceira linha.** O Cassandra roda na máquina
virtual Java e, sem elas, dimensiona a memória pela memória da máquina inteira, e não pelo que
precisa. Um Cassandra dimensionado assim cabe em 4 GB; os três das aulas 16 a 19, não. Com um heap
de 256 MB cada nó demora a subir e dá de sobra para os dados deste curso.

MongoDB e Redis respondem em um ou dois segundos. O Cassandra leva cerca de um minuto para subir, e
perguntar cedo demais é recusado:

```
ana@vm:~$ docker exec cassandra cqlsh
Connection error: ('Unable to connect to any servers', {'127.0.0.1:9042': ConnectionRefusedError(111, "Tried connecting to [('127.0.0.1', 9042)]. Last error: Connection refused")})
```

`Connection refused` aqui quer dizer "ninguém está escutando ainda", e não "algo deu errado". Espere
com um laço que pergunta a cada cinco segundos e volta, em silêncio, assim que o Cassandra responde:

```sh
until docker exec cassandra cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
```

```
ana@vm:~$ docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES       IMAGE           STATUS
cassandra   cassandra:5.0   Up About a minute
redis       redis:7.4       Up About a minute
mongo       mongo:8.0       Up About a minute
```

## A primeira conversa com cada um

Cada servidor vem com seu próprio cliente, e cada cliente tem seu próprio prompt. **O do MongoDB é o
`mongosh`**, que fala JavaScript; `--quiet` omite o banner que ele imprimiria:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet
test> db.version()
8.0.32
test> db.lab.insertOne({ greeting: "hello from the lab" })
{
  acknowledged: true,
  insertedId: ObjectId('6ac9e3ec1cdb95b496e200b8')
}
test> db.lab.find()
[
  {
    _id: ObjectId('6ac9e3ec1cdb95b496e200b8'),
    greeting: 'hello from the lab'
  }
]
test> exit
```

`test>` mostra o banco em que você está. Nada foi criado antes: a primeira escrita numa coleção
chamada `lab` criou a coleção e o banco. A aula 6 tem mais a dizer sobre esse hábito.

**O cliente do Redis é o `redis-cli`**, e um comando é uma palavra seguida dos seus argumentos:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> PING
PONG
127.0.0.1:6379> SET greeting "hello from the lab"
OK
127.0.0.1:6379> GET greeting
"hello from the lab"
127.0.0.1:6379> exit
ana@vm:~$ docker exec redis redis-server --version
Redis server v=7.4.11 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=f20da322597b16d7
```

**O do Cassandra é o `cqlsh`**, e a linguagem dele, CQL, parece SQL de propósito, com diferenças que
a aula 16 explora ao máximo:

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT cluster_name, release_version FROM system.local;

 cluster_name | release_version
--------------+-----------------
 Test Cluster |           5.0.9

(1 rows)
cqlsh> exit
```

`-it` dá ao cliente um terminal onde digitar. Deixe de fora quando for passar um único comando a um
cliente e quiser só a resposta, como faz a linha `redis-server --version` acima.

## Quanto custa deixar rodando

```
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME        MEM USAGE / LIMIT
cassandra   595MiB / 15.72GiB
redis       9.523MiB / 15.72GiB
mongo       204.1MiB / 15.72GiB
```

Cerca de 800 MB com os três ociosos, e **o Cassandra é três quartos disso** mesmo com o heap pequeno.
O número depois da barra é a memória da máquina inteira, 15,72 GiB no laboratório; numa VM de 4 GB o
seu vai dizer uns 3,8. Pergunte ao Cassandra quanto do heap ele está usando:

```
ana@vm:~$ docker exec cassandra nodetool info | grep -E "^Heap Memory"
Heap Memory (MB)       : 140.29 / 256.00
```

256, o limite que a configuração `-e` deu.

## Parar, ligar e recomeçar do zero

`docker stop` encerra os servidores e mantém os contêineres, com os dados; `docker start` os traz de
volta como estavam:

```
ana@vm:~$ docker stop mongo redis cassandra
mongo
redis
cassandra
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES       STATUS
cassandra   Exited (143) Less than a second ago
redis       Exited (0) 4 seconds ago
mongo       Exited (0) 4 seconds ago
ana@vm:~$ docker start mongo redis cassandra
mongo
redis
cassandra
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'db.lab.countDocuments()'
1
```

O documento gravado antes do stop continua lá. `docker rm -f` é a outra ponta: remove o contêiner, e
um novo contêiner com o mesmo nome começa do nada:

```
ana@vm:~$ docker rm -f mongo
mongo
ana@vm:~$ docker run -d --name mongo --network nosql mongo:8.0
5a79e581561e308a9b5e12e43035de3951093e0c5a43402a481e4aeecca4fd92
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'db.lab.countDocuments()'
0
```

Aqui isso é uma vantagem. **A maioria das aulas começa com servidores vazios**, e diz no início de
quais contêineres precisa; quando uma aula precisa de dados que sobrevivam a um contêiner, ela avisa
e dá um volume ao contêiner. Entre uma aula e outra, faça `docker stop` nos três para devolver a
memória à VM, e `docker start` quando voltar.
