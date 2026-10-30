---
title: Medindo no laptop, do docker run ao primeiro 200
version: 1
---

Nada num laptop reproduz a metade do Azure de uma partida a frio: achar uma instância, entregar o
pacote a ela, um placeholder virando o seu app. O que roda aqui é a outra metade, o mesmo host e o
mesmo worker na imagem da Microsoft, começando do nada. **Então esta seção mede a partida a frio do
app da aula 15 no laptop, e todo número nela é do laptop**: uma máquina com quatro processadores
divididos com outro trabalho, onde uma execução difere da anterior em um segundo. Leia a forma e as
proporções, nunca os milissegundos, e nunca como números do Azure.

## O app, e algo para cronometrá-lo

Isto parte dos arquivos da aula 15 em `~/azure/shopfn`, a primeira versão do `function_app.py` só
com `take_order`, e do `storage.sh`. Se os contêineres da aula 15 ainda estão rodando, remova o app
dela com `docker rm -f shopfn`, mantenha o `azurite` e a rede, e pule os dois comandos do meio:

```
ana@laptop:~/azure$ source storage.sh
ana@laptop:~/azure$ docker network create functions
67226d4ff1b3613350e09271538bb508510007bba7a8ad5e9cbf8d59c7b66d13
ana@laptop:~/azure$ docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
c3a748caa58f377b115d37be2c76ca040704d9e865ed3865ef021dfcdeb54f62
ana@laptop:~/azure$ docker build -q -t shopfn:1 shopfn
sha256:911fba7bb4dbff87c5c954c4f852eac7f90676cd232c0c65d997e512c8df909a
```

Uma partida a frio aqui é um `docker run` de uma imagem que ninguém iniciou ainda, e o fim dela é o
primeiro pedido respondido com `200`. A função de shell abaixo cronometra exatamente isso, de logo
antes do `docker run` até a resposta. Cole no terminal; ela dura até o terminal fechar.

```schooling-example
{"language": "sh", "file": "first200.sh", "parts": [{"code": "first200() {\n  docker rm -f cold > /dev/null 2>&1\n  local start=$(date +%s%N) code= seen= tries=0\n  docker run -d --name cold --network functions -p 7071:80 ${2:+--cpus \"$2\"} \\\n    -e AzureWebJobsStorage=\"$FN_STORAGE\" \"$1\" > /dev/null\n", "note": "Remove o contêiner da execução anterior, para que toda execução comece sem instância nenhuma, e anota a hora em nanossegundos. Depois inicia a imagem dada no primeiro argumento na rede da aula 15, com a porta 80 publicada como 7071 para não colidir com o app da aula 15 na 8080. `${2:+--cpus \"$2\"}` acrescenta um limite de processador só quando há um segundo argumento."}, {"code": "  until [ \"$code\" = 200 ]; do\n    code=$(curl -s -o /dev/null -w '%{http_code}' -XPOST localhost:7071/api/orders \\\n      -d '{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}')\n    seen=\"$seen $code\"\n    tries=$((tries + 1))\n    [ $tries -lt 600 ] || { echo \"$1: no answer after $tries tries\"; return 1; }\n    [ \"$code\" = 200 ] || sleep 0.1\n  done\n", "note": "Pede um pedido a cada décimo de segundo até um ser respondido com 200, e guarda todo código de status que recebeu. O `curl` imprime `000` quando nada respondeu. Depois de 600 tentativas, mais ou menos um minuto, ele desiste, em vez de girar para sempre num app que nunca vai começar."}, {"code": "  echo \"$1: first 200 after $(( ($(date +%s%N) - start) / 1000000 )) ms\"\n  echo $seen | tr ' ' '\\n' | uniq -c\n  curl -s -o /dev/null -w 'next request: %{time_total} s\\n' -XPOST localhost:7071/api/orders \\\n    -d '{\"order\": \"A-1002\", \"sku\": \"mug\", \"qty\": 1}'\n}\n", "note": "Imprime quanto o primeiro 200 levou, de antes do `docker run` até a resposta, e os códigos contados em sequência. Depois mais um pedido, cronometrado pelo `curl`: a mesma instância, agora quente. O contêiner fica rodando, para o log dele poder ser lido."}]}
```

## Três partidas a frio

```
ana@laptop:~/azure$ first200 shopfn:1
shopfn:1: first 200 after 5823 ms
     42 000
      1 200
next request: 0.020162 s
ana@laptop:~/azure$ first200 shopfn:1
shopfn:1: first 200 after 5662 ms
     41 000
      1 200
next request: 0.027548 s
ana@laptop:~/azure$ first200 shopfn:1
shopfn:1: first 200 after 6796 ms
     46 000
      1 200
next request: 0.027155 s
```

**Entre cinco e sete segundos até a primeira resposta, e dois ou três centésimos de segundo para a
seguinte.** A primeira execução levou 5823 ms, a segunda 5662, a terceira 6796; o pedido quente
depois de cada uma levou entre 0.020162 e 0.027548 s. Umas quarenta tentativas voltaram `000`, que é
o `curl` dizendo que nada respondeu: o contêiner estava rodando, e nada escutava na porta dele até o
host ficar pronto. No Azure um pedido não é recusado assim: a documentação o descreve esperando, com
"a latência a mais de escalar de zero para um". Aqui nada na frente do contêiner espera, então a
função pergunta de novo a cada décimo de segundo.

## Para onde vão os segundos

O contêiner da última execução ainda está lá. `docker logs -t` põe a hora em cada linha, e algumas
linhas do host marcam os passos da seção anterior:

```
ana@laptop:~/azure$ docker inspect -f '{{.State.StartedAt}}' cold
2026-10-30T19:24:37.662452365Z
ana@laptop:~/azure$ docker logs -t cold 2>&1 | grep -E 'CLOUD_CERTS|Initializing Host\.|Loading functions metadata|functions loaded|Host started|Executed ' | cut -c1-125
2026-10-30T19:24:37.908453393Z WEBSITES_INCLUDE_CLOUD_CERTS is not set to true.
2026-10-30T19:24:42.998519231Z       Initializing Host. OperationId: 'fc679771-b5fd-4f28-bb97-4c61e79798bc'.
2026-10-30T19:24:43.091792156Z       Loading functions metadata
2026-10-30T19:24:43.147283144Z       1 functions loaded
2026-10-30T19:24:43.256121276Z       Host started (165ms)
2026-10-30T19:24:44.143060434Z       Executed 'Functions.take_order' (Succeeded, Id=8cb3b0ee-8976-469d-bb47-d68a416adb3d, Dur
2026-10-30T19:24:44.324549985Z       Executed 'Functions.take_order' (Succeeded, Id=cb47b4af-b563-449f-b8b8-3362fcc2b57f, Dur
```

Leia as horas umas contra as outras, não contra o relógio:

| de | até | nesta execução |
|---|---|---|
| o contêiner começa | a primeira linha do script de início | 0,25 s |
| o script de início | `Initializing Host` | 5,09 s |
| `Initializing Host` | `Host started` | 0,26 s |
| `Host started` | o primeiro pedido executado | 0,89 s |

A linha do script de início, sobre `CLOUD_CERTS`, é da própria imagem e inofensiva. **Depois passam
cinco segundos sem nada no log**: o host .NET começando, carregando as extensões, e o worker Python
começando ao lado dele e importando o `function_app.py`. Só então o host diz que está inicializando,
e daí até um host rodando leva um quarto de segundo. Carregar a função, `1 functions loaded`, é
alguns centésimos disso. De `Host started` até o primeiro pedido executado vai quase mais um
segundo, que cobre a porta abrindo, a próxima tentativa da função e a primeira chamada pelo worker
novo; o log não separa essas coisas. A segunda linha `Executed`, o pedido quente, vem 0,18 s depois
da primeira, e quase tudo isso é o shell imprimindo as contagens e iniciando o `curl` de novo.

## Uma importação que custa alguma coisa

A seção anterior disse que a importação do `function_app.py` é paga por toda partida a frio. Para
vê-la acima da variação entre execuções, faça uma cópia do app cuja importação leva oito segundos.
Um sleep no topo do arquivo faz o papel de uma biblioteca lenta:

```
ana@laptop:~/azure$ cp -r shopfn slow
ana@laptop:~/azure$ sed -i 's/^import logging$/&\nimport time\ntime.sleep(8)/' slow/function_app.py
ana@laptop:~/azure$ head -6 slow/function_app.py
# function_app.py
import json
import logging
import time
time.sleep(8)

ana@laptop:~/azure$ docker build -q -t shopfn:slow slow
sha256:a3cbae2b3afa1a63a07b561eb0e2df9e855c11774223bede7e1a53b912349302
```

`time.sleep(8)` no nível do módulo roda uma vez, quando o worker importa o arquivo, exatamente onde
rodaria um `import` pesado ou um cliente criado no topo. Depois três partidas a frio dele, e o log:

```
ana@laptop:~/azure$ first200 shopfn:slow
shopfn:slow: first 200 after 16508 ms
    114 000
      1 200
next request: 0.017081 s
ana@laptop:~/azure$ first200 shopfn:slow
shopfn:slow: first 200 after 13827 ms
    109 000
      1 200
next request: 0.043927 s
ana@laptop:~/azure$ first200 shopfn:slow
shopfn:slow: first 200 after 13463 ms
    111 000
      1 200
next request: 0.040339 s
ana@laptop:~/azure$ docker logs -t cold 2>&1 | grep -E 'CLOUD_CERTS|Initializing Host\.|Loading functions metadata|functions loaded|Host started|Executed ' | cut -c1-125
2026-10-30T19:25:18.307011409Z WEBSITES_INCLUDE_CLOUD_CERTS is not set to true.
2026-10-30T19:25:30.739022227Z       Initializing Host. OperationId: '872582c5-1243-4b06-814b-574cf3f03a57'.
2026-10-30T19:25:30.802460788Z       Loading functions metadata
2026-10-30T19:25:30.844476836Z       1 functions loaded
2026-10-30T19:25:30.925340531Z       Host started (125ms)
2026-10-30T19:25:31.288105105Z       Executed 'Functions.take_order' (Succeeded, Id=fafacecd-c871-4199-b34c-47600992bb64, Dur
2026-10-30T19:25:31.394272807Z       Executed 'Functions.take_order' (Succeeded, Id=4852892a-f720-4bb9-89f0-24e1e4d8549e, Dur
```

**A primeira resposta passou de uns seis segundos para entre 13,4 e 16,5**, e o pedido quente depois
dela não se mexeu: 0.017081 s, 0.043927, 0.040339, alguns centésimos como antes. O log diz para onde
foi o tempo. Do script de início até `Initializing Host` foram 12,43 s aqui, contra 5,09 do app
simples, 7,34 s a mais; tudo depois disso é tão rápido quanto antes. A diferença é um pouco menor que
os oito segundos do sleep. O que isso sugere, e o laptop não consegue provar, é que o worker começa a
importar enquanto o host ainda está começando, então parte de uma importação curta se esconde atrás
do início do próprio host, e uma longa não. Num placeholder no Azure, que já tem o host rodando, não
há nada atrás do que a importação possa se esconder.

Duas coisas valem para a loja. Uma partida a frio paga pelo módulo uma vez e um pedido quente não
paga nada por ele, então uma importação pesada é um problema só de partida a frio. E ela é paga por
toda função do app, e é por isso que a biblioteca do relatório noturno não pertence ao arquivo da
API de pedidos.

## Um quarto de núcleo

A menor instância do Flex Consumption, 512 MB, vem com um quarto de núcleo, e a padrão, 2.048 MB,
com um. O Docker consegue limitar quanto processador um contêiner recebe, que é o mais perto disso
que o laptop chega. **Isto é um análogo, rodado com o `--cpus` do Docker, e não a alocação do
Azure**:

```
ana@laptop:~/azure$ nproc
4
ana@laptop:~/azure$ first200 shopfn:1 1
shopfn:1: first 200 after 5638 ms
     42 000
      1 200
next request: 0.021042 s
ana@laptop:~/azure$ first200 shopfn:1 0.5
shopfn:1: first 200 after 8698 ms
     65 000
      1 200
next request: 0.024337 s
ana@laptop:~/azure$ first200 shopfn:1 0.25
shopfn:1: first 200 after 16316 ms
    120 000
      1 200
next request: 0.084776 s
```

A mesma imagem, a mesma máquina: 5638 ms com um processador inteiro, 8698 com meio, 16316 com um
quarto, quase três vezes mais que com um. Iniciar o host é computação, e computação roda na
velocidade do processador que recebe. No laptop, pelo menos, **uma instância menor é uma partida a
frio mais lenta**, e a próxima seção põe o preço de cada tamanho ao lado disso.

Remova o último contêiner e a imagem lenta. Mantenha a rede e o Azurite: a aula 17 parte deles.

```sh
docker rm -f cold
docker image rm shopfn:slow
```
