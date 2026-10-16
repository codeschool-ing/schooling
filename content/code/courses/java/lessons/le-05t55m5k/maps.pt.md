---
title: Mapas, e os três métodos que substituem uma página de código
version: 1
---

Um `Map` é um conjunto de chaves com um valor preso a cada uma: um ISBN ao seu livro, um título ao
número de vezes em que foi emprestado. Ele nem é uma `Collection`, e não se percorre como uma, mas
as suas classes espelham as dos conjuntos uma a uma. **`HashMap`, `LinkedHashMap` e `TreeMap` são
`HashSet`, `LinkedHashSet` e `TreeSet` com um valor ao lado de cada elemento**, e guardam as mesmas
três ordens pelos mesmos motivos.

O programa abaixo conta empréstimos, e para isso usa os três métodos que tornam um mapa agradável:
`merge`, `getOrDefault` e `computeIfAbsent`.

```schooling-example
{
  "language": "java",
  "file": "Counts.java",
  "parts": [
    {
      "code": "import java.util.ArrayList;\nimport java.util.HashMap;\nimport java.util.LinkedHashMap;\nimport java.util.List;\nimport java.util.Map;\nimport java.util.TreeMap;\n\npublic class Counts {\n    public static void main(String[] args) {\n        String[] loans = {\"Dune\", \"Emma\", \"Dune\", \"Ulysses\", \"Dune\", \"Emma\"};",
      "note": "**Seis empréstimos, três títulos.** Um mapa é o formato para uma pergunta como *quantas vezes cada título foi emprestado*: uma entrada por chave, e um valor ao lado."
    },
    {
      "code": "\n        Map<String, Integer> count = new HashMap<>();\n        for (String title : loans) {\n            count.merge(title, 1, Integer::sum);\n        }\n        System.out.println(\"HashMap       \" + count);",
      "note": "**O `merge` é uma contagem numa chamada.** Se a chave não existe, ele guarda `1`; se existe, combina o valor antigo com `1` usando `Integer::sum`. Escrito à mão, é um `get`, um teste de `null` e um `put`."
    },
    {
      "code": "        System.out.println(\"Beloved       \" + count.get(\"Beloved\"));\n        System.out.println(\"or default    \" + count.getOrDefault(\"Beloved\", 0));",
      "note": "**O `get` responde `null` para uma chave que não está lá**, o que, desembrulhado num `int`, é um `NullPointerException` esperando para acontecer (lição 4). O `getOrDefault` deixa você mesmo nomear a resposta para *ausente*."
    },
    {
      "code": "\n        Map<String, Integer> firstSeen = new LinkedHashMap<>();\n        for (String title : loans) {\n            firstSeen.putIfAbsent(title, firstSeen.size());\n        }\n        System.out.println(\"LinkedHashMap \" + firstSeen);\n        System.out.println(\"TreeMap       \" + new TreeMap<>(count));",
      "note": "**As mesmas três ordens dos conjuntos.** Um `LinkedHashMap` guarda a ordem em que as chaves chegaram, e o `putIfAbsent` deixa em paz uma entrada que já existe. Um `TreeMap` construído a partir de `count` ordena as chaves."
    },
    {
      "code": "\n        Map<Character, List<String>> byLetter = new TreeMap<>();\n        for (String title : loans) {\n            byLetter.computeIfAbsent(title.charAt(0), k -> new ArrayList<>()).add(title);\n        }\n        System.out.println(\"grouped       \" + byLetter);\n    }\n}",
      "note": "**O `computeIfAbsent` é a expressão idiomática para agrupar.** Ele devolve a lista guardada sob a chave, criando antes uma vazia se não houver nenhuma, e assim o `.add(title)` sempre tem uma lista onde acrescentar. O `k -> new ArrayList<>()` é uma lambda, que o `java-functional` explica; aqui leia como *o jeito de fazer o valor que falta*."
    }
  ]
}
```

```
ana@vm:~/colls$ java Counts.java
HashMap       {Dune=3, Ulysses=1, Emma=2}
Beloved       null
or default    0
LinkedHashMap {Dune=0, Emma=1, Ulysses=2}
TreeMap       {Dune=3, Emma=2, Ulysses=1}
grouped       {D=[Dune, Dune, Dune], E=[Emma, Emma], U=[Ulysses]}
```

Três coisas para ler daí. **O `Dune=3` veio só do `merge`**, sem teste nenhum sobre a chave ser nova.
`Beloved` nunca foi emprestado, e o `get` disse `null` onde o `getOrDefault` disse `0`; o `0` é a
resposta que um relatório quer. E o `HashMap` imprimiu `Dune, Ulysses, Emma`, o `LinkedHashMap`
`Dune, Emma, Ulysses`, e o `TreeMap` de novo `Dune, Emma, Ulysses`, por ordem alfabética. Dois deles
concordarem é coincidência destes títulos.

## O que uma chave precisa ser

Tudo o que a seção 03 disse sobre os elementos de um conjunto vale para as chaves de um mapa, porque
um `HashMap` encontra uma chave exatamente como um `HashSet` encontra um elemento. Uma chave `Book`
com `equals` e sem `hashCode` quebra o `get` do mesmo jeito silencioso: a entrada está lá, e o `get`
com um livro igual responde `null`.

**Uma chave também não pode mudar enquanto está no mapa.** O hash code dela decidiu o balde quando ela
entrou; mude um campo que o hash code lê e a entrada fica no balde antigo, onde nenhuma busca vai
olhar. Strings, wrappers, records e enums não mudam, e é por isso que dão boas chaves e que a maioria
dos mapas usa um deles.
