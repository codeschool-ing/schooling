---
title: A mesma medição em outras linguagens
version: 1
---

Toda linguagem de uso comum tem uma ferramenta de cobertura, e todas medem a mesma coisa do mesmo
jeito: instrumentam o código, rodam os testes, contam o que rodou. O que muda é a unidade contada e o
nome do comando.

| linguagem | ferramenta | conta |
|---|---|---|
| Python | `coverage.py` | linhas e, quando pedido, ramos |
| JavaScript e TypeScript | Istanbul (`nyc`), `c8`, embutido no Jest e no Vitest | comandos, ramos, funções, linhas |
| Java e Kotlin | JaCoCo | instruções, ramos, linhas |
| Go | `go test -cover` | comandos |
| C# | Coverlet | linhas, ramos |

## Go, neste repositório

O lado Go do repositório que publica este curso tem cobertura embutida no comando de teste. Duas das
bibliotecas dele, o corretor por onde passa toda resposta de prova e o leitor de trechos por
trilha, medidas a partir de um checkout:

```
ana@laptop:~/schooling$ go test -count=1 -cover ./internal/grade/ ./internal/trackblock/
ok  	github.com/codeschool-ing/schooling/internal/grade	0.017s	coverage: 81.4% of statements
ok  	github.com/codeschool-ing/schooling/internal/trackblock	0.003s	coverage: 96.6% of statements
ana@laptop:~/schooling$ go test -coverprofile=/tmp/grade.out ./internal/grade/ > /dev/null; go tool cover -func=/tmp/grade.out | sort -k3 -n | head -4
github.com/codeschool-ing/schooling/internal/grade/expr.go:309:		unary			30.0%
github.com/codeschool-ing/schooling/internal/grade/expr.go:361:		number			47.1%
github.com/codeschool-ing/schooling/internal/grade/numeric.go:90:	key			50.0%
github.com/codeschool-ing/schooling/internal/grade/grade.go:145:	CheckKey		66.7%
```

O primeiro comando imprime uma porcentagem por pacote: **81,4%** dos comandos do corretor e
**96,6%** do leitor. `-count=1` faz o Go rodar os testes em vez de reaproveitar um resultado guardado,
o que ele faz por padrão quando nada mudou. O segundo grava um perfil e lista a cobertura por função,
ordenada para as menos cobertas virem primeiro: `unary` em `expr.go` com **30,0%**, depois `number`
com **47,1%**.

Essas duas funções são partes do leitor de expressões por trás do tipo de questão
`expression-answer`, e os números baixos são uma pista, não um veredito. Dizem que a maioria dos
comandos de `unary`, o tratamento de sinais na frente de uma expressão, nunca rodou nos testes deste
pacote. Se isso importa é a mesma pergunta que em Python: quanto custaria uma resposta errada ali? Um
aluno cujo `-x + 1` correto fosse marcado como errado seria uma falha real, então o perfil aponta um
teste que vale acrescentar, e as outras ferramentas desta aula, um mutante ou uma borda, dizem qual.

## O que vale em qualquer linguagem

Tudo nesta aula independe da ferramenta:

- cobertura diz o que **rodou**, nunca o que foi **conferido** (seção 04);
- ramos pegam o que linhas perdem, e os dois perdem o que acontece dentro de uma linha (seção 03);
- um número transformado em meta acaba atingido por testes que não conferem nada (seção 06);
- a barreira útil é sobre as linhas que uma mudança acrescentou, e a leitura útil é a lista do que
  falta (seções 07 e 09).

Os `statements` do Go e as `lines` do Python diferem em detalhe, e ninguém deveria comparar uma
porcentagem de uma ferramenta com a de outra. **Compare um projeto consigo mesmo ao longo do
tempo**, e leia a lista do que falta, em qualquer linguagem em que ela esteja escrita.
