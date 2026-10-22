---
title: Fusos horários, e o layout que é uma data
version: 1
---

Um `time.Time` é um instante, o mesmo em toda a Terra, mais uma localização que diz como
imprimi-lo. **Mudar a localização muda as palavras na tela e nunca o instante.** A maioria dos erros
com fusos horários vem de tratar `14:30` como um fato, quando é `14:30` em algum lugar.

Uma reunião marcada em São Paulo, impressa em três outros lugares, salvo como `zones.go`:

```go
// Command zones prints one instant in several places.
package main

import (
	"fmt"
	"time"
)

func main() {
	sp, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		fmt.Println(err)
		return
	}
	meeting := time.Date(2026, time.October, 16, 14, 30, 0, 0, sp)
	for _, name := range []string{"UTC", "Europe/Lisbon", "Asia/Tokyo"} {
		loc, _ := time.LoadLocation(name)
		fmt.Printf("%-14s %s\n", name, meeting.In(loc).Format("2006-01-02 15:04 MST"))
	}
	fmt.Println("same instant:", meeting.Equal(meeting.UTC()))

	_, err = time.LoadLocation("America/Sao Paulo")
	fmt.Println(err)
}
```

```
ana@vm:~/clock$ go run zones.go
UTC            2026-10-16 17:30 UTC
Europe/Lisbon  2026-10-16 18:30 WEST
Asia/Tokyo     2026-10-17 02:30 JST
same instant: true
unknown time zone America/Sao Paulo
```

Duas e meia da tarde em São Paulo são 17:30 em UTC, três horas adiante. Lisboa está no horário de
verão em outubro, `WEST`, uma hora depois do UTC; Tóquio já está no dia seguinte. **`Equal` compara
instantes, e disse que o valor de São Paulo e a sua cópia em UTC são o mesmo.** O operador `==`
compara a struct inteira, localização incluída, e teria dito que diferem, então valores de tempo
são comparados com `Equal`, `Before` e `After`.

A última linha é o erro mais comum. Uma localização tem o nome do banco de dados da IANA, onde
espaços são sublinhados. O deslocamento de São Paulo é fixo, três horas atrás do UTC, desde que o
Brasil acabou com o horário de verão em 2019, e é exatamente essa história que o nome consulta:
`time.FixedZone("-03", -3*3600)` imprimiria o mesmo hoje e a hora errada para uma data de verão
anterior a 2019.

## De onde vem o banco de fusos

`LoadLocation` lê o banco de dados do sistema operacional, que no Ubuntu é o pacote `tzdata`:

```
ana@vm:~/clock$ ls -l /usr/share/zoneinfo/America/Sao_Paulo
-rw-r--r-- 1 root root 1444 Jul 17 09:49 /usr/share/zoneinfo/America/Sao_Paulo
ana@vm:~/clock$ dpkg -S /usr/share/zoneinfo/America/Sao_Paulo
tzdata: /usr/share/zoneinfo/America/Sao_Paulo
```

Uma imagem de contêiner mínima muitas vezes não tem `/usr/share/zoneinfo` nenhum, e ali o mesmo
programa falha com `unknown time zone` para um nome escrito certo. **O programa pode levar o banco
de dados dentro de si**: importar `time/tzdata` em qualquer lugar dele, ou compilar com a tag
`timetzdata`, embute uma cópia. O preço é o tamanho do binário:

```
ana@vm:~/clock$ go build -o z1 zones.go
ana@vm:~/clock$ go build -tags timetzdata -o z2 zones.go
ana@vm:~/clock$ wc -c z1 z2
2461115 z1
2877291 z2
5338406 total
```

416.176 bytes a mais, cerca de 400 KB, por um programa que responde igual em todo lugar. A cópia
do sistema continua sendo usada primeiro quando existe, então a embutida é uma reserva.

## O layout é uma data

Toda outra linguagem formata datas com letras, `%Y-%m-%d` ou `yyyy-MM-dd`. **Go formata com um
exemplo: um momento fixo, escrito do jeito que você quer o seu escrito.** O momento é segunda-feira,
2 de janeiro de 2006, às 3:04:05 da tarde, no fuso sete horas atrás do UTC; na ordem em que a data
americana o escreve, os números são 1 2 3 4 5 6 7. Salvo como `layout.go`:

```go
// Command layout formats and parses with Go's reference time.
package main

import (
	"fmt"
	"time"
)

func main() {
	t := time.Date(2026, time.March, 5, 9, 7, 3, 0, time.UTC)
	fmt.Println(t.Format(time.RFC3339))
	fmt.Println(t.Format("02/01/2006 15:04"))
	fmt.Println(t.Format("2006-01-02 3:04PM"))
	fmt.Println(t.Format("DD/MM/YYYY"))

	p, err := time.Parse("02/01/2006", "05/03/2026")
	fmt.Println(p, err)
	_, err = time.Parse("2006-01-02", "05/03/2026")
	fmt.Println(err)
}
```

```
ana@vm:~/clock$ go run layout.go
2026-03-05T09:07:03Z
05/03/2026 09:07
2026-03-05 9:07AM
DD/MM/YYYY
2026-03-05 00:00:00 +0000 UTC <nil>
parsing time "05/03/2026" as "2006-01-02": cannot parse "05/03/2026" as "2006"
```

`02/01/2006` é a ordem brasileira, dia primeiro, e `15` pede um relógio de 24 horas onde `3` e `PM`
pedem um de 12. **`DD/MM/YYYY` imprimiu a si mesmo**, letra por letra, porque nenhuma dessas letras
faz parte do momento de referência, e o compilador não tem como saber que você queria outra coisa;
o `go vet` também não ajuda. `Parse` recebe o mesmo tipo de layout, e quando o texto não bate ele
diz que pedaço falhou: esperava os quatro dígitos de `2006` e encontrou `05/03/2026`.

Uma hora lida sem fuso no texto volta em UTC, como mostra a quinta linha. Um texto que veio de uma
pessoa em São Paulo é lido com `time.ParseInLocation` e a localização do começo desta seção.
