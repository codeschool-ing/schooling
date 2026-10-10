---
title: Uma dependência lenta
version: 1
---

Faça o serviço de estoque levar cinco segundos por resposta, e rode a mesma carga:

```
ana@vm:~/lab/bulkheads$ curl -s -X POST localhost:8001/slow/5
every answer now takes 5.0 s
ana@vm:~/lab/bulkheads$ $L mixed
catalogue  timeout: 193, 200: 7     median  3004 ms, slowest  3012 ms
stock      timeout: 200             median  3004 ms, slowest  3047 ms
```

A página de estoque deu timeout, o que não surpreende: a dependência dela leva cinco segundos e a carga
espera três. **O catálogo também deu timeout**, 193 das suas 200 requisições, e o catálogo nem chama o
serviço de estoque. A mediana dele foi de 3 milissegundos para o timeout inteiro de três segundos.

Siga as threads. Chegam vinte requisições de estoque por segundo, e cada uma segura uma das oito threads
por cinco segundos. Em meio segundo as oito estão esperando o serviço de estoque, e toda requisição
depois disso, de catálogo ou de estoque, espera na fila do pool por uma thread que não vai ficar livre
por segundos. O catálogo não estava quebrado; estava **faminto**. De fora, a loja está fora do ar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As oito threads da loja, desenhadas como oito espaços, em dois momentos. Saudável: alguns espaços estão ocupados por pouco tempo com requisições de estoque e de catálogo, e a maioria está livre. Com o serviço de estoque lento: os oito espaços estão presos em requisições de estoque esperando resposta, e uma requisição de catálogo espera do lado de fora sem onde rodar.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">saudável: a maioria das threads livre</text><rect x=\"40\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"80\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"120\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"160\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"60\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">estoque lento: toda thread esperando por ele</text><rect x=\"40\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"80\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"120\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"160\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"240\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"160\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"420\" y=\"160\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"480\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">catálogo</text><text x=\"560\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espera</text><rect x=\"420\" y=\"60\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisição de estoque</text><rect x=\"420\" y=\"84\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisição de catálogo</text></svg>", "caption": "Uma dependência lenta não faz falhar as requisições que a chamam; ela segura as threads em que elas rodam, e todo o resto também precisa dessas threads."}
```

Um timeout na chamada ao serviço de estoque encurtaria a espera de cinco segundos para um, o que ajuda e
não resolve: vinte por segundo, cada uma segurando uma thread por um segundo, ainda é mais que oito
threads. Um circuit breaker abriria depois de falhas suficientes, o que também ajuda, depois dessas
falhas. O que falta é uma regra que diga **o serviço de estoque não pode ficar com todas as threads**.

Ponha o serviço de estoque de volta antes de seguir:

```sh
curl -s -X POST localhost:8001/slow/0.02
```
