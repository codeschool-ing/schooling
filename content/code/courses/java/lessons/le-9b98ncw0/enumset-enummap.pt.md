---
title: EnumSet, EnumMap, e o número que nunca se guarda
version: 1
---

Coleções são as lições 31 a 33, e um `Set` ou um `Map` de gêneros funciona com qualquer uma delas.
**A biblioteca padrão também traz duas feitas só para enums, `EnumSet` e `EnumMap`**, que aproveitam
o fato de um enum ter um número fixo de constantes, cada uma com uma posição. Elas são menores e mais
rápidas que as gerais e mantêm a ordem do próprio enum, então, quando as chaves são um enum, elas são
a escolha padrão.

```java
// Shelving.java
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

public class Shelving {
    enum Genre {
        FICTION, HISTORY, SCIENCE, POETRY
    }

    public static void main(String[] args) {
        Set<Genre> groundFloor = EnumSet.of(Genre.POETRY, Genre.FICTION);
        System.out.println(groundFloor);
        System.out.println(EnumSet.complementOf(EnumSet.copyOf(groundFloor)));
        System.out.println(EnumSet.range(Genre.HISTORY, Genre.POETRY));

        Genre[] returned = {Genre.SCIENCE, Genre.FICTION, Genre.SCIENCE, Genre.POETRY};
        Map<Genre, Integer> counts = new EnumMap<>(Genre.class);
        for (Genre g : returned) {
            counts.put(g, counts.getOrDefault(g, 0) + 1);
        }
        System.out.println(counts);
    }
}
```

```
ana@vm:~/enums/sets$ javac Shelving.java && java Shelving
[FICTION, POETRY]
[HISTORY, SCIENCE]
[HISTORY, SCIENCE, POETRY]
{FICTION=1, SCIENCE=2, POETRY=1}
```

Quatro linhas, e cada uma mostra algo que um conjunto ou um mapa comum não mostraria:

- **`EnumSet.of(POETRY, FICTION)` imprimiu `[FICTION, POETRY]`**, na ordem que o enum declara, não na
  ordem em que foram acrescentadas. Por dentro, um `EnumSet` de até 64 constantes é um `long` com um
  bit por constante, e percorrer os bits segue a ordem dos ordinais.
- O `complementOf` é toda constante que **não** está num conjunto, o que só faz sentido quando o
  conjunto conhece todas as constantes que existem. O `range(HISTORY, POETRY)` são as constantes de
  uma até outra, inclusive.
- **O `EnumMap` também imprimiu as chaves na ordem do enum**, embora `SCIENCE` tenha sido contado
  primeiro. Por baixo ele é um array indexado pelo ordinal, e `new EnumMap<>(Genre.class)` passa a
  classe para ele saber o tamanho que o array precisa ter.

Para o resto do programa os dois são objetos `Set` e `Map` comuns, então um método que recebe um
`Set<Genre>` aceita um `EnumSet` sem saber.

## O ordinal é uma posição, nunca uma identidade

`EnumSet` e `EnumMap` usam ordinais por dentro, num único programa em execução, onde eles não têm
como mudar. **O seu próprio código nunca deve guardar um**: num arquivo, numa coluna de banco de
dados, numa mensagem para outro programa. O ordinal é onde uma constante por acaso está na lista, e a
lista é código-fonte que alguém vai editar.

O `Ordinals` mostra o que acontece. Ele traz o mesmo enum duas vezes, como era antes de alguém
acrescentar `BIOGRAPHY` no topo e como ficou depois, porque uma demonstração de verdade exigiria um
banco de dados e dois builds do programa. Ele guarda `SCIENCE` dos dois jeitos, e lê os dois de volta
pela versão nova:

```java
// Ordinals.java
public class Ordinals {
    enum GenreBefore {
        FICTION, HISTORY, SCIENCE, POETRY
    }

    enum GenreAfter {
        BIOGRAPHY, FICTION, HISTORY, SCIENCE, POETRY
    }

    public static void main(String[] args) {
        GenreBefore stored = GenreBefore.SCIENCE;
        int savedOrdinal = stored.ordinal();
        String savedName = stored.name();
        System.out.println("saved: " + savedOrdinal + " and " + savedName);

        System.out.println("by ordinal: " + GenreAfter.values()[savedOrdinal]);
        System.out.println("by name:    " + GenreAfter.valueOf(savedName));
    }
}
```

```
ana@vm:~/enums/sets$ javac Ordinals.java && java Ordinals
saved: 2 and SCIENCE
by ordinal: HISTORY
by name:    SCIENCE
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Por que um ordinal guardado dá errado. Antes da edição, o enum lista FICTION, HISTORY, SCIENCE e POETRY nas posições 0 a 3, e SCIENCE é guardado como 2. Depois que BIOGRAPHY entra no topo, cada constante anda uma posição, a posição 2 passa a ser HISTORY, e o 2 guardado volta como HISTORY. O nome guardado, SCIENCE, continua encontrando SCIENCE, agora na posição 3.\"><defs><marker id=\"jv28-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"jv28-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">antes da edição</text><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois da edição</text><rect x=\"256\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"308.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"308.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FICTION</text><rect x=\"372\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"424.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HISTORY</text><rect x=\"488\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"540.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SCIENCE</text><rect x=\"604\" y=\"40\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"656.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POETRY</text><rect x=\"140\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"192.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"192.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BIOGRAPHY</text><rect x=\"256\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"308.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"308.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FICTION</text><rect x=\"372\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"424.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HISTORY</text><rect x=\"488\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"540.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SCIENCE</text><rect x=\"604\" y=\"120\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"656.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POETRY</text><rect x=\"372\" y=\"204\" width=\"104\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">saved: 2</text><rect x=\"488\" y=\"204\" width=\"104\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">saved: SCIENCE</text><path d=\"M424.0 204 V168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv28-a)\"></path><path d=\"M540.0 204 V168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv28-b)\"></path></svg>", "caption": "O número 2 era uma posição, e todas as posições andaram quando uma constante entrou acima. O nome era a identidade da constante, e ele não andou."}
```

**O 2 guardado voltou como `HISTORY`.** Nenhuma exceção, nenhum aviso, e um gênero perfeitamente
válido: todo livro de ciência do banco agora está arquivado em história, e nada em lugar nenhum
falha. Acrescentar uma constante em qualquer lugar que não o fim desloca todas as que vêm depois, e o
mesmo vale para apagar uma ou ordenar a lista em ordem alfabética, o tipo de arrumação que alguém faz
numa tarde tranquila.

**O nome sobreviveu**, porque um nome é como a constante se chama, e não onde ela está. Guarde o
`name()` e leia de volta com `valueOf`, e a edição não faz mal. Renomear uma constante ainda quebra o
que foi guardado com o nome antigo. Para dados que vivem mais que o programa, a escolha mais forte é
um código próprio, escrito num campo: `SCIENCE("sci")`, com um método que encontra uma
constante pelo código.
