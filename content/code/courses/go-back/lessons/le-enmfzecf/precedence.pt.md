---
title: Qual padrão vence
version: 1
---

No programa anterior, `/events/latest` casou dois padrões, `GET /events/{id}` e
`GET /events/latest`, e o segundo respondeu. **A ordem em que foram registrados não teve nada a ver
com isso.** Muitos roteadores tentam as rotas de cima para baixo e param no primeiro casamento,
então mover uma linha muda o que uma requisição alcança. O `ServeMux` não, e a regra que ele usa no
lugar disso é curta.

> **O padrão mais específico vence.** Um padrão é mais específico que outro quando casa um
> subconjunto estrito das requisições que o outro casa.

`GET /events/latest` casa um caminho. `GET /events/{id}` casa esse caminho e todo outro segmento
único depois de `/events/`. O primeiro casa menos, então é mais específico, então vence, onde quer
que esteja no arquivo. O mesmo raciocínio ordena o resto:

| estes dois | o vencedor | porque |
|---|---|---|
| `GET /events/latest` contra `GET /events/{id}` | `/events/latest` | um segmento literal casa menos que um curinga |
| `GET /events/{id}` contra `/events/` | `GET /events/{id}` | ele nomeia um método, e casa um segmento em vez de uma subárvore inteira |
| `api.example.com/events` contra `/events` | o que tem host | só casa requisições mandadas para aquele nome |

## Dois padrões que se sobrepõem e nenhum vence

Às vezes nenhum de dois padrões casa um subconjunto do outro. Cada um casa caminhos que o outro não
casa, e os dois casam alguns caminhos em comum:

```go
// conflict/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events/{id}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "one event")
	})
	mux.HandleFunc("GET /{kind}/42", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "anything numbered 42")
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

Qual deveria alcançar `/events/42`? Não há resposta que não seja arbitrária, e **o `ServeMux` se
recusa a escolher. Ele entra em pânico quando o segundo padrão é registrado**, antes de o servidor
abrir a porta:

```
ana@vm:~/conflict$ go run .
panic: pattern "GET /{kind}/42" (registered at /home/ana/conflict/main.go:15) conflicts with pattern "GET /events/{id}" (registered at /home/ana/conflict/main.go:12):
	GET /{kind}/42 and GET /events/{id} both match some paths, like "/events/42".
	But neither is more specific than the other.
	GET /{kind}/42 matches "/kind/42", but GET /events/{id} doesn't.
	GET /events/{id} matches "/events/id", but GET /{kind}/42 doesn't.

goroutine 1 [running]:
net/http.(*ServeMux).register(...)
	/usr/local/go/src/net/http/server.go:2957
net/http.(*ServeMux).HandleFunc(0x0?, {0x695b14?, 0x401320?}, 0xfb4ac95e0d8?)
	/usr/local/go/src/net/http/server.go:2931 +0x5e
main.main()
	/home/ana/conflict/main.go:15 +0x59
exit status 2
```

**Leia as cinco primeiras linhas e pare.** Elas nomeiam os dois padrões com o arquivo e a linha que
registrou cada um, dão um caminho que os dois casam e depois provam que nenhum é mais específico,
com um caminho de cada lado que só ele casa. A pilha abaixo delas é o rastro habitual de um pânico,
e aqui não acrescenta nada que a mensagem já não tenha dito.

Pânico parece exagero para um erro de roteamento, e é a escolha gentil. **O programa falha na
primeira vez que roda, na sua máquina, com as duas linhas nomeadas.** A alternativa é um roteador
que manda `/events/42` em silêncio para o handler que preferir, e um relato de bug semanas depois de
alguém que viu a página errada. O conserto é tornar um padrão mais específico, ou renomear um
caminho para os dois pararem de se sobrepor.

## Quando código antigo se comporta diferente

Um módulo cujo `go.mod` diz `go 1.21` ou anterior recebe o mux antigo, em que um método ou uma `{`
num padrão é só parte de um caminho literal. O mesmo código compilado com uma linha `go 1.22` ou
posterior recebe o novo. O comportamento antigo também pode ser forçado com a configuração
`GODEBUG=httpmuxgo121=1`, feita para programas que registravam caminhos com chaves e precisam de
tempo para mudar. **Se um padrão com método responde 404 a tudo, olhe primeiro a linha `go` do
`go.mod`.**
