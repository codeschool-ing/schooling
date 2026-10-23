---
title: CompletableFuture
version: 1
---

**Um `Future` só pode ser esperado. Um `CompletableFuture` também pode receber ordens do que fazer em
seguida**, com o mesmo vocabulário dos streams e do `Optional`: `thenApply` mapeia o resultado,
`thenCombine` junta dois resultados, `exceptionally` transforma uma falha num valor. Um pipeline de
passos é descrito de antemão e roda conforme cada resultado chega, sem uma thread parada num `get` entre
os passos.

O caso para o qual ele foi feito: uma página de produto precisa de um preço de um serviço e de um estoque
de outro, cada um lento. Perguntados um depois do outro, a página espera a soma dos dois. Perguntados ao
mesmo tempo, espera o mais lento.

```schooling-example
{
  "language": "java",
  "file": "Page.java",
  "parts": [
    {
      "code": "// Page.java: two slow lookups at once, combined when both are back\nimport java.util.concurrent.CompletableFuture;\nimport java.util.concurrent.ExecutorService;\nimport java.util.concurrent.Executors;\n\npublic class Page {\n    static long price(String title) {\n        Pool.sleep(300);\n        return 4490;\n    }\n\n    static int stock(String title) {\n        Pool.sleep(200);\n        if (title.isBlank()) {\n            throw new IllegalArgumentException(\"no title\");\n        }\n        return 3;\n    }",
      "note": "Dois substitutos de serviços remotos: um leva 300 ms, o outro 200 ms, e o segundo falha para um título em branco. Eles reaproveitam o `Pool.sleep` da seção 02."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        try (ExecutorService io = Executors.newFixedThreadPool(4)) {\n            long start = System.nanoTime();\n            long p = price(\"Middlemarch\");\n            int s = stock(\"Middlemarch\");\n            System.out.printf(\"one after the other: %d cents, %d in stock, %d ms%n\", p, s, ms(start));",
      "note": "A versão simples: duas chamadas em sequência, então a página espera as duas, uma depois da outra."
    },
    {
      "code": "\n            start = System.nanoTime();\n            CompletableFuture<Long> priceF = CompletableFuture.supplyAsync(() -> price(\"Middlemarch\"), io);\n            CompletableFuture<Integer> stockF = CompletableFuture.supplyAsync(() -> stock(\"Middlemarch\"), io);\n            String line = priceF\n                    .thenCombine(stockF, (cents, copies) -> cents + \" cents, \" + copies + \" in stock\")\n                    .join();\n            System.out.printf(\"at once: %s, %d ms%n\", line, ms(start));",
      "note": "O `supplyAsync` começa cada consulta no pool `io` e volta na hora. O `thenCombine` descreve o que fazer quando as duas voltarem; o `join` espera esse valor final."
    },
    {
      "code": "\n            String fallback = CompletableFuture.supplyAsync(() -> stock(\" \"), io)\n                    .thenApply(copies -> copies + \" in stock\")\n                    .exceptionally(e -> \"stock unknown (\" + e.getCause().getMessage() + \")\")\n                    .join();\n            System.out.println(fallback);\n        }\n    }",
      "note": "Quando um passo falha, os passos depois dele são pulados até o `exceptionally`, que transforma a falha num valor que a página pode mostrar. A exceção original é a causa dela."
    },
    {
      "code": "\n\n    static long ms(long start) {\n        return (System.nanoTime() - start) / 1_000_000;\n    }\n}\n"
    }
  ],
  "output": "one after the other: 4490 cents, 3 in stock, 537 ms\nat once: 4490 cents, 3 in stock, 304 ms\nstock unknown (no title)"
}
```

## Lendo os tempos

Um depois do outro levou a soma, 537 ms. **Ao mesmo tempo levou mais ou menos o mais lento dos dois,
304 ms**, porque as duas consultas rodavam em duas threads do pool ao mesmo tempo. Numa página que
consulta cinco serviços, essa é a diferença entre a soma de cinco esperas e a maior delas.

O `exceptionally` recebeu a falha de um título em branco e produziu uma linha que a página pode
imprimir, onde a versão simples teria lançado a exceção para fora da página. **O erro vira valor de
propósito, e a mensagem diz isso**: um plano B que escondesse a causa seria a falha silenciosa de que
este curso não para de falar.

## Que executor

Passe sempre um. Sem o segundo argumento, o `supplyAsync` roda no pool fork-join comum, os mesmos três
workers que os streams paralelos usam (aula 9, seção 05), e consultas que esperam os segurariam e
parariam todos os streams paralelos do programa. Um pool próprio para trabalho que espera, ou, na aula
17, um executor de threads virtuais, mantém os dois tipos de trabalho separados.
