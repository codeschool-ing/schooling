---
title: Desligando
version: 1
---

Um servidor é parado muitas vezes na vida: um deploy, um reinício, uma máquina retirada. A parada
ingênua é o processo morrer, e toda requisição em andamento morre junto, meio pagamento, meio
upload. **Um desligamento gracioso para de aceitar trabalho novo, deixa terminar o trabalho que já
está dentro, e só então sai**, com um limite de quanto está disposto a esperar. Em Go isso são duas
peças da biblioteca padrão encontrando um contexto.

- **`signal.NotifyContext`** transforma um sinal do sistema operacional num contexto que termina.
  `SIGINT` é o que o Ctrl+C envia; `SIGTERM` é o que um gerenciador de serviços ou uma plataforma
  de contêineres envia quando quer que um processo pare.
- **`http.Server.Shutdown`** fecha a porta na hora, depois espera cada requisição ativa terminar, ou
  o contexto que recebeu terminar, o que vier primeiro.

O servidor abaixo responde cada requisição depois de um segundo. Ele é salvo em `~/cases/shutdown`
como `shutdown.go`:

```go
// Command shutdown serves until it is told to stop, then lets requests in flight finish.
package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func slow(w http.ResponseWriter, r *http.Request) {
	time.Sleep(time.Second)
	fmt.Fprintln(w, "slow answer, delivered")
	fmt.Println("server: answered", r.URL.Path)
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	srv := &http.Server{Addr: "127.0.0.1:8412", Handler: http.HandlerFunc(slow)}
	served := make(chan error, 1)
	go func() { served <- srv.ListenAndServe() }()
	fmt.Println("server: listening on", srv.Addr)

	<-ctx.Done()
	fmt.Println("server: signal received, shutting down")

	waitFor, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(waitFor); err != nil {
		fmt.Println("server: shutdown:", err)
	}
	if err := <-served; !errors.Is(err, http.ErrServerClosed) {
		fmt.Println("server:", err)
	}
	fmt.Println("server: stopped cleanly")
}
```

O `main` tem duas fases, e o contexto marca a linha entre elas. Até um sinal chegar, ele fica em
`<-ctx.Done()`. Depois, o `Shutdown` ganha um contexto próprio, de cinco segundos a partir de
agora, porque o desligamento não pode ser interrompido pelo contexto do sinal, que já terminou. O
`ListenAndServe` devolve `http.ErrServerClosed` assim que o `Shutdown` começa, que é o jeito normal
de ele terminar, então só vale imprimir um erro diferente.

Para vê-lo funcionar, uma requisição tem de estar em andamento no momento do sinal. Um script curto
faz isso: inicia o servidor, manda uma requisição lenta, interrompe o servidor enquanto a requisição
é respondida, e depois tenta uma segunda requisição. Ele é salvo ao lado como `demo.sh`:

```sh
#!/usr/bin/env bash
# demo.sh: start the server, send it a slow request, interrupt it halfway through.
./shutdown &
server=$!
sleep 0.5
curl -s 127.0.0.1:8412/report &
sleep 0.3
kill -INT "$server"
sleep 0.1
curl -sS 127.0.0.1:8412/late
wait
```

```
ana@vm:~/cases$ go build -o shutdown/shutdown ./shutdown
ana@vm:~/cases/shutdown$ bash demo.sh
server: listening on 127.0.0.1:8412
server: signal received, shutting down
curl: (7) Failed to connect to 127.0.0.1 port 8412 after 0 ms: Couldn't connect to server
server: answered /report
slow answer, delivered
server: stopped cleanly
```

Siga as linhas na ordem do tempo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O desligamento do demo.sh num eixo de tempo de 0 a 1,6 segundo. O servidor escuta desde 0. Aos 0,5 segundo chega a requisição de /report, que roda por um segundo, até 1,5. Aos 0,8 segundo chega o SIGINT e o Shutdown começa: a porta fecha na hora, então a requisição de /late aos 0,9 é recusada, enquanto /report segue até o fim. Quando /report é respondida, o Shutdown retorna e o servidor para de forma limpa.\"><defs><marker id=\"l12drain-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"65\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servidor</text><text x=\"65\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/report</text><text x=\"65\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/late</text><rect x=\"130.0\" y=\"50\" width=\"275.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"267.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escutando</text><rect x=\"405.0\" y=\"50\" width=\"240.60000000000002\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"525.3\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esvaziando: sem conexões novas</text><rect x=\"301.9\" y=\"110\" width=\"343.70000000000005\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"473.75\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">respondida por inteiro</text><rect x=\"439.4\" y=\"170\" width=\"70\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"474.4\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusada</text><path d=\"M405.0 36 V46 M405.0 82 V106 M405.0 142 V166 M405.0 202 V214\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"405.0\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">SIGINT: o Shutdown começa</text><path d=\"M645.6 82 V106 M645.6 142 V214\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"641.6\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o Shutdown retorna</text><path d=\"M130 252 H690\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12drain-paper-dim)\"></path><path d=\"M130.0 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"130.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M267.5 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"267.5\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4 s</text><path d=\"M405.0 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"405.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8 s</text><path d=\"M542.5 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"542.5\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,2 s</text><path d=\"M680.0 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,6 s</text><text x=\"65\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "O demo.sh numa linha do tempo. O Shutdown fecha a porta primeiro e depois espera as requisições que já estão dentro."}
```

A interrupção chegou 0,3 segundo depois do início da requisição de um segundo. O `Shutdown` fechou
a porta na hora, então a requisição de `/late`, um décimo de segundo depois, não encontrou ninguém
escutando, e o `curl` informou `Couldn't connect to server`. **A requisição de `/report` já estava
dentro e foi respondida por inteiro**: o servidor a registrou e o `curl` imprimiu
`slow answer, delivered`. Só então o `Shutdown` retornou e o programa imprimiu `stopped cleanly`.

Dois detalhes decidem se isso funciona em produção. O limite de cinco segundos é uma promessa a
quem enviou o sinal: uma plataforma que envia `SIGTERM` espera só um tanto antes de matar o processo
de vez, então o limite tem de ser menor que essa espera. E os handlers precisam olhar
`r.Context()` quando o trabalho é longo, como a seção 02 mostrou, porque o `Shutdown` espera por
eles; ele não os cancela.
