---
title: A referência de um objeto também é copiada
version: 1
---

É daqui que vem a crença comum. Passe um objeto para um método, deixe o método mudá-lo, e a mudança
aparece depois. Isso parece exatamente passagem por referência, e muita gente conclui que o Java passa
primitivos por valor e objetos por referência. **Não passa. O Java nunca passa um objeto.** A lição
12 mostrou que uma variável de tipo classe não guarda um objeto; ela guarda uma **referência**, uma
seta para um objeto em algum lugar do heap. O que o método recebe é uma cópia dessa seta.

Um `Book` e dois métodos, em `~/byvalue/refs`. O `renew` muda o objeto para o qual o parâmetro
aponta; o `replace` aponta o parâmetro para outro objeto:

```java
// Refs.java
class Book {
    String title;
    int renewals;

    Book(String title) {
        this.title = title;
    }

    @Override
    public String toString() {
        return title + ", renewed " + renewals + " times";
    }
}

public class Refs {
    static void renew(Book b) {
        b.renewals = b.renewals + 1;
    }

    static void replace(Book b) {
        b = new Book("Iracema");
        b.renewals = 99;
    }

    public static void main(String[] args) {
        Book mine = new Book("Dom Casmurro");
        renew(mine);
        System.out.println("after renew:   " + mine);
        replace(mine);
        System.out.println("after replace: " + mine);
    }
}
```

```
ana@vm:~/byvalue/refs$ javac Refs.java && java Refs
after renew:   Dom Casmurro, renewed 1 times
after replace: Dom Casmurro, renewed 1 times
```

**O `renew` alcançou o livro de `mine`. O `replace` não**: depois dele, `mine` continua sendo *Dom
Casmurro*, renovado uma vez, e o *Iracema* com 99 renovações não está em lugar nenhum. Os dois
resultados vêm da mesma regra, assim que as setas são desenhadas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas chamadas, desenhadas como frames e o heap. Durante renew(mine): o frame do main guarda a variável mine, o frame do renew guarda o parâmetro b, e os dois guardam uma cópia da mesma referência, então as duas setas apontam para um único objeto Book, Dom Casmurro, cujas renovações viram 1. Durante replace(mine): b começa como cópia da mesma referência, e depois recebe um Book novo, Iracema com 99 renovações; só a seta de b se move, e mine continua apontando para Dom Casmurro.\"><defs><marker id=\"jv30-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"jv30-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"340\" height=\"226\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">durante renew(mine)</text><text x=\"80\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">frames</text><text x=\"260\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o heap</text><text x=\"80\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">main</text><rect x=\"40\" y=\"94\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mine</text><text x=\"80\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">renew</text><rect x=\"40\" y=\"176\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><rect x=\"190\" y=\"74\" width=\"145\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"262\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Dom Casmurro, 1</text><path d=\"M120 106 H188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-a)\"></path><path d=\"M120 188 H160 V118 H188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-a)\"></path><rect x=\"370\" y=\"10\" width=\"340\" height=\"226\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">durante replace(mine)</text><text x=\"440\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">frames</text><text x=\"620\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o heap</text><text x=\"440\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">main</text><rect x=\"400\" y=\"94\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mine</text><text x=\"440\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">replace</text><rect x=\"400\" y=\"176\" width=\"80\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><rect x=\"550\" y=\"74\" width=\"145\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"622\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Dom Casmurro, 1</text><path d=\"M480 106 H548\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-a)\"></path><rect x=\"550\" y=\"160\" width=\"145\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book</text><text x=\"622\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Iracema, 99</text><path d=\"M480 188 H548\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv30-b)\"></path><rect x=\"10\" y=\"248\" width=\"340\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">duas cópias de uma referência, um objeto</text><rect x=\"370\" y=\"248\" width=\"340\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">b se moveu; mine, nunca</text></svg>", "same": ["frames"], "caption": "Um parâmetro é uma cópia da variável de quem chamou. Quando a variável guarda uma referência, a cópia aponta para o mesmo objeto, então as mudanças no objeto são compartilhadas. Reatribuir a cópia move uma seta, a dela."}
```

**Durante o `renew`, há duas setas e um objeto.** O `mine` guarda uma referência, e chamar
`renew(mine)` copiou essa referência para o `b`, exatamente como a seção 02 copiou 1 para o `a`. Duas
cópias de uma seta apontam para o mesmo `Book`, então `b.renewals = b.renewals + 1` mudou o único
objeto que as duas setas alcançam, e o `main` vê a mudança quando segue a própria seta.

**Durante o `replace`, o `b` começa como cópia da mesma seta e depois é apontado para outro lugar.**
O `b = new Book("Iracema")` muda o que a variável do próprio `replace` guarda, que é um slot dele no
frame dele, e o `mine` do `main` é outra variável, que ninguém tocou. O livro novo é construído,
ganha 99 renovações, e vira lixo quando o `replace` retorna, já que nada mais aponta para ele (lição
19).

O bytecode diz a mesma coisa com as palavras dele:

```
ana@vm:~/byvalue/refs$ javap -c Refs | grep -A 7 "void replace"
  static void replace(Book);
    Code:
         0: new           #8                  // class Book
         3: dup
         4: ldc           #13                 // String Iracema
         6: invokespecial #15                 // Method Book."<init>":(Ljava/lang/String;)V
         9: astore_0
        10: aload_0
```

`new`, `dup`, `ldc` e `invokespecial` constroem o `Book` novo. Depois **o `astore_0` guarda a
referência no slot 0, que é o parâmetro `b`**: um armazenamento comum no frame do próprio `replace`,
do mesmo tipo do `istore_0` da seção 02. Uma referência é um valor do jeito que um `int` é um valor,
e viaja do mesmo jeito.

## A frase para guardar

**O Java passa tudo por valor. Para um objeto, o valor é uma referência.** Então um método consegue
mudar o objeto que você lhe deu, porque tem uma seta para ele, e nunca consegue mudar para qual objeto
a sua variável aponta, porque tem só uma cópia da sua seta. Às vezes chamam isso de "passagem do
valor da referência" ou "passagem por compartilhamento", e são nomes para a mesma frase.

Dois testes separam os dois modelos, e a seção 04 roda os dois. Se o Java passasse objetos por
referência, o `replace` acima teria mudado o `mine`, e um método conseguiria trocar dois objetos de
lugar para quem o chamou. Nenhuma das duas coisas acontece.
