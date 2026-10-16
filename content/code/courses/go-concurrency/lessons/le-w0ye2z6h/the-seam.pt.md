---
title: A costura é uma interface pequena
version: 1
---

Até aqui toda função de `wordcount` recebe a entrada inteira: um reader, um map. Código de verdade
raramente faz isso. Ele abre um arquivo, pergunta a um servidor, lê um bucket na nuvem de alguém, e
um teste que faz o mesmo é lento, precisa de rede e falha por motivos que não têm nada a ver com o
código. A resposta usual em outras linguagens é um framework de mocks. **Em Go a resposta é uma
interface pequena, declarada pelo código que precisa dela**, e um teste que entrega a sua própria
implementação.

## Uma função que depende de algo

O pacote ganha uma função que recebe um documento pelo nome, conta as palavras e devolve as mais
frequentes. De onde vem o documento não é problema dela, então ela pede algo que saiba abrir um,
salva como `source.go`:

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
	counts, err := Count(rc)
	if err != nil {
		return nil, fmt.Errorf("count %s: %w", name, err)
	}
	return Top(counts, n), nil
}
```

**`Source` tem um método, e isso é uma decisão de projeto, e não um acaso.** Um teste satisfaz um
método em quatro linhas. Uma interface copiada de um cliente real, com os seus vinte métodos, faria
todo teste implementar dezenove que nunca chama. A interface também é declarada aqui, no pacote que
a usa, e não ao lado de alguma implementação: interfaces de Go são satisfeitas implicitamente, como
a lição 27 de `go` mostrou, então um cliente HTTP, um diretório em disco e um map num teste podem
todos ser um `Source` sem importar este pacote nem saber que ele existe.

`ctx` vem primeiro, como a lição 11 pediu de toda chamada que pode esperar. `TopOf` o repassa e
nunca olha para ele; a fonte que conversa com a rede vai olhar.

## O que a costura compra

Tudo o que `TopOf` faz além de abrir já está testado: `Count` pela tabela da lição 26, `Top` pelo
`TestTop`. O que sobra é a cola, e a cola tem exatamente três coisas que podem dar errado. Ela pode
não passar o nome certo, tratar mal um erro de `Open` ou tratar mal o documento que recebeu. Um
teste que controla o `Source` controla as três, e a seção 03 escreve um para cada uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"TopOf depende da interface Source, de um método, declarada no pacote wordcount. Três coisas a satisfazem sem importar nada de TopOf: os dublês de teste da seção 03, o FSSource sobre um sistema de arquivos na seção 04 e uma fonte HTTP na lição 28.\"><defs><marker id=\"l27seam-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l27seam-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">TopOf(ctx, src, name, n)</text><path d=\"M230 55 H300\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l27seam-amber)\"></path><text x=\"265\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chama</text><rect x=\"302\" y=\"20\" width=\"390\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"497\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">Source: Open(ctx, name) (io.ReadCloser, error)</text><text x=\"497\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um método, declarado pelo código que precisa dele</text><rect x=\"30\" y=\"170\" width=\"220\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nos testes: fake, stub, spy</text><text x=\"140\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.8\" fill=\"var(--paper-dim)\">mapSource · failingSource · spySource</text><path d=\"M140 168 L437 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l27seam-phosphor)\"></path><rect x=\"260\" y=\"170\" width=\"220\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um sistema de arquivos, seção 04</text><text x=\"370\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.8\" fill=\"var(--paper-dim)\">FSSource{fstest.MapFS / os.DirFS}</text><path d=\"M370 168 L497 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l27seam-phosphor)\"></path><rect x=\"490\" y=\"170\" width=\"220\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um servidor via HTTP, lição 28</text><text x=\"600\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.8\" fill=\"var(--paper-dim)\">HTTPSource</text><path d=\"M600 168 L557 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l27seam-phosphor)\"></path><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada um satisfaz Source implicitamente</text></svg>", "caption": "A costura: TopOf conhece um comportamento, não uma coisa, então um teste pode lhe entregar qualquer coisa que se comporte assim."}
```

A leitura do código desta seção numa frase: **`TopOf` depende de um comportamento, e não de uma
coisa**, e o comportamento é pequeno o bastante para um teste fornecê-lo. A lição 28 fornece o outro
lado, um `Source` que busca via HTTP, e o testa contra um servidor de verdade.
