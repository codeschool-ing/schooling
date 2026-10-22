---
title: Um diretório dentro do binário
version: 1
---

Uma string guarda um arquivo. Um site, um conjunto de templates ou uma pasta de migrações de banco
de dados são vários, e **um `embed.FS` guarda uma árvore inteira**: um sistema de arquivos somente
leitura dentro do programa, atrás da interface `fs.FS` do pacote `io/fs`. O programa abaixo embute
um diretório duas vezes, de dois jeitos, e lista o que cada um recebeu, salvo como `site/main.go`:

```go
// Command site lists the files it carries inside itself.
package main

import (
	"embed"
	"fmt"
	"io/fs"
)

//go:embed static
var static embed.FS

//go:embed all:static
var everything embed.FS

func list(name string, fsys fs.FS) {
	fmt.Println(name + ":")
	fs.WalkDir(fsys, ".", func(path string, d fs.DirEntry, err error) error {
		if !d.IsDir() {
			fmt.Println("  " + path)
		}
		return nil
	})
}

func main() {
	list("static", static)
	list("all:static", everything)

	page, err := static.ReadFile("static/index.html")
	fmt.Printf("%d bytes, %v\n", len(page), err)
	_, err = static.ReadFile("index.html")
	fmt.Println(err)
}
```

Quatro arquivos pequenos vão para `site/static`, dois deles com nomes que começam com `.` e `_`:

```
ana@vm:~/embedding$ mkdir site/static
ana@vm:~/embedding$ printf "<h1>Orders</h1>\n" > site/static/index.html
ana@vm:~/embedding$ printf "h1 { color: teal }\n" > site/static/style.css
ana@vm:~/embedding$ printf "draft\n" > site/static/.draft.html
ana@vm:~/embedding$ printf "notes\n" > site/static/_notes.txt
ana@vm:~/embedding$ go run ./site
static:
  static/index.html
  static/style.css
all:static:
  static/.draft.html
  static/_notes.txt
  static/index.html
  static/style.css
16 bytes, <nil>
open index.html: file does not exist
```

**O padrão simples deixou de fora `.draft.html` e `_notes.txt`.** Um diretório citado em
`//go:embed` traz os seus arquivos menos os de nome começado por ponto ou sublinhado, que é como
costumam se chamar os backups e rascunhos de editores. O prefixo `all:` leva tudo. Deixá-los de
fora por padrão é uma medida de segurança: um `.env` com uma senha, esquecido num diretório que
alguém embute, sairia dentro do binário para todo mundo que o baixa.

Os caminhos dentro de um `embed.FS` mantêm o nome do diretório, então a página é
`static/index.html` e `index.html` sozinho não existe. **O erro é o `fs.ErrNotExist` comum** que um
arquivo ausente em disco dá, `open index.html: file does not exist`, e é isso que deixa um código
escrito contra `fs.FS` funcionar nos dois sem saber em qual está. A próxima seção usa isso para
tirar o `static/`.
