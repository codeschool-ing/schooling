---
title: Comprimento e capacidade
version: 1
---

A lição 11 desenhou uma slice como três coisas sobre um array: onde ela começa, seu comprimento e
sua capacidade. Os dois números se confundem com facilidade, e o jeito mais comum de confundi-los é
acreditar que o comprimento é até onde a slice enxerga. Não é. **O comprimento é até onde você pode
indexar; a capacidade é até onde a slice pode ser esticada.** O array continua depois do
comprimento, você olhe para ele ou não.

Aqui está uma semana num array, e uma slice do meio dela:

```go
package main

import "fmt"

func main() {
	week := [7]string{"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
	mid := week[2:4]
	fmt.Println(mid, len(mid), cap(mid))

	more := mid[:5]
	fmt.Println(more, len(more), cap(more))

	fmt.Println(mid[3])
}
```

```
ana@vm:~/slices$ go run .
[wed thu] 2 5
[wed thu fri sat sun] 5 5
panic: runtime error: index out of range [3] with length 2

goroutine 1 [running]:
main.main()
	/home/ana/slices/main.go:13 +0x19a
exit status 2
```

Três linhas de saída, e cada uma é uma regra.

`week[2:4]` começa em `wed` e para antes do índice 4, então seu comprimento é 2. A capacidade é 5,
porque é quantos elementos o array tem de `wed` até o fim: `wed`, `thu`, `fri`, `sat`, `sun`. A
capacidade é contada a partir de onde a slice **começa**, nunca do começo do array.

`mid[:5]` refaz o fatiamento de `mid` com comprimento 5, maior que o do próprio `mid`. Isso é
permitido, e mostra `fri`, `sat` e `sun`, que estavam no array o tempo todo. **Fatiar de novo para
cima é legal até a capacidade**, e entrega elementos que a slice mais curta nunca imprimiu.

`mid[3]` é o mesmo elemento que `more[3]`, `sat`, e mesmo assim o programa parou. Um índice é
conferido contra o **comprimento** e mais nada: `index out of range [3] with length 2` diz qual
índice você pediu e qual comprimento recusou. O compilador deixou passar, embora 3 seja uma
constante, porque o comprimento de uma slice só é conhecido quando o programa roda. As linhas
abaixo da mensagem são um stack trace, que a lição 37 lê quadro a quadro, e `exit status 2` é como
termina um programa Go que entrou em pânico, o que a lição 36 explica.

## Além da capacidade

Esticar também tem limite. Pedindo a `mid` seis elementos, um a mais que a capacidade:

```go
package main

import "fmt"

func main() {
	week := [7]string{"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
	mid := week[2:4]
	fmt.Println(mid[:6])
}
```

```
ana@vm:~/slices-cap$ go run .
panic: runtime error: slice bounds out of range [:6] with capacity 5

goroutine 1 [running]:
main.main()
	/home/ana/slices-cap/main.go:8 +0x6a
exit status 2
```

Esta mensagem fala em **capacidade**, onde a anterior falava em comprimento, e essa diferença é a
seção inteira numa linha. Contando a partir de `wed`, o array tem cinco elementos e nenhum sexto, e
uma slice nunca alcança antes do próprio começo, então `mon` e `tue` ficam fora do alcance dela,
peça o que pedir.

| você escreve | é conferido contra | além disso |
|---|---|---|
| `s[i]` | `len(s)`: `i` tem de ser menor | `index out of range [i] with length n` |
| `s[:j]` | `cap(s)`: `j` pode ser igual | `slice bounds out of range [:j] with capacity n` |

O espaço sobrando entre o comprimento e a capacidade é onde o `append` escreve, e esse é o assunto
da seção 03.
