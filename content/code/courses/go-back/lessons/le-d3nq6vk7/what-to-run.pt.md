---
title: O que rodar, e quando
version: 1
---

Tudo, com a variável do banco definida e o cache desligado:

```
ana@vm:~/boxoffice$ time go test -count=1 ./...
ok  	example.com/boxoffice	0.238s
?   	example.com/boxoffice/cmd/seats	[no test files]
?   	example.com/boxoffice/cmd/sizes	[no test files]
?   	example.com/boxoffice/cmd/watchws	[no test files]
?   	example.com/boxoffice/internal/db	[no test files]
?   	example.com/boxoffice/internal/seatspb	[no test files]

real	0m0.902s
user	0m0.686s
sys	0m0.387s
```

Os pacotes com `[no test files]` são o código gerado e os pequenos clientes de `cmd/`, o que está certo; o
que o `?` quer dizer é que ninguém afirma o contrário. A mesma execução com o detector de corrida:

```
ana@vm:~/boxoffice$ time go test -race -count=1 ./...
ok  	example.com/boxoffice	1.285s
?   	example.com/boxoffice/cmd/seats	[no test files]
?   	example.com/boxoffice/cmd/sizes	[no test files]
?   	example.com/boxoffice/cmd/watchws	[no test files]
?   	example.com/boxoffice/internal/db	[no test files]
?   	example.com/boxoffice/internal/seatspb	[no test files]

real	0m2.117s
user	0m0.907s
sys	0m0.398s
```

**Cerca do dobro do tempo, aqui, e ainda uns dois segundos.** Instrumentar cada acesso à memória custa CPU
e memória, tipicamente várias vezes mais de cada, e para uma suíte deste tamanho o preço é nada. O detector
não é para binários de produção, onde esse custo seria pago em toda requisição; ele é para os testes, e para
rodar de vez em quando um build de homologação sob carga real.

## Três hábitos

| quando | o quê | por quê |
|---|---|---|
| a cada salvamento | `go test -run 'TestBuyTickets' .` para a parte que você está mudando | milissegundos, e o cache deixa o resto de graça |
| antes de cada commit | `go vet ./...` e `go test -race ./...` | a suíte inteira com corridas verificadas, ainda em segundos |
| na CI, a cada push | `go test -race -count=1 ./...` com `BOXOFFICE_TEST_DATABASE_URL` definida | sem cache, sem banco pulado, numa máquina que não é a sua |

A CI precisa de um PostgreSQL para onde apontar a variável. Todo serviço de CI consegue subir um ao lado do
job, e um job que não consegue é um job em que os testes da seção 07 são pulados e dizem `ok`. Um passo que
falha quando a variável está vazia é a proteção barata contra isso.

## Cobertura

```
ana@vm:~/boxoffice$ go test -count=1 -cover .
ok  	example.com/boxoffice	0.323s	coverage: 60.6% of statements
ana@vm:~/boxoffice$ go test -count=1 -coverprofile=cover.out . && go tool cover -func=cover.out | grep -w "0.0%"
ok  	example.com/boxoffice	0.231s	coverage: 60.6% of statements
example.com/boxoffice/config.go:31:	LogValue	0.0%
example.com/boxoffice/config.go:32:	String		0.0%
example.com/boxoffice/config.go:110:	LogValue	0.0%
example.com/boxoffice/grpc.go:29:	toStatus	0.0%
example.com/boxoffice/grpc.go:41:	GetEvent	0.0%
example.com/boxoffice/grpc.go:49:	Watch		0.0%
example.com/boxoffice/grpc.go:73:	Scan		0.0%
example.com/boxoffice/grpc.go:96:	logCalls	0.0%
example.com/boxoffice/grpc.go:103:	newGRPCServer	0.0%
example.com/boxoffice/main.go:19:	main		0.0%
example.com/boxoffice/middleware.go:43:	Unwrap		0.0%
example.com/boxoffice/pgstore.go:37:	List		0.0%
example.com/boxoffice/pgstore.go:49:	Get		0.0%
example.com/boxoffice/tickets.go:10:	HasTicket	0.0%
```

**Sessenta por cento das instruções do boxoffice rodaram durante os testes.** A aula 30 do go-concurrency
disse o que esse número não conta: uma linha que rodou não foi necessariamente verificada, e uma linha que
não rodou pode não importar. Leia-o ao contrário, como uma lista do que nenhum teste tocou. Um perfil
registra quais instruções rodaram, e o `go tool cover -func` o lista por função; estas são as funções em que
nenhum teste entrou:

```
ana@vm:~/boxoffice$ go test -count=1 -coverprofile=cover.out . && go tool cover -func=cover.out | grep -w "0.0%"
ok  	example.com/boxoffice	0.231s	coverage: 60.6% of statements
example.com/boxoffice/config.go:31:	LogValue	0.0%
example.com/boxoffice/config.go:32:	String		0.0%
example.com/boxoffice/config.go:110:	LogValue	0.0%
example.com/boxoffice/grpc.go:29:	toStatus	0.0%
example.com/boxoffice/grpc.go:41:	GetEvent	0.0%
example.com/boxoffice/grpc.go:49:	Watch		0.0%
example.com/boxoffice/grpc.go:73:	Scan		0.0%
example.com/boxoffice/grpc.go:96:	logCalls	0.0%
example.com/boxoffice/grpc.go:103:	newGRPCServer	0.0%
example.com/boxoffice/main.go:19:	main		0.0%
example.com/boxoffice/middleware.go:43:	Unwrap		0.0%
example.com/boxoffice/pgstore.go:37:	List		0.0%
example.com/boxoffice/pgstore.go:49:	Get		0.0%
example.com/boxoffice/tickets.go:10:	HasTicket	0.0%
```

O `main` roda toda vez que o servidor sobe, e o health check da aula 17 o exercita de fora. O `List` e o
`Get` do `pgStore` e o `HasTicket` são uma consulta cada um, que a seção 07 chamaria numa linha. Duas
entradas são promessas que ninguém confere: os métodos `LogValue` e `String` da aula 14, que escondem
segredos, e o `Unwrap`, de que os streams da aula 13 dependem e que nenhum teste alcança, porque nenhum abre
um stream. **O servidor gRPC da aula 10 é o buraco de verdade**, seis funções e uma segunda API inteira sem
teste nenhum; o `google.golang.org/grpc/test/bufconn` serve gRPC por uma conexão em memória, o que faz dele
um teste do tamanho dos da seção 04. O `go tool cover -html=cover.out` mostra o mesmo perfil sobre o código,
cada instrução colorida conforme rodou ou não.

**Suba o número testando promessas, nunca testando linhas**: um teste escrito para cobrir uma linha não
afirma nada de que alguém precisasse.
