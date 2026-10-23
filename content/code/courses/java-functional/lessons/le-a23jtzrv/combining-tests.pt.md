---
title: Combinando testes
version: 1
---

**`Predicate` tem `and`, `or` e `negate`, e cada um devolve um predicado novo.** São o `&&`, o `||`
e o `!` da linguagem, aplicados a testes em vez de respostas, então uma regra pode ser montada a
partir de partes com nome e passada adiante antes de qualquer coisa ser testada.

```java
// Tests.java: predicates combined, and the order they are evaluated in
import java.util.List;
import java.util.function.Predicate;

public class Tests {
    record Book(String title, int pages, long priceCents) {}

    static Predicate<Book> noisy(String name, Predicate<Book> p) {
        return b -> {
            boolean answer = p.test(b);
            System.out.println("  " + name + "(" + b.title() + ") = " + answer);
            return answer;
        };
    }

    public static void main(String[] args) {
        Predicate<Book> cheap = b -> b.priceCents() < 4000;
        Predicate<Book> doorstop = b -> b.pages() > 450;
        Book emma = new Book("Emma", 474, 3990);
        Book dune = new Book("Dune", 412, 6990);

        System.out.println("cheap and doorstop, Emma: " + cheap.and(doorstop).test(emma));
        System.out.println("cheap or doorstop, Dune:  " + cheap.or(doorstop).test(dune));
        System.out.println("not cheap, Dune:          " + cheap.negate().test(dune));

        System.out.println("evaluating cheap.and(doorstop) on Dune:");
        System.out.println(noisy("cheap", cheap).and(noisy("doorstop", doorstop)).test(dune));

        List<String> lines = List.of("Emma", "", "  ", "Dune");
        System.out.println(lines.stream().filter(Predicate.not(String::isBlank)).toList());
    }
}
```

```
ana@vm:~/fp/composition$ java Tests.java
cheap and doorstop, Emma: true
cheap or doorstop, Dune:  false
not cheap, Dune:          true
evaluating cheap.and(doorstop) on Dune:
  cheap(Dune) = false
false
[Emma, Dune]
```

As três primeiras linhas são os casos simples: Emma é barato e longo, Dune não é nem barato nem
longo, então o `or` dá `false`, e o `negate` transformou "barato" em "não barato".

## Eles param assim que sabem

O quarto caso embrulhou cada predicado em `noisy`, que imprime toda vez que roda. **Só o `cheap`
imprimiu.** Dune não é barato, então `cheap.and(doorstop)` já era `false`, e `doorstop` nunca foi
chamado. `and` e `or` fazem curto-circuito exatamente como `&&` e `||`: o `and` para no primeiro
`false`, o `or` no primeiro `true`. Duas consequências:

- **ponha o teste barato primeiro.** Uma regra que confere um campo antes de consultar um banco de
  dados economiza a consulta toda vez que o campo já diz não;
- **não conte com o segundo teste rodando.** Um predicado que também registra ou conta algo vai
  pular esse trabalho sempre que o primeiro decidir. É mais um motivo para manter testes sem efeitos
  colaterais (aula 4, seção 02).

## `Predicate.not`

O `negate()` precisa de um predicado em que ser chamado, e `String::isBlank` é uma referência a
método sem tipo até ter um alvo. `Predicate.not(String::isBlank)` dá um alvo a ela e a inverte numa
expressão só, e é por isso que se lê tão bem dentro de um `filter`. A última linha o usou num stream
para tirar as linhas vazias e em branco; a aula 6 explica streams, e o predicado lá dentro é tudo o
que esta seção precisa.
