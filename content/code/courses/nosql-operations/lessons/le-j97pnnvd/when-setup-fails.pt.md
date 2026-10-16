---
title: Quando a instalação não funciona
version: 1
---

Tudo da seção anterior pode falhar, e quase toda falha imprime uma frase que diz qual parte. **Leia a
frase antes de tentar qualquer outra coisa.** Cada falha abaixo foi provocada de propósito no
laboratório, então o que você vê é a mensagem real.

## `permission denied while trying to connect to the docker API`

Todo comando `docker` responde com essa frase, seguida do caminho do socket do daemon,
`/var/run/docker.sock`. O daemon está rodando e recusa você: o seu usuário não está no grupo
`docker`, ou foi adicionado e este shell foi aberto antes. Rode `id -nG`. Se `docker` não estiver na
lista, saia do shell e abra de novo; se continuar sem estar, a linha do `usermod` foi pulada.

## `Conflict. The container name "/mongo" is already in use`

```
ana@vm:~$ docker run -d --name mongo --network nosql mongo:8.0
docker: Error response from daemon: Conflict. The container name "/mongo" is already in use by container "5a79e581561e308a9b5e12e43035de3951093e0c5a43402a481e4aeecca4fd92". You have to remove (or rename) that container to be able to reuse that name.

Run 'docker run --help' for more information
```

Você está rodando pela segunda vez um `docker run` de uma aula, e o primeiro contêiner continua lá,
rodando ou parado. **Esta é a mensagem mais comum do curso**, porque muitas aulas sobem seus servidores
do zero. Ou fique com o que você tem (`docker start mongo`), ou remova e rode a linha de novo
(`docker rm -f mongo`), e decida sabendo que remover o contêiner remove os dados dele.

## `network nosql-lab not found`

```
ana@vm:~$ docker run -d --name redis --network nosql-lab redis:7.4
e5d04362abb0c29db3de51006e4cf46c5e431541bea645d10bc20e18122297fd
docker: Error response from daemon: failed to set up container networking: network nosql-lab not found

Run 'docker run --help' for more information
ana@vm:~$ docker ps -a --filter name=redis --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
redis     Created
ana@vm:~$ docker rm redis
redis
```

Um erro de digitação no nome da rede, ou o `docker network create nosql` nunca rodou nesta máquina.
**Repare no id longo impresso antes do erro**: o contêiner foi criado e só falhou ao iniciar, então o
nome dele agora está ocupado por um contêiner no estado `Created`. Corrija o nome, faça `docker rm`
no contêiner pela metade e rode a linha de novo; senão a próxima tentativa esbarra no conflito acima.

## `not found` no pull

```
ana@vm:~$ docker pull mongo:8.0.99
Error response from daemon: failed to resolve reference "docker.io/library/mongo:8.0.99": docker.io/library/mongo:8.0.99: not found
```

O registro respondeu e não tem imagem com essa tag. O curso usa `mongo:8.0`, `redis:7.4` e
`cassandra:5.0`, e o Docker Hub publica todas essas tags. Um pull que trava, ou que falha com uma
palavra como `timeout` ou `TLS`, é outro problema: a VM não alcança a internet, e
`curl -sI https://registry-1.docker.io/v2/` rodado na VM diz se alcança.

## `Connection refused` no `cqlsh`

A seção anterior mostrou: o Cassandra ainda está subindo. Espere com o laço `until` e tente de novo.
Se dois minutos passarem e ele continuar recusando, o contêiner provavelmente parou, que é o próximo
caso.

## O Cassandra sai com código 137

```
ana@vm:~$ docker run -d --name cassandra --network nosql --memory 400m cassandra:5.0
c9e234cf64ee21e5536c4cd3341f104f617caf1a4330b8dafa41bb629622e963
ana@vm:~$ docker ps -a --filter name=cassandra --format "table {{.Names}}\t{{.Status}}"
NAMES       STATUS
cassandra   Exited (137) 59 seconds ago
ana@vm:~$ docker inspect --format "{{.State.OOMKilled}}" cassandra
true
```

Esta foi provocada limitando o contêiner a 400 MB **e deixando de fora as duas configurações `-e`**,
então o Cassandra dimensionou o heap para a máquina inteira e foi morto por usar mais do que podia. O
código de saída 137 é um processo morto pelo sinal 9, e `OOMKilled` `true` diz que foi o kernel, por
falta de memória. Numa VM de 4 GB sem limite, a mesma coisa acontece com o segundo ou o terceiro nó das
aulas 16 a 19 se as configurações faltarem, ou se MongoDB e Redis ainda estiverem rodando ao lado.
Confira as configurações `-e`, faça `docker stop` no que não estiver usando e dê mais memória à VM se
puder.

## Por baixo de tudo isso: a máquina virtual

Se o Multipass se recusar a iniciar a máquina com uma mensagem sobre virtualização desativada, **o
processador consegue e o firmware do computador está com o recurso desligado.** É uma opção no menu da
BIOS ou da UEFI, aberto por uma tecla apertada enquanto o computador liga, e o site do fabricante diz
qual. Se não der para mudar, o caminho instalado ou o online não precisa de virtualização sua.

Uma VM com o disco cheio falha de jeitos que parecem não ter relação, de um pull que para no meio a um
banco que recusa escritas. `df -h /` dentro da VM mostra isso. `docker system prune` pergunta antes e
então remove contêineres parados, redes sem uso e imagens sem tag; os volumes ficam, a não ser que
você acrescente `--volumes`, a opção que apaga dados.

## Recomeçar

Nada aqui é precioso ainda. `docker rm -f mongo redis cassandra` e as três linhas de `docker run`
devolvem o laboratório ao estado que a próxima aula espera. `multipass delete vm` seguido de
`multipass purge` joga fora a máquina inteira, para você montar outra. Uma segunda instalação é um
preço pequeno por saber exatamente onde você está pisando.
