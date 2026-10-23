---
title: Mudar uma coleção enquanto se percorre
version: 1
---

A biblioteca quer tirar da lista os empréstimos atrasados, e o primeiro laço que qualquer um escreve
percorre a lista e remove o que combina. **Parece certo, compila, e falha**:

```java
// Overdue.java
import java.util.ArrayList;
import java.util.List;

public class Overdue {
    public static void main(String[] args) {
        List<String> loans = new ArrayList<>(List.of("Dune", "Emma:late", "Ulysses", "Beloved"));
        for (String loan : loans) {
            if (loan.endsWith(":late")) {
                loans.remove(loan);
            }
        }
        System.out.println(loans);
    }
}
```

```
ana@vm:~/iter$ java Overdue.java
Exception in thread "main" java.util.ConcurrentModificationException
	at java.base/java.util.ArrayList$Itr.checkForComodification(ArrayList.java:1096)
	at java.base/java.util.ArrayList$Itr.next(ArrayList.java:1050)
	at Overdue.main(Overdue.java:8)
```

A exceção foi lançada por `ArrayList$Itr.next`, o iterador que a seção 02 apresentou, a partir de
um método chamado `checkForComodification`. **A lista foi alterada enquanto um iterador a percorria**,
por algo que não era esse iterador. O `loans.remove(loan)` removeu `Emma:late` pelas costas do
iterador, e a chamada seguinte a `next()` percebeu.

Percebeu porque um `ArrayList` conta as suas mudanças estruturais, as que acrescentam ou removem
elementos, num campo chamado `modCount`. Um iterador copia esse número quando é criado e o compara a
cada `next()`. Uma diferença quer dizer que a lista que ele percorre não é mais a lista com que
começou, e **o iterador se recusa a adivinhar**: lança `ConcurrentModificationException` na primeira
chamada depois da mudança. O nome diz "concorrente", mas não há segunda thread nenhuma. Uma thread,
um laço, dois jeitos de mudar a lista ao mesmo tempo.

## O mesmo erro, sem a exceção

Leve os empréstimos atrasados para o fim da lista e o programa se comporta de outro jeito:

```java
// Quiet.java
import java.util.ArrayList;
import java.util.List;

public class Quiet {
    public static void main(String[] args) {
        List<String> loans = new ArrayList<>(List.of("Dune", "Emma", "Ulysses:late", "Beloved:late"));
        for (String loan : loans) {
            System.out.println("checking " + loan);
            if (loan.endsWith(":late")) {
                loans.remove(loan);
            }
        }
        System.out.println(loans);
    }
}
```

```
ana@vm:~/iter$ java Quiet.java
checking Dune
checking Emma
checking Ulysses:late
[Dune, Emma, Beloved:late]
```

Nenhuma exceção, uma lista impressa, e uma resposta errada. **O `Beloved:late` nunca foi
conferido**: o laço imprimiu `checking` três vezes para quatro empréstimos e parou. A figura mostra
por quê:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Por que o Quiet.java nunca conferiu o Beloved. Antes do remove, a lista guarda Dune, Emma, Ulysses:late e Beloved:late nos índices 0 a 3, tamanho 4, e o cursor do iterador está em 3, logo depois de Ulysses:late, que ele já devolveu. O laço remove Ulysses:late: Beloved:late desce para o índice 2 e o tamanho vira 3. O laço então pergunta hasNext, que compara o cursor, 3, com o tamanho, 3, os acha iguais e responde false. O laço acaba, e Beloved:late nunca foi devolvido nem conferido.\"><defs><marker id=\"jv34-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · o next() devolveu Ulysses:late</text><rect x=\"200\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"253\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><text x=\"253\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"310\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><text x=\"363\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"420\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"473\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ulysses:late</text><text x=\"473\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"530\" y=\"44\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"583\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Beloved:late</text><text x=\"583\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M530 116 V80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv34-a)\"></path><text x=\"538\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cursor = 3</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">size = 4</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · depois de loans.remove(Ulysses:late)</text><rect x=\"200\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"253\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Dune</text><text x=\"253\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"310\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Emma</text><text x=\"363\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"420\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"473\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Beloved:late</text><text x=\"473\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"530\" y=\"154\" width=\"106\" height=\"32\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"583\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M530 226 V190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv34-a)\"></path><text x=\"538\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cursor = 3</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">size = 3</text><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">hasNext() pergunta cursor != size: 3 != 3 é false, o laço acaba e Beloved:late nunca é conferido</text></svg>", "caption": "O iterador lembra uma posição, não um elemento. Remover atrás dele trouxe o último elemento para baixo da posição por onde ele já tinha passado."}
```

O `hasNext()` de um iterador de `ArrayList` compara o cursor com o tamanho da lista, e não confere o
`modCount`; só o `next()` confere. Remover `Ulysses:late` deixou o tamanho em 3 com o cursor parado
em 3, então o `hasNext()` disse que não havia mais nada e o `next()` nunca mais foi chamado. **É por
isso que a documentação diz que a verificação falha rápido "na base do melhor esforço"**: ela pega a
mudança quando consegue, e um programa não pode contar com a exceção para achar o seu defeito.

Então a regra não é "evitar a exceção". É **nunca mudar a estrutura de uma coleção enquanto um
`for-each` a percorre**, lance-se algo ou não. Substituir um elemento com `set(i, x)` não é mudança
estrutural, e o `modCount` não se mexe por ela. Acrescentar ou remover é, e a seção 04 tem quatro
jeitos seguros de fazer isso.
