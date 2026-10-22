---
title: Achar, extrair e reescrever
version: 1
---

Uma expressão regular é um pequeno programa para reconhecer texto, e o pacote `regexp` de Go a
compila antes de rodá-la. **`regexp.MustCompile` transforma o padrão num `*Regexp` uma vez, e todo
método depois disso roda a máquina compilada**: achar a primeira ocorrência, achar todas, tirar os
pedaços entre parênteses, substituir. O programa abaixo faz cada uma dessas coisas com três linhas
do log de um servidor web, salvo como `match/main.go`:

```go
// Command match finds, extracts and rewrites with a regular expression.
package main

import (
	"fmt"
	"regexp"
)

const logs = `2026-10-16 09:12:03 GET /orders/1042 200 18ms
2026-10-16 09:12:04 POST /orders 201 95ms
2026-10-16 09:12:09 GET /orders/77 404 3ms`

var line = regexp.MustCompile(`(?m)^\S+ \S+ (?P<method>[A-Z]+) (?P<path>\S+) (?P<status>\d{3}) (?P<ms>\d+)ms$`)

func main() {
	fmt.Println(regexp.MustCompile(`\d{3}`).FindString("GET /orders/1042 200"))
	fmt.Println(regexp.MustCompile(`\b\d{3}\b`).FindString("GET /orders/1042 200"))
	fmt.Println(regexp.MustCompile(`/orders/\d+`).FindAllString(logs, -1))

	for _, m := range line.FindAllStringSubmatch(logs, -1) {
		fmt.Println(m[line.SubexpIndex("status")], m[line.SubexpIndex("path")])
	}

	ids := regexp.MustCompile(`/orders/(\d+)`)
	fmt.Println(ids.ReplaceAllString("GET /orders/1042", "/orders/{id=$1}"))

	_, err := regexp.Compile(`[a-z`)
	fmt.Println(err)
}
```

Os padrões são escritos entre crases, as strings cruas de Go, para que `\d` chegue ao pacote como
uma barra invertida e um `d`, e não como um escape que o compilador teria de ler antes.

```
ana@vm:~/patterns$ go run ./match
104
200
[/orders/1042 /orders/77]
200 /orders/1042
201 /orders
404 /orders/77
GET /orders/{id=1042}
error parsing regexp: missing closing ]: `[a-z`
```

**A primeira linha é uma lição por si só**: `\d{3}` pediu três dígitos e achou `104`, o começo de
`1042`, porque uma ocorrência é a mais à esquerda e nada dizia onde os dígitos tinham de acabar. O
`\b`, uma fronteira de palavra, diz isso, e a segunda linha achou `200`. Um padrão que casa com o
que você queria não é o mesmo que um padrão que casa só com isso, e a diferença aparece na entrada
que você não testou.

`FindAllString` com `-1` devolveu todas as ocorrências. **`FindAllStringSubmatch` devolveu, para
cada linha, a ocorrência inteira seguida de cada grupo**, e `SubexpIndex` transformou os nomes
escritos como `(?P<status>…)` em posições, então o código lê `status` e não `m[3]`. O `(?m)` na
frente fez `^` e `$` casarem no começo e no fim de cada linha, e não do texto inteiro. O
`ReplaceAllString` escreveu o primeiro grupo de volta como `$1`.

## `Compile` ou `MustCompile`

`MustCompile` dá panic com um padrão que não é válido; `Compile` devolve o erro, e a última linha da
saída é esse erro: `missing closing ]`. **Um padrão escrito no código é conferido uma vez, quando o
programa começa, então `MustCompile` numa variável de pacote é o idioma**: um erro de digitação
para o programa na primeira execução, e não na primeira requisição que chega à linha errada. Um
padrão que vem de um usuário, de um arquivo ou de uma flag é `Compile`, porque o erro de digitação
de uma pessoa é um erro a relatar, e não um motivo para derrubar o programa.
