---
title: `super`, e a classe que toda classe estende
version: 1
---

O `Dvd` da seção 02 substituiu o `loanDays()` por inteiro. O mais comum é uma subclasse querer o
comportamento da mãe **mais** alguma coisa: a mesma descrição, com a duração no fim. Reescrever o
`Item.describe()` dentro de `Dvd` o copiaria, e a cópia se afastaria do original. **`super.metodo()`
chama a versão da superclasse de dentro de uma sobrescrita**, então a subclasse acrescenta em vez de
copiar.

Troque o `Dvd.java` por esta versão, que sobrescreve também o `describe()`:

```java
// Dvd.java
public class Dvd extends Item {
    private final int minutes;

    public Dvd(String title, int year, int minutes) {
        super(title, year);
        this.minutes = minutes;
    }

    @Override
    public int loanDays() {
        return 7;
    }

    @Override
    public String describe() {
        return super.describe() + ", " + minutes + " minutes";
    }
}
```

`super.describe()` executa o `describe()` de `Item` sobre este mesmo objeto DVD, e o resultado ganha
`, 153 minutes` no fim. Repare no que o próprio `super.describe()` continua chamando: `loanDays()`, e
num DVD esse é o sobrescrito, então a linha vai dizer 7 dias. O `super` escolhe qual `describe()`
roda, e não muda o objeto sobre o qual ele roda.

## Toda classe tem uma mãe

`Item` não diz nada sobre superclasse. **Uma classe que não diz `extends` estende
`java.lang.Object`**, então toda classe Java fica sob uma raiz só. Um programa curto sobe a partir de
`Book`, e depois tenta três coisas que `Book` nunca declarou:

```java
// Chain.java
public class Chain {
    public static void main(String[] args) {
        Class<?> c = Book.class;
        while (c != null) {
            System.out.println(c.getName());
            c = c.getSuperclass();
        }
        Book a = new Book("Effective Java", 2018, "Joshua Bloch");
        Book b = new Book("Effective Java", 2018, "Joshua Bloch");
        System.out.println(a.equals(b) + " " + (a.hashCode() == b.hashCode()));
        System.out.println(a);
        System.out.println(new Dvd("Metropolis", 1927, 153).describe());
    }
}
```
```
ana@vm:~/inherit$ javac *.java && java Chain
Book
Item
java.lang.Object
false false
Book@7ad041f3
Metropolis (1927), 7 days, 153 minutes
```

As três primeiras linhas são a cadeia: `Book`, `Item`, `java.lang.Object`, e então o
`getSuperclass()` devolveu `null`, porque `Object` não tem mãe. Tudo o que `Object` declara, todo
objeto tem. Três desses métodos importam em toda lição daqui em diante, e dois deles acabaram de se
comportar mal:

| método | o que a versão de `Object` faz | o que fez aqui |
|---|---|---|
| `toString()` | o nome da classe, `@`, e um número derivado da identidade do objeto | imprimiu `Book@7ad041f3`; o número muda a cada execução |
| `equals(Object)` | o mesmo que `==`: verdadeiro só para o mesmíssimo objeto | `a.equals(b)` deu `false` para dois livros com atributos idênticos |
| `hashCode()` | um número derivado da identidade do objeto | diferente para `a` e `b` |

**Dois objetos `Book` com o mesmo título, ano e autor não são iguais, no que depender de `Object`.**
Esse é o padrão certo para algo como uma carteirinha de sócio, em que a identidade é o que importa, e
o errado para um valor como um ISBN. Uma classe que quer igualdade por valor tem de sobrescrever
`equals` e `hashCode` juntos, e a lição 24 mostra o que dá errado quando só um é feito, ou quando é
feito com a assinatura errada. Os records da lição 29 escrevem os três para você. A última linha é o
novo `Dvd`, descrevendo-se com os seus próprios dias e as palavras da mãe.
