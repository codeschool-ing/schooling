---
title: Uma função que melhora uma função
version: 1
---

**As funções de ordem superior mais úteis recebem uma função e devolvem outra com a mesma forma e
algo a mais.** Quem chama vê uma `Function<T, R>` entrando e uma `Function<T, R>` saindo, e a nova
pode ser usada em todo lugar onde a antiga era. Dois acréscimos aparecem o tempo todo: dizer o que
aconteceu, e não fazer o mesmo trabalho duas vezes.

```java
// Wrappers.java: two functions that take a function and return a better one
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

public class Wrappers {
    static int lookups = 0;

    static <T, R> Function<T, R> logged(String name, Function<T, R> f) {
        return t -> {
            R result = f.apply(t);
            System.out.println("  " + name + "(" + t + ") = " + result);
            return result;
        };
    }

    static <T, R> Function<T, R> memoized(Function<T, R> f) {
        Map<T, R> cache = new HashMap<>();
        return t -> cache.computeIfAbsent(t, f);
    }

    static String authorOf(String title) {
        lookups++;
        return switch (title) {
            case "Dune" -> "Frank Herbert";
            case "Emma" -> "Jane Austen";
            default -> "unknown";
        };
    }

    public static void main(String[] args) {
        Function<String, String> author = memoized(logged("authorOf", Wrappers::authorOf));
        for (String title : new String[] {"Dune", "Emma", "Dune", "Dune", "Ulysses"}) {
            System.out.println(title + " by " + author.apply(title));
        }
        System.out.println("lookups: " + lookups);
    }
}
```

```
ana@vm:~/fp/higher-order$ java Wrappers.java
  authorOf(Dune) = Frank Herbert
Dune by Frank Herbert
  authorOf(Emma) = Jane Austen
Emma by Jane Austen
Dune by Frank Herbert
Dune by Frank Herbert
  authorOf(Ulysses) = unknown
Ulysses by unknown
lookups: 3
```

Leia a saída de dentro para fora. **`logged` imprimiu uma linha só quando a busca real rodou**, e ela
rodou três vezes para cinco perguntas: `Dune` foi perguntado três vezes e buscado uma. O contador
concorda, `lookups: 3`. Isso porque os dois embrulhos foram empilhados: `memoized(logged(...))`
consulta o cache primeiro, e só uma falta chega à função registrada e, dentro dela, ao `authorOf`.
Troque a ordem, `logged(memoized(...))`, e toda chamada seria registrada, acertos incluídos. **A
ordem dos embrulhos é a ordem das perguntas feitas**, do mais externo para dentro.

## Em que o `memoized` se apoia

`computeIfAbsent(t, f)` chama `f` só quando a chave falta, e guarda a resposta. Ele só é um cache
correto quando `f` **dá a mesma resposta toda vez para o mesmo argumento e não faz mais nada que
importe**. `authorOf` se qualifica, tirando o contador que está lá para ser contado. Uma função que
lê o relógio, um arquivo ou um banco de dados não se qualifica, e memorizá-la serve respostas
velhas sem nenhum sinal de que estão velhas.

O cache também não tem limite e não é seguro para duas threads ao mesmo tempo. Para um programa
percorrendo uma lista, tudo bem. Para um servidor, é o começo de um vazamento de memória e de uma
condição de corrida, e o `ConcurrentHashMap` da aula 15 é a primeira metade do remédio.

## A mesma forma em todo lugar

Este é o padrão decorator sem as classes. Um embrulho que acrescenta uma nova tentativa, um tempo
limite, uma verificação de permissão ou uma medição se escreve do mesmo jeito: receba uma
`Function`, devolva uma `Function` que faz o trabalho extra em volta de uma chamada à que recebeu.
Bibliotecas de servidores web e de resiliência são feitas exatamente disso, e é por isso que ler o
tipo `Function<T, R>` num parâmetro e de novo no tipo de retorno já diz quase tudo o que o método
faz.
