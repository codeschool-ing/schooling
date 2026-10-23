---
title: Onde os objetos moram enquanto o programa roda
version: 1
---

Uma JVM em execução mantém separados dois tipos de memória, e a diferença é o assunto da seção 03.
**Variáveis locais moram na pilha** (stack), num quadro (frame) que pertence a uma chamada de um
método e some quando a chamada retorna. **Objetos moram no heap**, uma região compartilhada pelo
programa todo, e ficam ali enquanto alguma referência ainda levar a eles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Pilha e heap durante o Refs. Na pilha, o quadro do main guarda cinco variáveis locais: args, a, b, c e none. a e b apontam para um mesmo objeto Book no heap, cujo title aponta para a string Memorial de Aires. c aponta para um segundo objeto Book, cujo title aponta para outra string com os mesmos caracteres. none não aponta para nada.\"><defs><marker id=\"jv12-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a pilha</text><rect x=\"20\" y=\"36\" width=\"180\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quadro do main</text><rect x=\"36\" y=\"70\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">args</text><rect x=\"36\" y=\"106\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a</text><rect x=\"36\" y=\"142\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><rect x=\"36\" y=\"178\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c</text><rect x=\"36\" y=\"214\" width=\"148\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">none = null</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o heap</text><rect x=\"250\" y=\"36\" width=\"450\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"290\" y=\"90\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"365\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">isbn  title  year</text><rect x=\"290\" y=\"176\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"365\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">isbn  title  year</text><rect x=\"500\" y=\"90\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Memorial de Aires\"</text><rect x=\"500\" y=\"176\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Memorial de Aires\"</text><path d=\"M184 120 H230 V114 H288\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M184 156 H230 V126 H288\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M184 192 H230 V206 H288\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M440 110 H498\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><path d=\"M440 196 H498\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#jv12-a)\"></path><text x=\"475\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dois objetos, três referências a eles, e nenhuma vinda de none</text></svg>", "caption": "O Refs da seção 03 logo antes da última linha. a e b levam a um Book; c leva a outro, cujo title é uma string igual e um objeto diferente."}
```

O atributo `title` é ele mesmo uma referência, e é por isso que o desenho tem duas camadas no heap: um
`Book` guarda o caminho até a sua `String`, não os caracteres. **Tudo o que não é um dos oito tipos
primitivos da lição 4 é alcançado por meio de uma referência.** Um atributo `int` como `year` guarda o
próprio número, dentro do objeto.

## Contando os objetos numa JVM em execução

Dá para contar o que está no heap. O `jcmd` do JDK, da lição 2, consegue perguntar a uma JVM em execução
quantos objetos de cada classe ela guarda. Este programa cria mil livros e os mantém por dez segundos,
tempo suficiente para perguntar:

```java
// Shelf.java
public class Shelf {
    public static void main(String[] args) throws InterruptedException {
        Book[] books = new Book[1000];
        for (int i = 0; i < books.length; i++) {
            books[i] = new Book();
            books[i].year = 1900 + i % 100;
        }
        System.out.println(books.length + " books on the shelf, waiting 10 seconds");
        Thread.sleep(10_000);
        System.out.println("done");
    }
}
```

O `throws InterruptedException` está ali porque o `Thread.sleep` o exige, o que a lição 36 explica.
Compile com `javac Shelf.java` e execute num terminal:

```
ana@vm:~/objects$ java Shelf
1000 books on the shelf, waiting 10 seconds
done
```

Enquanto ele espera, num segundo terminal no mesmo diretório, liste as JVMs e peça à que roda o
`Shelf` o seu histograma de classes:

```
ana@vm:~/objects$ jps
30259 Jps
30222 Shelf
ana@vm:~/objects$ jcmd Shelf GC.class_histogram | head -3
30222:
 num     #instances         #bytes  class name (module)
-------------------------------------------------------
ana@vm:~/objects$ jcmd Shelf GC.class_histogram | grep -E " Book$|\[LBook;"
   9:          1000          24000  Book
  24:             1           4016  [LBook;
```

O `jps` listou duas JVMs: `Shelf`, e o próprio `jps`, que também é um programa Java. Os números são
ids de processo, e os seus vão ser outros. O `jcmd` aceita o nome da classe no lugar do id.

**Mil objetos `Book`, 24.000 bytes: 24 bytes cada.** São doze bytes de cabeçalho, que todo objeto
carrega para a JVM saber a sua classe, depois quatro para cada uma das duas referências e quatro para
o `int`. A linha `[LBook;` é o próprio array, o nome que a JVM dá a um `Book[]`: um objeto de 4.016
bytes, um cabeçalho e mil referências de quatro bytes. O array guarda referências aos livros; ele não
os contém. Os dois atributos `String` nunca foram definidos neste programa, então nenhuma string foi
criada para eles.

Quando o `main` retorna, o quadro que guardava `books` vai embora, nada mais leva aos mil livros, e o
programa termina. O que acontece com objetos que ninguém alcança num programa que continua rodando é
a lição 19.
