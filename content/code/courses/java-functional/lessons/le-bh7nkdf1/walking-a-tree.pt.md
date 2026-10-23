---
title: Percorrendo uma árvore
version: 1
---

**Três métodos de `Files` transformam um diretório num stream de caminhos: `list` para um nível, `walk`
para todos os níveis, e `find` para todos os níveis com um teste.** Os três seguram o diretório aberto
enquanto o stream é usado, então cada um vai num `try` com recursos, como o `Files.lines`. O programa
monta uma pequena biblioteca, olha para ela de três jeitos e a apaga:

```schooling-example
{
  "language": "java",
  "file": "Tree.java",
  "parts": [
    {
      "code": "// Tree.java: build a small tree, list it, walk it, search it and delete it\nimport java.io.IOException;\nimport java.io.UncheckedIOException;\nimport java.nio.file.Files;\nimport java.nio.file.Path;\nimport java.util.Comparator;\nimport java.util.stream.Stream;\n\npublic class Tree {\n    public static void main(String[] args) throws IOException {\n        Path root = Path.of(\"library\");\n        Files.createDirectories(root.resolve(\"fiction/classics\"));\n        Files.createDirectories(root.resolve(\"poetry\"));\n        Files.writeString(root.resolve(\"fiction/dune.txt\"), \"Dune\\n\".repeat(400));\n        Files.writeString(root.resolve(\"fiction/classics/emma.txt\"), \"Emma\\n\".repeat(900));\n        Files.writeString(root.resolve(\"poetry/odes.txt\"), \"Odes\\n\".repeat(30));\n        Files.writeString(root.resolve(\"poetry/notes.md\"), \"# notes\\n\");",
      "note": "Seis linhas montam a árvore que o resto percorre: quatro diretórios e quatro arquivos, com o `createDirectories` criando de uma vez todo nível que falta. Os tamanhos são escolhidos: `dune.txt` tem exatamente 2.000 bytes."
    },
    {
      "code": "\n        System.out.println(\"one level:\");\n        try (Stream<Path> entries = Files.list(root)) {\n            entries.sorted().forEach(p -> System.out.println(\"  \" + p));\n        }",
      "note": "O `Files.list` dá um nível, as entradas logo dentro de `root`, sem ordem prometida, então elas são ordenadas antes de imprimir."
    },
    {
      "code": "\n        System.out.println(\"every .txt, with its size:\");\n        try (Stream<Path> all = Files.walk(root)) {\n            all.filter(Files::isRegularFile)\n                    .filter(p -> p.toString().endsWith(\".txt\"))\n                    .sorted()\n                    .forEach(p -> System.out.println(\"  \" + root.relativize(p) + \"  \" + size(p)));\n        }",
      "note": "O `Files.walk` dá todos os níveis, `root` incluído, diretórios e arquivos do mesmo jeito. Os filtros ficam com os arquivos comuns cujo nome termina em `.txt`."
    },
    {
      "code": "\n        System.out.println(\"over 2,000 bytes:\");\n        try (Stream<Path> big = Files.find(root, Integer.MAX_VALUE,\n                (p, attrs) -> attrs.isRegularFile() && attrs.size() > 2_000)) {\n            big.forEach(p -> System.out.println(\"  \" + p.getFileName()));\n        }",
      "note": "O `Files.find` também percorre, e entrega ao seu teste os atributos que já leu de cada entrada, então perguntar o tamanho não custa uma segunda ida ao disco."
    },
    {
      "code": "\n        try (Stream<Path> all = Files.walk(root)) {\n            all.sorted(Comparator.reverseOrder()).forEach(Tree::delete);\n        }\n        System.out.println(\"deleted, exists: \" + Files.exists(root));\n    }",
      "note": "Um diretório só pode ser apagado quando está vazio. Em ordem inversa todo caminho vem antes do seu pai, então o percurso apaga os arquivos primeiro e `library` por último."
    },
    {
      "code": "\n    static long size(Path p) {\n        try {\n            return Files.size(p);\n        } catch (IOException e) {\n            throw new UncheckedIOException(e);\n        }\n    }\n\n    static void delete(Path p) {\n        try {\n            Files.delete(p);\n        } catch (IOException e) {\n            throw new UncheckedIOException(e);\n        }\n    }\n}\n\n",
      "note": "O `Files.size` e o `Files.delete` lançam `IOException`, que nenhum lambda de `java.util.function` pode lançar. Cada auxiliar a embrulha numa `UncheckedIOException` e o stream a leva para fora."
    }
  ]
}
```

```
ana@vm:~/fp/files$ java Tree.java
one level:
  library/fiction
  library/poetry
every .txt, with its size:
  fiction/classics/emma.txt  4500
  fiction/dune.txt  2000
  poetry/odes.txt  150
over 2,000 bytes:
  emma.txt
deleted, exists: false
```

## O que cada um viu

O `list` viu os dois diretórios logo dentro de `library` e nada abaixo deles. **O `walk` desceu todos os
níveis** e encontrou oito caminhos, o próprio `library` entre eles; os filtros ficaram com os três
arquivos comuns terminados em `.txt`, e o `notes.md` e os quatro diretórios ficaram de fora. O `find`
encontrou os mesmos caminhos e ficou com um: `emma.txt`, com 4.500 bytes. O `dune.txt` tem exatamente
2.000, e o teste dizia mais de 2.000.

A ordem que importa é a de apagar. **O `Files.delete` recusa um diretório que ainda tenha alguma coisa
dentro**, então uma árvore é apagada das folhas para cima. Em ordem inversa, `library/poetry/odes.txt` vem
antes de `library/poetry`, que vem antes de `library`, e a última linha confirma que não sobrou nada.

## Exceções verificadas num stream

O `Files::isRegularFile` foi direto para o `filter`, mas o `Files.size` não podia: ele declara
`IOException`, e as interfaces funcionais da aula 2 não declaram exceções verificadas, então um lambda
que o chame não compila. **Os auxiliares a capturam e a relançam como `UncheckedIOException`**, que o
stream deixa passar até quem chamou, onde ela pode ser capturada e o seu `getCause()` lido. O mesmo
embrulho já estava dentro dos próprios streams: se um diretório não puder ser lido no meio de um percurso,
o `walk` lança `UncheckedIOException` da operação terminal.

O `walk` não segue links simbólicos a menos que peçam com `FileVisitOption.FOLLOW_LINKS`, então um link
que aponta de volta para cima na árvore não pode fazê-lo andar em círculos. Para um percurso que precisa
agir antes e depois de cada diretório, o `Files.walkFileTree` recebe um visitante com um método para cada
evento; a maioria dos programas nunca precisa de mais do que o stream.
