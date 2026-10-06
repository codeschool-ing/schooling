---
title: Floats são frações binárias, e 0.1 não é uma delas
version: 1
---

A imagem que quase todo mundo traz é que `0.1` num programa é o número um décimo. Não é. O
`float64` e o `float32` de Go são ponto flutuante binário, os formatos IEEE 754 (o
`go doc builtin.float64` diz isso numa linha), e **uma fração binária não consegue guardar um décimo
exatamente, assim como uma fração decimal não consegue guardar um terço**. O que `0.1` entrega é o
número mais próximo que o formato tem, e a diferença aparece no momento em que você faz uma conta.

## 0.1 + 0.2

```go
package main

import (
	"fmt"
	"math"
)

func main() {
	fmt.Println(0.1 + 0.2)

	a, b := 0.1, 0.2
	fmt.Println(a + b)
	fmt.Println(a+b == 0.3)
	fmt.Println(math.Abs(a+b-0.3) < 1e-9)

	fmt.Printf("%.20f\n", 0.1)
	fmt.Printf("%x\n", 0.1)
	fmt.Printf("%064b\n", math.Float64bits(0.1))
}
```

```
ana@vm:~/numbers-float$ go run .
0.3
0.30000000000000004
false
true
0.10000000000000000555
0x1.999999999999ap-04
0011111110111001100110011001100110011001100110011001100110011010
```

A primeira linha imprimiu `0.3`, o que parece um contraexemplo e não é. `0.1 + 0.2` escrito com
duas constantes é calculado pelo compilador, exatamente, do jeito que a lição 5 descreveu para
constantes sem tipo, e só o resultado vira `float64`. Ponha os mesmos dois números em variáveis e a
soma acontece em tempo de execução, em `float64`, onde dá `0.30000000000000004`. Isso não é igual a
`0.3`, e o `==` diz `false`.

As três últimas linhas mostram por quê. Impresso com vinte casas decimais, `0.1` é
`0.10000000000000000555`. O `%x` imprime o float em hexadecimal: `0x1.999999999999ap-04` é 1,6
vezes 2⁻⁴, onde 1,6 em hexadecimal é `1.999…` sem fim, cortado depois de treze dígitos e com o
último arredondado para cima, `a`. O `%064b` imprime os 64 bits:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os 64 bits do float64 mais próximo de 0.1, divididos em três campos. O primeiro bit, o sinal, é 0 para positivo. Os 11 bits seguintes, o expoente, valem 1019, o que quer dizer vezes 2 elevado a menos 4. Os últimos 52 bits, a fração, são o padrão 1001 que se repete, cortado e arredondado para cima, então o valor guardado é 0.10000000000000000555 e não 0.1.\"><rect x=\"25.0\" y=\"27\" width=\"8.5\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"35.5\" y=\"27\" width=\"113.5\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"27\" width=\"544.0\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"29.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0</text><text x=\"39.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0</text><text x=\"50.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"60.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"71.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"81.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"92.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"102.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"113.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"123.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0</text><text x=\"134.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"144.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"155.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"165.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"176.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"186.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"197.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"207.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"218.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"228.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"239.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"249.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"260.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"270.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"281.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"291.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"302.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"312.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"323.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"333.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"344.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"354.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"365.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"375.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"386.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"396.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"407.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"417.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"428.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"438.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"449.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"459.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"470.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"480.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"491.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"501.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"512.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"522.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"533.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"543.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"554.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"564.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"575.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"585.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"596.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"606.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"617.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"627.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"638.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"648.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"659.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"669.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"680.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"690.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><path d=\"M24.0 62 L34.5 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"24.0\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">sinal</text><text x=\"24.0\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 bit</text><path d=\"M34.5 62 L150.0 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"92.25\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">expoente</text><text x=\"92.25\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">11 bits</text><path d=\"M150.0 62 L696.0 62\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"423.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">fração</text><text x=\"423.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">52 bits</text><text x=\"24\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">0 quer dizer positivo</text><text x=\"24\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">1019 − 1023 = −4, então × 2⁻⁴</text><text x=\"330\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1,1001 1001 1001 … : o 1001 não acaba nunca,</text><text x=\"330\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">então é cortado em 52 bits e arredondado para cima</text><rect x=\"24\" y=\"180\" width=\"672\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que o float64 guarda de fato para 0.1:</text><text x=\"420\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0.10000000000000000555</text></svg>", "caption": "Os 64 bits que o %064b imprimiu para 0.1, nos três campos de um float64.", "same": ["1 bit", "11 bits", "52 bits"]}
```

O `float32` é o mesmo formato na metade dos bits, com 8 para o expoente e 23 para a fração, então é
ainda mais grosseiro. Use `float64`, a menos que você esteja guardando milhões deles e tenha medido
que a precisão basta; é o tipo que Go dá a `4.2` quando nada mais diz.

**Nunca compare dois floats calculados com `==`.** Compare o tamanho da diferença entre eles com uma
tolerância, `math.Abs(a+b-0.3) < 1e-9` no programa acima, e escolha a tolerância pelo problema: um
bilionésimo é folgado para um preço e inútil para um átomo.

## Infinito e NaN

Floats têm três valores que inteiros não têm: infinito positivo, infinito negativo e NaN, "not a
number" (não é um número). Dividir por zero produz esses valores em vez de um panic:

```go
package main

import (
	"fmt"
	"math"
)

func main() {
	zero := 0.0
	fmt.Println(1/zero, -1/zero)

	nan := zero / zero
	fmt.Println(nan, math.Sqrt(-1))
	fmt.Println(nan == nan, nan != nan)
	fmt.Println(math.IsNaN(nan), math.IsInf(1/zero, 1))
	fmt.Println(nan > 1, nan < 1)
}
```

```
ana@vm:~/numbers-nan$ go run .
+Inf -Inf
NaN NaN
false true
true true
false false
```

`1/zero` é `+Inf` e `-1/zero` é `-Inf`. `zero/zero` não tem resposta que faça sentido, e a raiz
quadrada de −1 entre os números reais também não, então os dois dão `NaN`. **NaN não é igual a
nada, nem a si mesmo**: `nan == nan` é `false` e `nan != nan` é `true`, e toda comparação de ordem
com ele também é `false`. Então `x == math.NaN()` nunca encontra um. Pergunte ao `math.IsNaN`, e,
para infinitos, ao `math.IsInf`, cujo segundo argumento diz que sinal procurar (1 para positivo).

Um NaN não para nada. Ele atravessa toda conta em que encosta e sai do outro lado como `NaN`, e por
isso o lugar de checar é onde ele pode aparecer pela primeira vez.

## Nunca dinheiro em floats

Aqui estão dez moedas de dez centavos, somadas duas vezes:

```go
// Command money adds ten coins of ten cents, twice.
package main

import "fmt"

func main() {
	total := 0.0
	for range 10 {
		total += 0.10
	}
	fmt.Println(total, total == 1.0)
	fmt.Printf("%.2f\n", total)

	cents := 0
	for range 10 {
		cents += 10
	}
	fmt.Println(cents, cents == 100)
	fmt.Printf("R$ %d,%02d\n", cents/100, cents%100)
}
```

```
ana@vm:~/numbers-money$ go run .
0.9999999999999999 false
1.00
100 true
R$ 1,00
```

Dez vezes `0.10` num `float64` dá `0.9999999999999999`, e isso não é igual a `1.0`. **O `%.2f`
imprimiu `1.00`, e é assim que um erro de float chega à produção: toda tela o arredonda e toda
comparação o enxerga.** Uma conferência de saldo, um teste de "pago integralmente" ou uma soma que
precisa bater com o extrato do banco erra por uns 0,0000000000000001, e ninguém consegue ver por
quê.

A correção é contar a menor unidade como inteiro. Dez moedas de 10 centavos são 100 centavos,
exatamente, e a divisão inteira e o `%` transformam isso de volta em reais e centavos para exibir,
como mostra a última linha. Dinheiro é um `int64` de centavos, nunca um `float64` de reais.
(`for range 10` roda o corpo dez vezes; laços são a lição 17.)
