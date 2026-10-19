---
title: Compondo os dois
version: 1
---

Como toda origem é um Reader e todo destino um Writer, a biblioteca padrão pode oferecer peças
pequenas que recebem um e devolvem outro, e um programa monta o que precisa encaixando-as. **É o
pipe do shell, `cat file | gzip | sha256sum`, feito com valores em vez de processos.** As peças de
`io` que vale conhecer pelo nome:

| função | recebe | devolve | o que faz |
|---|---|---|---|
| `io.Copy(dst, src)` | um Writer e um Reader | bytes copiados, erro | move tudo de `src` para `dst` até o `EOF` |
| `io.ReadAll(r)` | um Reader | `[]byte`, erro | lê até o fim, para a memória |
| `io.LimitReader(r, n)` | um Reader | um Reader | para depois de `n` bytes |
| `io.MultiReader(rs...)` | Readers | um Reader | um depois do outro, como se concatenados |
| `io.TeeReader(r, w)` | um Reader e um Writer | um Reader | o que se lê dele também é escrito em `w` |
| `io.MultiWriter(ws...)` | Writers | um Writer | toda escrita vai para todos eles |
| `io.Pipe()` | nada | um Reader e um Writer | o que uma goroutine escreve, outra lê |

O `io.Pipe` é onde as duas metades deste curso se encontram. Ele não tem buffer: um `Write` bloqueia
até um `Read` levar os bytes, exatamente como o canal sem buffer da lição 4, então quem escreve e
quem lê precisam ser goroutines diferentes.

## Quatro peças num programa

O programa abaixo faz uma goroutine escrever três linhas num pipe. A outra ponta é lida através de
um `TeeReader` que alimenta um hash, e copiada para um `MultiWriter` que alimenta o terminal e um
`strings.Builder`. Salvo como `pipe.go`:

```schooling-example
{"language": "go", "file": "pipe.go", "parts": [{"code": "// Command pipe connects a goroutine that writes to code that reads.\npackage main\n\nimport (\n\t\"crypto/sha256\"\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\t\"strings\"\n)\n\n", "note": "Nada fora da biblioteca padrão, e nada que toque um disco."}, {"code": "func main() {\n\tpr, pw := io.Pipe()\n\tgo func() {\n\t\tfor i := 1; i <= 3; i++ {\n\t\t\tfmt.Fprintf(pw, \"line %d from the writer\\n\", i)\n\t\t}\n\t\tpw.Close()\n\t}()\n\n", "note": "**A ponta de escrita vai para uma goroutine própria.** Cada `Fprintf` bloqueia até o lado de leitura levar os bytes. O `pw.Close()` é o que o leitor verá como `EOF`; esqueça-o e o `io.Copy` espera para sempre, que é o vazamento da lição 6 com outra cara."}, {"code": "\th := sha256.New()\n\tvar kept strings.Builder\n\tn, err := io.Copy(io.MultiWriter(os.Stdout, &kept), io.TeeReader(pr, h))\n", "note": "**Uma linha de encanamento.** O `io.Copy` lê do tee, o tee entrega cada pedaço ao hash no caminho, e o multi-writer manda cada pedaço para o terminal e para `kept`. Nenhuma peça aqui sabe o que é qualquer outra."}, {"code": "\tfmt.Println(\"copied\", n, \"bytes, err\", err)\n\tfmt.Printf(\"sha256 %x\\n\", h.Sum(nil))\n\tfmt.Print(strings.ToUpper(kept.String()))\n}\n", "note": "Três jeitos de mostrar que todo byte foi a todo lugar: a contagem que o `io.Copy` devolve, o hash, e a cópia guardada na memória, impressa de novo em maiúsculas."}], "output": "line 1 from the writer\nline 2 from the writer\nline 3 from the writer\ncopied 69 bytes, err <nil>\nsha256 dd142e8966cd4c3cad296af10a08470b0aa8cb054285239b78f1d238d8b60946\nLINE 1 FROM THE WRITER\nLINE 2 FROM THE WRITER\nLINE 3 FROM THE WRITER"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Como o pipe.go é encanado. Uma goroutine escreve três linhas em pw, a ponta de escrita do io.Pipe. main lê de pr, a ponta de leitura, através do io.TeeReader, que também escreve cada pedaço no hash sha256. O io.Copy move os pedaços para o io.MultiWriter, que escreve cada um em os.Stdout e num strings.Builder chamado kept.\"><defs><marker id=\"l17pipe-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17pipe-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"70\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma goroutine</text><rect x=\"20\" y=\"48\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fprintf(pw)</text><path d=\"M122 65 H150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-amber)\"></path><rect x=\"152\" y=\"48\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">io.Pipe</text><text x=\"207\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada escrita espera uma leitura</text><path d=\"M264 65 H292\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"294\" y=\"48\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">io.TeeReader</text><path d=\"M359 84 V138\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"304\" y=\"140\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sha256</text><path d=\"M426 65 H454\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"456\" y=\"48\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"516.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">io.MultiWriter</text><text x=\"516\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main, dentro do io.Copy</text><path d=\"M578 58 H606\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><path d=\"M578 74 C592 74 592 157 606 157\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"608\" y=\"41\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">os.Stdout</text><rect x=\"608\" y=\"140\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kept</text><text x=\"152\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pw</text><text x=\"262\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pr</text><path d=\"M152 108 V114\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M262 108 V114\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Todo pedaço lido do pipe é escrito duas vezes pelo tee e pelo multi-writer, e chega a três lugares: o hash, o terminal e o kept."}
```

A execução, depois as mesmas três linhas entregues ao `sha256sum` do shell para comparar, e o
programa de novo com o detector de corridas:

```
ana@vm:~/rw$ go run pipe.go
line 1 from the writer
line 2 from the writer
line 3 from the writer
copied 69 bytes, err <nil>
sha256 dd142e8966cd4c3cad296af10a08470b0aa8cb054285239b78f1d238d8b60946
LINE 1 FROM THE WRITER
LINE 2 FROM THE WRITER
LINE 3 FROM THE WRITER
ana@vm:~/rw$ printf "line %d from the writer\n" 1 2 3 | sha256sum
dd142e8966cd4c3cad296af10a08470b0aa8cb054285239b78f1d238d8b60946  -
ana@vm:~/rw$ go run -race pipe.go > /dev/null; echo "exit: $?"
exit: 0
```

**69 bytes passaram, os hashes concordam, e o detector fica quieto**, porque o próprio pipe
sincroniza as duas goroutines: cada byte que o leitor vê foi entregue, não compartilhado. O `err` é
`<nil>` embora os dados tenham acabado, pelo mesmo motivo que o `io.ReadAll` não informou erro na
seção 02: o `io.Copy` trata o `EOF` como linha de chegada, não como falha.

## Por que isso importa depois desta lição

Quase todo tipo do resto desta metade se encaixa nas mesmas duas interfaces. Um arquivo de
`os.Open` é um Reader e um Writer (lição 18). `json.NewDecoder` recebe um Reader e
`json.NewEncoder` um Writer (lição 19). Um handler de log escreve num Writer (lição 22). O corpo de
uma resposta HTTP é um Reader e um handler escreve a resposta num Writer (lição 28). **Escreva as
suas funções contra `io.Reader` e `io.Writer`, e não contra um arquivo ou uma string**, e elas
funcionam com tudo isso, e num teste com um `strings.Reader` e um `bytes.Buffer`, sem mudança.
