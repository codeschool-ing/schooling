---
title: O primeiro parâmetro
version: 1
---

A lição 10 criou contextos e os cancelou dentro de uma função só. Um programa real são muitas
funções chamando umas às outras, e a imagem tentadora é que cada uma cria o contexto de que precisa,
onde precisa. **Um contexto não é criado onde é usado. Ele é criado uma vez, perto do topo de um
trabalho, e entregue a tudo o que esse trabalho chama**, para que uma decisão no topo alcance o fundo
da chamada.

A convenção está escrita na própria documentação do pacote `context`, e o `go doc` a imprime:

```
ana@vm:~/propagate$ go doc context | sed -n 33,43p
Do not store Contexts inside a struct type; instead, pass a Context
explicitly to each function that needs it. This is discussed further in
https://go.dev/blog/context-and-structs. The Context should be the first
parameter, typically named ctx:

    func DoSomething(ctx context.Context, arg Arg) error {
    	// ... use ctx ...
    }

Do not pass a nil Context, even if a function permits it. Pass context.TODO if
you are unsure about which Context to use.
```

**Primeiro parâmetro, chamado `ctx`, sempre.** Não custa nada segui-la, e ela deixa uma coisa
visível num relance: uma função cuja assinatura começa com `ctx context.Context` pode receber ordem
de parar. Uma cuja assinatura não começa assim não pode.

## Três camadas, uma decisão

O programa abaixo tem a forma de uma requisição num servidor: um topo que a recebe, um meio que monta
um relatório, um fundo que busca dados e espera algo lento. Cada programa desta lição mora num
diretório próprio dentro de `~/propagate`, porque cada um é um `package main` separado, e
`go run ./layers` compila o que está em `layers`. Este é salvo em `~/propagate/layers` como
`layers.go`:

```go
// Command layers passes one context down three calls and stops all of them at once.
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// handle is the top: it decides how long the whole request may take.
func handle(ctx context.Context, user string) error {
	ctx, cancel := context.WithTimeout(ctx, 150*time.Millisecond)
	defer cancel()
	return report(ctx, user)
}

// report is the middle: it decides nothing about time and passes ctx on.
func report(ctx context.Context, user string) error {
	for _, month := range []string{"jan", "feb", "mar"} {
		if err := fetch(ctx, user, month); err != nil {
			return fmt.Errorf("report for %s: %w", user, err)
		}
	}
	return nil
}

// fetch is the bottom: it waits on something slow, or on ctx, whichever ends first.
func fetch(ctx context.Context, user, month string) error {
	select {
	case <-time.After(60 * time.Millisecond):
		fmt.Println("fetched", user, month)
		return nil
	case <-ctx.Done():
		return fmt.Errorf("fetch %s: %w", month, ctx.Err())
	}
}

func main() {
	err := handle(context.Background(), "ana")
	fmt.Println("error:", err)
	fmt.Println("deadline exceeded:", errors.Is(err, context.DeadlineExceeded))
}
```

Cada camada tem um papel em relação ao tempo. **`handle` decide**: a requisição inteira ganha 150
milissegundos, e ele deriva um contexto que diz isso. **`report` repassa**: ele não sabe nada de
prazos e entrega `ctx` a cada chamada que faz. **`fetch` respeita**: espera a coisa lenta ou
`ctx.Done()`, o que vier primeiro. Três buscas de 60 milissegundos não cabem em 150:

```
ana@vm:~/propagate$ go run ./layers
fetched ana jan
fetched ana feb
error: report for ana: fetch mar: context deadline exceeded
deadline exceeded: true
```

Duas buscas terminaram em 120 milissegundos, e a terceira foi interrompida aos 150 por um prazo
definido duas chamadas acima. O erro se lê de fora para dentro, porque cada camada o embrulhou com
`%w` no caminho de subida: o relatório, a busca e o motivo. `errors.Is` ainda encontra
`context.DeadlineExceeded` no fundo da corrente, e é assim que quem chamou distingue "a requisição
ficou sem tempo" de "os dados estavam errados".

Repare no que a camada do meio não precisou. `report` nunca menciona um prazo, nunca chama
`ctx.Done()`, e ainda assim parou no instante em que o tempo acabou, porque a única coisa que fez com
`ctx` foi repassá-lo. **A maioria das funções de um programa bem construído é a camada do meio**, e
repassar `ctx` é tudo o que elas fazem com ele.

## Por que não numa struct

A outra regra da documentação diz para não guardar um contexto num campo de struct. O motivo é o
tempo de vida. Um contexto pertence a uma chamada: uma requisição, um trabalho. Uma struct costuma
viver mais que a chamada que a criou, um serviço ou um cliente que dura o programa inteiro, e o
contexto guardado nela passa a pertencer a uma requisição que terminou há muito tempo. Toda chamada
seguinte por essa struct seria cancelada pela requisição de outra pessoa, ou carregaria os valores
dela.

A biblioteca padrão tem uma exceção conhecida, e ela confirma a regra: um `*http.Request` carrega o
contexto daquela requisição, porque uma requisição É uma chamada. A lição 12 o usa.

`context.TODO()` é para o lugar onde um contexto deveria existir e ainda não existe, em geral
enquanto um código antigo está sendo convertido. Ele se comporta como `context.Background()`, que
nunca termina; o nome diferente marca o lugar para que um leitor, ou uma busca, o encontre.
