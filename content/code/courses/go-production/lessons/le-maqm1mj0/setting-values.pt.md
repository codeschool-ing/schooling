---
title: Alterando um valor e chamando um método pelo nome
version: 1
---

Ler é metade do que o `reflect` faz. A outra metade é escrever: alterar uma variável, preencher um
campo de struct pelo nome, chamar um método cujo nome chegou como string. O `encoding/json` faz as
duas primeiras toda vez que decodifica, e o `text/template` faz a terceira quando um template diz
`{{.Describe}}`: ele chama `MethodByName` com a palavra que leu. **A regra para escrever é a que as
lições 22 e 23 do curso `go` ensinaram para funções: para alterar uma variável você precisa do
endereço dela, e uma cópia não serve.** A reflexão só torna a regra visível, como um método chamado
`CanSet`.

## Poder alterar quer dizer ser alcançável por um endereço

Um programa que altera um `int` e um campo de struct, chama um método e comete um erro escolhido
pelo argumento, em `~/reflect`:

```schooling-example
{
  "language": "go",
  "file": "set/main.go",
  "parts": [
    {
      "code": "// Command set changes values through reflect, and with an argument makes\n// one of the mistakes reflect refuses at run time.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"reflect\"\n)\n\n// Config is something a program might fill in by reflection.\ntype Config struct {\n\tName   string\n\tLimit  int\n\tsecret string\n}\n\n// Describe is a method for reflect to find by its name.\nfunc (c Config) Describe(prefix string) string {\n\treturn fmt.Sprintf(\"%s %s keeps %d\", prefix, c.Name, c.Limit)\n}\n",
      "note": "Uma struct com dois campos exportados e um não exportado, e um método com um parâmetro, para haver o que alterar e o que chamar."
    },
    {
      "code": "func main() {\n\tx := 10\n\tv := reflect.ValueOf(x)\n\te := reflect.ValueOf(&x).Elem()\n\tfmt.Println(\"ValueOf(x).CanSet():\", v.CanSet())\n\tfmt.Println(\"ValueOf(&x).Elem().CanSet():\", e.CanSet())\n\te.SetInt(25)\n\tfmt.Println(\"x is now\", x)\n",
      "note": "**`v` guarda uma cópia de `x`; `e` chega ao próprio `x`, pelo endereço.** Só `e` pode ser alterado, e alterá-lo muda a variável que o programa declarou."
    },
    {
      "code": "\tc := Config{Name: \"hits\", Limit: 3}\n\ts := reflect.ValueOf(&c).Elem()\n\ts.FieldByName(\"Limit\").SetInt(10)\n\tfmt.Printf(\"%+v\\n\", c)\n\tfmt.Println(\"secret CanSet():\", s.FieldByName(\"secret\").CanSet())\n",
      "note": "A mesma regra para uma struct: comece por um ponteiro, pegue o `Elem`, e todo campo exportado abaixo dele pode ser alterado. `secret` é alcançável e mesmo assim é recusado."
    },
    {
      "code": "\tm := reflect.ValueOf(c).MethodByName(\"Describe\")\n\tout := m.Call([]reflect.Value{reflect.ValueOf(\"config\")})\n\tfmt.Println(out[0])\n",
      "note": "O `MethodByName` acha um método por uma string, e o `Call` recebe os argumentos como uma slice de `reflect.Value` e devolve os resultados do mesmo jeito."
    },
    {
      "code": "\tif len(os.Args) < 2 {\n\t\treturn\n\t}\n\tswitch os.Args[1] {\n\tcase \"copy\":\n\t\tv.SetInt(25)\n\tcase \"kind\":\n\t\te.SetString(\"ten\")\n\tcase \"unexported\":\n\t\ts.FieldByName(\"secret\").SetString(\"open\")\n\tcase \"args\":\n\t\tm.Call(nil)\n\tcase \"typo\":\n\t\treflect.ValueOf(c).MethodByName(\"Describ\").Call(nil)\n\t}\n}",
      "note": "Cada palavra na linha de comando comete um erro. **Os cinco compilam, e os cinco passam no `go vet`**: o compilador vê chamadas a métodos de `reflect.Value` com os tipos certos, e é só isso que há para ver."
    }
  ]
}
```

Conferido pelo `go vet` e depois rodado sem argumento:

```
ana@vm:~/reflect$ go vet ./set && go run ./set
ValueOf(x).CanSet(): false
ValueOf(&x).Elem().CanSet(): true
x is now 25
{Name:hits Limit:10 secret:}
secret CanSet(): false
config hits keeps 10
```

**`ValueOf(x)` não pode ser alterado, e `ValueOf(&x).Elem()` pode.** A seção 02 mostrou o motivo: o
`ValueOf` recebe um `any`, e pôr `x` dentro de um `any` o copiou. Alterar essa cópia não mudaria nada
que alguém pudesse ver, então o pacote se recusa a fingir. Passar `&x` põe um ponteiro no `any`, uma
cópia do endereço, e o `Elem` segue o endereço de volta até a própria variável. O `x is now 25` é a
prova de que era o `x` de verdade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A variável x guarda 10. reflect.ValueOf(x) recebe uma cópia de 10 dentro de um any, então seu Value diz CanSet false, e SetInt entra em pânico com unaddressable value. reflect.ValueOf(&amp;x).Elem() parte de um ponteiro para x, então seu Value é o próprio x, CanSet é true, e e.SetInt(25) faz x passar de 10 para 25.\"><defs><marker id=\"st-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"st-phos\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"st-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">x := 10</text><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a variável x</text><rect x=\"300\" y=\"88\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10  -&gt;  25</text><text x=\"130\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">reflect.ValueOf(x)</text><rect x=\"40\" y=\"88\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma cópia de 10, no any</text><path d=\"M298 108 L224 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#st-amber)\"></path><text x=\"260\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">copiado</text><text x=\"130\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">CanSet() == false</text><text x=\"130\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mudar isso mudaria só a cópia,</text><text x=\"130\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">então o SetInt entra em pânico</text><text x=\"590\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">reflect.ValueOf(&amp;x).Elem()</text><rect x=\"500\" y=\"88\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um ponteiro para x</text><path d=\"M498 108 L424 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-phos)\"></path><text x=\"460\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">aponta para x</text><text x=\"590\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">CanSet() == true</text><text x=\"590\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mudar isso muda o próprio x:</text><text x=\"590\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">e.SetInt(25)</text></svg>", "caption": "Poder mudar quer dizer ser alcançável por um endereço. ValueOf(x) recebe uma cópia; ValueOf(&x).Elem() recebe o caminho de volta até x."}
```

A struct funciona do mesmo jeito. **`ValueOf(&c).Elem()` é a própria struct `c`, e todo campo
exportado abaixo dela pode ser alterado**: `Limit` foi de 3 para 10. `secret` é alcançável e mesmo assim dá
`CanSet() false`, pelo motivo que a seção 03 deu. A recusa vale até aqui, dentro do pacote `main`,
onde `Config` foi declarado e o código comum pode escrever `c.secret` à vontade. O `%+v` imprimiu
`secret:` com o valor vazio, o que mostra que o `fmt` lê campos não exportados quando imprime; ler é
permitido, escrever não.

`MethodByName("Describe")` devolveu o método como um `Value` ligado a `c`, e o `Call` o executou.
**Os argumentos entram como `[]reflect.Value` e os resultados voltam do mesmo jeito**, então `out[0]`
é um `Value` que guarda a string. O `Describe` viu `Limit` valendo 10, porque `c` tinha sido alterado
antes de o `ValueOf(c)` copiá-lo.

## Cinco erros, e quando cada um aparece

Cada argumento comete um erro. Aqui aparece só a primeira linha de cada pânico:

```
ana@vm:~/reflect$ for m in copy kind unexported args typo; do go run ./set $m 2>&1 | grep ^panic; done
panic: reflect: reflect.Value.SetInt using unaddressable value
panic: reflect: call of reflect.Value.SetString on int Value
panic: reflect: reflect.Value.SetString using value obtained using unexported field
panic: reflect: Call with too few input arguments
panic: reflect: call of reflect.Value.Call on zero Value
```

| argumento | o que o programa fez | o mesmo erro sem `reflect` |
|---|---|---|
| `copy` | alterou um `Value` feito de `x` em vez de `&x` | alterar um parâmetro, o que compila e não faz nada |
| `kind` | `SetString` num `int` | `x = "ten"`, erro de compilação |
| `unexported` | alterou `secret` | `c.secret = "open"` em outro pacote, erro de compilação |
| `args` | chamou `Describe` sem argumento | `c.Describe()`, erro de compilação |
| `typo` | pediu `Describ`, recebeu o `Value` zero e o chamou | `c.Describ`, erro de compilação |

**Quatro dos cinco são erros de compilação no Go comum, e todos eles compilaram aqui e passaram no
`go vet`**, que rodou limpo neste arquivo na primeira transcrição. O `typo` é o mais traiçoeiro: **um
nome mal escrito não falha onde foi escrito**. O `MethodByName` devolve o `Value` zero sem reclamar, e
o pânico vem do `Call`, uma linha depois, dizendo `zero Value` em vez de citar o método que ninguém
achou. Num programa maior, essa linha pode estar longe do erro de digitação.

Um pânico inteiro, para o `kind`:

```
ana@vm:~/reflect$ go run ./set kind 2>&1 | sed -n 7,20p
panic: reflect: call of reflect.Value.SetString on int Value

goroutine 1 [running]:
reflect.flag.mustBe(...)
	/usr/local/go/src/reflect/value.go:221
reflect.Value.SetString({0x577438?, 0x26f713b75d68?, 0x26f713b75df0?}, {0x4aa05b, 0x3})
	/usr/local/go/src/reflect/value.go:2330 +0xe7
main.main()
	/home/ana/reflect/set/main.go:49 +0x59f
exit status 2
```

O rastro aponta para `set/main.go:49`, a chamada ao `SetString`, e o `go run` informa o status de
saída 2 do programa. Um pânico para o programa na primeira chamada errada que ele alcança, então
**um caminho de código reflexivo que nenhum teste executa é um caminho cujos erros ninguém viu**.
Uma biblioteca que reflete sobre valores que recebeu costuma conferir `Kind` e `CanSet` antes de
cada escrita e devolver um erro, como o `columns.Reflect` confere se recebeu uma slice de structs na
seção 03. Fazer isso à mão, para cada caso, é parte do que a reflexão custa.
