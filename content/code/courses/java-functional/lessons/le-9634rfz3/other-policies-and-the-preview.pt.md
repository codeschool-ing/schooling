---
title: Outras políticas, e o que preview quer dizer
version: 1
---

**A política de um escopo é um `Joiner`, passado ao `open`, e ele decide quando o `join` retorna e o
que devolve.** "Todas precisam ter sucesso" é o padrão. A outra pergunta comum é a oposta: perguntar a
mesma coisa a várias fontes e ficar com a que responder primeiro.

```java
// FirstAnswer.java: three mirrors asked at once, the first answer kept, the others cancelled
import java.util.concurrent.StructuredTaskScope;
import java.util.concurrent.StructuredTaskScope.Joiner;

public class FirstAnswer {
    static String ask(String mirror, long ms) throws InterruptedException {
        try {
            Thread.sleep(ms);
            return mirror;
        } catch (InterruptedException e) {
            System.out.println(mirror + ": cancelled");
            throw e;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        try (var scope = StructuredTaskScope.open(Joiner.<String>anySuccessfulResultOrThrow())) {
            scope.fork(() -> ask("mirror-a", 400));
            scope.fork(() -> ask("mirror-b", 100));
            scope.fork(() -> ask("mirror-c", 250));
            System.out.println("first answer: " + scope.join());
        }
    }
}
```

```
ana@vm:~/fp/structured$ java --enable-preview --source 25 FirstAnswer.java
first answer: mirror-b
mirror-a: cancelled
mirror-c: cancelled
```

`mirror-b` respondeu primeiro, depois de 100 ms, o `join` devolveu a resposta dele, e **o escopo cancelou
os dois que ainda esperavam**. Uma consulta enviada a três réplicas, uma busca num cache e num banco ao
mesmo tempo, uma requisição repetida num segundo servidor quando o primeiro está lento: cada uma é essa
forma.

| `Joiner` | o `join` devolve | quando |
|---|---|---|
| padrão, `open()` | nada; leia cada `Subtask` | todas tiveram sucesso; falha com a primeira falha |
| `anySuccessfulResultOrThrow()` | o primeiro resultado de sucesso | uma teve sucesso; falha se todas falharam |
| `allSuccessfulOrThrow()` | as subtarefas, todas com sucesso | todas tiveram sucesso |
| `awaitAll()` | nada | todas terminaram, com sucesso ou não |

## O que preview quer dizer, e o que vai envelhecer

Um recurso em preview está no JDK para as pessoas o usarem e dizerem o que está errado nele. **A API dele
pode mudar entre versões**, e esta mudou: os previews do Java 21 ao 24 tinham subclasses chamadas
`ShutdownOnFailure` e `ShutdownOnSuccess` no lugar do `Joiner`, e código escrito para elas não compila no
Java 25. É por isso que esta aula é um panorama, por que os programas dela precisam de `--enable-preview`,
e por que ela vai precisar de revisão quando a API for final. As ideias não vão envelhecer: o tempo de
vida de uma tarefa limitado pelo bloco que a iniciou, a falha que cancela as irmãs, e a estrutura visível
num dump de threads.

Os **scoped values**, o recurso companheiro, ficaram finais no Java 25. Um `ScopedValue` leva um valor,
como o usuário atual ou o id de uma requisição, a todo método que um bloco chama e às subtarefas que ele
bifurca, sem passá-lo como parâmetro. Ele substitui a maioria dos usos de `ThreadLocal`, que custa
memória por thread e combina mal com um milhão de threads virtuais. Este curso para em dar o nome; a
documentação de `java.lang.ScopedValue` no JDK é o lugar para começar.
