---
title: Todo argumento é uma cópia
version: 1
---

A maioria das pessoas chega a Go vinda de uma linguagem em que entregar um objeto a uma função
deixa a função alterá-lo. Em Python, uma função que executa `p.score += 1` no jogador que recebeu
muda o jogador de quem chamou, e Java e JavaScript se comportam do mesmo jeito. Go tem structs onde
essas linguagens têm objetos, e o hábito vem junto com a sintaxe. É a primeira ideia a abandonar.
**Uma chamada em Go copia cada argumento para uma variável nova, que pertence à função, seja qual
for o tipo do argumento.** A lição 11 mostrou isso para um array. Aqui está para um `int`, uma
struct e uma struct com um array dentro, tudo em `~/byvalue`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Player struct {\n\tName  string\n\tScore int\n\tLast  [3]int\n}\n",
      "note": "Uma struct com uma string, um `int` e um array de três `int`. Nada na declaração diz como um `Player` é passado, porque só existe um jeito."
    },
    {
      "code": "\nfunc double(n int) {\n\tn = n * 2\n}\n",
      "note": "**`n` é uma variável da própria função**, criada para esta chamada e preenchida com o valor do argumento. Dobrá-la muda essa variável e nada lá fora."
    },
    {
      "code": "\nfunc win(p Player) {\n\tp.Score++\n\tp.Last[0] = 100\n}\n",
      "note": "**`p` é um segundo `Player` inteiro**: o nome, a pontuação e os três elementos do array foram copiados para ele. `p.Score++` e `p.Last[0] = 100` mudam a cópia."
    },
    {
      "code": "\nfunc main() {\n\tn := 21\n\tdouble(n)\n\tfmt.Println(n)\n",
      "note": "`double(n)` deixa `n` em 21, a primeira linha da saída."
    },
    {
      "code": "\n\tana := Player{Name: \"Ana\", Score: 10}\n\twin(ana)\n\tfmt.Println(ana)\n",
      "note": "Depois de `win(ana)` o jogador de quem chamou continua com pontuação 10 e um array de zeros. Nada do que `win` fez chegou a `ana`."
    },
    {
      "code": "\n\tbia := ana\n\tbia.Name = \"Bia\"\n\tbia.Last[1] = 50\n\tfmt.Println(ana)\n\tfmt.Println(bia)\n}\n",
      "note": "**Atribuir copia exatamente como chamar.** `bia` é um segundo `Player`, então renomeá-lo e escrever no seu array deixam `ana` como estava: as duas últimas linhas diferem."
    }
  ],
  "output": "21\n{Ana 10 [0 0 0]}\n{Ana 10 [0 0 0]}\n{Bia 10 [0 50 0]}"
}
```

```
ana@vm:~/byvalue$ go run .
21
{Ana 10 [0 0 0]}
{Ana 10 [0 0 0]}
{Bia 10 [0 50 0]}
```

Um parâmetro é uma variável local comum que a chamada preenche antes de a primeira linha da função
rodar. A função pode lê-lo, mudá-lo e jogá-lo fora, e nada disso aparece do lado de fora, porque a
variável de quem chamou nunca foi entregue, só o seu valor. `fmt.Println` imprime uma struct como
os seus campos entre chaves, `{Ana 10 [0 0 0]}`; a lição 15 é a lição sobre structs.

A struct levava um array, e o array foi copiado junto: `bia.Last[1] = 50` escreveu nos três `int`
de `bia` e não tocou nos de `ana`. **A cópia de uma struct é tão profunda quanto os próprios campos
da struct**, e um campo array faz parte da struct, cada elemento dele. A seção 03 trata dos campos
que não fazem, os que guardam um ponteiro para algo armazenado em outro lugar.

## Fazendo uma mudança sair

Uma função que precisa mudar um valor tem dois jeitos de fazer a mudança chegar a quem chamou. O
primeiro é o que a lição 11 usou para o `append`: devolver o valor novo e deixar quem chamou
guardá-lo.

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func win(p Player) Player {
	p.Score++
	return p
}

func main() {
	ana := Player{Name: "Ana", Score: 10}
	ana = win(ana)
	fmt.Println(ana)
}
```

```
ana@vm:~/byvalue-return$ go run .
{Ana 11}
```

Três cópias aconteceram nesse programa. `ana` foi copiada para `p`, `p` foi copiada para fora como
resultado, e o resultado foi copiado para `ana` pela atribuição. O que dá para ler na chamada é a
parte útil: **`ana = win(ana)` diz, na própria chamada, que `ana` muda**, e quem lê não precisa
abrir `win` para descobrir.

O segundo jeito é passar o endereço de `ana` em vez de `ana`, para que a função alcance a variável
de quem chamou através dele. Isso é um ponteiro, e a lição 23 trata deles. A regra também não se
dobra para ponteiros. Um ponteiro é um valor como qualquer outro, e passá-lo o copia; o que ele
copia é um endereço.

## Atribuições, resultados e laços também copiam

A chamada é um dos lugares em que um valor é copiado, e a mesma cópia acontece em todo lugar em que
um valor entra numa variável: o `bia := ana` acima, o resultado de `win` guardado de volta em `ana`
e a variável que um laço `range` entrega a cada volta, que a lição 17 mostrou ser uma cópia do
elemento e não o elemento. Com essa imagem, a pergunta diante de qualquer trecho de Go deixa de ser
"isto é passado por valor ou por referência?", porque a resposta é sempre a primeira. A pergunta é
**o que o valor deste tipo contém**, e a seção 03 responde a ela para os tipos em que a resposta
surpreende.
