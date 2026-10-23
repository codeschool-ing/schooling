---
title: Formatando números e texto
version: 1
---

Colar valores com `+` não lhe dá voz nenhuma sobre a aparência: `12.5` sai como `12.5` quando uma
multa deveria ler `12.50`, e um milhão sai como `1234567`. **Uma string de formato descreve a linha
uma vez, com marcadores, e os valores a preenchem.** A do Java vem do `printf` do C, e aparece em
três grafias que aceitam os mesmos marcadores: `String.format(...)`, `"...".formatted(...)` e
`System.out.printf(...)`, que imprime em vez de devolver.

```java
// Format.java
import java.util.Locale;

public class Format {
    public static void main(String[] args) {
        String title = "Dom Casmurro";
        int copies = 3;
        double fine = 12.5;
        long readers = 1234567;

        System.out.println(String.format("%s: %d copies", title, copies));
        System.out.println("Fine: %.2f".formatted(fine));
        System.out.println("[%10s] [%-10s]".formatted("right", "left"));
        System.out.println("[%5d] [%05d]".formatted(42, 42));
        System.out.println("%,d readers".formatted(readers));
        System.out.printf("%s%n", "printf ends its own line with %n");

        Locale br = Locale.forLanguageTag("pt-BR");
        System.out.println(String.format(br, "%,.2f", 1234.5));
        System.out.println(String.format(Locale.ROOT, "%,.2f", 1234.5));
        System.out.println(String.format("%d copies", "three"));
    }
}
```

```
ana@vm:~/strings$ java Format.java; echo $?
Dom Casmurro: 3 copies
Fine: 12.50
[     right] [left      ]
[   42] [00042]
1,234,567 readers
printf ends its own line with %n
1.234,50
1,234.50
Exception in thread "main" java.util.IllegalFormatConversionException: d != java.lang.String
	at java.base/java.util.Formatter$FormatSpecifier.failConversion(Formatter.java:4662)
	at java.base/java.util.Formatter$FormatSpecifier.printInteger(Formatter.java:3200)
	at java.base/java.util.Formatter$FormatSpecifier.print(Formatter.java:3155)
	at java.base/java.util.Formatter.format(Formatter.java:2761)
	at java.base/java.util.Formatter.format(Formatter.java:2698)
	at java.base/java.lang.String.format(String.java:4455)
	at Format.main(Format.java:21)
1
```

Cada marcador começa com `%` e termina com uma letra que diz que tipo de valor vai ali. Entre os
dois vão as opções:

| marcador | valor | impresso | o que faz |
|---|---|---|---|
| `%s` | `"Dom Casmurro"` | `Dom Casmurro` | qualquer valor, como texto |
| `%d` | `3` | `3` | um número inteiro |
| `%.2f` | `12.5` | `12.50` | um decimal, com exatamente duas casas depois do ponto |
| `%10s`, `%-10s` | `"right"`, `"left"` | completado até 10 | uma largura; o `-` completa à direita |
| `%05d` | `42` | `00042` | uma largura preenchida com zeros |
| `%,d` | `1234567` | `1,234,567` | grupos de milhar |
| `%n` | nenhum | uma quebra de linha | o fim de linha do sistema em que roda |

A sexta linha mostra um detalhe que vale ter visto uma vez. O `%n` dentro do **formato** termina a
linha, mas o texto `"printf ends its own line with %n"` era um **argumento**, posto ali pelo `%s`, e
um argumento nunca é lido como formato. Saiu como estava escrito.

## O locale decide os separadores

`1.234,50` e `1,234.50` são o mesmo número escrito para dois públicos. No Brasil a vírgula marca os
decimais e o ponto agrupa os milhares, e em inglês é o contrário. **Passe um `Locale` como primeiro
argumento e o formato segue as regras daquele país**: `pt-BR` deu a forma brasileira. Sem ele, o
`String.format` usa o padrão da máquina, e aqui esse padrão é inglês, porque o laboratório roda com
`LANG=C.UTF-8`.

A regra é a que a seção 03 deu para a maiúscula. Texto que uma pessoa lê leva o locale de quem lê;
texto que outro programa lê, um arquivo CSV ou uma linha de log, leva `Locale.ROOT`, para o número
sair igual em toda máquina. Um arquivo escrito em `pt-BR` e lido de volta por um programa que espera
pontos é o bug clássico de uma exportação de planilha brasileira.

## Um marcador errado falha quando roda

A última chamada pediu ao `%d` que imprimisse a string `"three"`. **O compilador aceitou**, porque
para o compilador o formato é só uma string, e o programa falhou quando a linha rodou:
`IllegalFormatConversionException: d != java.lang.String`, um marcador `d` que recebeu uma `String`.
O status de saída foi 1, e tudo o que vinha antes daquela linha já tinha sido impresso.

Esse é o primeiro stack trace deste curso, e ele se lê de cima para baixo. A primeira linha nomeia a
exceção e a mensagem dela. As linhas seguintes são as chamadas que estavam em andamento, a mais
recente primeiro, e **a primeira linha que nomeia o seu próprio código é onde olhar**:
`Format.main(Format.java:21)`, a linha 21 do arquivo, o `String.format` com `"three"`. As linhas
acima dela estão dentro do JDK e não são onde está o erro. A lição 36 lê stack traces por inteiro.
