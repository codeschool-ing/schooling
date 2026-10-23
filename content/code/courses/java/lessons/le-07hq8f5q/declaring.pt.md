---
title: Declarar uma variável, e dar um valor a ela antes de ler
version: 1
---

Uma variável é um nome para um lugar que guarda um valor de um tipo. Declará-la diz o nome e o tipo;
atribuí-la põe um valor ali. Em Java as duas coisas podem acontecer numa linha, `int daysLate = 3;`,
ou em duas. **O que o Java não permite é ler uma variável local antes de ela certamente ter recebido
um valor**, e esse "certamente" é conferido pelo compilador, caminho por caminho, antes de o programa
rodar.

## "Might not have been initialized"

Uma multa de 50 centavos por dia, em `~/scope`, com um erro:

```java
// Fine.java
public class Fine {
    public static void main(String[] args) {
        int daysLate = 3;
        int fine;
        if (daysLate > 0) {
            fine = daysLate * 50;
        }
        System.out.println(fine);
    }
}
```

```
ana@vm:~/scope$ javac Fine.java
Fine.java:9: error: variable fine might not have been initialized
        System.out.println(fine);
                           ^
1 error
```

Lendo o programa, você vê que `daysLate` é 3 e que o `if` vai rodar. **O compilador não raciocina
sobre valores**, só sobre caminhos pelo código. Existe um caminho em que o `if` não roda, e nesse
caminho `fine` é impressa sem nunca ter recebido nada. O Java chama a regra de **atribuição definida**
(definite assignment), e a correção é dar um valor a `fine` em todos os caminhos: `int fine = 0;` na
declaração, ou um `else` que a atribua, que a lição 10 mostra.

É uma característica que você vai agradecer. Em C, o mesmo programa compila e imprime o que estivesse
naquela memória, que muda entre execuções e máquinas. Em Java, uma variável local que não recebeu
valor **não pode ser lida de jeito nenhum**, então o bug é pego onde foi escrito.

## Campos ganham um padrão, locais não

Uma variável declarada dentro de um método é uma **variável local**, e a regra acima é para elas. Uma
variável declarada numa classe, fora de qualquer método, é um **campo** (field), e os campos recebem
um valor padrão quando são criados. A lição 13 é sobre campos. Aqui, campos `static` mostram os
padrões sem precisar de objeto, o que a lição 15 explica:

```java
// Defaults.java
public class Defaults {
    static int loans;
    static double balance;
    static boolean blocked;
    static char grade;
    static String name;

    public static void main(String[] args) {
        System.out.println(loans);
        System.out.println(balance);
        System.out.println(blocked);
        System.out.println(grade + 0);
        System.out.println(name);
    }
}
```

```
ana@vm:~/scope$ java Defaults.java
0
0.0
false
0
null
```

| tipo do campo | padrão |
|---|---|
| `int`, `long`, `short`, `byte` | `0` |
| `double`, `float` | `0.0` |
| `boolean` | `false` |
| `char` | o caractere de código 0, impresso acima como número |
| qualquer tipo de objeto, como `String` | `null` |

**Um padrão é um valor que ninguém escolheu.** Um `balance` de `0.0` e um `name` igual a `null`
parecem dados de verdade para o código que os lê. A diferença entre as duas regras não é acidente: um
campo pode ser lido por qualquer método da classe, a qualquer momento, e o compilador não consegue
seguir todos os caminhos até ele, então se contenta com um valor inicial conhecido. Uma variável local
só é visível dentro do próprio método, onde o compilador consegue conferir cada caminho, e confere.
