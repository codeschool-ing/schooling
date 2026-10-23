---
title: Os valores viajam separados do SQL
version: 1
---

Toda consulta que o boxoffice manda tem um texto fixo com `$1` e `$2` e os valores ao lado. **A
alternativa, colar o valor no texto, é a falha de segurança mais comum em código de banco de dados**, e
não é preciso um atacante para mostrar por quê. Um evento pode se chamar *Rock 'n' Roll Night*:

```go
// quote/main.go
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
)

func main() {
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer conn.Close(ctx)

	name := "Rock 'n' Roll Night"
	var n int

	glued := "SELECT count(*) FROM events WHERE name = '" + name + "'"
	fmt.Println("glued:", glued)
	err = conn.QueryRow(ctx, glued).Scan(&n)
	fmt.Println("  ->", n, err)

	err = conn.QueryRow(ctx, "SELECT count(*) FROM events WHERE name = $1", name).Scan(&n)
	fmt.Println("parameter:", n, err)
}
```

O `pgx.Connect` abre uma única conexão, que é tudo de que um programa avulso precisa. O programa faz a
mesma pergunta duas vezes, uma com o nome colado no SQL e outra com um placeholder:

```
ana@vm:~/quote$ DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql' go run .
glued: SELECT count(*) FROM events WHERE name = 'Rock 'n' Roll Night'
  -> 0 ERROR: syntax error at or near "n" (SQLSTATE 42601)
parameter: 0 <nil>
```

**A versão colada já não é uma consulta sobre aquele nome.** O primeiro apóstrofo fechou a string que o
PostgreSQL estava lendo, o `n` foi lido como SQL, e o parser desistiu com um erro de sintaxe, SQLSTATE
`42601`. Um nome digitado de boa-fé quebrou a instrução.

Agora inverta. Se um valor consegue fechar a string e continuar o SQL, então quem escolhe o valor
escolhe parte da consulta, e um valor escrito de propósito faz a instrução fazer algo que o autor dela
nunca escreveu: ler outras linhas, alterá-las, apagá-las. Isso é **SQL injection**, e há vinte anos está
perto do topo de toda lista de falhas de aplicações web. A defesa não é limpar o valor, escapando aspas
ou recusando certos caracteres; isso já foi tentado e errado de todos os jeitos possíveis. **A defesa é
nunca pôr um valor no texto SQL.**

## O que um placeholder faz de fato

Com `$1`, o pgx manda a instrução e o valor ao PostgreSQL **como duas partes separadas do protocolo**. O
servidor interpreta primeiro a instrução, com o placeholder no lugar de um valor cujo tipo ele já
conhece, e só depois recebe o valor, que nunca é interpretado como SQL porque a interpretação já
terminou. Os apóstrofos de *Rock 'n' Roll Night* chegam como três caracteres de uma string, e a
contagem dá um 0 correto. Não existe entrada para a qual isso dê errado, e é isso que faz dele uma
defesa e não uma precaução.

## O que um placeholder não guarda

**Um placeholder representa um valor, nunca uma parte da instrução**: nem nome de tabela, nem coluna,
nem `ASC` ou `DESC`. Uma API que deixa o cliente escolher a coluna de ordenação, `?sort=name`, fica
tentada a colar essa palavra no `ORDER BY`. A versão segura a compara com uma lista fixa e usa a string
da própria lista:

```go
columns := map[string]string{"name": "name", "seats": "seats"}
col, ok := columns[r.URL.Query().Get("sort")]
if !ok {
	col = "id"
}
query := "SELECT id, name, seats, sold FROM events ORDER BY " + col
```

O texto colado na consulta é sempre uma de três constantes do código-fonte, nunca o do cliente. **O que
o cliente mandou só escolhe entre strings que você escreveu.**
