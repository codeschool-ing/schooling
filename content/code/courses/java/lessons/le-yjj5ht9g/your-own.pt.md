---
title: Uma anotação sua, e o código que a lê
version: 1
---

Declarar uma anotação é declarar um tipo especial de interface, com `@interface`. Duas anotações do JDK
vão nela e decidem quase tudo o que ela pode fazer: **o `@Retention` diz quanto tempo ela vive**, como a
seção 03 mostrou, e **o `@Target` diz em que ela pode ser escrita**: uma classe, um método, um campo, um
parâmetro. Esta marca campos que não podem ficar em branco, e carrega uma mensagem:

```java
// NotBlank.java
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface NotBlank {
    String message() default "must not be blank";
}
```

O `message()` parece um método e funciona como uma configuração. O `default` lhe dá um valor, então
`@NotBlank` sozinho é válido, e `@NotBlank(message = "...")` o substitui. Os tipos que um elemento assim
pode ter são poucos e fixos: primitivos, `String`, `Class`, enums, outras anotações, e arrays desses,
porque o valor precisa ser gravado no arquivo de classe.

Uma classe que a usa em dois campos e deixa o terceiro em paz:

```java
// Member.java
public class Member {
    @NotBlank
    String name;

    @NotBlank(message = "an e-mail address is needed for reminders")
    String email;

    String phone;

    Member(String name, String email, String phone) {
        this.name = name;
        this.email = email;
        this.phone = phone;
    }
}
```

## O código que lhe dá significado

O `@NotBlank` ainda não significa nada. **O significado é o que faz o código que a lê**, e este
validador é esse código:

```schooling-example
{
  "language": "java",
  "file": "Validator.java",
  "parts": [
    {
      "code": "// Validator.java\nimport java.lang.reflect.Field;\nimport java.util.ArrayList;\nimport java.util.List;\n\npublic class Validator {\n    static List<String> check(Object o) throws IllegalAccessException {\n        List<String> problems = new ArrayList<>();",
      "note": "O `check` recebe qualquer objeto e devolve uma lista do que há de errado nele, vazia quando não há nada. **Ele não sabe nada sobre `Member`**, e é isso que o faz um validador, e não um método de uma classe."
    },
    {
      "code": "        for (Field f : o.getClass().getDeclaredFields()) {\n            NotBlank rule = f.getAnnotation(NotBlank.class);\n            if (rule == null) continue;",
      "note": "Para cada campo que a classe declara, pede o `@NotBlank` dele. O `getAnnotation` devolve a anotação, ou `null` quando o campo não tem, e um campo sem ela é pulado: o `phone` nunca passa desta linha."
    },
    {
      "code": "            Object value = f.get(o);\n            if (value == null || value.toString().isBlank()) {\n                problems.add(f.getName() + \": \" + rule.message());\n            }\n        }\n        return problems;\n    }",
      "note": "O `f.get(o)` lê o valor do campo neste objeto. Nulo ou só espaços é um problema, relatado com o nome do campo e o `message()` da própria anotação, que é o padrão a menos que o campo tenha definido outro."
    },
    {
      "code": "\n    public static void main(String[] args) throws IllegalAccessException {\n        System.out.println(check(new Member(\"Ana\", \"ana@example.com\", null)));\n        System.out.println(check(new Member(\"  \", null, \"\")));\n    }\n}",
      "note": "Dois membros: um completo, outro com um nome de dois espaços e sem e-mail. O telefone está vazio nos dois e ninguém se importa, porque nada o marcou."
    }
  ]
}
```

```
ana@vm:~/annot$ javac NotBlank.java Member.java Validator.java && java Validator
[]
[name: must not be blank, email: an e-mail address is needed for reminders]
```

`[]` para a Ana, que tem nome e endereço. Dois problemas para o segundo membro, cada um com a sua
mensagem: a padrão para `name`, que eram dois espaços, e a própria do campo para `email`, que era
`null`. **A regra mora no campo e a conferência mora num lugar só**, então uma terceira classe com
campos `@NotBlank` é validada sem código novo. Esse é o formato do Jakarta Bean Validation, a biblioteca
que o `java-back` usa nos dados que um serviço web recebe, numa fração do tamanho.

O `f.get(o)` funcionou aqui porque `Validator` e `Member` estão no mesmo pacote e os campos são de
pacote. Ler um campo `private` por reflexão exige antes um `f.setAccessible(true)`, e a lição 40 mostra
um caso em que até isso é recusado.

## O que o `@Target` recusa

Escrita num método, a anotação é recusada antes de qualquer coisa rodar:

```java
// Misplaced.java
public class Misplaced {
    @NotBlank
    String title() {
        return "";
    }
}
```

```
ana@vm:~/annot$ javac Misplaced.java
Misplaced.java:3: error: annotation interface not applicable to this kind of declaration
    @NotBlank
    ^
1 error
```

O compilador não tem como saber o que `@NotBlank` significa, mas sabe onde o autor dela permitiu que
ela fosse, e um método não está na lista. **A declaração de uma anotação é a única conferência que ela
ganha de graça.** Todo o resto, se o valor está em branco, se é conferido afinal, pertence ao código
que a lê. Um campo marcado com uma anotação que nenhum código lê é um campo com um comentário.
