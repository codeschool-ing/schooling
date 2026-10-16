---
title: Um limite, e o que o Redis faz quando chega nele
version: 1
---

Tudo o que o Redis guarda está na memória, então o tamanho da máquina é o tamanho do banco. **Deixado
como está, o Redis não tem limite nenhum**: cresce até o sistema operacional ficar sem memória e matar
o maior processo da máquina, que é o Redis. O `maxmemory` põe um teto dentro do processo, e o
`maxmemory-policy` decide o que acontece no teto. Essa segunda configuração é onde o Redis fica sabendo
se é um cache ou um banco de dados, e é o assunto desta aula.

Se você fez `servers-cache`, a aula 8 de lá viu o despejo na frente de um servidor web. Esta aula roda
cada política contra a mesma carga e depois olha a instância que é cache e banco ao mesmo tempo, que é
onde a operação dá errado.

## O contêiner

Esta aula precisa de um contêiner `redis`, e fica mais clara começando do zero:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql redis:7.4
2d36ee12e6bf1e129db6ac1ca589bc70167356649d65961c16dcdb9998b823c5
```

## Teto e política

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET maxmemory
1) "maxmemory"
2) "0"
127.0.0.1:6379> CONFIG GET maxmemory-policy
1) "maxmemory-policy"
2) "noeviction"
127.0.0.1:6379> CONFIG SET maxmemory 4mb
OK
```

`0` quer dizer sem limite, o padrão numa máquina de 64 bits, e a política padrão é `noeviction`. 4 MB
é absurdamente pouco de propósito, para o teto ser alcançado em um segundo.

## Enchendo sob `noeviction`

O shell escreve 20.000 comandos `SET`, cada um uma página de 100 bytes, e os manda por um pipe a um
único `redis-cli`, que os envia em sequência. `grep . | sort | uniq -c` conta as respostas:

```
ana@vm:~$ seq 1 20000 | awk '{ printf "SET page:%d %0100d\n", $1, 0 }' | docker exec -i redis redis-cli | grep . | sort | uniq -c
  17668 OK
   2332 OOM command not allowed when used memory > 'maxmemory'.
```

**17.668 páginas foram guardadas e 2.332 foram recusadas** com `OOM command not allowed when used
memory > 'maxmemory'`. Nada foi apagado para abrir espaço: sob `noeviction`, o Redis recusa todo
comando que poderia acrescentar dados quando está no teto. O que ele ainda permite:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET product:KB-101 34990
(error) OOM command not allowed when used memory > 'maxmemory'.
127.0.0.1:6379> GET page:1
"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
127.0.0.1:6379> DEL page:1
(integer) 1
ana@vm:~$ docker exec redis redis-cli INFO memory | grep -E "^(used_memory_human|maxmemory_human|maxmemory_policy):"
used_memory_human:4.06M
maxmemory_human:4.00M
maxmemory_policy:noeviction
```

Uma escrita de qualquer coisa nova é recusada, um produto inclusive; uma leitura funciona; um `DEL`
funciona, porque libera memória. A memória usada fica um pouco acima do teto, que é como o Redis decide
que um comando passaria dele.

**Esse é o comportamento certo para um banco de dados.** A aplicação recebe um erro que consegue ver,
alguém é acionado, e nada do que ela guardou sumiu em silêncio. Para um cache é o comportamento errado,
porque um cache que recusa entradas novas quando enche para de fazer cache justo quando está mais
ocupado.

## O teto dentro do teto do contêiner

O `maxmemory` conta os dados que o Redis guarda, não tudo o que o processo usa. Buffers de clientes e
de réplicas, e a cópia que um fork faz ao salvar (aula 13), vêm por cima. Se o contêiner também tem um
limite de memória, `docker run --memory`, ponha o `maxmemory` bem abaixo dele.
Senão o kernel mata o contêiner antes de o Redis chegar ao próprio teto, e aí é a saída 137 por falta de memória da aula 1,
e não um erro que o cliente consegue ler.
