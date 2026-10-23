---
title: Dois defaults, uma classe
version: 1
---

Os métodos default trouxeram de volta o problema que manteve a herança múltipla de classes fora do
Java: **dois pais dando ao mesmo método dois corpos diferentes**. Uma classe que implementa duas
interfaces com o mesmo default herda os dois, e uma chamada não consegue executar dois métodos. A
resposta do Java é se recusar a adivinhar.

## O conflito

Em `~/iface/diamond`, duas interfaces que dão cada uma um rótulo ao que descrevem:

```java
// Printed.java
public interface Printed {
    default String label() {
        return "printed matter";
    }
}
```

```java
// Recorded.java
public interface Recorded {
    default String label() {
        return "a recording";
    }
}
```

Um audiolivro é as duas coisas, então assina as duas e não escreve mais nada:

```java
// Audiobook.java
public class Audiobook implements Printed, Recorded {
}
```

```
ana@vm:~/iface/diamond$ javac Printed.java Recorded.java Audiobook.java
Audiobook.java:2: error: types Printed and Recorded are incompatible;
public class Audiobook implements Printed, Recorded {
       ^
  class Audiobook inherits unrelated defaults for label() from types Printed and Recorded
1 error
```

**O erro nomeia o método e as duas interfaces**, e é um erro de compilação, não uma regra sobre
qual vence. Nenhuma ordem no `implements` decide, nenhuma convenção de "a primeira da lista"; a
classe tem de dizer.

## Escolhendo, numa linha

```java
// Audiobook.java
public class Audiobook implements Printed, Recorded {
    @Override
    public String label() {
        return Recorded.super.label() + " of " + Printed.super.label();
    }
}
```

`Recorded.super.label()` quer dizer "o default de `Recorded`", e o mesmo com `Printed`. Uma classe
pode chamar um, os dois ou nenhum; aqui ela combina os dois. A forma `.super` só funciona para uma
interface que a classe nomeia diretamente no seu `implements`.

## Uma classe vence uma interface

Mais um caso, e este não precisa de código seu para se resolver. Quando um método vem de uma
**superclasse** e um default com a mesma assinatura vem de uma interface, vence o método da classe:

```java
// Catalogue.java
public class Catalogue {
    public String label() {
        return "a catalogue entry";
    }
}
```

```java
// Leaflet.java
public class Leaflet extends Catalogue implements Printed {
}
```

```java
// Labels.java
public class Labels {
    public static void main(String[] args) {
        System.out.println(new Audiobook().label());
        System.out.println(new Leaflet().label());
    }
}
```

```
ana@vm:~/iface/diamond$ javac *.java && java Labels
a recording of printed matter
a catalogue entry
```

O `Leaflet` imprimiu `a catalogue entry`, de `Catalogue`, e o default de `Printed` nunca rodou. A
regra existe para que acrescentar um default a uma interface antiga não consiga mudar o que uma
classe existente faz: uma classe que já tinha o método continua com ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas interfaces, Printed e Recorded, dão cada uma um método label padrão. Audiobook implementa as duas e herda dois padrões sem relação, então o compilador recusa até Audiobook escrever o seu próprio label, que pode chamar Recorded.super.label() e Printed.super.label(). Leaflet estende a classe Catalogue e implementa Printed; o método da classe vence o padrão da interface.\"><defs><marker id=\"jv23-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"190\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Printed</text><text x=\"115\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">label(): \"printed matter\"</text><rect x=\"240\" y=\"20\" width=\"190\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Recorded</text><text x=\"335\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">label(): \"a recording\"</text><text x=\"225\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um padrão cada</text><path d=\"M115 82 L215 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv23-a)\"></path><path d=\"M335 82 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv23-a)\"></path><rect x=\"110\" y=\"162\" width=\"230\" height=\"108\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"225\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Audiobook</text><text x=\"225\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">herda dois padrões sem relação</text><rect x=\"126\" y=\"218\" width=\"198\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"225\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o seu label() escolhe</text><text x=\"225\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Recorded.super.label()</text><rect x=\"470\" y=\"20\" width=\"110\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Catalogue</text><text x=\"525\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma classe</text><rect x=\"600\" y=\"20\" width=\"110\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Printed</text><text x=\"655\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um padrão</text><path d=\"M525 82 L575 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv23-a)\"></path><path d=\"M655 82 L620 198\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\" fill=\"none\"></path><rect x=\"490\" y=\"200\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Leaflet</text><text x=\"595\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">\"a catalogue entry\"</text><text x=\"595\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a classe vence</text></svg>", "caption": "À esquerda, o diamante: dois padrões se encontram e a classe precisa decidir. À direita, o método de uma superclasse contra o padrão de uma interface: a classe vence sem uma palavra."}
```

**O diamante é raro na prática e barato quando acontece**: o compilador encontra todos os casos, e a
correção é um método. O que ele ensina é o formato geral da herança em Java. Comportamento pode
chegar de várias interfaces; estado chega de uma classe; e onde quer que duas respostas disputem sem
regra para decidir, a linguagem obriga você a escrever a resposta.
