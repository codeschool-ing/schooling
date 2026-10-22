---
title: Fakes, stubs e spies, escritos à mão
version: 1
---

As coisas que um teste põe no lugar de uma dependência real têm nomes, e vale a pena tê-los porque
dizem para que serve o dublê. **Um stub devolve uma resposta pronta. Um fake é uma implementação
que funciona, simplificada. Um spy registra como foi usado, para o teste perguntar depois.** Um
mock, no sentido que os frameworks de mock usam, é um spy a quem se disse de antemão que chamadas
esperar e que as confere sozinho. Com uma interface de um método, código Go raramente precisa desse
último tipo, e os outros três são poucas linhas cada um.

## Um de cada

O arquivo de teste de `TopOf`, salvo como `source_test.go`:

```schooling-example
{"language": "go", "file": "source_test.go", "parts": [{"code": "package wordcount\n\nimport (\n\t\"context\"\n\t\"errors\"\n\t\"io\"\n\t\"io/fs\"\n\t\"slices\"\n\t\"strings\"\n\t\"testing\"\n)\n\n", "note": "Só biblioteca padrão. Não há pacote de mocks para importar, porque cada dublê abaixo é um tipo comum."}, {"code": "// mapSource is a fake: documents held in memory, by name.\ntype mapSource map[string]string\n\nfunc (m mapSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {\n\ttext, ok := m[name]\n\tif !ok {\n\t\treturn nil, fs.ErrNotExist\n\t}\n\treturn io.NopCloser(strings.NewReader(text)), nil\n}\n\n", "note": "**O fake se comporta como uma fonte real, só que menor**: um nome conhecido dá o seu texto, um desconhecido dá `fs.ErrNotExist`, o erro que um arquivo inexistente dá. `io.NopCloser` acrescenta a um reader simples um `Close` que não faz nada."}, {"code": "// failingSource is a stub: every Open fails with the same error.\ntype failingSource struct{ err error }\n\nfunc (s failingSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {\n\treturn nil, s.err\n}\n\n", "note": "O stub tem uma resposta pronta. Ele existe para levar `TopOf` ao caminho de erro quando se quer, o que nenhuma fonte real faz de forma confiável."}, {"code": "// spySource records the names it was asked for and every document it\n// handed out, so a test can ask afterwards what happened to them.\ntype spySource struct {\n\tasked []string\n\tdocs  []*spyDoc\n}\n\ntype spyDoc struct {\n\tio.Reader\n\tclosed bool\n}\n\nfunc (d *spyDoc) Close() error { d.closed = true; return nil }\n\nfunc (s *spySource) Open(ctx context.Context, name string) (io.ReadCloser, error) {\n\ts.asked = append(s.asked, name)\n\tdoc := &spyDoc{Reader: strings.NewReader(\"a b a\")}\n\ts.docs = append(s.docs, doc)\n\treturn doc, nil\n}\n\n", "note": "**O spy responde como um fake e também toma notas.** Ele guarda cada documento que entrega, e cada documento lembra se o seu `Close` foi chamado, então o teste pode perguntar depois se `TopOf` fechou o que abriu. `spyDoc` embute o reader e acrescenta esse `Close`."}, {"code": "func TestTopOf(t *testing.T) {\n\tctx := t.Context()\n\tsrc := mapSource{\"note\": \"to be or not to be\"}\n\tgot, err := TopOf(ctx, src, \"note\", 2)\n\tif err != nil {\n\t\tt.Fatalf(\"TopOf: %v\", err)\n\t}\n\tif want := []Entry{{\"be\", 2}, {\"to\", 2}}; !slices.Equal(got, want) {\n\t\tt.Errorf(\"TopOf(note, 2) = %v, want %v\", got, want)\n\t}\n}\n\n", "note": "O fake atende o caso comum. O contexto é `t.Context()`, da lição 25, cancelado quando o teste termina."}, {"code": "func TestTopOfOpenFails(t *testing.T) {\n\tboom := errors.New(\"disk on fire\")\n\t_, err := TopOf(t.Context(), failingSource{boom}, \"note\", 2)\n\tif !errors.Is(err, boom) {\n\t\tt.Errorf(\"TopOf with a failing source: err = %v, want it to wrap %v\", err, boom)\n\t}\n\tif err != nil && !strings.Contains(err.Error(), \"note\") {\n\t\tt.Errorf(\"error %q does not name the document\", err)\n\t}\n}\n\n", "note": "O stub leva ao caminho de erro. O teste pergunta duas coisas: se o erro original sobrevive ao embrulho, para o `errors.Is`, e se a mensagem dá o nome do documento."}, {"code": "func TestTopOfClosesTheDocument(t *testing.T) {\n\tspy := &spySource{}\n\tif _, err := TopOf(t.Context(), spy, \"note\", 1); err != nil {\n\t\tt.Fatalf(\"TopOf: %v\", err)\n\t}\n\tif !slices.Equal(spy.asked, []string{\"note\"}) {\n\t\tt.Fatalf(\"opened %v, want [note]\", spy.asked)\n\t}\n\tif !spy.docs[0].closed {\n\t\tt.Error(\"the document was not closed\")\n\t}\n}\n", "note": "**O spy pergunta como `TopOf` se comportou, e não o que devolveu**: que nome abriu, e se o fechou."}]}
```

```
ana@vm:~/wordcount$ go test -v -run TopOf
=== RUN   TestTopOf
--- PASS: TestTopOf (0.00s)
=== RUN   TestTopOfOpenFails
--- PASS: TestTopOfOpenFails (0.00s)
=== RUN   TestTopOfClosesTheDocument
    source_test.go:84: the document was not closed
--- FAIL: TestTopOfClosesTheDocument (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.003s
```

**O spy achou o que nada mais acharia.** O fake e o stub passaram, e o terceiro teste diz que o
documento não foi fechado. Volte ao `source.go` da seção 02: ele abre `rc` e nunca o fecha. Num
arquivo isso vaza um descritor; numa resposta HTTP impede que uma conexão seja reaproveitada. Nenhum
valor de retorno mostra isso, e é por isso que só um teste que observa a chamada o encontra.

O conserto é uma linha, `defer rc.Close()`, logo depois da conferência do erro. O `source.go` com
ela, salvo como `source.go`:

```go
package wordcount

import (
	"context"
	"fmt"
	"io"
)

// A Source hands over the text of a document, by name.
type Source interface {
	Open(ctx context.Context, name string) (io.ReadCloser, error)
}

// TopOf counts the words of the named document in src and returns its n
// most frequent.
func TopOf(ctx context.Context, src Source, name string, n int) ([]Entry, error) {
	rc, err := src.Open(ctx, name)
	if err != nil {
		return nil, fmt.Errorf("open %s: %w", name, err)
	}
	defer rc.Close()
	counts, err := Count(rc)
	if err != nil {
		return nil, fmt.Errorf("count %s: %w", name, err)
	}
	return Top(counts, n), nil
}
```

```
ana@vm:~/wordcount$ go test -run TopOf
PASS
ok  	example.com/wordcount	0.002s
```

## Quando um spy é a ferramenta errada

Um spy afirma como algo foi feito, e isso é um compromisso. **Confira as chamadas que fazem parte do
contrato e deixe o resto em paz.** Fechar o que se abre é uma promessa em que todo chamador confia.
Quantas vezes `Count` lê do documento, ou em pedaços de que tamanho, não é; um spy que contasse
leituras quebraria no dia em que alguém embrulhasse o reader num `bufio.Reader`, sem nada de errado
no código. Quando um teste falha depois de uma mudança que não quebrou nada, ele parou de testar
comportamento e passou a descrever a implementação, e as falhas dele ensinam as pessoas a ignorá-lo.
