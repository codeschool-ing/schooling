---
title: Um erro embrulhado é uma cadeia
version: 1
---

A lição 33 embrulhou erros com `%w` e imprimiu o resultado, e o que saiu foi uma mensagem mais
comprida. Isso faz o embrulho parecer concatenação de strings com passos a mais. **Não é: um erro
embrulhado com `%w` é um valor novo que guarda o antigo**, e o antigo continua lá, inteiro, para
qualquer código que for procurá-lo. Este programa vai procurar. Ele tenta ler um arquivo de
configuração que não existe, embrulha a falha duas vezes no caminho para cima e depois a desmonta:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n\t\"os\"\n)\n\n",
      "note": "O programa importa `errors` por uma função só, `errors.Unwrap`, e `os` para ler um arquivo que não existe."
    },
    {
      "code": "func readConfig(path string) ([]byte, error) {\n\tdata, err := os.ReadFile(path)\n\tif err != nil {\n\t\treturn nil, fmt.Errorf(\"read config: %w\", err)\n\t}\n\treturn data, nil\n}\n\n",
      "note": "**`readConfig` embrulha o que `os.ReadFile` devolveu**, com `%w` e as palavras `read config`, exatamente como a lição 33 fez."
    },
    {
      "code": "func start() error {\n\tif _, err := readConfig(\"settings.json\"); err != nil {\n\t\treturn fmt.Errorf(\"start server: %w\", err)\n\t}\n\treturn nil\n}\n\n",
      "note": "**`start` embrulha de novo**, então o erro que ela devolve tem duas camadas de contexto sobre a que `os.ReadFile` criou."
    },
    {
      "code": "func main() {\n\terr := start()\n\tfmt.Println(err)\n\tfor e := err; e != nil; e = errors.Unwrap(e) {\n\t\tfmt.Printf(\"%-20T %v\\n\", e, e)\n\t}\n}\n",
      "note": "**O laço tira um elo a cada volta.** `errors.Unwrap(e)` devolve o erro que `e` guarda, ou `nil` quando não guarda nenhum, e o `nil` encerra o laço. `%-20T` imprime o tipo de cada elo, completado até 20 colunas, e depois `%v` a mensagem."
    }
  ],
  "output": "start server: read config: open settings.json: no such file or directory\n*fmt.wrapError       start server: read config: open settings.json: no such file or directory\n*fmt.wrapError       read config: open settings.json: no such file or directory\n*fs.PathError        open settings.json: no such file or directory\nsyscall.Errno        no such file or directory\n"
}
```

A primeira linha é a mensagem que a lição 33 imprimiria. As quatro linhas abaixo dela são o mesmo
erro desmontado, um valor por linha, e cada valor é de um tipo diferente:

- dois `*fmt.wrapError`, que é o que `fmt.Errorf` devolve quando o formato tem um `%w`. O tipo não
  é exportado, então nenhum programa escreve o nome dele; o que importa é que ele tem um método
  `Unwrap() error` que devolve o erro que recebeu;
- um `*fs.PathError`, que `os.ReadFile` criou: a operação, o caminho e o erro por trás deles. Ele
  também tem um método `Unwrap`, e foi assim que o laço passou por ele;
- um `syscall.Errno`, o número com que o sistema operacional respondeu à chamada `open`, impresso
  em palavras. Ele não tem método `Unwrap`, então `errors.Unwrap` devolveu `nil` e o laço parou.

**`errors.Unwrap` faz uma coisa pequena: chama o método `Unwrap` do erro se ele tiver um, e devolve
`nil` se não tiver.** Nada mais na cadeia é mágico. Um embrulho é qualquer tipo de erro com esse
método, e o `%w` da lição 33 é o jeito mais rápido de criar um.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"O erro que start devolveu, desenhado como uma cadeia de quatro valores. O mais externo é um *fmt.wrapError cuja mensagem acrescenta &#x27;start server: &#x27;; Unwrap leva a um segundo *fmt.wrapError que acrescenta &#x27;read config: &#x27;; Unwrap leva a um *fs.PathError feito por os.ReadFile, que acrescenta &#x27;open settings.json: &#x27;; Unwrap leva a um syscall.Errno cuja mensagem é &#x27;no such file or directory&#x27;. Ele não tem método Unwrap, então a cadeia termina ali.\"><defs><marker id=\"ch-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*fmt.wrapError</text><text x=\"32\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">start server: </text><text x=\"116.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">read config: open settings.json: no such file or directory</text><text x=\"520\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o embrulho de start: o erro</text><text x=\"520\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">que main recebeu</text><path d=\"M60 66 L60 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><rect x=\"20\" y=\"94\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*fmt.wrapError</text><text x=\"32\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">read config: </text><text x=\"110.0\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">open settings.json: no such file or directory</text><text x=\"520\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o embrulho de readConfig</text><path d=\"M60 146 L60 174\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><rect x=\"20\" y=\"174\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*fs.PathError</text><text x=\"32\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">open settings.json: </text><text x=\"152.0\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">no such file or directory</text><text x=\"520\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">feito por os.ReadFile: a</text><text x=\"520\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">operação, o caminho, a causa</text><path d=\"M60 226 L60 254\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><rect x=\"20\" y=\"254\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">syscall.Errno</text><text x=\"32\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">no such file or directory</text><text x=\"520\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a resposta da chamada de sistema</text><path d=\"M60 306 L60 334\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><text x=\"60\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">nil</text><text x=\"84\" y=\"344\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem método Unwrap: a cadeia termina aqui</text></svg>", "caption": "O erro que start devolveu são quatro valores, cada um guardando o seguinte. A parte em negrito de cada mensagem é o que aquele elo acrescentou; errors.Unwrap segue uma seta, e errors.Is e errors.As seguem todas."}
```

Cada mensagem contém a mensagem do elo de baixo, porque a mensagem de cada elo foi montada com as
palavras dele seguidas da mensagem do erro que ele guarda. É por isso que a linha de cima se lê da
esquerda para a direita como a história da falha. **A mensagem é um subproduto da cadeia, e é a
cadeia que o código inspeciona.** As seções 03 e 04 tratam de inspecioná-la.

## Mais de um `%w` forma uma árvore

A lição 33 também embrulhou vários erros de uma vez, com vários `%w` num formato só ou com
`errors.Join`. Um erro feito assim guarda uma lista, e o método dele é `Unwrap() []error`, um
método diferente do de cima. `errors.Unwrap` só chama a forma de um erro só, então desiste diante
de um erro juntado:

```go
	both := errors.Join(fs.ErrNotExist, fs.ErrPermission)
	fmt.Printf("%T\n", both)
	fmt.Println(errors.Unwrap(both))
	fmt.Println(errors.Is(both, fs.ErrPermission))
```

```
ana@vm:~/is-as-tree$ go run .
*errors.joinError
<nil>
true
```

`errors.Unwrap` diz que não há nada dentro, e a linha seguinte encontra `fs.ErrPermission` lá
dentro mesmo assim. A documentação do pacote chama a forma geral de **árvore**: uma cadeia em que
qualquer elo pode se ramificar. `errors.Is` e `errors.As` percorrem tudo, primeiro o próprio erro e
depois cada ramo por vez, em profundidade.

Então `errors.Unwrap` é a ferramenta para olhar uma cadeia, como o laço acima fez, e raramente a
ferramenta para decidir alguma coisa. O código que precisa decidir o que fazer com um erro faz uma
de duas perguntas — um erro em particular está ali dentro, ou um erro de um tipo em particular está
ali dentro — e cada pergunta tem a sua função.
