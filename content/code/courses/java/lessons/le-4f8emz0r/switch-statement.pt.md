---
title: O `switch` clássico, e a queda entre os casos
version: 1
---

Uma cadeia de `if` que compara um valor com uma lista de constantes fica ruim de ler no quarto
`else if`. **O `switch` pega o valor uma vez e salta direto para o `case` que combina.** A forma desta
seção é a que o Java tem desde 1996, e você vai lê-la em todo código mais antigo. A seção 04 mostra a
forma escrita desde o Java 14, que remove a armadilha desta:

```java
// Shelf.java
public class Shelf {
    public static void main(String[] args) {
        String genre = "poetry";
        switch (genre) {
            case "novel":
                System.out.println("shelf A");
                break;
            case "poetry":
                System.out.println("shelf B");
            case "history":
                System.out.println("shelf C");
                break;
            default:
                System.out.println("returns desk");
        }

        int day = 6;
        switch (day) {
            case 6:
            case 7:
                System.out.println("weekend: closed");
                break;
            default:
                System.out.println("open");
        }

        String missing = null;
        switch (missing) {
            case "novel":
                System.out.println("shelf A");
                break;
            default:
                System.out.println("returns desk");
        }
    }
}
```

```
ana@vm:~/cond$ java Shelf.java
shelf B
shelf C
weekend: closed
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.hashCode()" because "<local4>" is null
	at Shelf.main(Shelf.java:29)
```

## Um `case` é um rótulo, não uma caixa

O gênero era `"poetry"`, e o programa imprimiu **duas** prateleiras. Essa é a armadilha, e é assim
que o `switch` clássico foi projetado, não um bug deste aqui. Um `case` é um lugar para onde saltar.
Chegando lá, o código roda para baixo, passando por quaisquer outros rótulos `case` no caminho, até um
`break` ou o fim do `switch`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Como um switch clássico roda para genre igual a poetry. O controle salta para o rótulo case \"poetry\" e imprime shelf B. Não há break, então ele segue passando pelo rótulo case \"history\", imprime shelf C, e só para no break depois dele, saindo do switch.\"><defs><marker id=\"jv10-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"60\" y=\"20\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">switch (genre)</text><rect x=\"80\" y=\"50\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">case \"novel\":</text><rect x=\"104\" y=\"80\" width=\"186\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf A; break;</text><rect x=\"80\" y=\"110\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case \"poetry\":</text><rect x=\"104\" y=\"140\" width=\"186\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf B</text><rect x=\"80\" y=\"170\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case \"history\":</text><rect x=\"104\" y=\"200\" width=\"186\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf C; break;</text><rect x=\"80\" y=\"230\" width=\"210\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">default: returns desk</text><path d=\"M40 32 V122 H78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv10-a)\"></path><text x=\"30\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\"></text><path d=\"M312 130 V204\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv10-a)\"></path><path d=\"M300 212 H350 V262\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv10-a)\"></path><text x=\"380\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. salta para o rótulo que combina</text><text x=\"380\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">genre é \"poetry\"</text><text x=\"380\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2. desce passando pelo rótulo seguinte</text><text x=\"380\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem break depois de shelf B: o case \"history\" não é parede</text><text x=\"380\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3. para no primeiro break</text><text x=\"380\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e sai do switch</text></svg>", "caption": "Um rótulo é um lugar para onde saltar, não um limite. Só o break, ou o fim do switch, para a execução."}
```

O bloco do `case "poetry"` não tem `break`, então ele caiu no `case "history"` e imprimiu `shelf C`
também. **Todo `case` que deve parar precisa do seu próprio `break`**, e esquecer um compila sem uma
palavra.

Às vezes a queda é o que você quer, e o segundo `switch` a usa de propósito: o `case 6:` não tem
instrução nenhuma, então o dia 6 e o dia 7 compartilham um bloco e um `break`. As duas formas são
válidas, e é exatamente por isso que um `break` esquecido não pode ser pego pelo compilador: ele não
tem como saber o que você quis.

## O que um `switch` clássico aceita

O valor pode ser um `int` ou um tipo inteiro menor, um `char`, uma `String`, ou um `enum`, que a
lição 28 apresenta. Cada `case` precisa ser uma constante que o compilador consiga ver. E o valor não
pode ser `null`:

```
ana@vm:~/cond$ javac -g Shelf.java && java Shelf 2>&1 | tail -2
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.hashCode()" because "<local4>" is null
	at Shelf.main(Shelf.java:29)
```

O terceiro `switch` recebeu `null` e lançou `NullPointerException`, na linha 29. **Um `switch`
clássico numa `String` chama `hashCode()` nela antes**, e foi isso que falhou. A mensagem fala em
`"<local4>"` mesmo depois do `javac -g`, porque a variável a que ela se refere não é `missing`, e sim
uma cópia escondida que o compilador fez para executar o `switch`, que não tem nome para guardar. A
seção 04 mostra a forma mais nova, que aceita `null` como um `case` próprio.
