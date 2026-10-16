---
title: Diretórios, percorrer uma árvore, e ficar dentro de uma
version: 1
---

Diretórios são onde os arquivos de um programa deixam de ser um arquivo só. Três tarefas aparecem
sempre: criar um caminho de diretórios, listar um, e visitar tudo embaixo de um. Uma quarta era
fácil de errar e desde o Go 1.24 tem um tipo próprio: **abrir arquivos por um nome que veio de
outra pessoa sem deixar o `..` levar você para fora do diretório que você queria.** Um programa faz
as quatro, salvo como `tree.go`:

```go
// Command tree makes directories, lists one, walks another and refuses to leave a root.
package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

func main() {
	for _, day := range []string{"14", "15", "16"} {
		dir := filepath.Join("logs", "2026", "10", day)
		if err := os.MkdirAll(dir, 0o755); err != nil {
			fmt.Println(err)
			return
		}
		os.WriteFile(filepath.Join(dir, "app.log"), []byte("day "+day+"\n"), 0o644)
	}

	entries, err := os.ReadDir("logs/2026/10")
	if err != nil {
		fmt.Println(err)
		return
	}
	for _, e := range entries {
		fmt.Println("entry:", e.Name(), "dir:", e.IsDir())
	}

	files, bytes := 0, int64(0)
	err = filepath.WalkDir("/usr/local/go/src/io", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() && filepath.Ext(path) == ".go" {
			info, err := d.Info()
			if err != nil {
				return err
			}
			files++
			bytes += info.Size()
		}
		return nil
	})
	fmt.Println("walked io:", files, "Go files,", bytes, "bytes, err", err)

	root, err := os.OpenRoot("logs")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer root.Close()
	if _, err := root.Open("2026/10/16/app.log"); err == nil {
		fmt.Println("inside the root: opened")
	}
	_, err = root.Open("../notes.txt")
	fmt.Println("outside the root:", err)
}
```

```
ana@vm:~/files$ go run tree.go
entry: 14 dir: true
entry: 15 dir: true
entry: 16 dir: true
walked io: 32 Go files, 144889 bytes, err <nil>
inside the root: opened
outside the root: openat ../notes.txt: path escapes from parent
```

## Criar e listar

`os.MkdirAll` cria todo diretório que falta no caminho e se dá por satisfeito quando eles já
existem, e é por isso que o laço pode chamá-lo três vezes em caminhos que dividem `logs/2026/10`. O
irmão dele, `os.Mkdir`, cria um diretório e falha se ele já existe. `os.ReadDir` devolve as entradas
de um diretório **ordenadas pelo nome**, então `14`, `15` e `16` saíram em ordem, seja qual for a
ordem em que o disco as guarda. Cada entrada sabe o nome e se é diretório sem outra ida ao disco; o
`e.Info()` é essa ida, para o tamanho e as datas.

Os caminhos foram montados com `filepath.Join`, nunca com `+ "/" +`. Ele põe o separador que o
sistema operacional usa e limpa os repetidos, então o mesmo código está certo no Windows.

## Percorrer

`filepath.WalkDir` visita um diretório e tudo embaixo dele, em ordem léxica, e chama a sua função
uma vez por entrada com o caminho, a entrada e qualquer erro que a alcance. Aqui ele percorreu o
próprio pacote `io` da biblioteca padrão, em `/usr/local/go/src/io`, e achou 32 arquivos Go com
144.889 bytes, testes incluídos. Duas regras deixam um percurso correto. **Devolva o `err` que
recebeu, a menos que queira pulá-lo**, porque um diretório que não pôde ser lido chega como esse
erro e não como uma queda. E devolva `filepath.SkipDir` na chamada de um diretório para deixar essa
subárvore de fora, que é como um percurso evita `.git` ou `node_modules`.

## Ficar dentro de uma raiz

Um programa que serve arquivos, descompacta um pacote ou grava uploads recebe nomes de fora. Um
nome como `../notes.txt` juntado a `logs` aponta para fora de `logs`, e procurar `..` à mão deixa
escapar os casos que um link simbólico cria. **`os.OpenRoot` devolve um `os.Root`, e todo nome
aberto por ele é resolvido dentro daquele diretório ou recusado.** `root.Open("2026/10/16/app.log")`
funcionou; `root.Open("../notes.txt")` falhou com `path escapes from parent` antes de qualquer coisa
fora de `logs` ser tocada. O `os.Root` tem as operações de arquivo de que você precisa lá dentro,
entre elas `Open`, `Create`, `OpenFile`, `Mkdir` e `Remove`.
