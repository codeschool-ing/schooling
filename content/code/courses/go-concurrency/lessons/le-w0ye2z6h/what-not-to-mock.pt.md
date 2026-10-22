---
title: O que não substituir
version: 1
---

A seção 03 substituiu o `Source` porque os reais são lentos, precisam de rede ou ainda não foram
escritos. Esse é o critério para todo dublê: **substitua uma dependência quando a coisa real é
lenta, instável, cara ou fora do seu controle, e use a coisa real em todo o resto.** Um dublê também
é código. Ele pode estar errado, e um teste que passa contra um dublê errado é um teste do dublê.

## Coisas reais que são baratas

Quase tudo de que uma função Go depende tem uma implementação na biblioteca padrão que não custa
nada usar num teste.

- **Um reader é um `strings.Reader`.** Ninguém escreve um `io.Reader` falso; as lições 25 e 26
  contaram frases pelo de verdade, e o fake de `TopOf` é um `strings.Reader` com um `Close` a mais.
- **Um writer é um `bytes.Buffer`** ou um `strings.Builder`, e o teste lê de volta o que foi
  escrito.
- **Um sistema de arquivos é um `fs.FS`**, e o `testing/fstest.MapFS` é um guardado num map, com
  arquivos, diretórios e modos, que se comporta como o do disco em tudo o que `fs.FS` promete.
- **Um servidor HTTP é um `httptest.Server`**, um servidor real numa porta local, que a lição 28 usa.

O terceiro item da lista merece uma fonte própria. A maioria dos documentos que vale contar são
arquivos, e `fs.FS` é a interface da biblioteca padrão para uma árvore deles, salva como
`fssource.go`:

```go
package wordcount

import (
	"context"
	"io"
	"io/fs"
)

// FSSource reads documents from a file system, such as os.DirFS("notes").
type FSSource struct{ FS fs.FS }

// Open opens the named file. The context is not used: fs.FS has no way to
// cancel an open.
func (s FSSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	f, err := s.FS.Open(name)
	if err != nil {
		return nil, err
	}
	return f, nil
}
```

Um `fs.File` tem `Read` e `Close`, então já é um `io.ReadCloser`. O `if err != nil` não é cerimônia.
Devolver `s.FS.Open(name)` direto transformaria um `fs.File` `nil` num `io.ReadCloser` não `nil`
guardando um valor `nil`, a armadilha que a lição 28 de `go` mostrou para interfaces, e quem
conferisse `rc != nil` seria enganado.

O teste dela não usa dublê nenhum, salvo como `fssource_test.go`:

```go
package wordcount

import (
	"errors"
	"io/fs"
	"slices"
	"testing"
	"testing/fstest"
)

func TestFSSource(t *testing.T) {
	src := FSSource{fstest.MapFS{
		"notes/a.txt": {Data: []byte("go go stop")},
	}}
	got, err := TopOf(t.Context(), src, "notes/a.txt", 1)
	if err != nil {
		t.Fatalf("TopOf: %v", err)
	}
	if want := []Entry{{"go", 2}}; !slices.Equal(got, want) {
		t.Errorf("TopOf(notes/a.txt, 1) = %v, want %v", got, want)
	}
	if _, err := TopOf(t.Context(), src, "notes/b.txt", 1); !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("missing file: err = %v, want fs.ErrNotExist", err)
	}
}
```

```
ana@vm:~/wordcount$ go test -v -run FSSource
=== RUN   TestFSSource
--- PASS: TestFSSource (0.00s)
PASS
ok  	example.com/wordcount	0.002s
```

`fstest.MapFS` não é um mock de sistema de arquivos; é um sistema de arquivos, guardado na memória,
e o mesmo código de `FSSource` roda contra ele no teste e contra `os.DirFS` em produção. O arquivo
que falta dá o mesmo `fs.ErrNotExist` que um disco daria, embrulhado por `TopOf` com o nome do
documento.

## A regra por baixo

Substitua aquilo de que você é dono da interface, e só na borda do seu código. `Source` é a
interface deste pacote, então um teste pode lhe entregar qualquer coisa. `http.Client`, `os.File` e
`sql.DB` não são; falsificá-los é adivinhar um comportamento que outra pessoa escreveu, e a
adivinhação erra exatamente onde importa, nos erros e nos casos de borda. **Ponha uma interface
pequena sua entre o seu código e o deles, teste o seu código contra dublês dela e teste a
implementação real dela contra a coisa real**, como esta seção fez com um sistema de arquivos e a
lição 28 faz com um servidor.

```
ana@vm:~/wordcount$ go test
PASS
ok  	example.com/wordcount	0.004s
```
