---
title: O que não é despachado
version: 1
---

O despacho dinâmico cobre uma coisa: **métodos de instância que podem ser sobrescritos**. Todo o
resto que uma classe tem é ligado pelo compilador, a partir do tipo declarado, e uma subclasse que
declara algo com o mesmo nome não o substitui, e sim o esconde. O erro que isso produz é um programa
que imprime o valor do pai onde você esperava o do filho, sem erro nenhum em lugar nenhum.

## Um pai e um filho que declaram tudo

Em `~/binding/hiding`, um pai com um membro de cada tipo:

```java
// Parent.java
public class Parent {
    public String name = "parent field";

    public static String kind() {
        return "parent static";
    }

    public String who() {
        return "parent method";
    }

    public String callSecret() {
        return secret();
    }

    private String secret() {
        return "parent private";
    }
}
```

E um filho que declara os mesmos quatro nomes de novo:

```java
// Child.java
public class Child extends Parent {
    public String name = "child field";

    public static String kind() {
        return "child static";
    }

    @Override
    public String who() {
        return "child method";
    }

    private String secret() {
        return "child private";
    }
}
```

O `@Override` está só em `who()`, porque é o único dos quatro que sobrescreve. Ponha-o em `kind()`
ou em `secret()` e o compilador recusa, como a lição 24 mostrou para um erro de digitação.

## O mesmo objeto, por dois tipos declarados

```java
// Hiding.java
public class Hiding {
    public static void main(String[] args) {
        Parent p = new Child();
        System.out.println(p.who());
        System.out.println(p.name);
        System.out.println(p.kind());
        System.out.println(p.callSecret());

        Child c = (Child) p;
        System.out.println(c.name);
        System.out.println(c.kind());
    }
}
```

```
ana@vm:~/binding/hiding$ javac *.java && java Hiding
child method
parent field
parent static
parent private
child field
child static
```

Um objeto, um `Child`, lido primeiro por uma variável `Parent` e depois por uma `Child`:

| membro | por `Parent p` | por `Child c` | ligado por |
|---|---|---|---|
| `who()`, um método de instância | `child method` | | o objeto, na execução |
| `name`, um atributo | `parent field` | `child field` | o tipo declarado, na compilação |
| `kind()`, um método `static` | `parent static` | `child static` | o tipo declarado, na compilação |
| `secret()`, um método `private` | `parent private` | | a classe que o chama |

**Só o método acompanhou o objeto.** O filho tem dois atributos chamados `name`, o seu e o herdado,
e qual deles você lê depende da variável por onde lê. O `kind()` estático pertence a uma classe, não a
um objeto; chamá-lo por `p` é legal mas enganoso, e o compilador simplesmente usou a classe declarada
de `p`.

## O bytecode diz isso com todas as letras

```
ana@vm:~/binding/hiding$ javap -c Hiding | grep -E "getfield|invoke"
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: invokespecial #9                  // Method Child."<init>":()V
        12: invokevirtual #16                 // Method Parent.who:()Ljava/lang/String;
        15: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        22: getfield      #28                 // Field Parent.name:Ljava/lang/String;
        25: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        33: invokestatic  #32                 // Method Parent.kind:()Ljava/lang/String;
        36: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        43: invokevirtual #35                 // Method Parent.callSecret:()Ljava/lang/String;
        46: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        58: getfield      #38                 // Field Child.name:Ljava/lang/String;
        61: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        69: invokestatic  #39                 // Method Child.kind:()Ljava/lang/String;
        72: invokevirtual #22                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
```

O `who()` foi compilado como `invokevirtual`, então a JVM escolheu o corpo. **As leituras de
atributo são `getfield Parent.name` e `getfield Child.name`**, dois atributos diferentes nomeados na
própria instrução, e as chamadas estáticas são `invokestatic` de `Parent.kind` e de `Child.kind`.
Não sobra nada para o tempo de execução decidir.

O método privado é o sutil:

```
ana@vm:~/binding/hiding$ javap -c -p Parent | grep -A3 "callSecret()"
  public java.lang.String callSecret();
    Code:
         0: aload_0
         1: invokevirtual #19                 // Method secret:()Ljava/lang/String;
```

Desde o Java 11, o `javac` chama até um método privado com `invokevirtual`. Isso não muda o
resultado: **um método privado é invisível para toda subclasse, então nunca é sobrescrito**, e a JVM
seleciona `Parent.secret` porque o método que a instrução nomeia é privado. O `Child.secret` é um
segundo método, sem relação, que por acaso tem o mesmo nome, e é por isso que o `callSecret()`
imprimiu `parent private`.

A regra a guardar: se você quer que uma subclasse mude um comportamento, dê a ela um método de
instância sobrescrevível. Atributos ficam privados atrás de métodos de acesso, como a lição 22
defendeu, e um método estático se chama pelo nome da sua classe, nunca por uma variável, para que
ninguém que leia a chamada seja enganado.
