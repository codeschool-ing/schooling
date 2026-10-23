---
title: Devolvendo comportamento
version: 1
---

**Um método pode devolver um lambda, e o lambda devolvido pode usar os argumentos do método muito
depois de o método ter terminado.** Isso transforma um método numa fábrica de regras: você dá os
números, e ele devolve um comportamento montado em volta deles.

```schooling-example
{
  "language": "java",
  "file": "Factories.java",
  "parts": [
    {
      "code": "// Factories.java: methods that build rules and hand them back\nimport java.util.List;\nimport java.util.concurrent.atomic.AtomicInteger;\nimport java.util.function.Predicate;\nimport java.util.function.Supplier;\nimport java.util.function.UnaryOperator;\n\npublic class Factories {\n    record Book(String title, int pages) {}"
    },
    {
      "code": "\n    static Predicate<Book> atLeast(int pages) {\n        return b -> b.pages() >= pages;\n    }",
      "note": "`atLeast` devolve um teste. O `pages` com que foi chamado é capturado pelo lambda, então cada chamada monta um teste diferente."
    },
    {
      "code": "\n    static UnaryOperator<Long> percentOff(int percent) {\n        return cents -> cents - cents * percent / 100;\n    }",
      "note": "A mesma ideia para preços: dê uma porcentagem, receba de volta uma função de um preço para um preço menor. A divisão inteira arredonda para baixo, no centavo."
    },
    {
      "code": "\n    static Supplier<String> orderNumbers(String prefix) {\n        AtomicInteger next = new AtomicInteger();\n        return () -> prefix + \"-\" + next.incrementAndGet();\n    }",
      "note": "Uma regra com estado. `next` nunca é reatribuído, então o lambda pode capturá-lo; o contador dentro dele muda, e a aula 15 explica por que `AtomicInteger` é o jeito seguro de fazer isso."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Predicate<Book> doorstop = atLeast(450);\n        Predicate<Book> anything = atLeast(0);\n        Book dune = new Book(\"Dune\", 412);\n        System.out.println(doorstop.test(dune) + \" \" + anything.test(dune));",
      "note": "Dois testes da mesma fábrica. Diferem só no número que cada um capturou."
    },
    {
      "code": "\n        UnaryOperator<Long> student = percentOff(15);\n        System.out.println(student.apply(8990L));",
      "note": "8990 centavos com 15% de desconto: 8990 menos 1348, o desconto arredondado para baixo."
    },
    {
      "code": "\n        Supplier<String> lumen = orderNumbers(\"LUM\");\n        Supplier<String> atlas = orderNumbers(\"ATL\");\n        System.out.println(List.of(lumen.get(), lumen.get(), atlas.get(), lumen.get()));\n    }\n}\n",
      "note": "Cada supplier tem o seu contador, feito quando `orderNumbers` foi chamado. Pedir ao `atlas` não fez o `lumen` avançar."
    }
  ],
  "output": "false true\n7642\n[LUM-1, LUM-2, ATL-1, LUM-3]"
}
```

## Cada chamada monta uma closure nova

`atLeast(450)` e `atLeast(0)` são dois objetos. Cada um guarda sua cópia de `pages`, copiada quando
foi montado (aula 1, seção 06), então os dois respondem diferente para o mesmo livro. Uma função
junto com os valores que capturou se chama **closure**, e o padrão de fábrica são closures feitas de
propósito.

`orderNumbers` mostra o único jeito de uma closure carregar estado que muda. A variável `next` é
efetivamente final, porque sempre se refere ao mesmo `AtomicInteger`; o que muda é o contador dentro
desse objeto. **A regra sobre variáveis capturadas é sobre a variável, não sobre o objeto para o
qual ela aponta.** Isso é legal e às vezes exatamente o certo, como aqui, e também é a porta por
onde o estado mutável compartilhado entra num código que devia ser funcional. Quando duas threads
chamam `lumen.get()` ao mesmo tempo, só o contador atômico mantém os números delas separados.

## Onde isso é usado

A biblioteca padrão está cheia de fábricas que devolvem comportamento, e você já anda lendo os nomes
delas:

| fábrica | devolve |
|---|---|
| `Comparator.comparing(Book::title)` (aula 5) | um `Comparator` montado a partir de uma chave |
| `Predicate.not(String::isBlank)` (aula 5) | o teste oposto |
| `Collectors.groupingBy(...)` (aula 8) | uma receita para coletar um stream |
| `Function.identity()` | uma função que devolve o argumento sem mudança |

Um valor de configuração lido uma vez na inicialização, um limite, um locale, uma alíquota, pode
virar regra por uma fábrica como `atLeast`, e o resto do programa passa a regra adiante sem conhecer
o número que está dentro dela.
