---
title: Uma fila, e os dois jeitos de cada operação falhar
version: 1
---

Uma fila é a fila de um balcão: quem chega primeiro é atendido primeiro. A interface `Queue` do
Java diz exatamente isso e pouco mais. Você põe elementos na cauda e os tira da cabeça, e nada no
meio é alcançável por posição. A crença a abandonar primeiro é a de que uma fila é uma lista que você
promete usar com cuidado. **Uma `Queue` é um tipo mais estreito de propósito**, e essa estreiteza é o
que deixa o `ArrayDeque` fazer o trabalho mais rápido que qualquer lista, como a seção 04 mede.

Cada operação vem em duas formas, uma que lança exceção quando não consegue fazer o trabalho e outra
que responde com um valor especial:

| operação | lança exceção | responde um valor especial |
|---|---|---|
| pôr na cauda | `add(e)`, `IllegalStateException` quando cheia | `offer(e)`, `false` quando cheia |
| tirar da cabeça | `remove()`, `NoSuchElementException` quando vazia | `poll()`, `null` quando vazia |
| olhar a cabeça | `element()`, `NoSuchElementException` quando vazia | `peek()`, `null` quando vazia |

**Use a forma que lança quando a situação é um engano, e o valor especial quando é um resultado
normal.** Um balcão vazio na hora de fechar é normal, então `poll` e um teste de `null` se leem bem.
Uma fila que nunca deveria estar vazia aqui, e está, merece a exceção.

## O balcão

Salve isto num diretório novo, `~/queues`. A segunda metade usa um `ArrayBlockingQueue`, uma fila de
capacidade fixa do `java.util.concurrent`, porque um `ArrayDeque` cresce sem limite e nunca
conseguiria mostrar o `offer` recusando:

```java
// Desk.java
import java.util.ArrayDeque;
import java.util.Queue;
import java.util.concurrent.ArrayBlockingQueue;

public class Desk {
    public static void main(String[] args) {
        Queue<String> desk = new ArrayDeque<>();
        desk.offer("Ana");
        desk.offer("Bruno");
        desk.offer("Carla");
        System.out.println("queue   " + desk);
        System.out.println("peek    " + desk.peek());
        System.out.println("poll    " + desk.poll());
        System.out.println("poll    " + desk.poll());
        System.out.println("poll    " + desk.poll());
        System.out.println("poll    " + desk.poll());
        System.out.println("peek    " + desk.peek());

        Queue<String> twoSeats = new ArrayBlockingQueue<>(2);
        System.out.println("offer   " + twoSeats.offer("Ana"));
        System.out.println("offer   " + twoSeats.offer("Bruno"));
        System.out.println("offer   " + twoSeats.offer("Carla"));
        System.out.println("add     " + twoSeats.add("Carla"));
    }
}
```

```
ana@vm:~/queues$ java Desk.java
queue   [Ana, Bruno, Carla]
peek    Ana
poll    Ana
poll    Bruno
poll    Carla
poll    null
peek    null
offer   true
offer   true
offer   false
Exception in thread "main" java.lang.IllegalStateException: Queue full
	at java.base/java.util.AbstractQueue.add(AbstractQueue.java:98)
	at java.base/java.util.concurrent.ArrayBlockingQueue.add(ArrayBlockingQueue.java:330)
	at Desk.main(Desk.java:24)
```

Três pessoas entram, três saem, na ordem em que chegaram. **O quarto `poll` respondeu `null`** e o
programa seguiu; o `peek` depois dele também. A fila de dois lugares aceitou duas pessoas, e o
`offer` respondeu `false` para a terceira. Depois o `add` pediu a mesma coisa e lançou
`IllegalStateException: Queue full`, na linha 24, e o programa terminou ali.

Responder `null` tem uma consequência: **uma fila que responde `null` para vazia não pode guardar
`null` como elemento**, senão os dois ficariam indistinguíveis. O `ArrayDeque` recusa `null` de saída
com um `NullPointerException`, e a maioria das filas também.

## Uma fila que não é por ordem de chegada

Uma `PriorityQueue` mantém na cabeça o *menor* elemento, pela ordem natural ou por um `Comparator`
que você lhe dá. As reservas da biblioteca vão para quem esperou menos dias, uma regra estranha para
uma biblioteca e conveniente para mostrar a ordem:

```schooling-example
{
  "language": "java",
  "file": "Holds.java",
  "parts": [
    {
      "code": "import java.util.Comparator;\nimport java.util.PriorityQueue;\nimport java.util.Queue;\n\npublic class Holds {\n    record Hold(String member, int days) {}",
      "note": "**Uma reserva é um sócio e quantos dias ele esperou**, como record: a classe de uma linha da lição 29, com construtor, acessores e `toString`."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Queue<Hold> holds = new PriorityQueue<>(Comparator.comparingInt(Hold::days));",
      "note": "**O comparador é a prioridade.** `Comparator.comparingInt(Hold::days)` se lê como *compare reservas pelos dias*, o menor primeiro; a sintaxe `::` é uma referência de método, que o `java-functional` explica."
    },
    {
      "code": "        holds.offer(new Hold(\"Bruno\", 9));\n        holds.offer(new Hold(\"Ana\", 2));\n        holds.offer(new Hold(\"Davi\", 5));\n        holds.offer(new Hold(\"Carla\", 1));\n        holds.offer(new Hold(\"Eva\", 3));\n        System.out.println(\"printed  \" + holds);",
      "note": "**Cinco reservas, sem ordem nenhuma**, e depois a fila impressa inteira. Compare a ordem impressa com a ordem que o `poll` dá."
    },
    {
      "code": "        while (!holds.isEmpty()) {\n            System.out.println(\"next     \" + holds.poll());\n        }\n        holds.remove();\n    }\n}",
      "note": "**O `poll` tira a cabeça a cada vez** até a fila esvaziar. A última linha pede a cabeça de uma fila vazia com `remove`, a forma que lança exceção."
    }
  ]
}
```

```
ana@vm:~/queues$ java Holds.java
printed  [Hold[member=Carla, days=1], Hold[member=Ana, days=2], Hold[member=Davi, days=5], Hold[member=Bruno, days=9], Hold[member=Eva, days=3]]
next     Hold[member=Carla, days=1]
next     Hold[member=Ana, days=2]
next     Hold[member=Eva, days=3]
next     Hold[member=Davi, days=5]
next     Hold[member=Bruno, days=9]
Exception in thread "main" java.util.NoSuchElementException
	at java.base/java.util.AbstractQueue.remove(AbstractQueue.java:117)
	at Holds.main(Holds.java:20)
```

**A fila impressa não está em ordem de prioridade: a Eva, com 3 dias, ficou por último.** Uma
`PriorityQueue` é um heap, um array arrumado de modo que o menor elemento fique na frente e cada
elemento não seja maior que os dois abaixo dele. Isso basta para achar a cabeça num passo e para
refazer a arrumação em poucos depois de um `poll`, e não é uma lista ordenada. O `toString` e um
`for-each` percorrem o array como ele está. Só o `poll`, uma chamada por vez, dá a ordem de
prioridade: Carla, Ana, Eva, Davi, Bruno.

A última linha mostra a outra forma falhando. O `remove()` na fila vazia lançou
`NoSuchElementException`, onde o `poll()` teria respondido `null`.
