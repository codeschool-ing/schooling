---
title: Rede e infraestrutura
version: 1
---

O banco e a trava foram achados pelo `Server-Timing`, porque os dois estão dentro da aplicação,
onde o relógio do próprio servidor corre. As duas causas desta seção estão fora dela, e o jeito de
achá-las é a subtração da primeira seção: **quando o tempo do cliente é muito maior que o do
servidor, a diferença foi gasta entre os dois.**

## Quarenta milissegundos numa conexão mantida

Toda ferramenta de carga das aulas 4 a 7 mantém a conexão aberta entre as requisições, como um
navegador faz, e no `app.py` cada uma delas paga uns 40 ms a mais por requisição do que o `curl`
paga. O `measure.py` abre uma conexão nova a cada vez, e por isso os números da aula 8 não mostram
isso. Este script pede `/health`, a resposta mais barata que a bilheteria tem, cinco vezes numa
conexão mantida e depois cinco vezes em conexões novas, e imprime o tempo do cliente ao lado do
total do servidor:

```python
# boxoffice/keepalive.py
# Five requests for /health on one kept connection, then five on fresh
# connections, each printed with the time the client saw and the time the
# server says it spent (the total in its Server-Timing header).
import http.client, time

def ask(conn):
    start = time.perf_counter()
    conn.request("GET", "/health")
    answer = conn.getresponse()
    answer.read()
    client = (time.perf_counter() - start) * 1000
    server = answer.getheader("Server-Timing").split("total;dur=")[1]
    return f"client {client:5.1f} ms   server {server} ms"

kept = http.client.HTTPConnection("127.0.0.1", 8000)
for i in range(5):
    print("kept connection ", ask(kept))
for i in range(5):
    fresh = http.client.HTTPConnection("127.0.0.1", 8000)
    print("fresh connection", ask(fresh))
    fresh.close()
```

Salve como `~/boxoffice/keepalive.py`. Pare o `app_fixed.py` com `Ctrl+C` e inicie o `app.py` de
novo por um momento; depois rode:

```
ana@nft:~/boxoffice$ python3 keepalive.py
kept connection  client   2.9 ms   server 0.5 ms
kept connection  client  43.4 ms   server 0.3 ms
kept connection  client  47.9 ms   server 43.5 ms
kept connection  client  44.0 ms   server 47.6 ms
kept connection  client  43.9 ms   server 44.1 ms
fresh connection client   1.7 ms   server 0.6 ms
fresh connection client   1.0 ms   server 0.4 ms
fresh connection client   0.7 ms   server 0.2 ms
fresh connection client   0.7 ms   server 0.2 ms
fresh connection client   0.8 ms   server 0.2 ms
```

Em conexões novas o cliente vê de 0.7 a 1.7 ms. Na mantida, a primeira requisição leva 2.9 ms e
**cada requisição depois dela cerca de 44 ms**, enquanto o servidor disse 0.3 ms para a segunda. Os
43 ms que ninguém explicou não estão na aplicação. Estão no TCP, e a causa são duas regras
razoáveis se encontrando:

- O `app.py` escreve cada resposta em dois pedaços, os cabeçalhos e depois o corpo, porque é assim
  que o `http.server` do Python os manda. O **algoritmo de Nagle** segura um pedaço pequeno de
  dados enquanto um anterior ainda não foi confirmado, para que um programa que escreve um byte
  por vez não inunde a rede de pacotes minúsculos. Então o corpo espera o cliente confirmar os
  cabeçalhos.
- O cliente atrasa a confirmação, esperando levá-la num pacote seu logo em seguida, o que economiza
  um pacote. No Linux essa **confirmação atrasada** (*delayed ACK*) espera pelo menos 40 ms.

Cada lado espera o outro, e o impasse se desfaz quando o atraso acaba. Uma conexão nova escapa
disso porque o Linux confirma na hora no começo de uma conexão. A correção é desligar o algoritmo
de Nagle no socket do servidor, a opção `TCP_NODELAY`, que é o que `disable_nagle_algorithm =
True` faz no `app_fixed.py`.

Olhe também a coluna do servidor da terceira requisição em diante: 43.5, 47.6, 44.1 ms. O servidor
não estava trabalhando nesse tempo. O `app.py` começa o relógio quando começa a esperar a próxima
requisição numa conexão, então numa conexão mantida o total dele inclui a espera por um cliente
que estava, ele mesmo, esperando o fim da última resposta. **Uma medida só é tão boa quanto o ponto
onde o relógio dela começa**, e o `app_fixed.py` reinicia o relógio em `parse_request`, quando uma
requisição chegou. Pare o `app.py`, inicie o `app_fixed.py` e rode de novo:

```
ana@nft:~/boxoffice$ python3 keepalive.py
kept connection  client   5.5 ms   server 0.2 ms
kept connection  client   0.4 ms   server 0.2 ms
kept connection  client   0.5 ms   server 0.1 ms
kept connection  client   0.3 ms   server 0.1 ms
kept connection  client   0.2 ms   server 0.0 ms
fresh connection client   1.4 ms   server 0.1 ms
fresh connection client   2.3 ms   server 0.1 ms
fresh connection client   2.6 ms   server 0.1 ms
fresh connection client   1.0 ms   server 0.2 ms
fresh connection client   1.1 ms   server 0.1 ms
```

Depois da primeira, cada requisição mantida leva entre 0.2 e 0.5 ms no cliente, e a coluna do
servidor diz 0.2 ms ou menos. Esse é o número que as aulas 4 a 7 teriam medido no `app_fixed.py`.

## A fila na frente do servidor

Antes de o servidor ver uma conexão, o sistema operacional tem de completá-la e pô-la numa fila
para o programa aceitar. O tamanho dela é definido pelo programa quando ele começa a escutar, e o
`socketserver` do Python, sobre o qual o `http.server` é construído, pede **5**. Quando a fila está
cheia, o kernel descarta o pacote de abertura da conexão nova, e o cliente, sem ouvir nada, tenta
de novo depois de um segundo, depois de mais dois, depois de quatro. O contador desses descartes é
o `TcpExtListenOverflows`, e o `nstat` o imprime: `-n` zera os contadores sem imprimi-los, e `-z`
imprime um contador mesmo quando ele é zero. Com o `app.py` rodando, trinta e dois workers:

```
ana@nft:~/boxoffice$ nstat -n; python3 measure.py 32 5 | sed -n "1p;4p"; nstat -z TcpExtListenOverflows
32 workers, 6.0 s: 3381 requests, 561.3 per second
all          3381    50.6     9.0    15.8    19.2  1035.5  4780.4
#kernel
TcpExtListenOverflows           190                0.0
```

**190 conexões foram descartadas em cinco segundos**, e os percentis mostram as novas tentativas
que os clientes fizeram: uma mediana de 9.0 ms, um p99 de 1035.5 ms, cerca de um segundo, e um
máximo de 4780.4 ms, uma requisição descartada várias vezes. Esses são os pontos de um segundo da
execução da seção do banco, e a forma é uma impressão digital que vale conhecer: uma cauda perto
de um segundo, ou perto de três, quase sempre é uma conexão sendo tentada de novo, não um servidor
lento. Nos termos do USE é a coluna de **erros** da fila de aceite, e ela é invisível em todo log
que a aplicação escreve, porque a aplicação nunca viu essas conexões.

O `app_fixed.py` pede uma fila de 128. Com ele rodando:

```
ana@nft:~/boxoffice$ nstat -n; python3 measure.py 32 5 | sed -n "1p;4p"; nstat -z TcpExtListenOverflows
32 workers, 5.1 s: 3178 requests, 626.2 per second
all          3178    50.5    49.5    65.1    70.8    85.6   115.4
#kernel
TcpExtListenOverflows           0                  0.0
```

Nenhuma conexão descartada, um p99 de 85.6 ms e um máximo de 115.4. A mediana subiu, de 9.0 para
49.5 ms, e isso está certo, não é uma regressão. Antes, muitos dos 32 workers estavam parados um
segundo esperando para tentar de novo, então havia menos requisições dentro do servidor, e essas
poucas eram rápidas. Agora as 32 estão dentro, e a lei de Little diz que 626.2 por segundo × 0.0505
s dá cerca de 32. **Uma mediana que melhora porque alguns usuários não estão sendo atendidos é a
mesma armadilha dos erros rápidos da aula 8.**

## Latência e banda

Em `127.0.0.1` não há distância nem fio, então esta aula não mede nenhuma das duas propriedades que
deixam uma rede de verdade lenta. **Latência** é o tempo que um pacote leva para atravessar, pago
a cada ida e volta: abrir uma conexão custa uma, e o TLS soma mais. O `curl -w` a mostra como
`time_connect`, que aqui foi 0.293 ms, e que entre continentes costuma ser dezenas de
milissegundos. **Banda** é quantos bytes por segundo o caminho carrega, e ela decide quanto tempo
uma resposta grande leva para chegar depois do primeiro byte. O `curl` a informa como
`%{speed_download}`, em bytes por segundo, ao lado de `%{size_download}`; nesta máquina os dois não
dizem nada, e nenhum foi rodado para esta aula. Um teste de carga rodado na mesma máquina que o
servidor, como todos deste curso, mede a aplicação com a rede tirada da conta, e essa é uma
condição que o requisito deve declarar, como a aula 1 pediu.

## Processadores, memória, disco, e o gerador

Rode trinta e dois workers contra o `app_fixed.py` e olhe os dois programas:

```
ana@nft:~/boxoffice$ python3 measure.py 32 8 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep "python3 [am]"; wait
  11951 ana       20   0 1399780  29868  11800 S 130.0   0.2   0:11.27 python3 app_fixed.py
  17678 ana       20   0 2320684  19852   9964 S  30.0   0.1   0:00.57 python3 measure.py 32 8
  11951 ana       20   0 1407960  29880  11800 S 116.5   0.2   0:13.60 python3 app_fixed.py
  17678 ana       20   0 2320812  20076   9964 S  23.5   0.1   0:01.04 python3 measure.py 32 8
ana@nft:~/boxoffice$ head -1 load.txt
32 workers, 8.0 s: 5773 requests, 717.3 per second
```

O `app_fixed.py` está em 116.5% de um processador no segundo retrato, e a vazão é 717.3
requisições por segundo. É pouco mais de um processador dos quatro, e **é onde este servidor para**. O Python roda o código Python de uma thread por vez, então um processo Python sozinho chega perto de
um processador e não passa muito disso, com um pouco a mais pelo tempo que ele passa no SQLite e no
kernel. A próxima correção seria mais processos, não um índice mais rápido. O `measure.py` está em
23.5%: **o gerador não é o gargalo**. Se o processo dele estivesse perto do próprio teto, o teste
estaria medindo o gerador, e o remédio é um segundo gerador, ou um mais eficiente como os das aulas
4 a 7, nunca uma conclusão sobre o servidor.

Para a memória, `free -m` dá os totais:

```
ana@nft:~/boxoffice$ free -m
               total        used        free      shared  buff/cache   available
Mem:           16093        1488        7359          14        7584       14604
Swap:              0           0           0
```

Esses números são do computador em que as transcrições foram gravadas, com 16 GB; na sua máquina
de 4 GB os números são menores e a leitura é a mesma. A coluna que importa é `available`, o que os
programas ainda podem ganhar sem empurrar nada para fora, e a linha `Swap`. A memória satura
**fazendo swap**, movendo páginas para o disco, e uma máquina que faz swap sob carga fica mais
lenta em ordens de grandeza; as colunas `si` e `so` do `vmstat` contam isso por segundo, e ficam em
0 abaixo. A bilheteria em si é pequena: a coluna `RES` do `top` mostrou cerca de 30 MB para ela.

O disco é o último recurso, e são as reservas que o usam, porque todo commit escreve. Enquanto
dezesseis workers reservam contra o `app_fixed.py`:

```
ana@nft:~/boxoffice$ python3 measure.py 16 8 1.0 > load.txt & sleep 2; vmstat 1 4; wait
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
11  0      0 7050516 423864 7331064    0    0  2075 30997 9694   50 46 14 34  5  1  0
 4  0      0 7068544 423864 7331180    0    0     0  7808 22244 37515 43 21 31  4  1  0
 2  0      0 7115428 423864 7331140    0    0     0  9900 18553 30387 42 18 33  5  2  0
 1  0      0 7178920 423864 7331296    0    0     0 10796 18035 31749 35 19 39  5  2  0
```

O `vmstat 1 4` imprime uma linha por segundo; a primeira é a média desde que a máquina ligou,
então leia as três depois dela. `bo` são kilobytes escritos por segundo, de 7808 a 10796 aqui;
`wa` é a fração do tempo em que os processadores ficaram esperando o disco, de 4 a 5%; `b` é o
número de processos bloqueados nele, 0. **O disco está ocupado e não saturado.** Como na linha de
resumo do `top`, essas colunas cobrem o computador de gravação inteiro, que também estava fazendo
outro trabalho.

## Distinguindo uns dos outros

| o que você vê | onde olhar |
|---|---|
| o `Server-Timing` do servidor perto do tempo do cliente, uma parte dominando | dentro da aplicação: essa parte |
| vazão plana, latência subindo, processadores ociosos | um recurso de software: uma trava, um pool, uma fila |
| vazão plana, o processo do servidor usando os processadores | o código, ou o banco que ele espera |
| o tempo do cliente muito maior que o do servidor | entre os dois: a rede, o TCP, um proxy |
| uma cauda perto de 1 s ou de 3 s | conexões descartadas e tentadas de novo |
| o processo do próprio gerador no teto | o gerador, não o sistema |
| `si`, `so` ou `wa` subindo | memória ou disco |

A ordem das seções desta aula é a ordem em que olhar. **Leia os relógios primeiro, porque são de
graça, e eles dizem qual camada antes que qualquer ferramenta precise dizer qual recurso.**
