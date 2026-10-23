---
title: Quando dá errado em vez de lento
version: 1
---

**Um pipeline sequencial que muda estado compartilhado em geral escapa ileso. Um paralelo, não**,
porque várias threads agora rodam o mesmo lambda no mesmo instante. As regras de aulas anteriores,
nada de efeitos colaterais num lambda (aula 4, seção 02) e reduções associativas (aula 7, seção 03),
deixam de ser estilo e viram correção:

```java
// Wrong.java: shared state, order and the difference between findAny and findFirst
import java.util.ArrayList;
import java.util.List;
import java.util.stream.IntStream;

public class Wrong {
    public static void main(String[] args) {
        for (int run = 1; run <= 10; run++) {
            List<Integer> shared = new ArrayList<>();
            try {
                IntStream.range(0, 10_000).parallel().forEach(shared::add);
                System.out.println("run " + run + ": " + shared.size() + " of 10000");
            } catch (RuntimeException e) {
                System.out.println("run " + run + ": " + e.getClass().getSimpleName());
            }
        }
        List<Integer> collected = IntStream.range(0, 10_000).parallel().boxed().toList();
        System.out.println("collected: " + collected.size() + " of 10000, first " + collected.get(0) + ", last " + collected.get(9999));

        System.out.print("forEach:        ");
        IntStream.range(0, 10).parallel().forEach(i -> System.out.print(i + " "));
        System.out.print("\nforEachOrdered: ");
        IntStream.range(0, 10).parallel().forEachOrdered(i -> System.out.print(i + " "));
        System.out.println();

        System.out.println("findFirst: " + IntStream.range(0, 1_000_000).parallel().filter(i -> i % 7919 == 0).findFirst().getAsInt());
        System.out.println("findAny:   " + IntStream.range(0, 1_000_000).parallel().filter(i -> i % 7919 == 0).findAny().getAsInt());
    }
}
```

```
ana@vm:~/fp/parallel$ java Wrong.java
run 1: 10000 of 10000
run 2: 6628 of 10000
run 3: 8682 of 10000
run 4: 8648 of 10000
run 5: 5000 of 10000
run 6: ArrayIndexOutOfBoundsException
run 7: 9303 of 10000
run 8: 10000 of 10000
run 9: 9983 of 10000
run 10: 10000 of 10000
collected: 10000 of 10000, first 0, last 9999
forEach:        1 0 4 2 5 3 7 9 8 6 
forEachOrdered: 0 1 2 3 4 5 6 7 8 9 
findFirst: 0
findAny:   625601
```

## Um `ArrayList` compartilhado perde elementos, ou quebra

Dez execuções do mesmo código, três resultados diferentes. Seis execuções perderam elementos, uma
perdeu metade deles. A execução 6 lançou `ArrayIndexOutOfBoundsException`. E três execuções saíram
certas, que é o pior dos três resultados, porque um teste que caísse numa delas passaria. O
`ArrayList.add` lê o tamanho, escreve o elemento nesse índice e guarda o tamanho novo; duas threads
fazendo isso ao mesmo tempo podem escrever na mesma posição, e um elemento some, ou uma thread
aumenta o array interno enquanto outra escreve além do fim antigo, e o resultado é uma exceção lá de
dentro do `ArrayList`. **Qual das duas acontece, e quantos elementos somem, muda de execução para
execução**, que é a assinatura de uma condição de corrida. A aula 14 dá nome a ela e a aula 12 explica
o que o processador está fazendo por baixo.

O conserto não é um lock em volta do `add`. **É parar de compartilhar**: deixar o stream montar a
lista com `toList()` ou um coletor, que dá a cada thread o seu próprio contêiner e os junta no fim.
`collected` tem os 10.000 elementos, em ordem.

## Ordem custa algo

O `forEach` num stream paralelo roda cada elemento na thread que estiver com ele, então os números
saíram misturados. O `forEachOrdered` mantém a ordem da fonte, fazendo as threads esperarem pelos
elementos anteriores aos seus. O `findFirst` também precisa devolver a primeira correspondência na
ordem da fonte, 0, mesmo que um worker tenha achado uma posterior primeiro, enquanto o `findAny` pode
devolver qualquer correspondência que alguma thread achou. **Peça ordem só quando a resposta precisar
dela**: num stream paralelo, `findAny` e `unordered()` deixam as threads pararem de esperar umas pelas
outras.
