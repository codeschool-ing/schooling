---
title: Quatro jeitos de remover enquanto percorre
version: 1
---

Os dois programas da seção 03 eram o mesmo erro: um laço `for-each`, e uma mudança na lista vinda de
fora do iterador. **As versões seguras têm todas uma coisa em comum: quem muda a lista é também quem a
percorre**, ou o percurso acontece sobre algo que não muda. Um programa mostra os quatro lado a lado:

```schooling-example
{
  "language": "java",
  "file": "Safe.java",
  "parts": [
    {
      "code": "import java.util.ArrayList;\nimport java.util.Iterator;\nimport java.util.List;\nimport java.util.ListIterator;\n\npublic class Safe {\n    public static void main(String[] args) {\n        List<String> loans = new ArrayList<>(List.of(\"Dune\", \"Emma:late\", \"Ulysses:late\", \"Beloved:late\"));",
      "note": "**Quatro empréstimos, três deles atrasados**, e cada técnica abaixo começa da sua própria cópia desta lista, para que não interfiram umas nas outras."
    },
    {
      "code": "\n        List<String> a = new ArrayList<>(loans);\n        Iterator<String> it = a.iterator();\n        while (it.hasNext()) {\n            if (it.next().endsWith(\":late\")) {\n                it.remove();\n            }\n        }\n        System.out.println(\"iterator.remove  \" + a);",
      "note": "**Remover pelo iterador.** O `it.remove()` apaga o elemento que o último `next()` devolveu, e, como foi o iterador que fez a mudança, ele atualiza a própria contagem e o cursor. É o laço que a seção 03 queria escrever, com o iterador à vista."
    },
    {
      "code": "\n        List<String> b = new ArrayList<>(loans);\n        b.removeIf(loan -> loan.endsWith(\":late\"));\n        System.out.println(\"removeIf         \" + b);",
      "note": "**Ou dizer só o que remover.** O `removeIf` recebe uma condição e faz o percurso sozinho, com segurança. O argumento é uma lambda, que o `java-functional` explica; leia como *um empréstimo cujo texto termina em `:late`*."
    },
    {
      "code": "\n        List<String> c = new ArrayList<>(loans);\n        ListIterator<String> li = c.listIterator();\n        while (li.hasNext()) {\n            String loan = li.next();\n            if (loan.endsWith(\":late\")) {\n                li.set(loan.replace(\":late\", \":fined\"));\n                li.add(\"letter to \" + loan.replace(\":late\", \"\"));\n            }\n        }\n        System.out.println(\"listIterator     \" + c);",
      "note": "**Um `ListIterator` também substitui e insere.** O `set` substitui o elemento recém-devolvido, e o `add` insere um novo depois dele, onde o próximo `next()` não o verá. Só listas têm um, porque só listas têm posições."
    },
    {
      "code": "\n        List<String> d = new ArrayList<>(loans);\n        for (String loan : List.copyOf(d)) {\n            if (loan.endsWith(\":late\")) {\n                d.remove(loan);\n            }\n        }\n        System.out.println(\"copy             \" + d);\n    }\n}",
      "note": "**Ou percorrer uma cópia e mudar o original.** O `for-each` itera sobre `List.copyOf(d)`, que nada altera, enquanto o `remove` trabalha em `d`. Custa uma segunda lista durante o laço."
    }
  ]
}
```

```
ana@vm:~/iter$ java Safe.java
iterator.remove  [Dune]
removeIf         [Dune]
listIterator     [Dune, Emma:fined, letter to Emma, Ulysses:fined, letter to Ulysses, Beloved:fined, letter to Beloved]
copy             [Dune]
```

Três técnicas removeram os empréstimos atrasados e deixaram `[Dune]`, sem exceção e sem elemento
pulado. A quarta fez mais: cada empréstimo atrasado virou `fined`, e uma carta foi inserida depois
dele. **Sete elementos saíram de quatro**, e o iterador seguiu percorrendo limpo depois de cada
inserção, porque ele mesmo fez cada uma.

## Qual escolher

| você quer | escreva |
|---|---|
| remover o que satisfaz uma condição | `removeIf`, o mais curto e o mais difícil de errar |
| decidir elemento a elemento, com mais de uma condição ou um efeito colateral | um `Iterator` explícito e `it.remove()` |
| substituir ou inserir enquanto percorre uma lista | um `ListIterator` e o seu `set` ou `add` |
| chamar de dentro do laço um método que muda a lista | percorrer uma cópia, `List.copyOf(...)` |

A cópia é o último recurso e às vezes o único, por exemplo quando o laço chama
`member.returnLoan(loan)`, que remove de uma lista que o laço não enxerga. **Cada um dos outros evita
a segunda lista**, e isso importa quando a lista tem um milhão de entradas.

## E para mapas

Um `Map` é percorrido por uma das suas visões, `keySet()`, `values()` ou `entrySet()`, e a mesma regra
vale: mude o mapa pelo iterador da visão, ou não mude, enquanto o percurso durar.
`map.entrySet().removeIf(e -> e.getValue() == 0)` remove cada entrada cujo valor é zero, e
`map.values().removeIf(...)` faz o mesmo olhando só os valores. **Uma visão é apoiada no mapa**, então
o que ela remove some do próprio mapa.
