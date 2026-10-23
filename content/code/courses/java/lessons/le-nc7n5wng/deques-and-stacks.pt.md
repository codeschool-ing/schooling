---
title: Uma deque, e a pilha que ela substitui
version: 1
---

Uma **deque**, *double-ended queue* (fila de duas pontas), é aberta nas duas pontas: dá para
acrescentar e remover na cabeça e na cauda. Isso faz dela uma fila quando você usa uma ponta para
cada trabalho, e uma **pilha** quando usa uma ponta para os dois, o último a entrar é o primeiro a
sair, como uma pilha de livros devolvidos em que você guarda primeiro o de cima.

O Java tem uma classe chamada `Stack`, e a crença comum é que ela é a que se usa para uma pilha. Não
é, e o programa abaixo mostra por quê. **A própria documentação do JDK recomenda `Deque` para
pilhas**, e o `ArrayDeque` é a classe que a implementa.

O exemplo é um histórico de desfazer, o uso de livro-texto de uma pilha: a última ação é a primeira
a ser desfeita.

```java
// Undo.java
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Stack;

public class Undo {
    public static void main(String[] args) {
        Deque<String> undo = new ArrayDeque<>();
        undo.push("lend Dune");
        undo.push("lend Emma");
        undo.push("return Dune");
        System.out.println("deque  " + undo);
        System.out.println("pop    " + undo.pop());
        System.out.println("peek   " + undo.peek());

        Stack<String> old = new Stack<>();
        old.push("lend Dune");
        old.push("lend Emma");
        old.push("return Dune");
        System.out.println("stack  " + old);
        System.out.println("pop    " + old.pop());
        old.add(0, "slipped in at the bottom");
        System.out.println("get(0) " + old.get(0));
        System.out.println("stack  " + old);

        Deque<String> both = new ArrayDeque<>();
        both.offerLast("from the back");
        both.offerFirst("from the front");
        System.out.println("both   " + both + "  first " + both.peekFirst() + "  last " + both.peekLast());
    }
}
```

```
ana@vm:~/queues$ java Undo.java
deque  [return Dune, lend Emma, lend Dune]
pop    return Dune
peek   lend Emma
stack  [lend Dune, lend Emma, return Dune]
pop    return Dune
get(0) slipped in at the bottom
stack  [slipped in at the bottom, lend Dune, lend Emma]
both   [from the front, from the back]  first from the front  last from the back
```

## A deque como pilha

O `push` põe um elemento na cabeça e o `pop` o tira da cabeça, então a ação mais recente sai
primeiro: o `pop` deu `return Dune`, e o `peek` mostrou então `lend Emma`. **A deque imprime a partir
da cabeça**, a mais nova primeiro, que é a ordem em que as ações seriam desfeitas.

Os nomes são os da pilha, e cada um é outro nome para um método da deque: `push` é `addFirst`, `pop`
é `removeFirst`, `peek` é `peekFirst`. Como os métodos de fila da seção 02, o `pop` lança exceção numa
deque vazia e o `peek` responde `null`.

A última linha usou as duas pontas ao mesmo tempo: o `offerLast` pôs um elemento na cauda e o
`offerFirst` um na cabeça. Uma deque que faz isso não é nem fila nem pilha, e alguns problemas querem
exatamente isso, como guardar as cem entradas mais recentes acrescentando numa ponta e descartando
na outra.

## O que há de errado com `Stack`

A `Stack` vem do Java 1.0, de 1996, antes de o framework de coleções existir, e foi construída
estendendo `Vector`, a lista daquela época. **Uma `Stack` é, portanto, uma lista**, e o programa usou
isso contra ela:

- `old.add(0, "slipped in at the bottom")` pôs um elemento debaixo dos outros, o que nenhuma pilha
  permite, e o compilador não disse nada, porque `add(int, E)` é um método de `Vector` que a `Stack`
  herdou.
- `old.get(0)` leu o elemento do fundo diretamente, por posição.
- A `Stack` imprimiu o fundo primeiro, `[lend Dune, lend Emma, return Dune]`, o contrário da deque,
  porque ela imprime como o `Vector` que é.

Esse é o aviso da lição 20 sobre herança, entregue dentro do JDK: no código a `Stack` é um `Vector`,
e no significado não é, então cada operação de lista é um jeito de quebrar a pilha. Os métodos do
`Vector` também são `synchronized`, o que faz cada chamada pagar por um bloqueio, haja ou não duas
threads mexendo na pilha. A classe continua lá por compatibilidade com código escrito nos anos 1990.

**Para uma pilha, declare uma `Deque` e crie um `ArrayDeque`.** Uma `Deque` ainda tem `addLast`, que
uma pilha cuidadosa nunca chama, mas não tem `get(i)` nem `add(i, e)` para alcançar o meio, e a
classe não faz bloqueio nenhum.
