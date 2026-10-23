---
title: O custo do backtracking
version: 1
---

**As expressões regulares do Java funcionam tentando: quando um jeito de casar falha, o motor volta e tenta
outro, e só para quando achou um casamento ou acabaram os jeitos.** Isso se chama backtracking, e para a
maioria dos padrões os jeitos acabam rápido. Para alguns, o número de jeitos de dividir o texto cresce a
cada letra, e um padrão que responde na hora numa linha de teste leva segundos, depois minutos, numa um
pouco maior. Quatro padrões que descrevem as mesmas strings, cronometrados num texto que quase casa:

```java
// Backtrack.java: four patterns for the same text, timed on input that almost matches
import java.util.regex.Pattern;

public class Backtrack {
    public static void main(String[] args) {
        Pattern plain = Pattern.compile("a+b");
        Pattern nested = Pattern.compile("(a+)+b");
        Pattern twice = Pattern.compile("((a+)+)+b");
        Pattern possessive = Pattern.compile("((a++)+)+b");
        for (int n = 16; n <= 28; n += 4) {
            String input = "a".repeat(n) + "c";
            System.out.printf("%d letters   a+b %d ms   (a+)+b %d ms   ((a+)+)+b %5d ms   ((a++)+)+b %d ms%n",
                    n, time(plain, input), time(nested, input), time(twice, input), time(possessive, input));
        }
    }

    static long time(Pattern pattern, String input) {
        long start = System.nanoTime();
        pattern.matcher(input).matches();
        return (System.nanoTime() - start) / 1_000_000;
    }
}
```

```
ana@vm:~/fp/regex$ java Backtrack.java
16 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b     7 ms   ((a++)+)+b 0 ms
20 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b    56 ms   ((a++)+)+b 0 ms
24 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b   674 ms   ((a++)+)+b 0 ms
28 letters   a+b 0 ms   (a+)+b 0 ms   ((a+)+)+b 10813 ms   ((a++)+)+b 0 ms
```

## Por que um padrão explodiu

Os quatro descrevem a mesma coisa: alguns `a`s e depois um `b`. A entrada tem os `a`s e termina em `c`,
então nenhum pode casar, e a pergunta é quanto cada um leva para descobrir isso.

O `a+b` não levou nada: os `a`s são tomados, o `b` falta, acabou. **O `((a+)+)+b` foi de 7 ms com dezesseis
letras para quase onze segundos com vinte e oito.** Antes de desistir, ele tem de tentar todos os jeitos de
repartir a fileira de `a`s entre as três repetições aninhadas, dez letras num grupo e dezoito em outro, ou
três e vinte e cinco, e assim por diante, e o número de jeitos mais ou menos dobra a cada letra. Cada quatro
letras multiplicaram o tempo por oito a dezesseis, então uma linha de quarenta letras levaria horas, numa
chamada só.

O `(a+)+b` não levou nada, embora seja o exemplo clássico desse problema. **O motor do JDK reconhece esse
formato mais simples e evita o trabalho repetido**, e é por isso que ele já não é um bom teste, e por isso o
nível a mais é: uma otimização que cobre o caso comum não é garantia para todo padrão.

## As curas

A última coluna é a primeira cura: `a++` é um quantificador **possessivo**, que toma quantos `a`s puder e
nunca devolve nenhum, então não há nada para tentar de novo. O `(?>...)`, um grupo atômico, faz o mesmo para
um grupo inteiro. A cura melhor costuma ser a primeira coluna: **escreva o padrão de modo que cada trecho de
texto só possa casar de um jeito**. Repetições aninhadas da mesma coisa, `(x+)+`, e alternativas que podem
casar com o mesmo texto, `(a|a)+`, são os formatos a reescrever.

Isso pesa mais onde o texto vem de fora. Um servidor que roda um padrão como o terceiro em cada requisição
pode ser parado por qualquer um que mande uma requisição com trinta `a`s e um `c`, sem enxurrada de tráfego,
só uma requisição paciente por thread. Esse ataque tem nome, ReDoS, e a defesa está no padrão, antes de
qualquer requisição chegar. A próxima seção é a outra metade.
