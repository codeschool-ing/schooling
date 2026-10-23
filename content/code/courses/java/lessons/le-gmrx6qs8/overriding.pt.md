---
title: Sobrescrita, decidida pelo objeto
version: 1
---

**Sobrescrita (overriding) é uma subclasse substituindo um método que herdou**, com o mesmo nome e os
mesmos tipos de parâmetro. A sobrecarga acrescentava métodos lado a lado numa classe; a sobrescrita
põe um corpo novo no lugar de um antigo, um nível abaixo. Qual corpo roda é decidido pelo objeto,
com o programa rodando, e é isso que a lição 25 desmonta.

## Uma sobrescrita, e a anotação que a confere

Em `~/overload/override`, uma classe pai:

```java
// Item.java
public class Item {
    protected final String title;

    public Item(String title) {
        this.title = title;
    }

    public String describe() {
        return "item " + title;
    }

    public Item copy() {
        return new Item(title);
    }
}
```

E uma subclasse que sobrescreve os dois métodos dela:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {
      "code": "public class Book extends Item {\n    public Book(String title) {\n        super(title);\n    }",
      "note": "`Book` estende `Item` e passa o título para o construtor de `Item` com `super`, como a lição 20 mostrou."
    },
    {
      "code": "\n    @Override\n    public String describe() {\n        return \"book \" + title;\n    }",
      "note": "**Uma sobrescrita: mesmo nome, mesmos parâmetros, mesmo tipo de retorno.** O `@Override` pede ao compilador que confirme que `Item` tem mesmo um `describe()` para este substituir."
    },
    {
      "code": "\n    @Override\n    public Book copy() {\n        return new Book(title);\n    }\n}",
      "note": "**Um retorno covariante.** `Item.copy()` devolve um `Item`; a sobrescrita pode estreitar isso para `Book`, porque um `Book` é um `Item` e todo chamador da assinatura antiga continua recebendo o que lhe foi prometido."
    }
  ]
}
```

As regras de uma sobrescrita são curtas, e o compilador faz valer cada uma:

| | a sobrescrita precisa | exemplo |
|---|---|---|
| nome e parâmetros | ser exatamente iguais | `describe()`, sem parâmetros |
| tipo de retorno | ser o mesmo, ou um subtipo dele | `Book copy()` para `Item copy()` |
| acesso | ser o mesmo, ou mais amplo | `public` continua `public` |
| métodos `static`, `final` e `private` | não podem ser sobrescritos | a lição 25 mostra o que acontece no lugar |

## Uma letra errada

Agora uma subclasse cujo autor queria sobrescrever `describe` e digitou `descibe`:

```java
// Typo.java
public class Typo extends Item {
    public Typo(String title) {
        super(title);
    }

    public String descibe() {
        return "typo " + title;
    }
}
```

```java
// Counter.java
public class Counter {
    public static void main(String[] args) {
        Book copy = new Book("Iracema").copy();
        System.out.println(copy.describe());
        Item typo = new Typo("Dom Casmurro");
        System.out.println(typo.describe());
    }
}
```

```
ana@vm:~/overload/override$ javac *.java && java Counter
book Iracema
item Dom Casmurro
```

A sobrescrita do livro rodou e imprimiu `book Iracema`. O erro de digitação não falhou em lugar
nenhum. **`descibe` é um método novo que ninguém chama**, então `Typo` herdou o `describe` de `Item`
intacto e imprimiu `item Dom Casmurro`. O compilador não tinha como saber a intenção do autor, porque
acrescentar um método novo é perfeitamente legal.

O `@Override` é como a intenção fica escrita:

```java
// Typo.java
public class Typo extends Item {
    public Typo(String title) {
        super(title);
    }

    @Override
    public String descibe() {
        return "typo " + title;
    }
}
```

```
ana@vm:~/overload/override$ javac Typo.java
Typo.java:7: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

**Com a anotação, o erro de digitação vira erro de compilação na linha certa.** Esse é todo o
propósito do `@Override`: ele não muda nada no código que roda, e transforma "eu queria substituir um
método" de esperança em algo que o compilador confere. Ponha-o em toda sobrescrita. A lição 39 olha
para as anotações como um todo.

## Estreitar o acesso é recusado

```java
// Quiet.java
public class Quiet extends Item {
    public Quiet(String title) {
        super(title);
    }

    @Override
    protected String describe() {
        return "quiet " + title;
    }
}
```

```
ana@vm:~/overload/override$ javac Quiet.java
Quiet.java:8: error: describe() in Quiet cannot override describe() in Item
    protected String describe() {
                     ^
  attempting to assign weaker access privileges; was public
1 error
```

Uma sobrescrita pode tornar um método mais visível e nunca menos. Um código que segura um `Item` tem
direito de chamar `describe()`, porque `Item` diz que ele é público; se uma subclasse pudesse torná-lo
`protected`, essa promessa quebraria para todo `Item` que acabasse sendo um `Quiet`. Então o
compilador recusa, e diz qual era o acesso: `was public`.
