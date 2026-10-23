---
title: Um array por dentro, trocado quando enche
version: 1
---

"Uma lista que cresce" soa como se o `ArrayList` fosse um tipo novo de estrutura. **Ele é um array
comum, guardado num campo privado, mais uma contagem de quantos espaços dele estão em uso.** Quando o
array enche, o próximo `add` cria um array maior, copia todos os elementos para ele e joga o antigo
fora. O **tamanho** é quantos elementos a lista guarda; a **capacidade** é o comprimento do array
interno.

O campo é privado, e o programa abaixo o lê mesmo assim, por reflexão, a parte do Java que deixa um
programa inspecionar classes enquanto roda. A lição 39 usa reflexão de propósito; aqui ela é um jeito
de olhar por dentro, e o JDK não facilita. Em `~/lists/growth`:

```java
// Growth.java
import java.lang.reflect.Field;
import java.util.ArrayList;

public class Growth {
    public static void main(String[] args) throws Exception {
        Field data = ArrayList.class.getDeclaredField("elementData");
        data.setAccessible(true);

        ArrayList<Integer> list = new ArrayList<>();
        int capacity = -1;
        for (int i = 0; i < 100; i++) {
            list.add(i);
            int now = ((Object[]) data.get(list)).length;
            if (now != capacity) {
                System.out.println("size " + list.size() + ": capacity " + now);
                capacity = now;
            }
        }
    }
}
```

```
ana@vm:~/lists/growth$ javac Growth.java && java Growth
Exception in thread "main" java.lang.reflect.InaccessibleObjectException: Unable to make field transient java.lang.Object[] java.util.ArrayList.elementData accessible: module java.base does not "opens java.util" to unnamed module @2b2fa4f7
	at java.base/java.lang.reflect.AccessibleObject.throwInaccessibleObjectException(AccessibleObject.java:353)
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:329)
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:277)
	at java.base/java.lang.reflect.Field.checkCanSetAccessible(Field.java:179)
	at java.base/java.lang.reflect.Field.setAccessible(Field.java:173)
	at Growth.main(Growth.java:8)
```

**Recusado.** O `java.util` pertence ao módulo `java.base`, e desde o Java 16 o JDK não deixa código de
fora alcançar os campos privados dele. A lição 40 explica módulos e esta mensagem. O número depois do
`@` identifica o módulo sem nome nesta execução e muda de uma execução para outra. Para olhar os
detalhes internos numa lição, a JVM aceita uma opção que abre o pacote para o programa, e é uma opção
para exatamente isso e nada que você entregaria:

```
ana@vm:~/lists/growth$ java --add-opens java.base/java.util=ALL-UNNAMED Growth
size 1: capacity 10
size 11: capacity 15
size 16: capacity 22
size 23: capacity 33
size 34: capacity 49
size 50: capacity 73
size 74: capacity 109
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Tamanho contra capacidade de um ArrayList que cresce de 0 a 100 elementos. O tamanho sobe um a cada add. A capacidade, o comprimento do array interno, salta em degraus: 10 no primeiro add, depois 15, 22, 33, 49, 73 e 109, cada um cerca de uma vez e meia o anterior, nos tamanhos 11, 16, 23, 34, 50 e 74.\"><path d=\"M80 250 H680 M80 250 V30\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"230\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><text x=\"380\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"530\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">75</text><text x=\"680\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"72\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M80 150 H680\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M80 50 H680\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"380\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">elementos acrescentados (tamanho)</text><text x=\"80\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">comprimento do array interno</text><path d=\"M80 250 L680 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\"></path><path d=\"M80 250 V230 H146 V220 H176 V206 H218 V184 H284 V152 H380 V104 H524 V32 H680\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"82\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><text x=\"142\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15</text><text x=\"172\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">22</text><text x=\"214\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33</text><text x=\"280\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">49</text><text x=\"376\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">73</text><text x=\"520\" y=\"23\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">109</text><path d=\"M560 200 H588\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></path><text x=\"596\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">capacidade</text><path d=\"M560 220 H588\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></path><text x=\"596\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tamanho</text></svg>", "caption": "Cada degrau é um array novo, meia vez maior que o antigo, e uma cópia de todos os elementos. Entre os degraus, um add só escreve num espaço que já existe."}
```

Há três fatos nessas sete linhas.

**Um `ArrayList` novo não tem um array que mereça o nome.** O primeiro `add` lhe dá 10 espaços, que é
a capacidade padrão. Criar uma lista não custa quase nada até alguma coisa entrar nela.

**Cada array novo tem cerca de uma vez e meia o anterior**: 10, 15, 22, 33, 49, 73, 109. O comprimento
novo é o antigo mais a metade dele, arredondado para baixo, então 15 + 7 = 22 e 49 + 24 = 73.
Acrescentar cem elementos trocou o array seis vezes depois da primeira, e as cópias somaram 202
elementos (10 + 15 + 22 + 33 + 49 + 73), umas duas para cada elemento acrescentado.

**A maioria dos adds não copia nada.** Entre dois degraus, o `add` escreve num espaço que já existe e
aumenta o tamanho. A cópia ocasional se dilui entre todos os adds baratos entre ela e a próxima, então
acrescentar no fim continua rápido, na média, por maior que a lista fique. Se você sabe de antemão que
uma lista vai guardar um milhão de elementos, `new ArrayList<>(1_000_000)` ou
`ensureCapacity(1_000_000)` dimensiona o array uma vez e pula todos os degraus.

## Acrescentar na frente move tudo

Acrescentar no **fim** escreve um espaço. Acrescentar no índice 0 precisa abrir espaço antes: cada
elemento anda uma posição, e numa lista longa isso é uma caminhada longa. Os mesmos 100.000 números,
acrescentados dos dois jeitos:

```java
// Shifting.java
import java.util.ArrayList;
import java.util.List;

public class Shifting {
    static long millis(boolean atFront) {
        List<Integer> list = new ArrayList<>();
        long start = System.nanoTime();
        for (int i = 0; i < 100_000; i++) {
            if (atFront) {
                list.add(0, i);
            } else {
                list.add(i);
            }
        }
        return (System.nanoTime() - start) / 1_000_000;
    }

    public static void main(String[] args) {
        System.out.println("at the end:   " + millis(false) + " ms");
        System.out.println("at the front: " + millis(true) + " ms");
    }
}
```

```
ana@vm:~/lists/growth$ javac Shifting.java && java Shifting
at the end:   26 ms
at the front: 492 ms
```

**Cerca de dezenove vezes mais lento na frente, nesta execução.** Os dois números mudam a cada
execução e a cada máquina, e a distância entre eles cresce com o tamanho da lista, porque cada
inserção na frente move todos os elementos que já estão lá. O `remove(0)` tem o mesmo custo pelo mesmo
motivo. Quando um programa precisa acrescentar e remover na frente com frequência, outra estrutura
cabe melhor, e o `ArrayDeque` da lição 33 é ela.
