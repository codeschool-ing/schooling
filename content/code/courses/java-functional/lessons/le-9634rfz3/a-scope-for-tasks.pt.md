---
title: Um escopo para tarefas
version: 1
---

**A concorrência estruturada dá às tarefas concorrentes um escopo, do jeito que um bloco dá um às
variáveis.** As tarefas são bifurcadas (fork) dentro de um `StructuredTaskScope`, o escopo espera por
elas no `join`, e quando o bloco try-with-resources termina, toda tarefa bifurcada nele também terminou.
Nenhuma tarefa sobrevive ao bloco que a iniciou. A política padrão é a de que a página precisava:
**todas precisam ter sucesso, e a primeira falha cancela o resto.**

O `StructuredTaskScope` é uma **API em preview** no Java 25. Recursos em preview estão completos e
especificados, mas ainda podem mudar, então o compilador os recusa a não ser que alguém peça:
`--enable-preview` os liga, e com o modo de arquivo-fonte o `--source 25` diz o preview de qual versão
usar.

```schooling-example
{
  "language": "java",
  "file": "Scoped.java",
  "parts": [
    {
      "code": "// Scoped.java: the same page, with the lookups forked in a structured scope\nimport java.util.concurrent.StructuredTaskScope;\n\npublic class Scoped {\n    static long price() throws InterruptedException {\n        Thread.sleep(300);\n        throw new IllegalStateException(\"price service down\");\n    }\n\n    static int stock() throws InterruptedException {\n        try {\n            Thread.sleep(1000);\n            System.out.println(\"stock: finished\");\n            return 3;\n        } catch (InterruptedException e) {\n            System.out.println(\"stock: cancelled, because the price failed\");\n            throw e;\n        }\n    }",
      "note": "As mesmas duas consultas. `stock` agora avisa quando é interrompida, para o cancelamento poder ser visto."
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        long start = System.nanoTime();\n        try (var scope = StructuredTaskScope.open()) {\n            StructuredTaskScope.Subtask<Long> p = scope.fork(Scoped::price);\n            StructuredTaskScope.Subtask<Integer> s = scope.fork(Scoped::stock);",
      "note": "O `open()` faz um escopo com a política padrão. Cada `fork` inicia uma subtarefa numa thread virtual nova e devolve uma `Subtask`, uma alça para o resultado dela."
    },
    {
      "code": "\n            scope.join();\n            System.out.println(p.get() + \" cents, \" + s.get() + \" in stock\");",
      "note": "O `join` espera todas as subtarefas. Com a política padrão, ele só retorna se todas tiveram sucesso, então o `get` é seguro depois dele."
    },
    {
      "code": "\n        } catch (StructuredTaskScope.FailedException e) {\n            System.out.printf(\"page failed after %d ms: %s%n\", (System.nanoTime() - start) / 1_000_000, e.getCause());\n        }\n        System.out.printf(\"main returned after %d ms%n\", (System.nanoTime() - start) / 1_000_000);\n    }\n}\n",
      "note": "Quando uma subtarefa falha, o escopo interrompe as outras, o `join` lança `FailedException` com a primeira falha como causa, e o bloco só termina depois de toda subtarefa ter terminado."
    }
  ]
}
```

Rode-o com o preview ligado, e depois uma vez sem, para ver a recusa:

```
ana@vm:~/fp/structured$ java --enable-preview --source 25 Scoped.java
stock: cancelled, because the price failed
page failed after 309 ms: java.lang.IllegalStateException: price service down
main returned after 315 ms
ana@vm:~/fp/structured$ java Scoped.java 2>&1 | head -n 4
Scoped.java:2: error: StructuredTaskScope is a preview API and is disabled by default.
import java.util.concurrent.StructuredTaskScope;
                           ^
  (use --enable-preview to enable preview APIs)
```

## A mesma falha, tratada pela estrutura

**A consulta de estoque foi cancelada no momento em que o preço falhou**, e disse isso; a página
informou a falha por volta dos 300 ms; e a `main` retornou logo depois, não um segundo mais tarde. A
regra que fez isso não está no código que chama `price` e `stock`. Ela está no escopo, e vale para toda
tarefa bifurcada ali, inclusive as que alguém acrescentar no ano que vem.

O padrão é "tudo ou nada" porque é isso que a maioria das bifurcações quer dizer: uma página que precisa
de um preço e de um estoque precisa dos dois. O bloco também torna a estrutura visível para as
ferramentas: um dump de threads, tirado com `jcmd <pid> Thread.dump_to_file -format=json`, mostra as
threads das subtarefas agrupadas sob o escopo que as bifurcou, que é o "a quem isto pertencia" que a
seção 02 não conseguia responder.
