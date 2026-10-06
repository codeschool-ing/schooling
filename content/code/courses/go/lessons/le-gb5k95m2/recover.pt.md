---
title: recover, e os dois lugares onde ele cabe
version: 1
---

`recover` é o único jeito de parar um panic, e a leitura tentadora é que ele seria o `catch` de Go:
basta envolver qualquer coisa arriscada com ele e seguir em frente. **Ele não é um `catch`, e não
foi feito para ser usado como um.** Funciona numa posição só, não retoma o código que entrou em
panic, e os lugares onde ele cabe se resumem a dois. A documentação diz qual é a posição:

```
ana@vm:~/panic-sum$ go doc builtin.recover
package builtin // import "builtin"

func recover() any
    The recover built-in function allows a program to manage behavior of
    a panicking goroutine. Executing a call to recover inside a deferred
    function (but not any function called by it) stops the panicking sequence
    by restoring normal execution and retrieves the error value passed to the
    call of panic. If recover is called outside the deferred function it will
    not stop a panicking sequence. In this case, or when the goroutine is not
    panicking, recover returns nil.

    Prior to Go 1.21, recover would also return nil if panic is called with a
    nil argument. See [panic] for details.

```

**`recover` só para um panic quando uma função adiada o chama diretamente.** A seção 03 mostrou por
que esse é o lugar: enquanto um panic está de saída, as chamadas adiadas são o único código que
ainda roda. Em qualquer outro lugar, `recover` devolve `nil` e não faz nada. Quando ele para um
panic, devolve o valor que foi passado a `panic`, e a função que o adiou então retorna a quem a
chamou como se nada tivesse acontecido. O resto daquela função, depois da linha que entrou em
panic, nunca roda.

## Dentro de um pacote: panic para sair, um erro na porta

O primeiro lugar é um pacote que entra em panic de propósito, dentro de si mesmo, para sair de um
código aninhado muitas chamadas abaixo, e transforma o panic de volta num `error` antes que ele
chegue a quem o chamou. Aqui está ele no menor tamanho que ainda mostra a forma. `Sum`, em
`~/panic-sum`, soma os números de um texto como `"1+2+3"`, e o helper `number` desiste por meio de
um panic em vez de devolver um erro:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command sum adds the numbers in a text like \"1+2+3\".\npackage main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n\t\"strings\"\n)\n\n// parseError carries a failure out of the helpers. It never leaves Sum.\ntype parseError struct {\n\terr error\n}\n",
      "note": "**Um tipo do próprio pacote, que não serve para nada além dos seus panics.** Ele guarda um `error` comum. Como ninguém fora do pacote consegue criar um, um `parseError` que chega ao recover lá embaixo só pode ter vindo de `fail`."
    },
    {
      "code": "\nfunc fail(format string, args ...any) {\n\tpanic(parseError{fmt.Errorf(format, args...)})\n}\n",
      "note": "**`fail` monta um erro e entra em panic com ele, embrulhado em `parseError`.** Onde quer que um helper o chame, o helper para ali, e o mesmo vale para toda função entre ele e `Sum`."
    },
    {
      "code": "\nfunc number(s string) int {\n\tif s == \"\" {\n\t\tfail(\"empty term\")\n\t}\n\tn, err := strconv.Atoi(s)\n\tif err != nil {\n\t\tfail(\"%q is not a number\", s)\n\t}\n\treturn n\n}\n",
      "note": "Um helper que devolve só o número. As duas falhas dele saem por `fail`, então a assinatura dele não carrega `error`, nem carregariam as dos helpers que o chamassem num parser maior."
    },
    {
      "code": "\n// Sum answers with an error, never with a panic.\nfunc Sum(text string) (total int, err error) {\n\tdefer func() {\n\t\tr := recover()\n\t\tif r == nil {\n\t\t\treturn\n\t\t}\n\t\tpe, ok := r.(parseError)\n\t\tif !ok {\n\t\t\tpanic(r)\n\t\t}\n\t\ttotal, err = 0, pe.err\n\t}()\n",
      "note": "**A porta, e o recover que a guarda.** `recover()` devolve `nil` quando nada entrou em panic. Senão, a type assertion da lição 29 pergunta se o valor é um `parseError`: se não for, é o bug de alguém e continua em panic; se for, os resultados nomeados passam a ser `0` e o erro de dentro."
    },
    {
      "code": "\tfor _, term := range strings.Split(text, \"+\") {\n\t\ttotal += number(term)\n\t}\n\treturn total, nil\n}\n",
      "note": "O trabalho em si, escrito como se nada pudesse falhar. `strings.Split` corta o texto em cada `+`, então `\"1++3\"` dá um termo vazio no meio."
    },
    {
      "code": "\nfunc main() {\n\tfor _, text := range []string{\"1+2+3\", \"1++3\", \"1+two\"} {\n\t\tfmt.Println(Sum(text))\n\t}\n}\n",
      "note": "Três textos, um bom e dois ruins. `fmt.Println(Sum(text))` passa os dois resultados de `Sum` direto para `Println`."
    }
  ],
  "output": "6 <nil>\n0 empty term\n0 \"two\" is not a number\n"
}
```

Leia as três chamadas como a figura desenha a segunda. `number("")` chamou `fail`, `fail` entrou
em panic, e o panic saiu de `number`, que não tinha adiado nada, e chegou a `Sum`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O panic de ~/panic-sum subindo pelas chamadas. main chama Sum, que chama number com um termo vazio. number chama fail, que entra em panic com um parseError. number não tem chamadas adiadas, então o panic sai dela e sobe até Sum. A função adiada de Sum chama recover, que para o panic e devolve o parseError; a função define total como 0 e err como o erro, e Sum retorna normalmente a main, que recebe 0 e um erro e segue em frente.\"><defs><marker id=\"rc-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"rc-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"rc-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"24\" width=\"300\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main()</text><text x=\"56\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">fmt.Println(Sum(&quot;1++3&quot;))</text><rect x=\"40\" y=\"110\" width=\"300\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Sum(&quot;1++3&quot;)</text><rect x=\"56\" y=\"146\" width=\"266\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">defer func() { recover() ... }</text><rect x=\"40\" y=\"228\" width=\"300\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">number(&quot;&quot;)</text><text x=\"56\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">fail(&quot;empty term&quot;)</text><path d=\"M90 80 L90 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rc-wire)\"></path><path d=\"M90 200 L90 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rc-wire)\"></path><text x=\"100\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chama</text><text x=\"100\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chama</text><path d=\"M340 254 H360 V166 H324\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#rc-amber)\"></path><text x=\"366\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">panic</text><path d=\"M260 108 L260 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rc-phosphor)\"></path><text x=\"270\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">retorna</text><text x=\"420\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">main segue em frente</text><text x=\"420\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">recebe 0 e um erro, e nenhum panic</text><text x=\"420\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o recover para o panic</text><text x=\"420\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a função adiada define total e err,</text><text x=\"420\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e Sum retorna a quem a chamou</text><text x=\"420\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">fail entra em panic com um parseError</text><text x=\"420\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">number não adia nada, então o panic</text><text x=\"420\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sai dela e sobe até Sum</text></svg>", "caption": "Um panic sobe pelas chamadas até um recover adiado pará-lo. A função que adiou o recover retorna normalmente, com o que os seus resultados nomeados guardam."}
```

**A função cuja chamada adiada faz o recover retorna normalmente, com o que os resultados nomeados
dela guardam.** É o padrão que a lição 20 prometeu, uma função adiada mudando um resultado nomeado
na saída, posto no seu uso de verdade: o panic entrou por uma ponta de `Sum` e um `error` comum saiu
pela outra. `Sum` está no pacote `main` aqui só para manter o exemplo num arquivo; num programa de
verdade ela seria a função exportada de um pacote próprio, com `parseError`, `fail` e `number` não
exportados, o que a lição 39 explica.

Com dois níveis de chamadas, devolver um erro de `number` teria sido mais simples, e essa é a
escolha certa para um código deste tamanho. O padrão compensa num parser, em que o helper que
encontra o engano pode estar dez chamadas abaixo da função que quem chama chamou, e cada nível no
meio precisaria do próprio `if err != nil`.

### A verificação que o mantém honesto

A função adiada só faz o recover do seu próprio `parseError`, e entra em panic de novo com qualquer
outra coisa. Essa linha parece excesso de zelo até alguém acrescentar um bug. `~/panic-sumbug`
acrescenta uma regra contra números negativos e põe a verificação dela em primeiro lugar em
`number`:

```go
func number(s string) int {
	if s[0] == '-' {
		fail("%s: negative numbers are not allowed", s)
	}
	if s == "" {
		fail("empty term")
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		fail("%q is not a number", s)
	}
	return n
}
```

```
ana@vm:~/panic-sumbug$ go build && ./sum 2>&1 | head -2
6 <nil>
panic: runtime error: index out of range [0] with length 0 [recovered, repanicked]
ana@vm:~/panic-sumbug$ ./sum >/dev/null 2>&1; echo $?
2
```

O termo vazio em `"1++3"` chegou a `s[0]` antes da verificação de `""`, o engano de ordem que a
lição 8 mostrou com `&&`. Isso é um erro de runtime, não um `parseError`, então a função adiada
entrou em panic de novo, e a mensagem diz isso: `[recovered, repanicked]`. **Um recover que ficasse
com todo panic teria informado esse bug como entrada ruim**, quem chama teria mostrado ao usuário
um erro de leitura, e o índice fora do intervalo nunca teria chegado a um trace que alguém lesse.

A biblioteca padrão escreve a mesma regra no `encoding/gob`, que codifica e decodifica valores Go
desse jeito:

```
ana@vm:~/panic-sum$ sed -n 9,14p $(go env GOROOT)/src/encoding/gob/error.go
// Errors in decoding and encoding are handled using panic and recover.
// Panics caused by user error (that is, everything except run-time panics
// such as "index out of bounds" errors) do not leave the file that caused
// them, but are instead turned into plain error returns. Encoding and
// decoding functions and methods that do not return an error either use
// panic to report an error or are guaranteed error-free.
```

O parser de templates em `text/template/parse` faz o mesmo, e o `encoding/json` também fazia até
Go 1.27. O `encode.go` dele ainda tem o recover adiado, com a mesma verificação de tipo e o mesmo
`panic(r)` para tudo o que não é dele:

```
ana@vm:~/panic-sum$ grep -n -A10 '^func (e \*encodeState) marshal' $(go env GOROOT)/src/encoding/json/encode.go
332:func (e *encodeState) marshal(v any, opts encOpts) (err error) {
333-	defer func() {
334-		if r := recover(); r != nil {
335-			if je, ok := r.(jsonError); ok {
336-				err = je.error
337-			} else {
338-				panic(r)
339-			}
340-		}
341-	}()
342-	e.reflectValue(reflect.ValueOf(v), opts)
```

Só que esse arquivo não faz mais parte do pacote do jeito que o go1.27.1 o compila. O `go list`
lista os arquivos que um build compila, então dá para comparar três builds de `encoding/json`: o
go1.27.1 como vem, o go1.27.1 com o experimento `jsonv2` desligado, e o toolchain go1.26.0 da
lição 2:

```
ana@vm:~/panic-sum$ go list -f '{{.GoFiles}}' encoding/json
[v2_decode.go v2_encode.go v2_indent.go v2_inject.go v2_options.go v2_scanner.go v2_stream.go]
ana@vm:~/panic-sum$ GOEXPERIMENT=nojsonv2 go list -f '{{.GoFiles}}' encoding/json
[decode.go encode.go fold.go indent.go scanner.go stream.go tables.go tags.go]
ana@vm:~/panic-sum$ cd ~ && GOTOOLCHAIN=go1.26.0 go list -f '{{.GoFiles}}' encoding/json
[decode.go encode.go fold.go indent.go scanner.go stream.go tables.go tags.go]
```

O último comando roda a partir de `~` porque o `go.mod` deste módulo pede 1.27.1. No go1.27.1 o
`encoding/json` é compilado a partir dos arquivos `v2_`, que rodam sobre o código de
`encoding/json/v2`, o pacote com que a lição 15 o comparou; os arquivos antigos, `encode.go` entre
eles, são o que o go1.26.0 compilava e o que a chave do experimento ainda seleciona. O padrão não
foi a lugar nenhum. Um pacote deixou de precisar dele.

## Numa fronteira: uma requisição ruim

O segundo lugar é a borda de um programa que atende muitas requisições independentes, em que uma
delas dar errado não pode derrubar as outras. O servidor HTTP de Go é o exemplo padrão, e a
documentação dele diz o que ele faz:

```
ana@vm:~/panic-http$ go doc net/http.Handler | sed -n 21,26p
    If ServeHTTP panics, the server (the caller of ServeHTTP) assumes that the
    effect of the panic was isolated to the active request. It recovers the
    panic, logs a stack trace to the server error log, and either closes the
    network connection or sends an HTTP/2 RST_STREAM, depending on the HTTP
    protocol. To abort a handler so the client sees an interrupted response but
    the server doesn't log an error, panic with the value ErrAbortHandler.
```

`~/panic-http` atende dois caminhos, e o handler de `/boom` escreve num map nil, o bug da seção 03:

```go
// Command panic-http answers on two paths, and one of them has a bug.
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	log.SetFlags(0) // no date on each line
	http.HandleFunc("/ok", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})
	http.HandleFunc("/boom", func(w http.ResponseWriter, r *http.Request) {
		var hits map[string]int
		hits[r.URL.Path]++
		fmt.Fprintln(w, "never sent")
	})
	log.Fatal(http.ListenAndServe("localhost:8036", nil))
}
```

Cada `HandleFunc` associa um caminho à função que o responde, e `ListenAndServe` atende requisições
até o programa ser parado. O servidor começa em segundo plano com o log indo para `server.log`, e o
`curl` pede os dois caminhos:

```
ana@vm:~/panic-http$ go build && (./panic-http 2>server.log &)
ana@vm:~/panic-http$ curl -sS --local-port 41036 localhost:8036/boom
curl: (52) Empty reply from server
ana@vm:~/panic-http$ curl -s localhost:8036/ok
ok
ana@vm:~/panic-http$ head -1 server.log
http: panic serving 127.0.0.1:41036: assignment to entry in nil map
ana@vm:~/panic-http$ grep panic-http/main.go server.log
	/home/ana/panic-http/main.go:17 +0x36
```

A requisição para `/boom` ficou sem resposta: o servidor fechou aquela conexão, e o `curl` disse
isso. A requisição seguinte foi respondida como se nada tivesse acontecido. O log identifica o
cliente pelo endereço e pela porta, a mensagem do panic e, mais abaixo no stack trace, a linha do
bug, `main.go:17`. A opção `--local-port` só fixa a porta do `curl`, para a linha sair igual toda
vez que esta lição é gravada. **Uma requisição falhou e o servidor não.** Sem o recover dentro de `net/http`, o map
nil teria encerrado o processo e, com ele, todas as requisições em andamento.

Continua sendo um bug, e a linha do log é o relato dele. Um recover numa fronteira mantém o programa
atendendo enquanto alguém lê o trace, que é o assunto da lição 37; ele não conserta o handler. Um
programa seu com a mesma forma, um laço que pega trabalhos um de cada vez, põe o recover no mesmo
lugar: em volta de um trabalho, registrando no log o que pegou.

## O que `recover` não pega

**Um recover protege só a goroutine em que roda.** Uma goroutine é uma função rodando por conta
própria, iniciada com a palavra-chave `go`; elas são o assunto do curso `go-concurrency`, e uma
basta aqui. `~/panic-goroutine` adia um recover em `main` e inicia uma goroutine que entra em panic,
depois dorme um décimo de segundo para a goroutine ter tempo de rodar:

```go
// Command goroutine panics somewhere its recover cannot reach.
package main

import (
	"fmt"
	"time"
)

func main() {
	defer func() {
		fmt.Println("recovered:", recover())
	}()
	go func() {
		panic("in another goroutine")
	}()
	time.Sleep(100 * time.Millisecond)
	fmt.Println("never printed")
}
```

```
ana@vm:~/panic-goroutine$ go build && ./goroutine 2>/dev/null; echo $?
2
ana@vm:~/panic-goroutine$ ./goroutine 2>&1 | grep -E '^(panic|created by)'
panic: in another goroutine
created by main.main in goroutine 1
```

Nada chegou à saída padrão: nem `recovered:` nem `never printed`. O panic pertencia à goroutine que
`main` tinha iniciado, as chamadas adiadas dela eram as únicas que rodaram, não havia nenhuma, e o
programa inteiro parou com código 2. É por isso que o `net/http` faz o recover onde faz: o servidor
atende cada conexão numa goroutine própria, e o recover adiado fica dentro da função dessa
goroutine, `(*conn).serve`, e não em volta do servidor.

**Um erro fatal não é um panic, e nada o recupera.** `~/panic-overflow` chama uma função que chama a
si mesma para sempre:

```go
// Command overflow calls itself until the stack runs out.
package main

import "fmt"

func depth(n int) int {
	return depth(n+1) + 1
}

func main() {
	defer func() {
		fmt.Println("recovered:", recover())
	}()
	fmt.Println(depth(0))
}
```

```
ana@vm:~/panic-overflow$ go build && ./overflow 2>&1 | grep -E '^(runtime: goroutine|fatal error)'
runtime: goroutine stack exceeds 1000000000-byte limit
fatal error: stack overflow
ana@vm:~/panic-overflow$ ./overflow >/dev/null 2>&1; echo $?
2
```

A pilha da goroutine chegou ao limite do runtime, um bilhão de bytes, o runtime imprimiu
`fatal error` e parou o programa, e a função adiada nunca rodou. Ficar sem memória encerra um
programa do mesmo jeito, assim como duas goroutines escrevendo no mesmo map ao mesmo tempo, o que o
curso `go-concurrency` mostra. O `os.Exit`, da seção 03, é uma terceira saída que nenhum recover vê,
porque nem é um panic.

Então os lugares são dois, e os dois são deliberados: **dentro de um pacote, em volta dos panics que
ele mesmo provoca, e na fronteira de uma requisição ou de um trabalho.** Um `recover` em qualquer
outro lugar transforma um bug num programa que continua rodando num estado que ninguém quis, o que
é pior do que a queda que ele evitou.
