---
title: Métodos sem objeto
version: 1
---

Um método da lição 13 sempre rodava num objeto: o que vinha antes do ponto, que ele alcançava como
`this`. Alguns comportamentos não têm objeto em que rodar. Conferir se uma string tem o formato de um
ISBN precisa da string e de mais nada. **Um método `static` pertence à classe, é chamado pelo nome
dela, e não tem `this`.**

```java
// Isbns.java
class Isbns {
    static boolean looksValid(String isbn) {
        String digits = isbn.replace("-", "");
        return digits.length() == 13;
    }
}
```

```java
// Check.java
public class Check {
    public static void main(String[] args) {
        System.out.println(Isbns.looksValid("978-85-359-0277-1"));
        System.out.println(Isbns.looksValid("85-359-0277"));
        System.out.println(Math.max(3, 7));
    }
}
```

```
ana@vm:~/static$ javac Check.java && java Check
true
false
7
```

Nenhum objeto `Isbns` foi criado, e nada nele ajudaria: a entrada inteira do método é o parâmetro. O
`Math.max` é o mesmo tipo de método, da própria biblioteca do JDK, e `Math` é uma classe feita só de
métodos estáticos e constantes, da qual ninguém nunca cria um objeto. (A conferência em si só conta
dígitos; uma de verdade também confere o último dígito, que é uma conta de que esta lição não
precisa.)

## Por que o `main` é estático

Quando `java Check` começa, a JVM carregou uma classe e não criou objeto nenhum. Ela precisa de um
método que consiga chamar **sem objeto**, e é exatamente isso que `public static void main(String[]
args)` é. De dentro de um método estático, porém, não há `this`, então um método de instância da
mesma classe não pode ser chamado só pelo nome:

```java
// Greeter.java
public class Greeter {
    String greeting = "Olá";

    void greet() {
        System.out.println(greeting);
    }

    public static void main(String[] args) {
        greet();
    }
}
```

```
ana@vm:~/static$ javac Greeter.java
Greeter.java:10: error: non-static method greet() cannot be referenced from a static context
        greet();
        ^
1 error
```

**Um *contexto estático* é código que roda sem objeto**, e o `greet()` precisa de um, porque lê
`greeting`, de que cada `Greeter` tem a sua cópia. A correção é criar o objeto primeiro e chamar o
método nele:

```java
// Greeter.java
public class Greeter {
    String greeting = "Olá";

    void greet() {
        System.out.println(greeting);
    }

    public static void main(String[] args) {
        Greeter g = new Greeter();
        g.greet();
    }
}
```

```
ana@vm:~/static$ javac Greeter.java && java Greeter
Olá
```

Esse erro é um dos primeiros que um programador Java encontra, e "deixa estático também" é a resposta
errada de sempre, porque se espalha: o `greet` passaria a precisar que `greeting` fosse estático, e
logo o programa tem uma cópia compartilhada de tudo. **Pergunte se o método precisa dos dados de um
objeto. Se precisa, precisa de um objeto; se não precisa, pode ser estático.** O `looksValid` precisa
só do parâmetro; o `greet` precisa de uma saudação. Os arquivos-fonte compactos da lição 3, que não
existem no Java 21, deixam o próprio `main` ser um método de instância, porque o lançador cria o
objeto antes; a pergunta é a mesma.
