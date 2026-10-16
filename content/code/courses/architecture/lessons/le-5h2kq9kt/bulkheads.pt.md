---
title: Bulkheads
version: 1
---

O casco de um navio é dividido por paredes, as **anteparas** (*bulkheads*), para a água que entra por um
buraco alagar um compartimento e não o navio. Em software é a mesma ideia aplicada a um recurso
compartilhado: dar a cada dependência a sua parte das threads, das conexões ou da memória, para uma
dependência com problema gastar a sua parte e nada mais. O *Release It!* de Nygard deu nome a ele junto
com o circuit breaker.

O bulkhead da loja é um semáforo: no máximo `BULKHEAD` threads podem esperar o serviço de estoque, e uma
requisição que encontra todas ocupadas é recusada com `503` na hora, em vez de pegar uma thread e esperar
também. Reinicie a loja com três, deixe o serviço de estoque lento, e rode a carga:

```
ana@vm:~/lab/bulkheads$ BULKHEAD=3 docker compose up -d
 Container bulkheads-stock-1 Running 
 Container bulkheads-shop-1 Recreate 
 Container bulkheads-shop-1 Recreated 
 Container bulkheads-shop-1 Starting 
 Container bulkheads-shop-1 Started 
ana@vm:~/lab/bulkheads$ curl -s -X POST localhost:8001/slow/5
every answer now takes 5.0 s
ana@vm:~/lab/bulkheads$ $L mixed
catalogue  200: 200                 median     2 ms, slowest    61 ms
stock      timeout: 6, 503: 194     median     2 ms, slowest  3063 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"As mesmas oito threads com um bulkhead. Três delas podem ser usadas por requisições esperando o serviço de estoque, e as três estão cheias. Uma quarta requisição de estoque é recusada na hora com 503. As outras cinco threads continuam disponíveis, e as requisições de catálogo rodam nelas.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"70\" width=\"140\" height=\"60\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"100\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">estoque: no máximo 3</text><rect x=\"40\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"82\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"124\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"190\" y=\"70\" width=\"230\" height=\"60\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"305\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">todo o resto: 5</text><rect x=\"200\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"244\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"288\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"332\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"376\" y=\"84\" width=\"32\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"80\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4ª requisição de estoque: 503 na hora</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um compartimento alagado não afunda o navio</text></svg>", "caption": "Um bulkhead limita quanto de um recurso compartilhado uma dependência pode segurar. O excesso é recusado na hora, e o resto do serviço fica com as suas threads."}
```

**O catálogo nem percebeu**: 200 respostas, mediana de 2 milissegundos. A página de estoque não se saiu
melhor que antes, o que está certo, porque a dependência dela realmente estava levando cinco segundos;
mas quase todas as falhas dela foram `503` rápidos em vez de timeouts de três segundos, e três threads
esperando o serviço de estoque deixaram cinco para todo o resto. A falha ficou dentro do compartimento.

## As formas que um bulkhead toma

| forma | o que é dividido | onde você o encontra |
| --- | --- | --- |
| um semáforo ou um pool por dependência, num processo | threads | o `Bulkhead` do Resilience4j, a política de bulkhead do Polly, o laboratório |
| um pool de conexões por dependência | conexões | um cliente HTTP, ou pool de banco, separado para cada serviço chamado |
| instâncias separadas para tráfegos separados | servidores inteiros | a API do checkout em instâncias próprias, para um pico de relatórios não pegá-las |
| implantações separadas por grupo de clientes | tudo | uma célula de servidores por grupo de clientes, para uma falha alcançar uma célula |

A primeira linha é a mais barata, e é a resposta que a aula 2 prometeu para um monólito: **isolamento
não exige serviços separados**. Um monólito com um bulkhead em volta de cada dependência mantém o catálogo
no ar enquanto o serviço de estoque está lento, exatamente como a loja acabou de fazer. A última linha, em
geral chamada de **arquitetura baseada em células**, é como os maiores sistemas limitam quantos clientes
uma única falha pode alcançar.

Ponha o serviço de estoque de volta antes de seguir:

```sh
curl -s -X POST localhost:8001/slow/0.02
```
