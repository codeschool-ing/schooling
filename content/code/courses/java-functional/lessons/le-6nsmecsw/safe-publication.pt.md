---
title: Publicando um objeto com segurança
version: 1
---

**Entregar um objeto a outra thread se chama publicá-lo, e fazer isso sem happens-before pode mostrar
à outra thread um objeto que não está pronto.** As escritas do construtor e a escrita da referência
são escritas independentes, e a seção 03 mostrou que escritas independentes podem ser vistas na ordem
errada. Uma thread que lê a referência por uma condição de corrida pode, portanto, ver o objeto com
alguns campos ainda nos valores padrão: `0`, `false`, `null`.

Essa falha é real e está especificada, e também é rara no x86, que mantém as escritas em ordem entre si
com mais rigor do que o modelo exige. *Ela não foi reproduzida para este curso*, e um teste que
tentasse quase sempre não provaria nada. É por isso que se confia nas regras e não em experimentos:
**um bug de concorrência que um teste não consegue mostrar continua sendo um bug no próximo
processador.**

## Quatro jeitos seguros

O modelo garante publicação segura quando a referência viaja por qualquer um destes:

- **um campo `final`.** Se todo campo de um objeto é `final` e o construtor não deixa o `this` escapar,
  qualquer thread que veja o objeto vê esses campos inicializados, mesmo por uma condição de corrida.
  Records (aula 29 do `java`) só têm campos `final`, o que faz de um record imutável o objeto mais fácil
  de compartilhar;
- **um campo `volatile` ou um atômico** (aulas 13 e 15) que guarde a referência;
- **um lock**: escrever a referência dentro de `synchronized` e lê-la dentro de `synchronized` no mesmo
  lock (aula 14);
- **uma coleção concorrente ou um `Future`**: pô-la num `ConcurrentHashMap` ou numa `BlockingQueue`, ou
  devolvê-la de uma tarefa (aulas 15 e 16).

## A imutabilidade elimina a pergunta

```java
// Published.java: an immutable record shared between threads with no lock at all
import java.util.List;

public class Published {
    record PriceList(String currency, List<Long> cents) {
        PriceList {
            cents = List.copyOf(cents);
        }
    }

    static volatile PriceList current = new PriceList("BRL", List.of(3490L, 5290L));

    public static void main(String[] args) throws InterruptedException {
        Thread reader = new Thread(() -> {
            PriceList seen = current;
            System.out.println("reader sees " + seen.currency() + " " + seen.cents());
        });
        current = new PriceList("BRL", List.of(3290L, 4990L, 7990L));
        reader.start();
        reader.join();
    }
}
```

```
ana@vm:~/fp/memory$ java Published.java
reader sees BRL [3290, 4990, 7990]
```

`PriceList` não pode mudar depois de construído: os campos são `final`, e o construtor compacto copia
a lista para uma que ninguém pode modificar. Quem lê nunca precisa de lock, porque não há nada que
possa mudar por baixo. **Para atualizar os preços, monte um `PriceList` novo e troque a referência**,
aqui por um campo `volatile`, para todo leitor ver ou a lista antiga ou a nova, inteira. Esse padrão,
valores imutáveis atrás de uma referência, é o jeito correto mais barato de compartilhar dados entre
threads, e é a metade funcional deste curso encontrando a metade concorrente.
