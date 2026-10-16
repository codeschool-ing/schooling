---
title: Como uma goroutine fica para trás
version: 1
---

Uma goroutine que terminou o seu trabalho retorna, e o runtime recolhe a pilha dela. **Uma
goroutine bloqueada para sempre nunca retorna, e nada a recolhe.** Ela segura a pilha, tudo aquilo
para que as variáveis dela apontam e uma linha em toda contagem que o runtime mantém. Isso é um
vazamento de goroutine, e o programa continua funcionando perfeitamente enquanto ele acontece, e é
por isso que vazamentos são descobertos em produção por um gráfico que só sobe.

Go não tem como parar uma goroutine de fora. Não existe um identificador para matar, e uma goroutine
só termina retornando. Então **toda goroutine que você inicia precisa de um jeito de terminar que não
dependa de sorte**, e os dois programas abaixo são os dois jeitos mais comuns de esquecer isso.

## Um remetente que ninguém escuta

O primeiro programa faz a mesma pergunta a três servidores e fica com a resposta que voltar
primeiro. Os servidores são de mentira, um `time.Sleep` que cresce com o número do servidor, então a
lição não precisa de rede. `runtime.NumGoroutine` informa quantas goroutines existem naquele
momento, `main` incluída. Salvo como `first.go`:

```go
// Command first asks three slow servers and keeps the fastest answer.
package main

import (
	"fmt"
	"runtime"
	"time"
)

// ask stands in for a request to a server: server n takes n*10 ms to answer.
func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

// first returns whichever answer arrives first.
func first() string {
	ch := make(chan string)
	for s := 1; s <= 3; s++ {
		go func() { ch <- ask(s) }()
	}
	return <-ch
}

func main() {
	fmt.Println(first())
	fmt.Println("goroutines at start:", runtime.NumGoroutine())
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines after 100 more calls:", runtime.NumGoroutine())
}
```

```
ana@vm:~/leaks$ go run first.go
answer from server 1
goroutines at start: 3
goroutines after 100 more calls: 203
```

A resposta está certa e veio rápido, e o programa está quebrado. **Depois de uma chamada já existem
três goroutines onde deveria haver uma**, e cem chamadas depois existem 203. Cada chamada de `first`
deixou duas goroutines para trás.

O motivo está em `first`. Ela recebe uma vez, de um canal sem buffer, e retorna. O servidor 1
responde depois de 10 milissegundos, a goroutine dele entrega a string, e `first` já foi embora. Os
servidores 2 e 3 terminam a espera um pouco depois e tentam enviar em `ch`. Um envio sem buffer
espera um receptor, como a lição 4 mostrou, e o único receptor já retornou. Ninguém vai ler `ch` de
novo, então esses dois envios esperam para sempre:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Uma chamada de first. Três goroutines, os servidores 1, 2 e 3, enviam no canal sem buffer ch. A função first recebe a resposta do servidor 1 e retorna. Os servidores 2 e 3 chegam ao envio depois, sem nenhum receptor, e esperam para sempre: duas goroutines vazadas por chamada.\"><defs><marker id=\"l06leak-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06leak-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">first()</text><text x=\"105\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">recebe uma vez, retorna</text><rect x=\"270\" y=\"110\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ch</text><path d=\"M268 135 H192\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06leak-phosphor)\"></path><text x=\"325\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum receptor daqui em diante</text><rect x=\"460\" y=\"40\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">go func() { ch &lt;- ask(s) }</text><text x=\"580\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">após 10 ms: enviou, retornou</text><path d=\"M458 67 L382 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06leak-phosphor)\"></path><rect x=\"460\" y=\"125\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">go func() { ch &lt;- ask(s) }</text><text x=\"580\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">após 20 ms: bloqueada no envio</text><path d=\"M458 152 L382 135\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#l06leak-amber)\"></path><rect x=\"460\" y=\"210\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">go func() { ch &lt;- ask(s) }</text><text x=\"580\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">após 30 ms: bloqueada no envio</text><path d=\"M458 237 L382 135\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#l06leak-amber)\"></path><rect x=\"20\" y=\"222\" width=\"360\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"200\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">duas goroutines que nunca retornam</text></svg>", "caption": "Uma chamada de first: a resposta mais rápida é aceita, e os dois remetentes mais lentos esperam num canal que ninguém vai ler de novo."}
```

## Um receptor que ninguém fecha

A imagem espelhada é uma goroutine esperando para receber. O segundo programa entrega linhas de
texto a uma goroutine auxiliar, que faz as vezes de uma que escreve um log. Um `for range` sobre um
canal termina quando o canal é fechado, como a lição 3 mostrou, e `process` o fecha no fim. Salvo
como `early.go`:

```go
// Command early hands lines to a helper goroutine and gives up on a bad one.
package main

import (
	"errors"
	"fmt"
	"runtime"
	"time"
)

// process sends each line to a goroutine that counts characters,
// as a stand-in for one that writes a log.
func process(lines []string) error {
	logs := make(chan string)
	go func() {
		chars := 0
		for l := range logs {
			chars += len(l)
		}
		_ = chars
	}()
	for _, l := range lines {
		if l == "" {
			return errors.New("empty line")
		}
		logs <- l
	}
	close(logs)
	return nil
}

func main() {
	good := []string{"one", "two", "three"}
	bad := []string{"one", "", "three"}
	for range 50 {
		process(good)
		process(bad)
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines after 100 calls:", runtime.NumGoroutine())
}
```

```
ana@vm:~/leaks$ go run early.go
goroutines after 100 calls: 51
```

Cem chamadas, metade delas com uma linha vazia, e 51 goroutines: `main` e cinquenta auxiliares.
**Toda chamada que retornou cedo deixou a sua auxiliar para trás**, porque o `return` antecipado
pula o `close(logs)`, e um `for range` sobre um canal que nunca é fechado espera para sempre. As
cinquenta chamadas que chegaram ao fim fecharam o canal, e as auxiliares delas terminaram.

Essa é a forma da maioria dos vazamentos reais. O caminho feliz está correto, alguém acrescentou uma
verificação de erro meses depois, e o novo `return` pulou a linha que deixava a goroutine ir embora.
Nada falhou; a contagem subiu um por erro.

## Quanto custa um vazamento

Uma goroutine bloqueada não usa processador. O que ela segura é memória: a pilha, que começa com
poucos kilobytes e cresce com o que ela estava fazendo, e tudo o que as variáveis dela ainda
alcançam, que o coletor de lixo não pode liberar enquanto a goroutine existir. Aqui, as strings de
`ask` e o slice de linhas. Um vazamento de duas goroutines por requisição é invisível num teste e,
a algumas centenas de requisições por segundo, é um serviço que fica sem memória num fim de semana.
