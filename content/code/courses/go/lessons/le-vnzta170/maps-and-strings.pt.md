---
title: Percorrendo maps e strings
version: 1
---

O `range` funciona com mais do que slices, e cada tipo de valor decide o que as duas variáveis
guardam. Um map entrega uma **chave** e o seu valor, onde uma slice entregava um índice. Uma string
entrega um **deslocamento em bytes** e uma rune, e é essa que surpreende, e é a segunda metade
desta seção.

## Maps: chave, valor e nenhuma ordem

A lição 14 percorreu o mesmo map duas vezes e obteve duas ordens diferentes.
Essa é a primeira coisa a saber sobre `for key, value := range m`: **a ordem não é algo em que você possa confiar.**
Todo o resto sobre percorrer um map vem disso. Este programa percorre um map de três jeitos:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"maps\"\n\t\"slices\"\n)\n\nfunc main() {\n\tstock := map[string]int{\"apples\": 3, \"pears\": 0, \"plums\": 7, \"figs\": 0}\n\n\tfor fruit, n := range stock {\n\t\tif n == 0 {\n\t\t\tdelete(stock, fruit)\n\t\t}\n\t}\n\tfmt.Println(stock)\n",
      "note": "**Apagar entradas enquanto você percorre um map é permitido.** As frutas que acabaram sumiram, seja qual for a ordem que o percurso tomou. O `fmt.Println` imprime um map com as chaves ordenadas, como a lição 14 avisou, então esta linha sai igual em toda execução."
    },
    {
      "code": "\n\tfor _, fruit := range slices.Sorted(maps.Keys(stock)) {\n\t\tfmt.Println(fruit, stock[fruit])\n\t}\n",
      "note": "Quando a ordem importa, percorra uma slice ordenada das chaves. É a técnica da lição 14, com o `range` sobre a slice fazendo o que um índice fazia lá."
    },
    {
      "code": "\n\ttotal := 0\n\tfor n := range maps.Values(stock) {\n\t\ttotal += n\n\t}\n\tfmt.Println(\"total\", total)\n}\n",
      "note": "`maps.Values` devolve um **iterador**, uma função que entrega os valores um de cada vez, e o `range` o aceita diretamente. Uma soma não liga para ordem, então a ordem do próprio map serve aqui."
    }
  ],
  "output": "map[apples:3 plums:7]\napples 3\nplums 7\ntotal 10"
}
```

Acrescentar entradas durante um percurso é a outra metade da regra, e ela é mais fraca. Uma entrada
criada enquanto o laço roda pode ser visitada ou pode ser pulada, e a especificação da linguagem
deixa a escolha em aberto. Monte as entradas novas num segundo map e copie-as quando o laço
terminar.

O último laço merece mais uma palavra. O `go doc maps.Keys` da lição 14 mostrou um tipo de retorno
`iter.Seq[K]`, que é o tipo de uma função dessas. Antes do Go 1.23, o `range` não conseguia
chamá-la:

```
ana@vm:~/loops-map$ go mod edit -go=1.22 && go run .
# example.com/loops-map
./main.go:24:17: cannot range over maps.Values(stock) (value of func type iter.Seq[int]): requires go1.23 or later (-lang was set to go1.22; check go.mod)
```

Escrever um iterador seu precisa de valores de função, o assunto da lição 21. Percorrer os que a
biblioteca padrão devolve não pede nada além do que você acabou de ver.

## Strings: deslocamentos em bytes e runes

A lição 9 mostrou que `s[i]` é um byte, e que fatiar uma string contando caracteres dá errado fora
do ASCII. **O `range` sobre uma string decodifica o UTF-8 por você**: a cada volta ele dá o
deslocamento em bytes onde uma rune começa, e a rune. Este programa põe as duas formas de percorrer
uma string lado a lado, numa string com um `é` e um byte que não é UTF-8 de jeito nenhum:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\ts := \"café\\xff!\"\n\n\tfor i, r := range s {\n\t\tfmt.Printf(\"%d %U\\n\", i, r)\n\t}\n",
      "note": "**A primeira variável é um deslocamento em bytes, não uma contagem de caracteres.** Ela vai 0, 1, 2, 3 e depois 5, porque o `é` no deslocamento 3 ocupou dois bytes. `\\xff` não começa caractere nenhum, então o `range` devolve U+FFFD, o caractere de substituição, e avança um único byte, até o `!` no 6."
    },
    {
      "code": "\n\tfmt.Println(len(s))\n\tfor i := 0; i < len(s); i++ {\n\t\tfmt.Printf(\"%d %x\\n\", i, s[i])\n\t}\n}\n",
      "note": "Indexar com um laço de três cláusulas percorre os 7 bytes. `c3 a9` é o `é`, como a lição 8 o imprimiu, e `ff` é o byte quebrado, passado adiante intacto."
    }
  ],
  "output": "0 U+0063\n1 U+0061\n2 U+0066\n3 U+00E9\n5 U+FFFD\n6 U+0021\n7\n0 63\n1 61\n2 66\n3 c3\n4 a9\n5 ff\n6 21"
}
```

Seis voltas contra sete bytes. Nenhum dos dois laços está errado: o de bytes é o certo para um
formato de arquivo ou um checksum, e o de `range` para qualquer coisa que trate a string como texto.

O U+FFFD pede uma leitura cuidadosa, porque o `range` não falhou no byte quebrado. Ele produziu uma
rune perfeitamente válida, a mesma que a biblioteca padrão chama de seu valor de erro:

```
ana@vm:~/loops-string$ go doc unicode/utf8.RuneError | grep 'RuneError ='
	RuneError = '\uFFFD'     // the "error" Rune or "Unicode replacement character"
```

Então um programa que copia texto rune a rune com `range` transforma cada byte quebrado num U+FFFD
válido, e daí em diante ninguém consegue saber que o texto um dia esteve quebrado. **Quando uma
string vem de fora do seu programa e a correção dela importa, confira-a com `utf8.ValidString`
antes do laço**, como a lição 9 aconselhou, em vez de procurar o estrago depois.

## O que o `range` dá, por tipo

| você percorre | a primeira variável | a segunda variável |
|---|---|---|
| um inteiro `n` | de 0 a `n`-1 | nenhuma |
| uma slice ou um array | o índice | uma cópia do elemento |
| uma string | o deslocamento em bytes onde uma rune começa | a rune |
| um map | a chave | uma cópia do valor |
| um iterador como `maps.Values(m)` | o que o iterador entrega | em alguns iteradores, um segundo valor |

Channels também podem ser percorridos. Eles pertencem ao curso `go-concurrency`, junto com as
goroutines que enviam valores por eles.
