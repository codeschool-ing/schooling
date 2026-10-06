---
title: Declarando um sentinela seu
version: 1
---

Um sentinela pertence a um pacote, e só vale o que custa quando código de outro pacote o procura.
Por isso este exemplo é um módulo, `example.com/shop`, com um pacote `store` num diretório só dele
e um `main` que o usa. A loja vende maçãs e peras, e pedir qualquer outra coisa é a falha que quem
chama deve reconhecer:

```schooling-example
{
  "language": "go",
  "file": "store/store.go",
  "parts": [
    {
      "code": "// Package store keeps the shop's stock in memory.\npackage store\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n)\n\n",
      "note": "Um pacote próprio, no diretório `store` do módulo `example.com/shop`. A lição 39 trata de pacotes; aqui basta que `main` importe este por esse caminho."
    },
    {
      "code": "// ErrNotFound means the store does not sell the item asked for.\nvar ErrNotFound = errors.New(\"not found\")\n\n",
      "note": "**O sentinela: uma variável exportada, criada uma vez, cujo nome começa com `Err`.** O comentário acima dela é o que o `go doc` imprime, e diz o que o erro significa, que é a parte em que quem chama confia."
    },
    {
      "code": "var stock = map[string]int{\"apple\": 12, \"pear\": 0}\n\n",
      "note": "O estoque não é exportado, então nada fora do pacote o enxerga. `pear` está nele com 0: não ter nenhuma é uma resposta, não um erro."
    },
    {
      "code": "// Count reports how many of an item are in stock. For an item the store\n// does not sell, the error wraps ErrNotFound.\nfunc Count(item string) (int, error) {\n\tn, ok := stock[item]\n\tif !ok {\n\t\treturn 0, fmt.Errorf(\"count %q: %w\", item, ErrNotFound)\n\t}\n\treturn n, nil\n}\n",
      "note": "**`Count` embrulha o sentinela com `%w` e acrescenta o nome do item**, e o comentário dela diz que sentinela procurar. A mensagem ganha o detalhe de que uma pessoa precisa; a cadeia guarda o valor que um programa confere."
    }
  ]
}
```

O programa pergunta por três itens e **desvia pelo sentinela com `errors.Is`**, porque `Count` o
devolve embrulhado:

```go
func main() {
	for _, item := range []string{"apple", "pear", "plum"} {
		n, err := store.Count(item)
		switch {
		case errors.Is(err, store.ErrNotFound):
			fmt.Printf("%s: not sold here (%v)\n", item, err)
		case err != nil:
			fmt.Printf("%s: failed: %v\n", item, err)
		default:
			fmt.Printf("%s: %d in stock\n", item, n)
		}
	}
}
```

```
ana@vm:~/sentinel-store$ go run .
apple: 12 in stock
pear: 0 in stock
plum: not sold here (count "plum": not found)
```

Três respostas, e a segunda importa tanto quanto a terceira. Uma contagem de 0 peras voltou com
erro `nil`: não ter nenhuma em estoque é uma resposta perfeitamente boa, e um erro teria feito todo
mundo que chama tratá-la como falha. `plum` é o caso para o qual o sentinela existe. **A mensagem
nomeia o item, porque uma pessoa lendo um log precisa dele, e a cadeia ainda guarda
`store.ErrNotFound`, porque o programa precisa disso.** O embrulho deu a cada leitor a sua metade.
`err == store.ErrNotFound` teria dado `false` para `plum`, pelo motivo que a lição 34 mostrou: o
valor que `Count` devolveu é o embrulho.

A linha `case err != nil` também não é enfeite. `Count` não tem como falhar de outro jeito hoje, e
quem desvia por um sentinela ainda precisa fazer algo com todo erro que não reconhece.

## O sentinela faz parte do que o pacote diz

O `go doc` imprime o sentinela ao lado da função, que é onde quem chama procura:

```
ana@vm:~/sentinel-store$ go doc ./store
package store // import "example.com/shop/store"

Package store keeps the shop's stock in memory.

var ErrNotFound = errors.New("not found")
func Count(item string) (int, error)
ana@vm:~/sentinel-store$ go doc ./store Count
package store // import "example.com/shop/store"

func Count(item string) (int, error)
    Count reports how many of an item are in stock. For an item the store does
    not sell, the error wraps ErrNotFound.

```

Duas coisas juntas tornam o sentinela utilizável. A variável é exportada, então outros pacotes
podem nomeá-la, e **o comentário de `Count` diz qual sentinela ela devolve e quando**, porque a
assinatura só diz `error`. A lição 32 notou o mesmo sobre `os.Open`, cuja documentação diz o tipo
que o erro dela vai ter. Sem essa frase, quem chama precisa ler o código-fonte para descobrir o que
vale conferir, e o código-fonte é livre para mudar.

Alguns hábitos da biblioteca padrão, todos visíveis acima e na lista da seção 02:

- a variável é declarada uma vez, no nível do pacote, com `errors.New`, e nunca é reatribuída;
- a mensagem é curta, em minúsculas e sem ponto final, como toda mensagem da lição 33, porque
  acaba na ponta direita da frase de outra pessoa: `count "plum": not found`;
- o comentário diz o que o erro significa, não como ele é feito.

O que `store` fez agora foi prometer algo a todo programa que procura `store.ErrNotFound`. A seção
04 trata de quando um pacote deve fazer essa promessa, e de quanto custa voltar atrás.
