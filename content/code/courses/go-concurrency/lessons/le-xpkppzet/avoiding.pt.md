---
title: Dando a toda goroutine uma saída
version: 1
---

Achar vazamentos é o recurso de reserva. **A regra que os evita é a posse: quem inicia uma goroutine
decide como ela vai terminar, no momento de iniciá-la**, e escreve isso no código em vez de torcer.
Na prática a resposta é uma de três: o trabalho da goroutine tem um fim natural que não pode
bloquear, alguém fecha o canal que ela lê, ou ela recebe a ordem de parar. Os dois vazamentos da
seção 02 ficam com uma cada.

## Espaço para toda resposta

O `first.go` vazava porque dois remetentes não tinham de quem receber. Se o canal tem espaço para
toda resposta, nenhum envio espera. Três servidores, três lugares no buffer, e os remetentes que
perdem a corrida deixam a resposta no buffer e retornam. O buffer é recolhido junto com o canal
quando ninguém mais se refere a ele. Salvo como `buffered.go`:

```go
// Command buffered is first.go with room in the channel for every answer.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

func first() string {
	const servers = 3
	ch := make(chan string, servers)
	for s := 1; s <= servers; s++ {
		go func() { ch <- ask(s) }()
	}
	return <-ch
}

func main() {
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines after 100 calls:", runtime.NumGoroutine())
}
```

```
ana@vm:~/leaks$ go run buffered.go
goroutines after 100 calls: 1
```

Uma goroutine, `main`, depois de cem chamadas. **A única mudança é o `3` no `make`**, escrito como
uma constante ao lado do laço com que ele tem de bater. Esse acoplamento é a parte frágil: alguém
acrescenta um quarto servidor, esquece o buffer, e o vazamento volta, uma goroutine por chamada. A
lição 4 é inteira sobre buffers.

## Fechar em todo caminho

O `early.go` vazava porque um caminho pulava o `close(logs)`. **O `defer` roda em toda saída de uma
função**, o `return` antecipado incluído, então um `close` adiado logo depois do `make` não pode ser
pulado. Salvo como `done.go`:

```go
// Command done is early.go with a way for the helper goroutine to hear that it is over.
package main

import (
	"errors"
	"fmt"
	"runtime"
	"time"
)

func process(lines []string) error {
	logs := make(chan string)
	defer close(logs)
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
ana@vm:~/leaks$ go run done.go
goroutines after 100 calls: 1
```

`defer close(logs)` fica duas linhas depois da criação do canal, e o `close` explícito do fim sumiu.
Os dois caminhos agora fecham o canal, as duas auxiliares veem o seu `for range` acabar, e a
contagem fica em um.

## Mandada parar

A terceira saída é a goroutine escutar um sinal além do seu trabalho. A forma clássica em Go é um
canal chamado `done` que o dono fecha quando não quer mais nada; um `select`, o assunto da lição 5,
espera o envio e o `done` ao mesmo tempo, e ganha o que ficar pronto primeiro. Um canal fechado fica
pronto para todos os receptores de uma vez, então um único `close` para qualquer número de
goroutines. O pacote `context` da lição 10 é esse padrão com nome padronizado, prazo e motivo, e da
lição 10 em diante o curso o usa no lugar de um `done` feito à mão.

## Uma lista para todo `go`

Antes de escrever `go`, responda três perguntas, e se uma ficar sem resposta a goroutine pode vazar:

1. **Em que ela bloqueia?** Um envio, um recebimento, uma trava, um `Wait`.
2. **Quem faz essa operação terminar?** Um receptor que com certeza estará lá, um `close` que roda em
   todo caminho, um buffer com espaço.
3. **O que acontece se quem chamou desistir cedo?** Um erro, um prazo, um pânico: a goroutine ainda
   tem saída?
