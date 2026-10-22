---
title: O que uma classe abstrata ainda tem, e quando escrever uma
version: 1
---

"Não pode ser instanciada" é fácil de ler como "não é bem uma classe". **Uma classe abstrata é uma
classe completa a que faltam alguns corpos**: tem atributos, construtores, métodos privados e
concretos, e todo objeto de subclasse carrega tudo isso. O `javap` mostra o `Loanable` como o
compilador o deixou:

```
ana@vm:~/abstract/fees$ javap -p Loanable
Compiled from "Loanable.java"
public abstract class Loanable {
  private final java.lang.String title;
  protected Loanable(java.lang.String);
  public final int lateFeeCents(int);
  protected abstract int dailyFeeCents();
  protected int maximumFeeCents();
  public java.lang.String title();
}
```

Um atributo privado, um construtor, três métodos com corpo e um sem, marcado `abstract`. A própria
classe é `public abstract class`, e essa palavra é a diferença inteira no arquivo.

## Um construtor que ninguém chama com `new`

O `Loanable` tem um construtor, e `new Loanable(...)` é proibido. O construtor existe para as
subclasses: **todo `Book` e todo `Dvd` o executa por meio do `super(title)`**, que é como o `title`
recebe o valor, seja qual for a subclasse criada. Declará-lo `protected` diz isso em voz alta, já que
nada além de uma subclasse consegue usá-lo de qualquer forma.

Há mais um jeito de obter um `Loanable`, e é o da lição 17. Uma classe anônima pode estender uma
classe abstrata tão facilmente quanto implementa uma interface, fornecendo os corpos que faltam nas
chaves. Salve isto também em `~/abstract/fees`:

```java
// Special.java
public class Special {
    public static void main(String[] args) {
        Loanable map = new Loanable("Map of Lisbon, 1755") {
            @Override
            protected int dailyFeeCents() {
                return 500;
            }
        };
        System.out.println(map.title() + ": " + map.lateFeeCents(10) + " cents");
        System.out.println(map.getClass().getName() + " extends " + map.getClass().getSuperclass().getName());
    }
}
```
```
ana@vm:~/abstract/fees$ javac Special.java && java Special
Map of Lisbon, 1755: 2000 cents
Special$1 extends Loanable
```

`new Loanable("Map of Lisbon, 1755") { ... }` passou o título ao construtor, escreveu o
`dailyFeeCents()` nas chaves e criou o único objeto dessa classe. Dez dias a 5.00 dariam 5000
centavos, e o máximo herdado os limitou a 2000. A classe se chama `Special$1`, e a superclasse dela é
`Loanable`: continua não sendo um objeto da própria classe abstrata, mas de uma subclasse concreta sem
nome, feita na hora.

## Classe abstrata ou não

Escreva uma classe abstrata quando **várias classes dividem estado e código, e o código comum precisa
de algo que só elas podem fornecer**. O `Loanable` se encaixa: todo item tem um título, e a regra da
taxa precisa de uma diária. Dois outros formatos são mais comuns do que se imagina, e nenhum precisa
de uma:

- **Toda subclasse é igual, a não ser pelos dados.** Se um livro e um DVD diferissem só na taxa diária,
  esse número poderia ser um atributo definido por um construtor, e uma classe concreta bastaria. Um
  método abstrato se justifica quando as subclasses executam *código* diferente.
- **Só o comportamento é comum, sem estado.** Uma promessa de métodos sem atributos por trás é para o
  que serve uma **interface**, e uma classe pode implementar várias interfaces enquanto só pode
  estender uma classe. A lição 23 é sobre interfaces, e a própria biblioteca do Java usa as duas
  juntas: a interface `List` é a promessa, e a classe abstrata `AbstractList` é uma implementação
  parcial para quem escreve uma lista própria.

**O teste é a frase da lição 20, com uma palavra a mais**: todo `Dvd` *é um tipo de* `Loanable`, e um
`Loanable` que não é tipo nenhum de coisa não faz sentido. Quando as duas metades são verdadeiras, a
classe é abstrata.
