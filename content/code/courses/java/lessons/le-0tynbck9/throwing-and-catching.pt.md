---
title: Ler um stack trace, e capturar o que você esperava
version: 1
---

Várias lições deste curso terminaram um programa com um stack trace, e cada um foi a última coisa que
o programa imprimiu. Esta lição é sobre o que eles são. A imagem errada é a de que uma exceção é uma
mensagem de erro. **Uma exceção é um objeto, lançado por um método e voltando por cada método que o
chamou**, até um deles capturá-la ou não sobrar nenhum. O stack trace é a lista desses métodos.

Salve isto num diretório novo, `~/exc`. Ele calcula uma multa a cinquenta centavos por dia, duas
vezes:

```java
// Fine.java
public class Fine {
    static int centsPerDay = 50;

    static int daysLate(String text) {
        return Integer.parseInt(text);
    }

    static int fine(String text) {
        return daysLate(text) * centsPerDay;
    }

    public static void main(String[] args) {
        System.out.println(fine("3"));
        System.out.println(fine("ten"));
        System.out.println("done");
    }
}
```

```
ana@vm:~/exc$ java Fine.java; echo "exit $?"
150
Exception in thread "main" java.lang.NumberFormatException: For input string: "ten"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Fine.daysLate(Fine.java:6)
	at Fine.fine(Fine.java:10)
	at Fine.main(Fine.java:15)
exit 1
```

A primeira multa saiu como `150`. A segunda nunca saiu, e o `done` também não: o programa imprimiu
um stack trace e terminou com status de saída 1.

## De cima para baixo

Um stack trace se lê de cima. A primeira linha diz **o que** foi lançado e por quê:
`NumberFormatException`, com a mensagem `For input string: "ten"`. Cada linha depois dela é uma
chamada de método que estava em andamento quando a exceção foi lançada, **a mais recente primeiro**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A pilha de chamadas quando o Fine.java falhou, desenhada como quadros empilhados, do main embaixo ao Integer.parseInt em cima. O main chamou o fine na linha 15, o fine chamou o daysLate na linha 10, o daysLate chamou o Integer.parseInt na linha 6, e o parseInt lançou NumberFormatException. A exceção desce por cada quadro, nenhum dos quais a captura, e a thread termina. O stack trace imprime os quadros de cima para baixo: onde foi lançada, depois cada chamador.\"><defs><marker id=\"jv36-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Integer.parseInt</text><text x=\"56\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lança NumberFormatException</text><text x=\"30\" y=\"41\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"40\" y=\"72\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Fine.daysLate</text><text x=\"56\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linha 6 chamou o parseInt</text><text x=\"30\" y=\"93\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"40\" y=\"124\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Fine.fine</text><text x=\"56\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linha 10 chamou o daysLate</text><text x=\"30\" y=\"145\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"40\" y=\"176\" width=\"330\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Fine.main</text><text x=\"56\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linha 15 chamou o fine</text><text x=\"30\" y=\"197\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M390 41 V210\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#jv36-a)\"></path><text x=\"404\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a exceção desce pela pilha,</text><text x=\"404\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">procurando um catch que combine com ela</text><text x=\"404\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nenhum quadro aqui tem um, então cada método</text><text x=\"404\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">termina onde estava, e a thread também</text><text x=\"404\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">exit 1</text><text x=\"40\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o stack trace imprime esta coluna de cima para baixo: onde foi lançada, depois quem chamou quem</text></svg>", "caption": "Um stack trace é a pilha de chamadas no momento do lançamento, impressa de cima. Os quadros de java.base acima do daysLate estão dentro da biblioteca; o primeiro quadro do seu próprio código é onde olhar primeiro."}
```

As três primeiras linhas `at` começam com `java.base/`: estão dentro da própria classe `Integer` do
JDK, cujo código você não escreveu. **A primeira linha que cita a sua própria classe é onde começar a
ler**, aqui `Fine.daysLate(Fine.java:6)`, a chamada a `parseInt`. As linhas abaixo dela dizem como o
programa chegou lá: o `fine`, na linha 10, chamou o `daysLate`, e o `main`, na linha 15, chamou o
`fine` com `"ten"`.

Esse último quadro costuma ser o mais útil. A biblioteca fez o que lhe mandaram; o defeito está no
que ela recebeu, e isso veio da linha 15.

## Capturar o que você esperava

Um bloco `try` marca código que você espera que possa falhar, e um bloco `catch` depois dele diz o
que fazer quando falha. Capture só o que você esperava; para todo o resto, o stack trace acima é
melhor que qualquer tratamento. Este programa espera entrada ruim:

```schooling-example
{
  "language": "java",
  "file": "Desk.java",
  "parts": [
    {
      "code": "public class Desk {\n    static int perBook(int totalCents, String books) {\n        return totalCents / Integer.parseInt(books);\n    }",
      "note": "**Uma linha, dois jeitos de falhar.** O `parseInt` lança `NumberFormatException` para texto que não é número, e a divisão inteira por zero lança `ArithmeticException`."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        for (String books : new String[] {\"4\", \"four\", \"0\", \"2\"}) {\n            try {\n                System.out.println(books + \" -> \" + perBook(600, books));",
      "note": "**O bloco `try` é o código que você está preparado para ver falhar.** Seiscentos centavos de multas divididos por um número de livros, quatro vezes, uma delas uma palavra e outra zero."
    },
    {
      "code": "            } catch (NumberFormatException e) {\n                System.out.println(books + \" -> not a number: \" + e.getMessage());",
      "note": "**Um `catch` cita a classe de exceção que trata**, e recebe o objeto da exceção como `e`. O `getMessage()` é o texto depois dos dois-pontos num stack trace."
    },
    {
      "code": "            } catch (ArithmeticException e) {\n                System.out.println(books + \" -> \" + e.getMessage());\n            }\n        }\n    }\n}",
      "note": "**Os blocos `catch` são tentados em ordem**, e o primeiro cuja classe combina trata a exceção. Depois disso o laço segue com o próximo valor, que é o motivo de capturar, afinal."
    }
  ]
}
```

```
ana@vm:~/exc$ java Desk.java
4 -> 150
four -> not a number: For input string: "four"
0 -> / by zero
2 -> 300
```

**Dois valores falharam e o laço sobreviveu aos dois**, que é o que os dois blocos `catch` compraram.
O `four` foi tratado pelo primeiro e o `0` pelo segundo, com a mensagem que cada exceção carregava.

Quando duas exceções são tratadas do mesmo jeito, um `catch` pode citar as duas, separadas por uma
barra: `catch (NumberFormatException | ArithmeticException e)`. Isso é um **multi-catch**, e dentro
dele `e` tem o tipo que as duas classes compartilham. Ele poupa escrever o mesmo bloco duas vezes;
não muda quais exceções são capturadas.
