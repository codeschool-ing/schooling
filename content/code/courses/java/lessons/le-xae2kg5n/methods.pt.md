---
title: Os métodos que você vai usar todo dia
version: 1
---

A `String` tem uns setenta métodos públicos, e uma dúzia deles faz quase todo o trabalho. O programa
abaixo limpa e desmonta uma linha do arquivo de exportação de uma biblioteca, `autor;título;ano`,
que é o tipo de string que um programa mais encontra:

```java
// Methods.java
import java.util.Arrays;
import java.util.Locale;

public class Methods {
    public static void main(String[] args) {
        String line = "  Machado de Assis;Dom Casmurro;1899  ";
        String s = line.strip();
        System.out.println("[" + s + "]");
        System.out.println(s.length());
        System.out.println(s.charAt(0));
        System.out.println(s.indexOf(';'));
        System.out.println(s.substring(0, s.indexOf(';')));
        System.out.println(Arrays.toString(s.split(";")));
        System.out.println(s.replace(';', '|'));
        System.out.println(s.contains("Casmurro"));
        System.out.println(s.toUpperCase(Locale.ROOT));
        System.out.println("apple".compareTo("banana"));
        System.out.println("Zebra".compareTo("apple"));
    }
}
```

```
ana@vm:~/strings$ java Methods.java
[Machado de Assis;Dom Casmurro;1899]
34
M
16
Machado de Assis
[Machado de Assis, Dom Casmurro, 1899]
Machado de Assis|Dom Casmurro|1899
true
MACHADO DE ASSIS;DOM CASMURRO;1899
-1
-7
```

Linha por linha, o que cada chamada respondeu:

| chamada | imprimiu | o que ela diz |
|---|---|---|
| `strip()` | a linha sem os espaços das pontas | os colchetes mostram as duas pontas limpas |
| `length()` | `34` | quantos `char`s: 34 depois do `strip` |
| `charAt(0)` | `M` | **as posições começam em 0**, então a última é `length() - 1` |
| `indexOf(';')` | `16` | a primeira posição do `;`, ou `-1` quando não há nenhum |
| `substring(0, 16)` | `Machado de Assis` | do primeiro índice **até, sem incluir,** o segundo |
| `split(";")` | três pedaços | um array, que é o assunto da lição 9 |
| `replace`, `;` por uma barra | a linha com barras | toda ocorrência, não só a primeira |
| `contains("Casmurro")` | `true` | um sim ou não, onde o `indexOf` dá uma posição |
| `toUpperCase(Locale.ROOT)` | maiúsculas | uma string nova, como a seção 02 mostrou |
| `compareTo` | `-1`, depois `-7` | negativo, zero ou positivo, para ordenar |

Duas dessas respostas pegam as pessoas. O `substring(0, 16)` para **antes** do índice 16, então o
índice final é a posição do próprio `;`, e o `indexOf` é exatamente o número a passar. E o
`compareTo` não é ordem alfabética no sentido de uma pessoa. `"apple"` antes de `"banana"` deu `-1`,
a distância de `a` até `b`. Mas `"Zebra"` antes de `"apple"` deu `-7`, um número negativo, então
**`Zebra` vem primeiro**: toda letra maiúscula tem um código menor que toda minúscula.

O `strip()` é a grafia moderna do `trim()`. Os dois removem espaços das pontas; o `strip()` também
conhece os espaços do Unicode que o `trim()`, mais velho que o crescimento do Unicode, não conhece.

## Um `char` nem sempre é um caractere

Dois métodos daquela tabela, `length()` e `toUpperCase`, respondem algo mais sutil do que os nomes
sugerem, e é no texto em português que isso aparece:

```schooling-example
{
  "language": "java",
  "file": "Chars.java",
  "parts": [
    {
      "code": "import java.util.Locale;\n\npublic class Chars {\n    public static void main(String[] args) {\n        String word = \"ação\";\n        System.out.println(word.length());",
      "note": "**O `length()` conta `char`s**, e cada uma destas quatro letras é um `char`, acentos incluídos. Imprimiu: `4`."
    },
    {
      "code": "        String thumb = \"\\uD83D\\uDC4D\";\n        System.out.println(thumb.length());\n        System.out.println(thumb.codePointCount(0, thumb.length()));",
      "note": "Um emoji de joinha, escrito com os seus dois códigos de escape. **Um símbolo, dois `char`s**: o `length()` diz `2` e o `codePointCount` diz `1`. Um `char` tem 16 bits, e um caractere fora dos primeiros 65.536 precisa de dois."
    },
    {
      "code": "\n        System.out.println(\"title\".toUpperCase(Locale.ROOT));\n        System.out.println(\"title\".toUpperCase(Locale.forLanguageTag(\"tr\")));\n        System.out.println(\"title\".toUpperCase(Locale.forLanguageTag(\"tr\")).equals(\"TITLE\"));\n    }\n}",
      "note": "**A maiúscula depende do idioma.** Em turco o `i` com ponto vira `İ`, então `\"title\"` vira `TİTLE`, e um programa que compara com `\"TITLE\"` recebe `false`. O `Locale.ROOT` pede idioma nenhum, que é o que um código que compara identificadores quer."
    }
  ],
  "output": "4\n2\n1\nTITLE\nTİTLE\nfalse\n"
}
```

**O `length()` acerta para toda letra do português**, acentos incluídos, porque cada uma cabe num
`char`. Ele erra para emoji e para algumas escritas raras, e a correção é o `codePointCount` quando
você precisa contar o que uma pessoa vê. A maiúscula é a armadilha mais comum. Um programa rodando
numa máquina configurada em turco, com um `toUpperCase()` simples, sem argumento, usa o idioma dessa
máquina, e uma verificação como `command.toUpperCase().equals("TITLE")` falha lá e em nenhum outro
lugar. **Passe `Locale.ROOT` quando o texto for um identificador**, e o locale do próprio usuário
quando for uma frase que alguém vai ler.
