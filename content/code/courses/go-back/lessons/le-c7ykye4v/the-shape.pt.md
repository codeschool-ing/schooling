---
title: Um handler que guarda um handler
version: 1
---

Há trabalho que pertence a toda requisição e não a uma rota: escrever uma linha no log,
transformar um pânico num 500, responder às perguntas de um navegador sobre para onde ele pode
mandar requisições, conferir quem está pedindo. Escrito dentro de cada handler, ele é copiado uma
dúzia de vezes e esquecido na décima terceira. **Um middleware é esse trabalho escrito uma vez,
como um handler que guarda outro handler.** Ele faz a sua parte, chama o que guarda e pode fazer
mais depois que esse outro retorna.

Em Go não existe um tipo de framework para isso. O formato é uma função de handler para handler:

```go
func(next http.Handler) http.Handler
```

Ela recebe o handler a envolver, `next`, e devolve um handler novo cujo `ServeHTTP` decide se,
quando e como chamar `next.ServeHTTP`. A seção 04 da aula 1 terminou no fato que faz isso
funcionar: **um mux também é handler**, então o roteador inteiro pode ser o `next` de alguma coisa.

## Vendo a ordem

Este programa envolve um mux duas vezes, e cada envoltório imprime na entrada e na saída:

```go
// wrap/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

// announce returns a middleware that prints its name on the way in and on
// the way out of every request.
func announce(name string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			fmt.Println(name, "in")
			next.ServeHTTP(w, r)
			fmt.Println(name, "out")
		})
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("  the handler")
		fmt.Fprintln(w, "hello")
	})
	var h http.Handler = mux
	h = announce("inner")(h)
	h = announce("outer")(h)
	log.Fatal(http.ListenAndServe("localhost:8080", h))
}
```

`h` começa como o mux. `announce("inner")` o envolve, e `announce("outer")` envolve o resultado,
então o servidor recebe o de fora. Rode, pergunte duas vezes e leia o que o servidor imprimiu:

```
ana@vm:~/wrap$ curl -s localhost:8080/hello
hello
ana@vm:~/wrap$ curl -s localhost:8080/nothing
404 page not found
ana@vm:~/wrap$ go run .
outer in
inner in
  the handler
inner out
outer out
outer in
inner in
inner out
outer out
```

**O último envoltório aplicado é o primeiro a rodar e o último a terminar.** Uma requisição entra
por todas as camadas e volta por elas na ordem inversa, como uma pilha de chamadas, porque é isso
que ela é: cada `ServeHTTP` chama o próximo e espera por ele. A segunda requisição não achou rota,
e os dois middlewares rodaram assim mesmo em volta do 404 do mux. **Um middleware envolve tudo o
que está dentro dele, inclusive as respostas que ninguém escreveu.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Três caixas lado a lado: announce outer, announce inner e o mux. Setas marcadas entra vão de outer para inner e para o mux, onde o handler roda; setas marcadas sai voltam do mux para inner e para outer. Os números dão a ordem em que as linhas foram impressas: 1 outer in, 2 inner in, 3 o handler, 4 inner out, 5 outer out.\"><defs><marker id=\"gb-l2-onion-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"40\" width=\"150\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">announce(\"outer\")</text><rect x=\"230\" y=\"40\" width=\"150\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">announce(\"inner\")</text><rect x=\"420\" y=\"40\" width=\"150\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">mux</text><text x=\"115\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1 outer in</text><text x=\"305\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2 inner in</text><text x=\"495\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 o handler</text><text x=\"305\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4 inner out</text><text x=\"115\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5 outer out</text><path d=\"M 190 110 L 228 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><path d=\"M 380 110 L 418 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><path d=\"M 420 160 L 382 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><path d=\"M 228 160 L 192 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><text x=\"209\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entra</text><text x=\"209\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sai</text><text x=\"399\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entra</text><text x=\"399\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sai</text></svg>", "caption": "O último envoltório aplicado é o mais de fora: uma requisição entra por todas as camadas e volta por elas na ordem inversa."}
```

## Uma função auxiliar para a ordem

Envolver à mão se lê de trás para a frente, o de dentro primeiro, e o boxoffice vai envolver quatro
vezes. Uma função pequena os põe na ordem de leitura, o primeiro mais de fora:

```go
func chain(h http.Handler, mws ...func(http.Handler) http.Handler) http.Handler {
	for _, mw := range slices.Backward(mws) {
		h = mw(h)
	}
	return h
}
```

`slices.Backward` percorre a lista a partir do fim, então o último middleware nomeado é aplicado
primeiro e fica mais por dentro. `chain(mux, a, b)` é `a(b(mux))`: uma requisição encontra `a`,
depois `b`, depois o mux.

## O que o resto desta aula constrói

As seções 03 a 06 acrescentam cada uma um middleware ao boxoffice, num arquivo próprio, e a seção
07 liga todos eles ao servidor e o inicia. **As transcrições das seções 03 a 06 vêm desse servidor
pronto**, porque cada uma imprime o mesmo com ou sem os middlewares que vêm depois; digite cada
arquivo quando chegar a ele e rode o conjunto no final.
