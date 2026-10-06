---
title: Sentinela, tipo de erro ou nenhum dos dois
version: 1
---

A seção 03 faz declarar um sentinela parecer barato: uma linha, um `errors.New`. O hábito que vem
daí é declarar um para cada jeito de uma função falhar, "caso alguém queira". **Cada um é uma
promessa que você mantém enquanto o pacote existir**, e a maioria das falhas não vale promessa
nenhuma. Há três formas que um erro pode ter, e duas perguntas escolhem entre elas:

| quem chama desvia por essa falha? | precisa de dados dela? | devolva | exemplos |
|---|---|---|---|
| sim | não | um sentinela, `var ErrX = errors.New(...)` | `io.EOF`, `fs.ErrNotExist`, `store.ErrNotFound` |
| sim | sim | um tipo de erro, encontrado com `errors.As` | `*fs.PathError`, o `*LineError` da lição 32 |
| não | não | um erro opaco de `errors.New` ou `fmt.Errorf` | a idade inválida do `price` da lição 32 |

A terceira linha é o padrão, e é a resposta certa muito mais vezes do que o desenho da tabela
sugere. Um erro opaco continua sendo um erro perfeitamente bom: tem mensagem, pode embrulhar o que
o causou, e quem chama faz com ele o que o idioma da lição 32 faz com qualquer erro, que é devolvê-lo
com algum contexto ou relatá-lo. O que ele não tem é um nome que alguém possa procurar, e é
justamente isso que o deixa livre para mudar.

## Um tipo pode carregar um sentinela

As duas linhas de cima não se excluem, e `strconv` mostra as duas ao mesmo tempo. Uma conversão que
falha devolve um `*strconv.NumError`, cujo campo `Err` guarda um de dois sentinelas:

```
ana@vm:~/sentinel-strconv$ go doc strconv.NumError
package strconv // import "strconv"

type NumError struct {
	Func string // the failing function (ParseBool, ParseInt, ParseUint, ParseFloat, ParseComplex)
	Num  string // the input
	Err  error  // the reason the conversion failed (e.g. ErrRange, ErrSyntax, etc.)
}
    A NumError records a failed conversion.

func (e *NumError) Error() string
func (e *NumError) Unwrap() error
```

`Unwrap` devolve esse campo, então quem chama pode fazer qualquer das duas perguntas ao mesmo erro:

```go
	for _, s := range []string{"42", "4x2", "99999999999999999999"} {
		n, err := strconv.Atoi(s)
		switch {
		case err == nil:
			fmt.Println(s, "->", n)
		case errors.Is(err, strconv.ErrSyntax):
			fmt.Println(s, "-> not a number")
		case errors.Is(err, strconv.ErrRange):
			fmt.Println(s, "-> too big for an int")
		}
		if ne, ok := errors.AsType[*strconv.NumError](err); ok {
			fmt.Printf("   Func=%s Num=%q Err=%v\n", ne.Func, ne.Num, ne.Err)
		}
	}
```

```
ana@vm:~/sentinel-strconv$ go run .
42 -> 42
4x2 -> not a number
   Func=Atoi Num="4x2" Err=invalid syntax
99999999999999999999 -> too big for an int
   Func=Atoi Num="99999999999999999999" Err=value out of range
```

**O sentinela responde que tipo de falha foi; o tipo responde de que entrada se tratava.** Um
programa que só precisa da primeira resposta nunca precisa nomear `NumError`, e um que precisa da
entrada a tira de um campo em vez da mensagem.

## Voltando atrás numa promessa

`store.ErrNotFound` agora tem quem o use, o `main` da seção 03. Há dois jeitos de parar de prometê-lo,
e eles falham de jeitos muito diferentes.

O silencioso: alguém arruma `Count` e escreve a mensagem à mão, `fmt.Errorf("count %q: not found", item)`,
sem `%w`. A variável continua lá e continua exportada, e o comentário de `Count` ainda diz
que o erro a embrulha. O `main` não é tocado:

```
ana@vm:~/sentinel-v2$ go vet && go run .
apple: 12 in stock
pear: 0 in stock
plum: failed: count "plum": not found
```

O `go vet` não encontrou nada e o programa compilou. A mensagem para `plum` é o mesmo texto, letra
por letra. **A única mudança é que o desvio de quem chama parou de disparar**, e `plum` agora é
relatado como uma falha da loja, e não como um item que ela não vende. Nenhuma ferramenta desta
lição teria pegado isso; um teste que pedisse um item que falta pegaria, e testes são assunto do
curso `go-concurrency`.

O barulhento: apagar a variável.

```
ana@vm:~/sentinel-v3$ go run .; echo $?
# example.com/shop
./main.go:14:29: undefined: store.ErrNotFound
1
```

Isso quebra todos que chamam de uma vez, e pelo menos avisa: linha 14 de `main.go`, o `case` que a
nomeava. **Remover um sentinela quebra quem chama em voz alta; deixar de devolvê-lo quebra em
silêncio**, e a versão silenciosa é a que chega à produção.

Esse é o custo do outro lado da tabela. Um sentinela não pode ser retirado sem quebrar alguém, e é
por isso que as duas primeiras linhas são uma decisão e a terceira é o padrão. A lição 33 disse o
mesmo do `%w`: embrulhar um erro o torna parte da sua API. Um sentinela é essa promessa feita de
propósito, com nome, e as versões da lição 40 são como um módulo avisa a quem o usa que quebrou uma.
