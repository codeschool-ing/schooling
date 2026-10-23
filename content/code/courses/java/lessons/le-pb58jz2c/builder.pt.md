---
title: O builder
version: 1
---

Um empréstimo precisa de um livro e de um sócio, e pode ter um prazo diferente dos 21 dias de sempre
e uma observação. Construtores lidam mal com isso. Ou há um construtor recebendo os quatro, e todo
chamador passa `21` e `""` para as partes que não lhe importam, ou há quatro construtores, um por
combinação, e o próximo atributo opcional os dobra. **Um builder recolhe as partes uma chamada por
vez, pelo nome, e confere todas juntas quando você pede o resultado.**

## O empréstimo e o seu builder

No mesmo `~/fluent`:

```schooling-example
{
  "language": "java",
  "file": "Loan.java",
  "parts": [
    {
      "code": "public class Loan {\n    private final String book;\n    private final String member;\n    private final int days;\n    private final String note;",
      "note": "**O empréstimo em si é imutável**: quatro atributos `final` e nenhum setter. Depois de construído, nada o altera."
    },
    {
      "code": "\n    private Loan(Builder b) {\n        this.book = b.book;\n        this.member = b.member;\n        this.days = b.days;\n        this.note = b.note;\n    }",
      "note": "O construtor é `private`, e o único argumento dele é um builder. O único jeito de fazer um `Loan` é pelo builder, então as verificações do `build()` não têm como ser puladas."
    },
    {
      "code": "\n    public static Builder of(String book) {\n        return new Builder(book);\n    }",
      "note": "A porta de entrada. O livro é obrigatório, então é o argumento aqui e não pode ser esquecido."
    },
    {
      "code": "\n    @Override\n    public String toString() {\n        return book + \" to \" + member + \" for \" + days + \" days\" + (note.isEmpty() ? \"\" : \" (\" + note + \")\");\n    }",
      "note": "Como um empréstimo se imprime, com a observação só quando existe uma."
    },
    {
      "code": "\n    public static class Builder {\n        private final String book;\n        private String member;\n        private int days = 21;\n        private String note = \"\";\n\n        private Builder(String book) {\n            this.book = book;\n        }",
      "note": "**O builder é uma classe aninhada estática** (lição 17), com os mesmos atributos do empréstimo, mas não `final`. Os dois opcionais começam nos seus padrões: 21 dias e nenhuma observação."
    },
    {
      "code": "\n        public Builder to(String member) {\n            this.member = member;\n            return this;\n        }\n\n        public Builder days(int days) {\n            this.days = days;\n            return this;\n        }\n\n        public Builder note(String note) {\n            this.note = note;\n            return this;\n        }",
      "note": "Um método por parte opcional, cada um devolvendo `this`. Quem chama define as partes que lhe importam, em qualquer ordem, e pula o resto."
    },
    {
      "code": "\n        public Loan build() {\n            if (member == null) {\n                throw new IllegalStateException(\"a loan needs a member: \" + book);\n            }\n            if (days < 1 || days > 60) {\n                throw new IllegalStateException(\"days out of range: \" + days);\n            }\n            return new Loan(this);\n        }\n    }\n}",
      "note": "**O `build()` é onde toda regra é conferida, uma vez, com todas as partes à vista.** Um empréstimo sem sócio, ou com um prazo impossível, nunca chega a existir."
    }
  ]
}
```

Os métodos do builder se leem como uma descrição do empréstimo, e a guarda das regras acontece num
lugar só. Dois empréstimos e um erro:

```java
// Lending.java
public class Lending {
    public static void main(String[] args) {
        Loan plain = Loan.of("Iracema").to("Ana").build();
        Loan dvd = Loan.of("Central do Brasil").to("Bruno").days(7).note("DVD").build();
        System.out.println(plain);
        System.out.println(dvd);
        Loan broken = Loan.of("O Guarani").days(14).build();
    }
}
```

```
ana@vm:~/fluent$ javac Loan.java Lending.java && java Lending
Iracema to Ana for 21 days
Central do Brasil to Bruno for 7 days (DVD)
Exception in thread "main" java.lang.IllegalStateException: a loan needs a member: O Guarani
	at Loan$Builder.build(Loan.java:50)
	at Lending.main(Lending.java:8)
ana@vm:~/fluent$ ls Loan*.class
Loan$Builder.class
Loan.class
```

O primeiro empréstimo ficou com os padrões; o segundo definiu duas partes opcionais pelo nome, e não
há dúvida sobre qual número é o prazo. O terceiro esqueceu o `to(...)`, e **o erro parou o programa no
`build()`**, com uma mensagem nomeando o livro, antes que qualquer empréstimo pela metade pudesse ser
guardado ou impresso. O stack trace chama o builder de `Loan$Builder`, e o `ls` mostra por quê: uma
classe aninhada compila num arquivo de classe próprio, com o nome da classe externa e um `$` no meio,
como a lição 17 mostrou.

## Quando um builder vale a pena

Um builder é uma segunda classe com cada atributo escrito duas vezes, então ele precisa merecer o
lugar:

| situação | o que escrever |
|---|---|
| dois ou três atributos, todos obrigatórios | um construtor, ou o `record` da lição 29 |
| vários atributos opcionais com padrões sensatos | um builder |
| regras que envolvem mais de um atributo ao mesmo tempo | um builder, com as regras no `build()` |
| um objeto que nunca pode mudar depois de feito | qualquer um dos dois, sem setters no resultado |

O builder do JDK que você mais deve encontrar é o `StringBuilder`, cujo `toString()` faz o papel do
`build()`. O curso `java-back` encontra muitos outros, porque requisições HTTP e consultas a banco de
dados têm exatamente esse formato: algumas partes obrigatórias e uma cauda longa de opcionais.
