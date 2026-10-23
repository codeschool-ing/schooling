---
title: `if`, `else` e os operadores que decidem
version: 1
---

Um programa que não consegue escolher faz a mesma coisa toda vez. **O `if` executa um bloco só quando
uma condição é `true`**, e a condição precisa ser um `boolean`: uma comparação como `loans < limit`,
um método que responde sim ou não, ou vários desses unidos com `&&` (e), `||` (ou) e `!` (não). Crie
um diretório para esta lição, `~/cond`, e salve isto como `Loans.java`, uma biblioteca decidindo se
um sócio pode pegar mais um livro emprestado:

```schooling-example
{
  "language": "java",
  "file": "Loans.java",
  "parts": [
    {
      "code": "public class Loans {\n    static boolean hasOverdue(String member) {\n        System.out.println(\"  checked the overdue loans of \" + member);\n        return member.equals(\"Bruno\");\n    }",
      "note": "Um método que **avisa quando roda**, para a saída mostrar se uma condição o chamou. Ele responde `true` só para o Bruno. A lição 13 é sobre escrever métodos; aqui ele é uma testemunha."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        int loans = 3;\n        int limit = 3;\n        if (loans < limit) {\n            System.out.println(\"may borrow\");\n        } else if (loans == limit) {\n            System.out.println(\"at the limit\");\n        } else {\n            System.out.println(\"over the limit\");\n        }",
      "note": "**Uma cadeia de `if` toma o primeiro ramo cuja condição é `true` e pula o resto.** 3 não é menor que 3, 3 é igual a 3, então imprimiu `at the limit`, e o `else` nem foi olhado."
    },
    {
      "code": "\n        System.out.println(\"with &&:\");\n        if (loans < limit && hasOverdue(\"Ana\")) {\n            System.out.println(\"  refused\");\n        }",
      "note": "O `&&` para no primeiro `false`. `loans < limit` é `false`, então **o `hasOverdue` nunca foi chamado**: nada foi impresso abaixo de `with &&:`."
    },
    {
      "code": "        System.out.println(\"with &:\");\n        if (loans < limit & hasOverdue(\"Ana\")) {\n            System.out.println(\"  refused\");\n        }",
      "note": "Um `&` simples avalia os dois lados, dê o primeiro o que der, então desta vez o método rodou e imprimiu a linha dele. A resposta é o mesmo `false`; só o trabalho muda."
    },
    {
      "code": "\n        String word = loans == 1 ? \"loan\" : \"loans\";\n        System.out.println(loans + \" \" + word);",
      "note": "O **operador condicional**, `condição ? a : b`, é um `if` que produz um valor. Ele escolheu `\"loans\"` porque `loans` não é 1."
    },
    {
      "code": "\n        int fine = 0;\n        if (loans > limit)\n            fine = 5;\n            System.out.println(\"fine charged\");\n        System.out.println(\"fine \" + fine);\n    }\n}",
      "note": "**Sem chaves, um `if` controla exatamente uma instrução**, a seguinte. A indentação sugere duas, e o compilador ignora indentação: `fine charged` saiu impresso com multa 0."
    }
  ],
  "output": "at the limit\nwith &&:\nwith &:\n  checked the overdue loans of Ana\n3 loans\nfine charged\nfine 0\n"
}
```

## Curto-circuito, e por que isso importa

`&&` e `||` se chamam operadores de **curto-circuito**: cada um avalia o lado direito só quando o
lado esquerdo ainda não decidiu a resposta. `false && qualquer coisa` é `false`, e
`true || qualquer coisa` é `true`, então o lado direito é pulado. Isso é um detalhe de desempenho até
o lado direito fazer alguma coisa, e aí passa a ser o ponto todo. O uso mais comum é uma guarda:
`member != null && member.equals("Bruno")` nunca chama `equals` num `null`, porque o lado esquerdo o
impede antes. **Inverta os dois lados e a guarda some.**

`&` e `|` em `boolean` sempre avaliam os dois lados. Eles existem, e a saída os mostra funcionando;
numa condição, o par de curto-circuito é quase sempre o que você quer dizer.

## Escreva sempre as chaves

O último bloco do programa é o bug que as chaves evitam. As duas linhas indentadas parecem um bloco
só sob o `if`, e **só a primeira pertence a ele**. Nada avisou: o programa compilou e rodou, e
imprimiu `fine charged` para um sócio sem multa nenhuma. Os guias de estilo de Java mais usados
exigem chaves em todo `if`, mesmo naquele cujo corpo é uma linha só, para que acrescentar uma segunda
linha depois não possa fazer isso.

## Uma condição precisa ser um `boolean`

Em C, `if (x = 5)` atribui 5 a `x` e depois trata o 5 como verdadeiro, e é um bug famoso. O Java o
recusa na compilação:

```java
// Assign.java
public class Assign {
    public static void main(String[] args) {
        int loans = 3;
        if (loans = 5) {
            System.out.println("five");
        }
    }
}
```

```
ana@vm:~/cond$ javac Assign.java
Assign.java:5: error: incompatible types: int cannot be converted to boolean
        if (loans = 5) {
                  ^
1 error
```

`loans = 5` é uma atribuição, e o valor dela é o `int` 5. **O Java nunca trata um número como
verdadeiro ou falso**, então o compilador para na linha 5 e põe um acento circunflexo embaixo do
`=`. A comparação é `==`.
