---
title: Quanto custa uma cópia
version: 1
---

Duas crenças opostas sobre cópias andam juntas. Uma diz que copiar é lento, então toda struct
deveria ser passada por um ponteiro. A outra diz que copiar é de graça, então nunca importa. **Uma
cópia custa em proporção aos bytes copiados**, e as duas crenças acertam sobre algum tamanho e erram
sobre o resto. O jeito de descobrir de que lado da linha um valor está é medir, e um programa Go
pode medir a si mesmo com o pacote `testing` da biblioteca padrão, chamado a partir de `main`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"testing\"\n\t\"unsafe\"\n)\n\ntype Point struct{ X, Y int }\n\ntype Record struct {\n\tID     int\n\tValues [127]int\n}\n\nvar big [1_000_000]int\n",
      "note": "Quatro valores de quatro tamanhos. `Point` são dois `int`, 16 bytes. `Record` é um `int` e um array de mais 127, 1.024 bytes. `big` é um milhão de `int`, o array que a lição 13 disse que esta lição mediria."
    },
    {
      "code": "\n//go:noinline\nfunc viaPoint(p Point) int { return p.X }\n\n//go:noinline\nfunc viaRecord(r Record) int { return r.ID }\n\n//go:noinline\nfunc viaArray(a [1_000_000]int) int { return a[0] }\n\n//go:noinline\nfunc viaSlice(s []int) int { return s[0] }\n",
      "note": "Cada função recebe um deles por valor e lê um campo, então o trabalho lá dentro é o mesmo e só a cópia muda. **`//go:noinline`, sem espaço depois das barras, diz ao compilador para não colar a função dentro de quem a chama**; sem ele uma função de uma linha é embutida, e a cópia que se quer medir pode sumir na otimização."
    },
    {
      "code": "\nfunc main() {\n\tvar p Point\n\tvar r Record\n\ts := big[:]\n\tfmt.Println(unsafe.Sizeof(p), unsafe.Sizeof(r), unsafe.Sizeof(big), unsafe.Sizeof(s))\n",
      "note": "`s` é uma slice sobre `big` inteiro, então `viaSlice` lê o mesmo elemento que `viaArray`. A primeira linha imprime os quatro tamanhos."
    },
    {
      "code": "\tfmt.Println(\"Point \", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaPoint(p)\n\t\t}\n\t}))\n\tfmt.Println(\"Record\", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaRecord(r)\n\t\t}\n\t}))\n\tfmt.Println(\"array \", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaArray(big)\n\t\t}\n\t}))\n\tfmt.Println(\"slice \", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaSlice(s)\n\t\t}\n\t}))\n}\n",
      "note": "**`testing.Benchmark` executa a função que recebe e devolve quanto tempo uma volta do laço levou.** `b.Loop()` mantém o laço girando até completar cerca de um segundo, o padrão, e o resultado impresso é o número de voltas e o tempo por volta."
    }
  ]
}
```

```
ana@vm:~/byvalue-cost$ go run .
16 1024 8000000 24
Point  617491884	         1.954 ns/op
Record 81182157	        15.51 ns/op
array      3415	    350746 ns/op
slice  560946219	         2.026 ns/op
```

Os números pertencem a esta execução, na máquina do laboratório, um Xeon de 4 núcleos a 2,10 GHz;
rode de novo e cada um deles se mexe um pouco. Leia cada linha como o número de voltas que couberam
em cerca de um segundo e, depois, o tempo que uma volta levou.

| passado por valor | bytes copiados | tempo por chamada |
|---|---|---|
| `Point` | 16 | 1,954 ns |
| `Record` | 1.024 | 15,51 ns |
| `[1_000_000]int` | 8.000.000 | 350.746 ns |
| `[]int` sobre esse array | 24 | 2,026 ns |

`Point` e a slice levaram cerca de dois nanossegundos cada, que é o preço de uma chamada; a cópia de
16 ou 24 bytes se perde dentro dele. `Record` copiou sessenta e quatro vezes os bytes de `Point` e
levou cerca de oito vezes mais, ainda nada que um programa perceba, a menos que a chamada esteja num
laço que roda milhões de vezes. **O array levou cerca de um terço de milissegundo por chamada**,
gasto copiando um milhão de `int` para que a função lesse um deles, e mil chamadas assim somam cerca
de um terço de segundo. A slice leu o mesmo elemento pelo custo de uma chamada, porque o array não
foi copiado.

Então o array grande é o caso sobre o qual a lição 13 avisou, e **a correção de costume para um
array grande é uma slice sobre ele**, que a lição 11 mostrou ter 24 bytes seja o que for que ela
enxergue. A função passa a compartilhar os elementos de quem chamou em vez de receber os seus, que é
a troca descrita na seção 03: mais barato, e não mais uma cópia particular.

## O que fazer com isso

A maioria das structs em programas reais tem um punhado de campos: um nome, alguns números, um
horário. Elas ficam na ponta `Point` desta medição, e **passá-las por valor é a escolha normal**, não
um hábito a ser abandonado. A cópia é o que torna uma função segura de chamar. Nada do que ela faz
com o seu parâmetro alcança quem chamou, como a seção 02 mostrou, e essa garantia vale mais do que
alguns nanossegundos.

O outro jeito de evitar uma cópia grande é um ponteiro, a lição 23. Ele também não sai de graça: um
valor cujo endereço é tomado pode ter de morar fora da memória da própria função, e a lição 24 mostra
o compilador decidindo onde. Um ponteiro escolhido para poupar uma cópia que nunca foi cara paga esse
custo por nada, então meça primeiro, como esta seção fez.

O `testing.Benchmark` chamado de `main` basta para uma medição avulsa como esta. O jeito de todo dia
de escrever benchmarks é em arquivos de teste executados por `go test -bench`, que pertence ao curso
`go-concurrency` junto com o resto do `go test`.
