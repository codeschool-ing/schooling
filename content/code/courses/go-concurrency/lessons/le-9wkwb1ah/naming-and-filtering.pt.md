---
title: Nomes que acham o seu caso
version: 1
---

O `name` de uma linha é a única parte da tabela que o relatório imprime, então é o que alguém lê no
momento em que um caso falha. **Dê a um caso o nome do que o torna diferente**, como as linhas
acima são chamadas: `accents`, `digits`, `only punctuation`. Um nome como `case 3` ou `test2` não
diz nada numa falha e para de dizer qualquer coisa no dia em que uma linha é inserida acima dele,
porque os números andam e as linhas não.

## O que o relatório faz com um nome

```
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
=== RUN   TestCount/punctuation
=== RUN   TestCount/case
=== RUN   TestCount/accents
=== RUN   TestCount/possessive
=== RUN   TestCount/empty
=== RUN   TestCount/only_punctuation
=== RUN   TestCount/digits
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/punctuation (0.00s)
    --- PASS: TestCount/case (0.00s)
    --- PASS: TestCount/accents (0.00s)
    --- PASS: TestCount/possessive (0.00s)
    --- PASS: TestCount/empty (0.00s)
    --- PASS: TestCount/only_punctuation (0.00s)
    --- PASS: TestCount/digits (0.00s)
=== RUN   TestCountFile
--- PASS: TestCountFile (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

**O espaço de `only punctuation` virou um sublinhado**, então o nome completo é uma palavra só que
um shell e uma expressão regular carregam sem problema de aspas. Sete linhas, sete subtestes, na
ordem da tabela.

## Rodando uma linha

O `-run` funciona nesses nomes exatamente como funcionou nos subtestes da lição 25. O padrão pode
ser escrito com o espaço ou com o sublinhado, porque o pacote `testing` reescreve o padrão do mesmo
jeito que reescreveu o nome:

```
ana@vm:~/wordcount$ go test -v -run 'TestCount/only punctuation'
=== RUN   TestCount
=== RUN   TestCount/only_punctuation
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/only_punctuation (0.00s)
=== RUN   TestCountFile
--- PASS: TestCountFile (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

Rodou uma linha do `TestCount`, e também o `TestCountFile` inteiro, que ninguém pediu. **O primeiro
nível do padrão, `TestCount`, é uma expressão regular que também casa dentro de
`TestCountFile`**, e esse teste não tem subtestes para o segundo nível filtrar. Ancorar o primeiro
nível faz o comando significar o que diz:

```
ana@vm:~/wordcount$ go test -v -run '^TestCount$/only_punctuation'
=== RUN   TestCount
=== RUN   TestCount/only_punctuation
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/only_punctuation (0.00s)
PASS
ok  	example.com/wordcount	0.002s
```

Vale manter o hábito para qualquer nome que seja o começo de outro nome. Um conjunto de testes
cresce acrescentando `TestCountFile` ao lado de `TestCount`, e um padrão que casava com um teste
ontem casa com dois hoje, sem aviso.

## Pulando uma linha de propósito

Às vezes um caso sabidamente falha e está sendo trabalhado, ou precisa de algo que a máquina talvez
não tenha. **`t.Skip` encerra um teste como pulado, e não como falho, com um motivo que o `-v`
imprime.** É a alternativa honesta a comentar a linha, porque um caso pulado continua aparecendo no
relatório toda vez que o conjunto roda, e um comentado some da vista de todo mundo. Use-o com um
motivo sobre o qual alguém possa agir, e tire-o quando o motivo acabar.
