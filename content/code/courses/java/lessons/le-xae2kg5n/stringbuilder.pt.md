---
title: Construindo uma string pedaço por pedaço
version: 1
---

Se uma string nunca muda, então `s = s + "x"` não consegue acrescentar um `x` a `s`. **Ele constrói
uma string inteira nova**, copia para ela cada caractere da antiga, acrescenta o `x`, e aponta `s`
para o resultado. Uma vez, não é nada. Num laço, é uma cópia de tudo até ali, a cada volta, e o
trabalho cresce com o quadrado do comprimento. O `StringBuilder` é a classe para esse serviço: um
buffer de caracteres que **muda**, sim, que você enche e depois transforma numa `String` uma vez só.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 264\" role=\"img\" aria-label=\"Construindo uma string de cinco caracteres de dois jeitos. Com s = s + x, cada passo cria uma string nova e copia a antiga para dentro dela: 0, 1, 2, 3 e 4 caracteres, dez ao todo, e o trabalho cresce com o quadrado do comprimento. Com um StringBuilder, cinco appends preenchem um buffer só, no lugar, e o toString copia os cinco caracteres uma vez.\"><rect x=\"16\" y=\"16\" width=\"380\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">s = s + \"x\", cinco vezes</text><rect x=\"36\" y=\"56\" width=\"32\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><text x=\"250\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma string nova; 0 copiados</text><rect x=\"36\" y=\"90\" width=\"54\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"63.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xx</text><text x=\"250\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma string nova; 1 copiados</text><rect x=\"36\" y=\"124\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xxx</text><text x=\"250\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma string nova; 2 copiados</text><rect x=\"36\" y=\"158\" width=\"98\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xxxx</text><text x=\"250\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma string nova; 3 copiados</text><rect x=\"36\" y=\"192\" width=\"120\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">xxxxx</text><text x=\"250\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma string nova; 4 copiados</text><text x=\"206\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0+1+2+3+4 = 10 caracteres copiados</text><rect x=\"412\" y=\"16\" width=\"292\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"558\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">StringBuilder, cinco appends</text><rect x=\"440\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"453\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"470\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"483\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"500\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"513\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"530\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"543\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"560\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"573\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">x</text><rect x=\"590\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"620\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"650\" y=\"90\" width=\"26\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"558\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um buffer só, preenchido no lugar, com folga</text><text x=\"558\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">sb.toString()</text><text x=\"558\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copia os 5 caracteres uma vez</text><text x=\"558\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 caracteres copiados</text></svg>", "caption": "Cinco passos de cada. A coluna da esquerda cresce com o quadrado do comprimento; a da direita, com o comprimento."}
```

Este programa constrói a mesma string de 50.000 caracteres dos dois jeitos e cronometra cada um:

```java
// Concat.java
public class Concat {
    public static void main(String[] args) {
        int n = 50_000;

        long start = System.nanoTime();
        String s = "";
        for (int i = 0; i < n; i++) {
            s = s + "x";
        }
        long plus = System.nanoTime() - start;

        start = System.nanoTime();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) {
            sb.append("x");
        }
        String t = sb.toString();
        long builder = System.nanoTime() - start;

        System.out.println(s.length() + " " + t.length() + " " + s.equals(t));
        System.out.println("with +:             " + plus / 1_000_000 + " ms");
        System.out.println("with StringBuilder: " + builder / 1_000_000 + " ms");
    }
}
```

```
ana@vm:~/strings$ javac Concat.java && java Concat
50000 50000 true
with +:             1715 ms
with StringBuilder: 5 ms
```

A mesma string, `true`, e o laço com `+` levou mais de 300 vezes mais tempo. **Os dois tempos são de
uma execução, e eles variam**: em três execuções deste mesmo programa na mesma máquina, o primeiro
mudou num fator de cinco e o segundo ficou na casa de um dígito. A proporção é o achado, e ela
cresce quando `n` cresce, porque as cópias crescem junto. O `System.nanoTime()` é o relógio para
medir um intervalo assim; `/ 1_000_000` transforma nanossegundos em milissegundos, e os sublinhados
em `50_000` estão ali só para quem lê.

## Quando o `+` está bem

Nada disso torna o `+` errado. **Fora de um laço, o `+` é a escolha mais clara e não custa nada a
mais.** O compilador nem o transforma numa cadeia de cópias. Este método junta quatro pedaços:

```java
// Greeting.java
public class Greeting {
    static String greet(String name, int books) {
        return "Hello, " + name + ", you have " + books + " books";
    }

    public static void main(String[] args) {
        System.out.println(greet("Ana", 3));
    }
}
```

```
ana@vm:~/strings$ javac Greeting.java && java Greeting
Hello, Ana, you have 3 books
ana@vm:~/strings$ javap -c Greeting | grep -A5 "greet(java"
  static java.lang.String greet(java.lang.String, int);
    Code:
         0: aload_0
         1: iload_1
         2: invokedynamic #7,  0              // InvokeDynamic #0:makeConcatWithConstants:(Ljava/lang/String;I)Ljava/lang/String;
         7: areturn
```

A lição 1 leu bytecode com `javap -c`, e este método tem quatro instruções: carrega `name`, carrega
`books`, um `invokedynamic`, retorna. **A expressão inteira virou uma chamada só** a
`makeConcatWithConstants`, que a JVM prepara na primeira vez que roda e que dimensiona o resultado
uma vez. As partes literais, `"Hello, "` e as outras, viajam como um modelo, e não como strings
separadas. O `int` também não precisou de conversão no código: quando um dos lados do `+` é uma
`String`, o outro vira texto, seja qual for o tipo.

Então a regra é estreita. **Dentro de um laço que faz uma string crescer, use um `StringBuilder`.**
Em qualquer outro lugar, escreva `+` e deixe o resto com o compilador. Os métodos do `StringBuilder`
devolvem o próprio builder, então `sb.append(a).append(b)` é uma instrução só, e a lição 26 é sobre
esse estilo de método.
