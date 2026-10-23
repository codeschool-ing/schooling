---
title: Uma família, dois ramos
version: 1
---

A lição 36 traçou uma linha entre exceções verificadas e não verificadas e deixou uma pergunta em
aberto: **de onde vem essa linha?** Não é uma marca em cada classe. Vem dos ancestrais da classe. Toda
exceção e todo erro em Java é subclasse de uma classe só, `java.lang.Throwable`, e o ramo dessa árvore
genealógica em que a classe está decide o que o compilador lhe pede.

Um programa consegue percorrer a árvore sozinho. O `getSuperclass()` devolve a classe que uma classe
estende, e segui-lo até ele devolver `null` dá a linha inteira de ancestrais:

```java
// Ancestry.java
import java.util.List;

public class Ancestry {
    public static void main(String[] args) {
        List<Class<?>> types = List.of(
                java.nio.file.NoSuchFileException.class,
                NumberFormatException.class,
                StackOverflowError.class);
        for (Class<?> type : types) {
            StringBuilder line = new StringBuilder(type.getSimpleName());
            for (Class<?> up = type.getSuperclass(); up != null; up = up.getSuperclass()) {
                line.append(" -> ").append(up.getSimpleName());
            }
            System.out.println(line);
        }
    }
}
```

```
ana@vm:~/hierarchy$ javac Ancestry.java Deep.java && java Ancestry
NoSuchFileException -> FileSystemException -> IOException -> Exception -> Throwable -> Object
NumberFormatException -> IllegalArgumentException -> RuntimeException -> Exception -> Throwable -> Object
StackOverflowError -> VirtualMachineError -> Error -> Throwable -> Object
```

Três linhas, três ramos:

- **`NoSuchFileException` passa por `IOException`** no caminho até `Exception`. Isso a torna
  verificada: um método que pode lançá-la tem de dizer isso, como o `throws IOException` fez na
  lição 37.
- **`NumberFormatException` passa por `RuntimeException`**, e tudo o que está abaixo de
  `RuntimeException` é não verificado. O `Integer.parseInt` a lança, e ninguém é obrigado a capturá-la.
- **`StackOverflowError` nunca encontra `Exception`.** Ele descende de `Error`, o outro ramo abaixo
  de `Throwable`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A hierarquia de Throwable. Throwable tem dois ramos. Error, com VirtualMachineError e abaixo dele StackOverflowError e OutOfMemoryError, é não verificado. Exception tem IOException, com NoSuchFileException embaixo, que são verificadas, e RuntimeException, com IllegalArgumentException e NumberFormatException embaixo, que são não verificadas.\"><rect x=\"300\" y=\"16\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Throwable</text><rect x=\"40\" y=\"86\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Error</text><rect x=\"440\" y=\"86\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Exception</text><path d=\"M360 46 V66 H140 V86 M360 66 H540 V86\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"40\" y=\"146\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VirtualMachineError</text><path d=\"M140 116 V146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"16\" y=\"206\" width=\"128\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">StackOverflowError</text><rect x=\"150\" y=\"206\" width=\"112\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OutOfMemoryError</text><path d=\"M140 176 V191 H80 V206 M140 191 H206 V206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"376\" y=\"146\" width=\"148\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IOException</text><rect x=\"540\" y=\"146\" width=\"164\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RuntimeException</text><path d=\"M540 116 V131 H450 V146 M540 131 H622 V146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"370\" y=\"206\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NoSuchFileException</text><path d=\"M450 176 V206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"536\" y=\"206\" width=\"172\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IllegalArgumentException</text><path d=\"M622 176 V206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"546\" y=\"256\" width=\"152\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NumberFormatException</text><path d=\"M622 236 V256\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"262\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não verificada: o compilador não pergunta nada</text><rect x=\"20\" y=\"286\" width=\"14\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">verificada: capture ou declare</text></svg>", "caption": "Toda exceção e todo erro são um Throwable. O que o compilador confere é decidido pelo ramo: RuntimeException e Error, e tudo abaixo deles, ficam de fora."}
```

## `Error` é da JVM, não seu

Um `Error` relata um problema com a máquina em que o programa roda, e não com os dados do programa: a
thread ficou sem pilha, o heap ficou sem memória, um arquivo de classe que existia na compilação falta
na execução. **A reação normal a um `Error` é deixar o programa terminar**, porque a JVM pode já não
estar num estado em que o seu código de recuperação rode direito.

Uma primeira consequência surpreende muita gente. `catch (Exception e)` parece capturar tudo, e não
captura um `Error`:

```java
// Deep.java
public class Deep {
    static int depth = 0;

    static void down() {
        depth++;
        down();
    }

    public static void main(String[] args) {
        try {
            down();
        } catch (Exception e) {
            System.out.println("caught an Exception at depth " + depth);
        }
        System.out.println("after the try");
    }
}
```

```
ana@vm:~/hierarchy$ java Deep 2>&1 | head -4
Exception in thread "main" java.lang.StackOverflowError
	at Deep.down(Deep.java:7)
	at Deep.down(Deep.java:7)
	at Deep.down(Deep.java:7)
ana@vm:~/hierarchy$ java Deep > deep.txt 2>&1; echo "exit $?"; wc -l < deep.txt; grep -c "after the try" deep.txt
exit 1
1025
0
```

O `down` chama a si mesmo até a pilha da thread encher, e a JVM lança `StackOverflowError`. O
`catch (Exception e)` não casou com ele, então nem `caught an Exception` nem `after the try` chegaram a
ser impressos: o `grep -c` contou 0 do segundo em 1025 linhas de saída, e o status de saída foi 1. As
1025 linhas são a primeira linha mais 1024 frames, todos `Deep.down(Deep.java:7)`. **A JVM para de
imprimir um stack trace em 1024 frames**, então uma recursão muito funda nunca mostra o frame em que
começou.

Escrever `catch (Throwable t)` no lugar o capturaria. Um código que faz isso, registra uma linha e
segue como se nada tivesse acontecido está rodando numa JVM que acabou de dizer que está em apuros. As
exceções que você captura e trata são as que estão abaixo de `Exception`; as que estão abaixo de
`Error` são para a JVM relatar e para você ler.
