---
title: Handler é qualquer coisa com ServeHTTP
version: 1
---

A função da seção anterior parecia a ideia inteira, e é metade dela. **O que o `net/http` de fato
roteia é uma interface com um método**:

```go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}
```

Qualquer tipo com esse método é um handler, pela regra que a aula 27 do `go` ensinou para toda
interface: nada é declarado, o conjunto de métodos basta. Uma função não é um tipo com métodos,
então o pacote traz um adaptador, `http.HandlerFunc`, que é um tipo função cujo `ServeHTTP` chama a
própria função. **O `HandleFunc` é o `Handle` com essa conversão feita por você.** O programa abaixo
usa as três grafias:

```schooling-example
{
  "language": "go",
  "file": "counter/main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"log\"\n\t\"net/http\"\n\t\"sync\"\n)\n\n",
      "note": "O `sync` está aqui porque o handler abaixo guarda uma contagem, e uma contagem compartilhada entre requisições precisa de um lock."
    },
    {
      "code": "// visits counts the requests it has answered.\ntype visits struct {\n\tmu sync.Mutex\n\tn  int\n}\n\n",
      "note": "**Um handler pode carregar estado.** Uma struct é o lugar de tudo que dura mais que uma requisição: um contador aqui, um pool do banco de dados da aula 6 em diante."
    },
    {
      "code": "func (v *visits) ServeHTTP(w http.ResponseWriter, r *http.Request) {\n\tv.mu.Lock()\n\tv.n++\n\tn := v.n\n\tv.mu.Unlock()\n\tfmt.Fprintf(w, \"visit %d\\n\", n)\n}\n\n",
      "note": "**Este método é o que faz de `*visits` um handler.** O lock não é enfeite: o `net/http` roda cada requisição numa goroutine própria, então duas requisições podem chegar a `v.n++` no mesmo instante. O valor é copiado sob o lock e escrito depois dele, para que um cliente lento nunca segure o lock enquanto a resposta atravessa a rede."
    },
    {
      "code": "func hello(w http.ResponseWriter, r *http.Request) {\n\tfmt.Fprintln(w, \"hello\")\n}\n\n",
      "note": "Uma função comum com a assinatura certa. Sozinha ela não é handler, porque não tem métodos."
    },
    {
      "code": "func main() {\n\tmux := http.NewServeMux()\n\tmux.Handle(\"/visits\", &visits{})\n\tmux.Handle(\"/hello\", http.HandlerFunc(hello))\n\tmux.HandleFunc(\"/hi\", hello)\n\tlog.Fatal(http.ListenAndServe(\"localhost:8080\", mux))\n}\n",
      "note": "**Um mux do próprio programa**, passado ao `ListenAndServe` onde a seção anterior passou `nil`. `/visits` recebe a struct; `/hello` recebe a função convertida à mão num `http.HandlerFunc`; `/hi` recebe a mesma função pelo `HandleFunc`, que faz a conversão por você. Os dois últimos são uma coisa escrita duas vezes."
    }
  ]
}
```

Rode e pergunte cada caminho:

```
ana@vm:~/counter$ curl -s localhost:8080/visits; curl -s localhost:8080/visits; curl -s localhost:8080/visits
visit 1
visit 2
visit 3
ana@vm:~/counter$ curl -s localhost:8080/hello; curl -s localhost:8080/hi
hello
hello
ana@vm:~/counter$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:49 GMT
Content-Length: 19

404 page not found
```

A contagem sobreviveu entre requisições porque **um único valor `visits` atendeu as três**:
`&visits{}` foi criado uma vez, no `main`, e o mux guarda um ponteiro para ele. Um caminho para o
qual o mux não tem padrão recebe o `404 page not found` do próprio pacote, com um cabeçalho pedindo
ao navegador que não adivinhe o tipo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Três requisições curl chegam ao mesmo tempo. O http.Server dá a cada uma uma goroutine própria, e as três goroutines chamam o mesmo mux, que chama o mesmo valor visits. O contador dentro dele é compartilhado por todas.\"><defs><marker id=\"gb-l1-shared-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"170\" y=\"12\" width=\"240\" height=\"214\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"290\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">http.Server</text><rect x=\"20\" y=\"40\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl /visits</text><rect x=\"190\" y=\"40\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goroutine da requisição 1</text><path d=\"M 140 60 L 188 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><path d=\"M 390 60 L 448 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"20\" y=\"105\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl /visits</text><rect x=\"190\" y=\"105\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goroutine da requisição 2</text><path d=\"M 140 125 L 188 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><path d=\"M 390 125 L 448 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"20\" y=\"170\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl /visits</text><rect x=\"190\" y=\"170\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goroutine da requisição 3</text><path d=\"M 140 190 L 188 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><path d=\"M 390 190 L 448 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"450\" y=\"100\" width=\"100\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mux</text><text x=\"500\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um para todas</text><path d=\"M 550 125 L 578 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"580\" y=\"90\" width=\"105\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"632\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*visits</text><text x=\"632\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">n, compartilhado</text><text x=\"632\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">atrás de mu</text></svg>", "caption": "Uma goroutine por requisição, um mux e um valor visits para todas. O valor que elas compartilham é o motivo de o ServeHTTP pegar um lock."}
```

## Por que o lock, se as requisições vieram uma de cada vez

Estas três requisições vieram mesmo uma depois da outra, e o programa teria impresso o mesmo sem o
mutex. **Um programa que só está correto quando as requisições chegam em fila é um programa
esperando uma noite movimentada.** A aula 16 do `go-concurrency` mostrou o detector de corrida
pegando exatamente esse formato, um contador sem proteção escrito por várias goroutines, e a aula
15 deste curso o roda contra um handler.

## Um mux também é handler

`http.NewServeMux()` devolve um `*ServeMux`, e o `ServeMux` tem um método `ServeHTTP`: ele olha a
requisição, escolhe o handler cujo padrão casa e chama o `ServeHTTP` desse handler. **Então um mux
pode ser registrado dentro de outro mux, e qualquer coisa que envolve um handler pode envolver um
mux inteiro.** Esse fato é a base da aula 2: um middleware é um handler que guarda outro handler, e
o servidor só enxerga o mais de fora.
