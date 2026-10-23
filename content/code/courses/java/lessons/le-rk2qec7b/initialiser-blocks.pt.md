---
title: Código fora de qualquer método
version: 1
---

A maioria das pessoas imagina uma classe como campos e métodos, com cada linha de código dentro de
um método, e o construtor como o lugar onde a preparação de um objeto acontece. **Uma classe também
pode guardar código em blocos que não pertencem a método nenhum**, e o Java os executa por você em
momentos fixos. Há dois tipos: o **bloco estático**, que roda uma vez para a classe, e o **bloco de
instância**, que roda uma vez para cada objeto. Os inicializadores de campo, o `= …` depois da
declaração de um campo, rodam nos mesmos momentos que os blocos do seu tipo.

Aqui estão os dois, num diretório só deles, `~/init`:

```schooling-example
{
  "language": "java",
  "file": "Shelf.java",
  "parts": [
    {
      "code": "import java.util.ArrayList;\nimport java.util.List;\n\npublic class Shelf {\n    static final List<String> GENRES = new ArrayList<>();",
      "note": "**Um campo estático com inicializador.** A expressão à direita roda uma vez, quando a classe é usada pela primeira vez, e antes de qualquer outra coisa da classe."
    },
    {
      "code": "\n    static {\n        GENRES.add(\"fiction\");\n        GENRES.add(\"history\");\n        System.out.println(\"static block: \" + GENRES);\n    }",
      "note": "**Um bloco estático: código que pertence à classe e não a um método.** Ele roda uma vez, logo depois do campo acima dele, porque os inicializadores estáticos rodam na ordem em que estão escritos. É o lugar da preparação que uma expressão só não comporta."
    },
    {
      "code": "\n    private final List<String> titles = new ArrayList<>();",
      "note": "Um campo de instância com inicializador. Este roda para cada objeto, como a primeira coisa que cada construtor faz depois de chamar o da superclasse."
    },
    {
      "code": "\n    {\n        titles.add(\"(empty)\");\n        System.out.println(\"instance block: \" + titles);\n    }",
      "note": "**Um bloco de instância: as mesmas chaves, sem `static` e sem nome.** Ele roda para cada objeto, depois do campo acima dele e antes do corpo do construtor que foi chamado, seja ele qual for."
    },
    {
      "code": "\n    Shelf() {\n        System.out.println(\"Shelf(): \" + titles);\n    }\n\n    Shelf(String first) {\n        titles.set(0, first);\n        System.out.println(\"Shelf(String): \" + titles);\n    }",
      "note": "Dois construtores, e nenhum repete a preparação. Os dois encontram `titles` já contendo `(empty)`, porque o bloco de instância rodou antes do corpo deles."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        System.out.println(\"main starts\");\n        new Shelf();\n        new Shelf(\"Dom Casmurro\");\n    }\n}",
      "note": "O `main` imprime uma linha antes, para a saída mostrar se o bloco estático rodou antes ou depois dele."
    }
  ],
  "output": "static block: [fiction, history]\nmain starts\ninstance block: [(empty)]\nShelf(): [(empty)]\ninstance block: [(empty)]\nShelf(String): [Dom Casmurro]"
}
```

Compilado e executado:

```
ana@vm:~/init$ javac Shelf.java && java Shelf
static block: [fiction, history]
main starts
instance block: [(empty)]
Shelf(): [(empty)]
instance block: [(empty)]
Shelf(String): [Dom Casmurro]
```

Leia a saída junto com o programa, linha por linha:

- **`static block` vem antes de `main starts`.** A JVM precisa inicializar uma classe antes de
  executar qualquer método estático dela, e o `main` é um. Inicializar `Shelf` quer dizer rodar os
  inicializadores de campos estáticos e os blocos estáticos dela, de cima para baixo, uma vez.
- **`instance block` aparece duas vezes**, uma por `new Shelf`, e cada vez antes da linha do próprio
  construtor. Qual construtor foi chamado não fez diferença nisso.
- O `Shelf(String)` trocou `(empty)` pelo título, então o corpo do construtor rodou depois do bloco
  e conseguiu ver o que ele tinha feito.

## Onde o compilador os põe

O `javap -p` lista todos os membros, inclusive os privados:

```
ana@vm:~/init$ javap -p Shelf
Compiled from "Shelf.java"
public class Shelf {
  static final java.util.List<java.lang.String> GENRES;
  private final java.util.List<java.lang.String> titles;
  Shelf();
  Shelf(java.lang.String);
  public static void main(java.lang.String[]);
  static {};
}
```

**O bloco de instância sumiu, e o bloco estático virou um método chamado `static {}`.** É assim que o
compilador os organiza. Todos os inicializadores e blocos estáticos, na ordem do código, são juntados
num único inicializador da classe, que a JVM chama uma vez. Todos os inicializadores e blocos de
instância são copiados para o começo de **cada** construtor, depois da chamada ao construtor da
superclasse. Não existe método do bloco de instância para chamar, e é por isso que ele não pode ser
chamado duas vezes nem pulado.

## Quando escrever um

**Um bloco estático se justifica quando um campo estático precisa de mais de uma expressão para ser
preparado**: uma tabela de consulta preenchida num laço, ou um valor que pode lançar exceção e precisa
ser capturado. Um campo `static final` que uma expressão consegue preencher dispensa o bloco, e
`List.of("fiction", "history")` teria resolvido aqui, como uma lista não modificável.

**Um bloco de instância é raro em código de verdade.** O trabalho dele é a preparação comum a vários
construtores, e a lição 13 já deu esse trabalho ao `this(...)`, em que um construtor chama outro. A
maioria dos guias de estilo prefere a chamada, porque ela está visível no construtor que alguém está
lendo, e um bloco de instância vinte linhas acima não está. Você ainda vai encontrar blocos de
instância em código antigo, e a seção 03 mostra exatamente onde eles entram na ordem dos
acontecimentos.
