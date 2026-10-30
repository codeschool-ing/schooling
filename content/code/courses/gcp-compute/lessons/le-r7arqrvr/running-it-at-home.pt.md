---
title: Rodando em casa sob o mesmo contrato
version: 1
---

A imagem da seção anterior é a que o Cloud Run rodaria. **Iniciada com `docker run` e com um `PORT`,
ela se comporta no seu laptop como o contrato diz que se comportará lá**, o que faz do laptop o
lugar mais barato para descobrir se ela cumpre o contrato. Todo comando desta seção roda a partir
de `~/gcp`.

## Respondendo

Inicie em segundo plano com a variável que o Cloud Run definiria, e pergunte alguma coisa:

```
ana@laptop:~/gcp$ docker run -d --name orders -p 8080:8080 -e PORT=8080 orders:1
f71358e76cb6429f08b96a9599efb2a90b7663a02383feab47162de6317f58ca
ana@laptop:~/gcp$ curl -s localhost:8080/orders; echo
{"orders": [{"id": 1001, "item": "notebook", "quantity": 2}, {"id": 1002, "item": "pencil", "quantity": 12}], "revision": "local"}
ana@laptop:~/gcp$ curl -s localhost:8080/health; echo
{"status": "ok"}
ana@laptop:~/gcp$ curl -s -i localhost:8080/nothing; echo
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.13
Date: Fri, 30 Oct 2026 18:27:19 GMT
Content-Type: application/json
Content-Length: 22

{"error": "not found"}
```

**O `-p 8080:8080` faz as vezes do front end do Cloud Run**: ele leva as requisições da porta do
laptop à do contêiner, como o front end do Google as leva do endereço HTTPS público ao `PORT`. O
`404` veio do programa, com corpo JSON, que é o comportamento que um cliente de uma API de verdade
espera; o Cloud Run o repassaria sem mudança.

Agora a parte do contrato que a maioria dos programas pula. O Cloud Run é livre para mandar outra
porta, então inicie uma segunda cópia na 9090 e leia a primeira linha de log dela:

```
ana@laptop:~/gcp$ docker run -d --name orders-9090 -p 9090:9090 -e PORT=9090 orders:1
af1f8ce7b68352110f279c2fc21741f46756e713417a54937f09619265ab2aa6
ana@laptop:~/gcp$ curl -s localhost:9090/health; echo
{"status": "ok"}
ana@laptop:~/gcp$ docker logs orders-9090
{"severity": "INFO", "message": "listening on 9090"}
{"severity": "INFO", "message": "\"GET /health HTTP/1.1\" 200 -"}
```

**O programa escutou onde mandaram**, e a linha de log diz isso no JSON que o Cloud Logging
arquivaria como entrada `INFO`. O log da requisição tem o mesmo formato.

## Dois jeitos de quebrar o contrato

O primeiro é o bug mais comum numa primeira publicação no Cloud Run: um servidor que escuta só no
endereço de loopback. O próprio `http.server` do Python facilita o teste:

```
ana@laptop:~/gcp$ docker run -d --name orders-local -p 8081:8081 orders:1 python3 -m http.server --bind 127.0.0.1 8081
f24c210cd3d194e45725958bc2f327fbbb197d678f9a6bfd22ef0abc45c4c2a2
ana@laptop:~/gcp$ curl -sS localhost:8081/; echo "exit status $?"
curl: (56) Recv failure: Connection reset by peer
exit status 56
```

**O contêiner está rodando e o servidor dele está de pé, e nada fora do contêiner o alcança.** O
Docker aceitou a conexão na porta do laptop e não achou ninguém escutando na interface externa do
contêiner, então a conexão foi reiniciada. No Cloud Run a mesma imagem sobe, falha na sondagem de
inicialização porque a porta nunca responde de fora, e a publicação é dada como falha com uma
mensagem sobre o contêiner não escutar em `PORT`. A correção é uma palavra, `0.0.0.0`, e o serviço
de pedidos já a tem.

O segundo é sobre parar. Pare o serviço de pedidos e cronometre:

```
ana@laptop:~/gcp$ time docker stop orders
orders

real	0m0.251s
user	0m0.010s
sys	0m0.022s
ana@laptop:~/gcp$ docker logs orders
{"severity": "INFO", "message": "listening on 8080"}
{"severity": "INFO", "message": "\"GET /orders HTTP/1.1\" 200 -"}
{"severity": "INFO", "message": "\"GET /health HTTP/1.1\" 200 -"}
{"severity": "INFO", "message": "\"GET /nothing HTTP/1.1\" 404 -"}
{"severity": "INFO", "message": "SIGTERM: shutting down"}
```

**Uma fração de segundo, e a última linha de log é do próprio programa**: o Docker mandou
`SIGTERM`, o tratador registrou e saiu. Agora rode a mesma imagem com o comando escrito na forma
shell, de modo que o `sh` suba primeiro e o `python3` rode debaixo dele:

```
ana@laptop:~/gcp$ docker run -d --name orders-sh -p 8080:8080 orders:1 sh -c 'python3 app.py'
8703e2ee0117a1fe9ff9920db4de53ab6434ff81eee7ca1260057e22bbb65246
ana@laptop:~/gcp$ time docker stop orders-sh
orders-sh

real	0m10.223s
user	0m0.014s
sys	0m0.019s
ana@laptop:~/gcp$ docker inspect orders-sh --format "{{.State.ExitCode}}"
137
```

**Dez segundos, e código de saída 137**, que é 128 mais 9, o número do `SIGKILL`. O `sh` era o
primeiro processo do contêiner e recebeu o `SIGTERM`; como processo 1 ele ignora o sinal e não o
repassa, então o Python nunca soube, e o Docker matou os dois quando os dez segundos acabaram. O
Cloud Run dá à instância que está parando os mesmos dez segundos e depois faz a mesma coisa. Uma
requisição em andamento nesse momento é cortada em vez de concluída, a cada redução de escala, e é
por isso que o `CMD` da seção anterior é uma lista.

## Limpando

Os contêineres parados acima ainda aparecem em `docker ps -a`; apague-os, e os dois que continuam
rodando, antes da próxima lição:

```sh
docker rm -f orders orders-sh orders-local orders-9090
```

A imagem `orders:1` fica: as lições 9 a 11 a usam.
