---
title: O que o volatile garante
version: 1
---

**O `volatile` faz duas promessas, e a segunda é a que o torna útil além de uma flag isolada.**

1. **Visibilidade.** Uma leitura de um campo `volatile` vê a escrita mais recente nele, de qualquer
   thread.
2. **Ordem.** Uma escrita num campo `volatile` acontece-antes de toda leitura posterior dele (aula 12,
   seção 04). Tudo o que a thread que escreve fez *antes* da escrita fica, portanto, visível para a
   thread que lê *depois* da leitura, inclusive campos comuns.

A segunda promessa transforma um campo `volatile` num portão para qualquer quantidade de dados comuns.
Um produtor preenche campos comuns e depois liga uma flag `volatile`; um consumidor espera a flag,
depois lê os campos comuns e tem a garantia de vê-los completos:

```schooling-example
{
  "language": "java",
  "file": "Handoff.java",
  "parts": [
    {
      "code": "// Handoff.java: ordinary fields published by one volatile write\npublic class Handoff {\n    static String title;\n    static long priceCents;\n    static int copies;\n    static volatile boolean ready;",
      "note": "Três campos comuns, e uma flag `volatile` que os guarda."
    },
    {
      "code": "\n    public static void main(String[] args) throws InterruptedException {\n        Thread consumer = new Thread(() -> {\n            while (!ready) {\n                Thread.onSpinWait();\n            }\n            System.out.println(title + \", \" + copies + \" copies at \" + priceCents);\n        });\n        consumer.start();",
      "note": "O consumidor lê a flag até ela ser `true`. `Thread.onSpinWait()` avisa o processador que isto é uma espera ativa, o que alguns processadores usam para economizar energia; ele não cria ordem nenhuma."
    },
    {
      "code": "\n        title = \"Middlemarch\";\n        priceCents = 4490;\n        copies = 3;\n        ready = true;\n        consumer.join();\n    }\n}\n",
      "note": "O produtor escreve os dados primeiro e a flag por último. A ordem importa: uma escrita posta depois de `ready = true` não estaria coberta pela promessa."
    }
  ],
  "output": "Middlemarch, 3 copies at 4490"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Linhas do tempo do produtor e do consumidor. O produtor escreve title, priceCents e copies, depois a escrita volatile ready = true. A leitura volatile de ready no consumidor devolve true, e depois dela vêm as leituras comuns dos três campos. Uma seta da escrita volatile à leitura volatile leva tudo o que foi escrito antes dela.\"><defs><marker id=\"gate-ah-paperdim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"gate-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">produtor</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">consumidor</text><rect x=\"110\" y=\"20\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">title = ...; priceCents = ...; copies = 3;</text><rect x=\"450\" y=\"20\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ready = true</text><rect x=\"330\" y=\"140\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">while (!ready)</text><rect x=\"510\" y=\"140\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lê os três campos</text><path d=\"M410 40 L446 40\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gate-ah-paperdim)\"></path><path d=\"M480 160 L506 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gate-ah-paperdim)\"></path><path d=\"M525 60 L430 136\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#gate-ah-phosphor)\"></path><text x=\"560\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">escrita volatile, depois leitura</text></svg>", "caption": "Tudo o que foi escrito antes da escrita volatile fica visível depois da leitura volatile que a vê."}
```

## A ordem das escritas é o truque inteiro

O consumidor imprimiu os três valores, todos, porque as três escritas comuns vieram **antes** da
escrita `volatile` na ordem do programa do produtor, e as leituras comuns do consumidor vieram
**depois** da sua leitura `volatile`. A ordem do programa de cada lado, mais a aresta entre os dois
acessos `volatile`, ordena tudo. Leve `ready = true` para cima de `copies = 3` e o consumidor pode ver
`ready` e ainda ler `copies` como 0: nada mais ordena essa última escrita antes da leitura.

É isso que o `volatile` compra na prática: **um jeito de uma thread entregar um trabalho completo a
outra sem lock**, desde que o trabalho esteja terminado antes de a flag subir e ninguém o mude depois.
As filas da aula 15 e os futures da aula 16 fazem a mesma entrega com as arestas embutidas, e são o que
você deve usar primeiro; saber que funcionam assim por baixo é o que torna as garantias deles
críveis.
