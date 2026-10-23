---
title: Wrappers, boxing, e os dois jeitos em que isso morde
version: 1
---

Cada primitivo tem uma **classe wrapper** (empacotadora): `Integer` para `int`, `Long` para `long`,
`Double` para `double`, `Character` para `char`, `Boolean` para `boolean`, e assim por diante. Um
wrapper é um objeto que guarda um valor primitivo. Os wrappers existem porque boa parte do Java só
trabalha com objetos: as coleções das lições 31 a 35 guardam objetos e nunca primitivos, então uma
lista de números é uma lista de `Integer`.

**O Java converte entre os dois sozinho.** Pôr um `int` onde se espera um `Integer` é **boxing**
(empacotar), e tirar o `int` de volta é **unboxing** (desempacotar). O compilador escreve as duas
conversões para você, o que é cômodo, e esconde duas armadilhas que todo programador Java encontra
uma vez.

## `==` entre dois `Integer`

```java
// Boxing.java
public class Boxing {
    public static void main(String[] args) {
        Integer a = 127;
        Integer b = 127;
        System.out.println(a == b);
        Integer c = 128;
        Integer d = 128;
        System.out.println(c == d);
        System.out.println(c.equals(d));
        int sum = c + d;
        System.out.println(sum);
    }
}
```

```
ana@vm:~/types$ java Boxing.java
true
false
true
256
```

`127 == 127` deu `true` e `128 == 128` deu `false`. **Em objetos, `==` pergunta se duas referências
apontam para o mesmo objeto, não se os valores são iguais.** O `Integer` mantém um pequeno cache de
objetos prontos para os valores de -128 a 127, e o boxing de um valor nessa faixa entrega o objeto do
cache, então `a` e `b` são o mesmo objeto. 128 fica fora do cache, então `c` e `d` são dois objetos
diferentes guardando o mesmo número, e o `==` diz isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Boxing de 127 duas vezes: as variáveis a e b apontam para um único objeto Integer com 127, tirado do cache, então a == b é true. Boxing de 128 duas vezes: c e d apontam para dois objetos Integer separados que guardam 128, então c == d é false enquanto c.equals(d) é true.\"><defs><marker id=\"jv4-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">valores de -128 a 127</text><rect x=\"40\" y=\"60\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a</text><rect x=\"40\" y=\"120\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b</text><rect x=\"200\" y=\"78\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Integer 127</text><text x=\"265\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">do cache</text><path d=\"M100 75 L198 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><path d=\"M100 135 L198 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a == b é true: um objeto</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">valores fora do cache</text><rect x=\"400\" y=\"60\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text><rect x=\"560\" y=\"54\" width=\"130\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Integer 128</text><path d=\"M460 75 L558 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><rect x=\"400\" y=\"120\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d</text><rect x=\"560\" y=\"114\" width=\"130\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Integer 128</text><path d=\"M460 135 L558 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv4-a)\"></path><text x=\"540\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">c == d é false: dois objetos</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c.equals(d) é true: mesmo valor</text><path d=\"M360 16 V214\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\" fill=\"none\"></path></svg>", "caption": "O == entre objetos compara setas, não conteúdos. Dentro do cache, dois boxings do mesmo valor dividem um objeto; fora dele, cada boxing cria um novo."}
```

`c.equals(d)` compara os valores e disse `true`, e esse é o método a usar. `c + d` imprimiu 256
porque a aritmética desempacota os dois lados primeiro. A regra a guardar é a que a lição 7 repete
para strings: **compare objetos com `equals`, e deixe o `==` para primitivos**. O cache faz a escolha
errada passar em todo teste que usa números pequenos, e é por isso que ela é perigosa, e não só
errada.

## Desempacotando `null`

Um wrapper é um objeto, então uma variável wrapper pode guardar `null`, que quer dizer objeto nenhum.
Um primitivo não pode. Desempacote um `null` e não há de onde tirar o valor:

```java
// Missing.java
public class Missing {
    public static void main(String[] args) {
        Integer copiesLeft = null;
        int copies = copiesLeft;
        System.out.println(copies);
    }
}
```

```
ana@vm:~/types$ java Missing.java; echo $?
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.lang.Integer.intValue()" because "<local1>" is null
	at Missing.main(Missing.java:5)
1
ana@vm:~/types$ javac -g Missing.java && java Missing
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.lang.Integer.intValue()" because "copiesLeft" is null
	at Missing.main(Missing.java:5)
```

**Um `NullPointerException`, numa linha sem chamada de método à vista.** A mensagem nomeia a chamada
mesmo assim: para transformar `copiesLeft` num `int`, o compilador escreveu uma chamada a
`intValue()`, e chamar um método em `null` é exatamente o que essa exceção relata. A primeira
execução, a partir do fonte, chamou a variável de `<local1>`, a primeira variável local do `main`.
Compilada com `javac -g`, que mantém os nomes das variáveis locais no arquivo de classe, a segunda
execução a chamou de `copiesLeft`.

Então, onde um valor pode faltar, um wrapper consegue dizer isso com `null`, e cada lugar que o
desempacota é um lugar onde ele pode falhar. Onde um valor está sempre lá, um primitivo não pode ser
`null` de jeito nenhum. **Use o primitivo, a não ser que precise do objeto**, e a lição 30 volta ao
que uma variável que guarda um objeto guarda de fato.
