---
title: Uma troca que não faz nada
version: 1
---

Uma pergunta está por baixo de uma família inteira de bugs em Java, aqueles em que um método mudou
algo que não devia, ou deixou de mudar algo que devia. **Quando você chama um método e entrega uma
variável, o que o método recebe?** Há duas respostas possíveis nas linguagens de programação em
geral. *Por valor*: o método ganha uma cópia do que a variável guarda, e nada do que ele faz com a
cópia alcança a sua variável. *Por referência*: o método ganha a própria variável, e atribuir ao
parâmetro é atribuir à sua.

**O Java tem exatamente uma das duas, para tudo: por valor.** Esta seção mostra isso com números,
onde ninguém duvida. A seção 03 mostra com objetos, onde a maioria duvida.

O teste clássico é um método que troca os seus dois argumentos de lugar. Numa linguagem que passa
por referência ele funciona; numa que passa por valor ele não tem como funcionar. Em `~/byvalue`:

```java
// Swap.java
public class Swap {
    static void swap(int a, int b) {
        int t = a;
        a = b;
        b = t;
        System.out.println("inside swap: a=" + a + " b=" + b);
    }

    static void addOne(int n) {
        n = n + 1;
    }

    public static void main(String[] args) {
        int x = 1;
        int y = 2;
        swap(x, y);
        System.out.println("after swap:  x=" + x + " y=" + y);
        addOne(x);
        System.out.println("after addOne: x=" + x);
    }
}
```

```
ana@vm:~/byvalue$ javac Swap.java && java Swap
inside swap: a=2 b=1
after swap:  x=1 y=2
after addOne: x=1
```

**Dentro do `swap`, os dois valores trocaram de lugar. Fora, nada aconteceu.** O `x` continua 1 e o
`y` continua 2, e o `addOne(x)` também deixou o `x` em 1. O `swap` tinha duas variáveis próprias, `a`
e `b`, que nasceram como cópias de `x` e `y`, e tudo o que ele fez, fez com as cópias dele. Quando
ele retornou, as cópias foram jogadas fora junto com ele.

## Onde as cópias moram

A lição 5 disse que as variáveis locais de um método moram no **frame** dele, criado quando o método
é chamado e descartado quando ele retorna. **Parâmetros são variáveis locais do método**, preenchidas
por quem chama. O bytecode mostra a entrega. Primeiro o `main`, até a chamada:

```
ana@vm:~/byvalue$ javap -c Swap | sed -n 32,40p
  public static void main(java.lang.String[]);
    Code:
         0: iconst_1
         1: istore_1
         2: iconst_2
         3: istore_2
         4: iload_1
         5: iload_2
         6: invokestatic  #23                 // Method swap:(II)V
```

`istore_1` e `istore_2` põem 1 e 2 nos slots locais 1 e 2 do `main`, que são `x` e `y` (o slot 0 é
o `args`). Depois **`iload_1` e `iload_2` empilham os dois valores**, não as variáveis, e o
`invokestatic` chama o `swap` com eles. Dentro do `swap`:

```
ana@vm:~/byvalue$ javap -c Swap | sed -n 9,16p
  static void swap(int, int);
    Code:
         0: iload_0
         1: istore_2
         2: iload_1
         3: istore_0
         4: iload_2
         5: istore_1
```

Os parâmetros do `swap` são os slots 0 e 1 **dele**, e o `t` dele é o slot 2. As seis instruções
trocam valores entre esses três slots e não tocam em mais nada. Nenhuma instrução da JVM deixa o
`swap` alcançar o slot 1 do `main`: **um método lê e escreve o próprio frame e o de mais ninguém.**
Isso é passagem por valor, do jeito que a máquina faz.

Ninguém se surpreende com isso num `int`. O que surpreende é que **objetos seguem exatamente a mesma
regra**, e a próxima seção é o motivo de não parecer assim.
