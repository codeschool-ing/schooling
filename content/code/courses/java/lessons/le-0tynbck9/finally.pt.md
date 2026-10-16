---
title: "`finally`: o bloco que roda em toda saída"
version: 1
---

Um método pode sair de vários jeitos: chegando ao fim, por `return`, ou com uma exceção passando por
ele. Algum trabalho precisa acontecer em todos eles. Um livro-caixa aberto precisa ser fechado, tenha
o empréstimo dado certo ou não. **Um bloco `finally` roda sempre que o controle deixa o seu `try`**,
por qualquer desses caminhos, e é só para isso que ele existe.

O programa abaixo abre e fecha um livro-caixa imaginário, e depois mostra os dois lugares onde o
`finally` se comporta de um jeito que ninguém espera da primeira vez:

```java
// Always.java
public class Always {
    static String lend(String title) {
        System.out.println("open the ledger");
        try {
            if (title.isBlank()) {
                throw new IllegalArgumentException("no title");
            }
            System.out.println("lend " + title);
            return "lent";
        } finally {
            System.out.println("close the ledger");
        }
    }

    @SuppressWarnings("finally")
    static String swallow() {
        try {
            throw new IllegalStateException("the real problem");
        } finally {
            return "all fine";
        }
    }

    public static void main(String[] args) {
        System.out.println(lend("Dune"));
        try {
            lend(" ");
        } catch (IllegalArgumentException e) {
            System.out.println("caught: " + e.getMessage());
        }
        System.out.println(swallow());
        try {
            System.out.println("exiting");
            System.exit(0);
        } finally {
            System.out.println("this line never prints");
        }
    }
}
```

```
ana@vm:~/exc$ java Always.java; echo "exit $?"
open the ledger
lend Dune
close the ledger
lent
open the ledger
close the ledger
caught: no title
all fine
exiting
exit 0
```

## Toda saída

A primeira chamada retornou normalmente. O `close the ledger` foi impresso **depois** de `lend Dune`
e **antes** de quem chamou imprimir `lent`: o `return "lent"` foi avaliado, depois o `finally` rodou,
depois o método de fato retornou. Um `return` dentro de um `try` não pula o `finally`; ele o espera.

A segunda chamada lançou. O `close the ledger` foi impresso antes de `caught: no title`, então o
`finally` rodou enquanto a exceção saía, e a exceção seguiu depois até o `catch` do `main`. **O
livro-caixa foi fechado nos dois caminhos**, que é a propriedade que faz do `finally` o lugar da
limpeza. A lição 37 troca esse padrão por um mais curto para tudo o que pode ser fechado, e o motivo
de ela poder é este bloco.

## Um `return` no `finally` engole a exceção

O `swallow()` lançou `IllegalStateException("the real problem")`, e o programa imprimiu `all fine`.
**Um `return` dentro do `finally` substitui o que quer que estivesse saindo do método**, exceção
inclusive, e a exceção some sem rastro: nenhum stack trace, nenhuma mensagem, nada num log.

O compilador sabe que isso é quase sempre um engano e avisa com `-Xlint:finally`; o
`@SuppressWarnings("finally")` acima do método está ali só para que esta demonstração compile quieta,
e a lição 39 explica a anotação. No seu código, nunca dê `return` de um `finally`, nem `throw`, que
substitui a exceção original do mesmo jeito.

## A única saída que o `finally` não vê

O último `try` chamou `System.exit(0)`, e o `this line never prints` nunca foi impresso; o status de
saída foi 0. **O `System.exit` para a JVM, e uma JVM parada não roda mais código**, blocos `finally`
inclusive. O mesmo vale se o processo for morto de fora, ou se a máquina perder energia. Um `finally`
garante a limpeza em todo jeito de o *método* terminar, não em todo jeito de o *programa* terminar.
