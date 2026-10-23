---
title: O primeiro servidor
version: 1
---

**Um servidor web em Go é um programa comum que nunca retorna do `main`**: ele abre uma porta,
espera uma conexão e entrega cada requisição a uma função que você escreveu. O `net/http` da
biblioteca padrão faz a espera, a leitura e a resposta. A sua parte é a função. Eis o menor
servidor completo:

```go
// hello/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "hello from %s %s\n", r.Method, r.URL.Path)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", nil))
}
```

A função passada ao `HandleFunc` recebe duas coisas. **`r` é a requisição**, já interpretada: o
método, o caminho, os cabeçalhos, o corpo esperando para ser lido. **`w` é para onde vai a
resposta**, e o que for escrito nele é mandado ao cliente. O `fmt.Fprintf` escreve em qualquer
`io.Writer`, e um `ResponseWriter` é um, então a linha que responde é a mesma chamada que imprime
num arquivo.

O `ListenAndServe` abre a porta e serve até algo falhar. Ele só retorna com um erro, e é por isso
que o `log.Fatal` o envolve: se a porta não puder ser aberta, o programa diz por quê e sai, em vez
de ficar ali parado sem fazer nada.

## Dois terminais

Ponha o arquivo num diretório chamado `hello`, dê a ele um módulo e inicie-o num terminal:

```
ana@vm:~/hello$ go mod init example.com/hello
go: creating new go.mod: module example.com/hello
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/hello$ go run .
```

O `go run .` não imprime nada e não devolve o prompt. Isso é o servidor rodando. Abra um **segundo
terminal** e seja o cliente dele:

```
ana@vm:~/hello$ curl -s localhost:8080/
hello from GET /
ana@vm:~/hello$ curl -s localhost:8080/events/7
hello from GET /events/7
ana@vm:~/hello$ curl -s -X POST localhost:8080/anything
hello from POST /anything
```

**A mesma função respondeu as três**, qualquer que fosse o caminho e o método. O padrão `"/"` casa
todo caminho, porque um padrão que termina em barra reivindica tudo abaixo dele, e este reivindica
o site inteiro. As seções 05 e 06 tratam de escrever padrões que dizem mais.

O `-i` pede ao `curl` que imprima também a linha de status e os cabeçalhos da resposta:

```
ana@vm:~/hello$ curl -si localhost:8080/
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:44 GMT
Content-Length: 17
Content-Type: text/plain; charset=utf-8

hello from GET /
```

O handler não definiu nada disso. **O `net/http` preencheu o status, a data, o tamanho e o tipo**:
200 porque nada disse o contrário, 17 porque foram escritos 17 bytes, e `text/plain` porque ele
olhou esses bytes e chutou. A seção 07 trata de quando esse chute é bem-vindo e quando não é.

## A porta está ocupada

Inicie uma segunda cópia num terceiro terminal enquanto a primeira ainda está rodando, e ela
recusa:

```
ana@vm:~/hello$ go run .
2026/10/16 19:11:44 listen tcp 127.0.0.1:8080: bind: address already in use
exit status 1
```

**`bind: address already in use` quer dizer que outro programa segura a porta**, e muitas vezes
esse programa é uma cópia anterior do seu próprio servidor, esquecida rodando num terminal. Pare-a
com Ctrl+C no terminal dela. Se não achar qual era, `ss -ltnp` lista toda porta em escuta com o
programa por trás. A linha veio do `log.Fatal`, e o `exit status 1` do `go run`, contando como o
programa terminou.

## `localhost` e `nil`

Dois argumentos daquele programa decidem mais do que parece.

**`"localhost:8080"` escuta só nesta máquina.** A mensagem de erro o mostra como `127.0.0.1`, um
endereço que nada fora do computador alcança. Escrever `":8080"` escuta em todas as interfaces de
rede, que é o que um servidor em produção faz e o que um notebook no Wi-Fi da padaria não deveria
fazer. Este curso fica no `localhost` até a aula 16 pôr o servidor num container, onde o lado de
fora do container é justamente o ponto.

**`nil` como handler quer dizer `http.DefaultServeMux`**, um roteador que pertence ao pacote e no
qual o `http.HandleFunc` registra. É prático e é compartilhado: qualquer pacote que o seu programa
importa também pode registrar uma rota nele. O `net/http/pprof` faz exatamente isso, acrescentando
um conjunto de páginas `/debug/pprof/` no momento em que é importado. **Da próxima seção em diante,
todo programa monta o próprio mux** e o passa adiante, de modo que as rotas que o servidor responde
são as rotas que o `main` dele enxerga.
