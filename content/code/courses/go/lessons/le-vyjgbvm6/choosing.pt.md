---
title: Escolhendo o receptor
version: 1
---

Dois conselhos circulam, e os dois estão meio certos. Um diz para usar receptores ponteiro em todo
lugar porque eles evitam uma cópia. O outro diz para usar receptores por valor porque uma cópia é
segura. **O receptor não é escolhido método a método, por velocidade ou por segurança. Ele é
escolhido uma vez por tipo, a partir do que o tipo é**, e quatro perguntas resolvem, feitas nesta
ordem.

## 1. Algum método muda o receptor?

**Então esse método precisa de um ponteiro**, como a seção 02 mostrou: um receptor por valor muda uma
cópia e quem chamou nunca vê. É a pergunta que decide a maioria dos tipos, e quando um método
precisa de ponteiro, a regra no fim da pergunta 4 dá o ponteiro a todos eles.

## 2. O tipo guarda algo que não pode ser copiado?

Alguns valores param de funcionar quando copiados. O mais claro é um `sync.Mutex`, uma trava que
deixa só uma parte do programa por vez mexer em certos dados. Travas pertencem ao curso
`go-concurrency`; o que importa aqui é que **a cópia de uma trava é outra trava**, então um método
que copia uma está travando algo que mais ninguém segura. Aqui um receptor por valor a copia a cada
chamada:

```go
package main

import (
	"fmt"
	"sync"
)

type Stats struct {
	mu   sync.Mutex
	hits int
}

func (s *Stats) Hit() {
	s.mu.Lock()
	s.hits++
	s.mu.Unlock()
}

func (s Stats) Hits() int {
	s.mu.Lock()
	n := s.hits
	s.mu.Unlock()
	return n
}

func main() {
	var s Stats
	s.Hit()
	s.Hit()
	fmt.Println(s.Hits())
}
```

```
ana@vm:~/receivers-lock$ go run .
2
ana@vm:~/receivers-lock$ go vet; echo $?
main.go:19:9: Hits passes lock by value: example.com/stats.Stats contains sync.Mutex
1
```

O programa imprime a resposta certa, porque nada mais está rodando ao mesmo tempo, e o `go vet` o
recusa mesmo assim. A linha 19 é o receptor de `Hits`. `Hits` só lê, então pela pergunta 1 sozinha
poderia ter sido um método por valor. A pergunta 2 passa por cima disso: um tipo que guarda uma
trava recebe ponteiro em todo método. O `strings.Builder` diz o mesmo de si na própria documentação,
mais abaixo.

## 3. O valor é grande?

Um receptor por valor copia o valor inteiro a cada chamada, como qualquer parâmetro. A lição 22
mediu quanto isso custa na máquina do laboratório: 1,954 ns para passar uma struct de 16 bytes,
15,51 ns para uma de 1.024 bytes e 350.746 ns para um array de 8.000.000 bytes. Uma struct de
poucos campos não chega nem perto do tamanho que importa. **Um tipo que carrega um array grande
dentro de si chega, e os métodos dele recebem ponteiro.**

## 4. Senão, um valor, e de qualquer jeito um tipo de receptor por tipo

Um tipo pequeno usado como um número — uma data, uma quantia, uma coordenada — fica melhor com
receptores por valor. Os métodos dele devolvem valores novos em vez de mudar o antigo, e um valor
dele pode ser passado, guardado e impresso sem ninguém perguntar quem mais o segura. `time.Time` é
o exemplo da biblioteca padrão, e a documentação dele diz isso diretamente:

```
ana@vm:~/receivers$ go doc time.Time | head -10
package time // import "time"

type Time struct {
	// Has unexported fields.
}
    A Time represents an instant in time with nanosecond precision.

    Programs using times should typically store and pass them as values,
    not pointers. That is, time variables and struct fields should be of type
    time.Time, not *time.Time.
ana@vm:~/receivers$ go doc -all time | grep -c "^func (t Time)"
43
ana@vm:~/receivers$ go doc -all time | grep "^func (t \*Time)"
func (t *Time) GobDecode(data []byte) error
func (t *Time) UnmarshalBinary(data []byte) error
func (t *Time) UnmarshalJSON(data []byte) error
func (t *Time) UnmarshalText(data []byte) error
```

Quarenta e três métodos com receptor por valor e quatro com ponteiro, e os quatro não são um
descuido. Cada um decodifica um `Time` a partir de bytes, o que significa sobrescrever o receptor,
e essa é a pergunta 1. `t.Add(d)` devolve um `Time` novo; `t.UnmarshalJSON(data)` precisa
substituir `t`.

**Fora métodos como esses quatro, escolha um tipo de receptor para o tipo e use-o em todo método.**
A seção 03 é o motivo. Um tipo com métodos misturados tem um conjunto de métodos de valor ao qual
faltam alguns deles, então se um valor dele satisfaz uma interface depende de qual método a
interface por acaso nomeia. O `strings.Builder` mostra a outra metade da regra:

```
ana@vm:~/receivers$ go doc strings.Builder
package strings // import "strings"

type Builder struct {
	// Has unexported fields.
}
    A Builder is used to efficiently build a string using Builder.Write methods.
    It minimizes memory copying. The zero value is ready to use. Do not copy a
    non-zero Builder.

func (b *Builder) Cap() int
func (b *Builder) Grow(n int)
func (b *Builder) Len() int
func (b *Builder) Reset()
func (b *Builder) String() string
func (b *Builder) Write(p []byte) (int, error)
func (b *Builder) WriteByte(c byte) error
func (b *Builder) WriteRune(r rune) (int, error)
func (b *Builder) WriteString(s string) (int, error)
```

`Len`, `Cap` e `String` só leem, e recebem ponteiro como os demais, porque o tipo é um que não pode
ser copiado — "Do not copy a non-zero Builder" é a pergunta 2, nas palavras do próprio tipo. Um
`Builder` é feito para ser guardado como `*strings.Builder`, e a lição 27 passa um para uma função
que escreve nele.

Então as quatro perguntas se resumem a uma decisão por tipo:

| o tipo | receptor | exemplo |
|---|---|---|
| tem um método que o muda | ponteiro, em todo método | `strings.Builder` |
| guarda uma trava ou outra coisa que não pode ser copiada | ponteiro, em todo método | `Stats` acima |
| é grande | ponteiro, em todo método | uma struct que carrega um array grande |
| é pequeno e usado como um número | valor, em todo método | `time.Time`, `Money` |
