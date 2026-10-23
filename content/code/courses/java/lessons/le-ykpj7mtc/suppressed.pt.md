---
title: Para onde vai a segunda exceção
version: 1
---

A seção 02 terminou com uma exceção lançada pelo `close` apagando a que o `use` lançou. O
try-with-resources tem de decidir a mesma questão, duas exceções e uma saída, e **ele fica com a
primeira e anexa a segunda a ela** como uma exceção *suprimida*. Nada se perde, e a que você lê
primeiro é a que começou o problema.

O `Suppressed` é o `Masked` da seção 02, reescrito com o `try` novo. O recurso falha enquanto é usado e
de novo enquanto é fechado:

```java
// Suppressed.java
public class Suppressed {
    public static void main(String[] args) {
        try (Resource r = new Resource("loans.db", true)) {
            r.use(true);
        }
    }
}
```

```
ana@vm:~/twr$ javac Suppressed.java Inspect.java
ana@vm:~/twr$ java Suppressed
open loans.db
use loans.db
close loans.db
Exception in thread "main" java.lang.IllegalStateException: use of loans.db failed
	at Resource.use(Resource.java:15)
	at Suppressed.main(Suppressed.java:5)
	Suppressed: java.lang.IllegalStateException: close of loans.db failed
		at Resource.close(Resource.java:23)
		at Suppressed.main(Suppressed.java:4)
```

A linha principal é `use of loans.db failed`, a causa original, em `Resource.use`. **Abaixo do stack
trace dela há uma linha que começa com `Suppressed:`**, recuada um passo a mais, com a falha do
fechamento e um stack trace próprio. Compare com a saída do `Masked`, que relatou só o fechamento:
mesmo recurso, as mesmas duas falhas, e desta vez as duas estão na tela na ordem em que aconteceram.

Os números de linha andaram uma posição em relação à seção 02 (`Resource.java:23` para o fechamento,
onde o `Masked` dizia 22) porque este `Resource.java` é a versão da seção 03, com `@Override`
acrescentado acima do `close`. Um stack trace numera as linhas do arquivo que foi compilado, o que vale
lembrar quando o código à sua frente não é esse arquivo.

## Lendo as exceções pelo código

Todo `Throwable` carrega a lista, e o `getSuppressed()` a devolve como um array. Com dois recursos que
falham ao fechar, a lista tem duas entradas:

```java
// Inspect.java
public class Inspect {
    public static void main(String[] args) {
        try (Resource db = new Resource("loans.db", true);
             Resource log = new Resource("audit.log", true)) {
            db.use(true);
        } catch (IllegalStateException e) {
            System.out.println("main:       " + e.getMessage());
            for (Throwable s : e.getSuppressed()) {
                System.out.println("suppressed: " + s.getMessage());
            }
        }
    }
}
```

```
ana@vm:~/twr$ java Inspect
open loans.db
open audit.log
use loans.db
close audit.log
close loans.db
main:       use of loans.db failed
suppressed: close of audit.log failed
suppressed: close of loans.db failed
```

Os recursos fecharam em ordem inversa, como a seção 03 mostrou, e **as exceções suprimidas estão na
ordem em que foram acrescentadas**, que é essa mesma ordem inversa: o `audit.log` primeiro. Uma
biblioteca de log as imprime por você quando recebe a exceção, e o relatório `Exception in thread
"main"` da própria JVM as imprimiu acima sem ninguém pedir. Você só chama o `getSuppressed()` quando
trata a exceção e quer dizer algo sobre cada falha que ela contém.

## A regra, toda num lugar

| o que falhou | o que quem chamou recebe |
|---|---|
| só o corpo | a exceção do corpo |
| só o `close` | a exceção do `close` |
| o corpo, depois o `close` | a exceção do corpo, com a do `close` suprimida dentro dela |
| o corpo, depois dois fechamentos | a exceção do corpo, com os dois fechamentos suprimidos, o último aberto primeiro |

**A exceção do corpo sempre vence**, porque é ela que explica por que o trabalho não aconteceu. Uma
falha ao fechar é real e vale saber dela, e quase nunca é a causa. A lição 38 acrescenta o terceiro
jeito de duas exceções viajarem juntas, a *causa*, que é para uma exceção que explica outra, e não
para uma que aconteceu ao lado dela.
