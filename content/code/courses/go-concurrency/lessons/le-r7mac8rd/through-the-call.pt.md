---
title: Pela chamada inteira
version: 1
---

Repassar `ctx` sem mudança é quase tudo o que um programa faz com ele. O resto é **derivar**: uma
função que precisa de um limite mais apertado, ou de um jeito de parar os próprios ajudantes, cria
um filho do contexto que recebeu e repassa o filho. A lição 10 mostrou `WithTimeout` e `WithCancel`
uma vez cada. Usados em cadeia, eles formam uma árvore, e a árvore tem regras fáceis de adivinhar
errado.

## Um filho só pode viver menos

O palpite errado comum é que um filho com timeout maior que o do pai fica com o maior. O programa
abaixo deriva dois filhos de uma raiz que tem 100 milissegundos: um pede um segundo inteiro, o outro
é cancelado à mão. Ele é salvo em `~/propagate/tree` como `tree.go`:

```go
// Command tree derives contexts from a context and shows what each one inherits.
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	start := time.Now()
	root, cancelRoot := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancelRoot()

	child, cancelChild := context.WithTimeout(root, time.Second)
	defer cancelChild()
	sibling, cancelSibling := context.WithCancel(root)

	rootDeadline, _ := root.Deadline()
	childDeadline, _ := child.Deadline()
	fmt.Println("child's deadline is root's:", childDeadline.Equal(rootDeadline))

	cancelSibling()
	fmt.Println("sibling:", sibling.Err())
	fmt.Println("root:   ", root.Err())
	fmt.Println("child:  ", child.Err())

	<-child.Done()
	fmt.Printf("child done after %v: %v\n", time.Since(start).Round(10*time.Millisecond), child.Err())
}
```

```
ana@vm:~/propagate$ go run ./tree
child's deadline is root's: true
sibling: context canceled
root:    <nil>
child:   <nil>
child done after 100ms: context deadline exceeded
```

Três regras, uma por linha de saída:

- **O prazo de um filho é o mais cedo entre o dele e o do pai.** `child` pediu um segundo e informa
  o prazo de root no lugar, e terminou aos 100 milissegundos com `context deadline exceeded`, o
  motivo do pai.
- **Cancelar um filho não toca no pai nem nos irmãos.** `sibling` foi cancelado, e `root` e `child`
  ainda responderam `<nil>` logo depois.
- **Um fim desce pela árvore e nunca sobe.** O que termina um contexto termina tudo o que foi
  derivado dele, em qualquer profundidade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os contextos do tree.go como uma árvore. context.Background no topo; abaixo dele root, com timeout de 100 milissegundos; abaixo de root dois filhos: child, que pediu um segundo mas herda o prazo de root, aos 100 milissegundos, e sibling, cancelado à mão. Cancelar sibling parou em sibling: root e child seguiram. O prazo de root alcançou os dois filhos.\"><defs><marker id=\"l11tree-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11tree-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">context.Background()</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nunca termina</text><rect x=\"250\" y=\"100\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">root</text><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">prazo em 100 ms</text><rect x=\"90\" y=\"196\" width=\"220\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">child</text><text x=\"200\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pediu 1 s</text><text x=\"200\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">termina aos 100 ms, com root</text><rect x=\"410\" y=\"196\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sibling</text><text x=\"520\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cancelado à mão</text><path d=\"M360 62 V98\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11tree-wire)\"></path><path d=\"M330 142 L230 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11tree-phosphor)\"></path><path d=\"M390 142 L490 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11tree-phosphor)\"></path><text x=\"80\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um fim desce</text><text x=\"80\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nunca sobe nem vai para o lado</text></svg>", "caption": "Os contextos do tree.go. Um contexto termina quando o pai termina ou quando chega o motivo dele, o que vier primeiro; o fim dele só alcança o que foi derivado dele."}
```

É isso que torna derivar seguro. Uma função pode impor um limite menor à própria parte do trabalho,
ou cancelar os ajudantes que iniciou, e nada do que ela faz consegue encurtar o trabalho de quem a
chamou nem o de um vizinho. O inverso também vale: nenhum filho estende o que quem chamou permitiu.

**Todo contexto derivado vem com uma função de cancelamento, e `defer cancel()` vai na linha
seguinte.** Chamá-la libera o que o runtime guarda para acompanhar o filho, mesmo quando o prazo o
terminaria de qualquer jeito; o `go vet` aponta uma função de cancelamento descartada em algum
caminho, porque o filho então vive até o pai terminar.

## Duas ferramentas para as bordas

Duas funções do pacote `context` cuidam de trabalho que fica na fronteira de uma requisição. O
programa abaixo usa as duas, salvo em `~/propagate/detach` como `detach.go`:

```go
// Command detach runs code when a context ends, and keeps one piece of work going past it.
package main

import (
	"context"
	"fmt"
)

type requestID struct{}

func main() {
	ctx := context.WithValue(context.Background(), requestID{}, "req-7f3a")
	ctx, cancel := context.WithCancel(ctx)

	closed := make(chan struct{})
	stop := context.AfterFunc(ctx, func() {
		fmt.Println("AfterFunc: request over, closing its connection")
		close(closed)
	})
	defer stop()

	audit := context.WithoutCancel(ctx)

	cancel()
	<-closed
	fmt.Println("ctx:  ", ctx.Err())
	fmt.Println("audit:", audit.Err(), "| request", audit.Value(requestID{}))
	fmt.Println("stop after the fact:", stop())
}
```

```
ana@vm:~/propagate$ go run ./detach
AfterFunc: request over, closing its connection
ctx:   context canceled
audit: <nil> | request req-7f3a
stop after the fact: false
```

**`context.AfterFunc` roda uma função, numa goroutine própria, quando o contexto termina.** Serve
para código que precisa reagir a um cancelamento sem uma goroutine sua parada num `select` à espera
dele: fechar uma conexão, liberar um recurso. A função que ele devolve, `stop`, desfaz o combinado se
o trabalho terminou antes. Aqui ela chegou tarde e disse isso com `false`: a função já tinha rodado.
O programa a esperou num canal, `closed`, e não com uma pausa, porque a lição 1 mostrou que uma pausa
não promete nada.

**`context.WithoutCancel` mantém os valores e descarta o fim.** `audit` ainda responde o id da
requisição, `req-7f3a`, e o `Err` dele continua `<nil>` depois que a requisição foi cancelada. Serve
para o pequeno trabalho que precisa terminar mesmo quando a requisição não termina, como gravar o
registro de auditoria de uma requisição que o cliente abandonou. Usado em qualquer outro lugar, ele
desliga justamente o mecanismo que esta lição monta, então pertence à borda de uma requisição e a
nenhum ponto do meio.
