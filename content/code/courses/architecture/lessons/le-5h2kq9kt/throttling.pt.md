---
title: Throttling num cliente que pede vezes demais
version: 1
---

O bulkhead protegeu a loja de uma dependência. O perigo oposto vem de quem chama: a integração de um
parceiro em loop, um scraper, um aplicativo com um defeito que atualiza a cada 20 milissegundos. Um
cliente mandando mais que a sua parte tira threads de todo mundo.

O **throttling**, ou limite de taxa (*rate limiting*), limita com que frequência cada cliente pode pedir. O
limite da loja é um **token bucket** por cliente, o algoritmo mais comum: um balde guarda até dez fichas e
é reabastecido a dez por segundo, e cada requisição tira uma. Um cliente consegue mandar uma rajada de
até dez requisições de uma vez, e depois disso recebe dez por segundo, por mais que tente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um token bucket. Fichas pingam num ritmo constante, dez por segundo, até uma capacidade de dez. Cada requisição tira uma ficha e passa. Uma requisição que encontra o balde vazio recebe 429 Too Many Requests, com Retry-After.\"><defs><marker id=\"l12-bucket-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-bucket-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">10 fichas por segundo</text><path d=\"M180 44 L180 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-bucket-ah-phosphor)\"></path><rect x=\"120\" y=\"80\" width=\"120\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><circle cx=\"150\" cy=\"165\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"210\" cy=\"165\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"150\" cy=\"135\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"210\" cy=\"135\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capacidade 10</text><rect x=\"400\" y=\"60\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ficha tirada: 200</text><rect x=\"400\" y=\"140\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">balde vazio: 429, Retry-After: 1</text><path d=\"M242 110 L398 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-bucket-ah-phosphor)\"></path><path d=\"M242 150 L398 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-bucket-ah-amber)\"></path></svg>", "caption": "Um token bucket permite uma rajada até o seu tamanho e, depois disso, o ritmo em que é reabastecido."}
```

Uma requisição que encontra o balde vazio recebe **`429 Too Many Requests`**, com um cabeçalho
`Retry-After` dizendo quantos segundos esperar. É o código de status feito para isso, e importa qual é
usado: um `429` diz "você, vá mais devagar", enquanto um `503` diz "estou com problemas". Um cliente bem
comportado, e toda biblioteca de retry da aula 11, lê o `Retry-After` e espera.

Reinicie a loja com um limite de dez por segundo por cliente. Depois, por cinco segundos, um cliente
guloso pede cinquenta vezes por segundo enquanto a Ana pede duas vezes por segundo:

```
ana@vm:~/lab/bulkheads$ RATE=10 docker compose up -d
 Container bulkheads-stock-1 Running 
 Container bulkheads-shop-1 Recreate 
 Container bulkheads-shop-1 Recreated 
 Container bulkheads-shop-1 Starting 
 Container bulkheads-shop-1 Started 
ana@vm:~/lab/bulkheads$ $L greedy
ana        200: 10                  median     2 ms, slowest    41 ms
greedy     200: 59, 429: 191        median     2 ms, slowest    42 ms
```

O cliente guloso recebeu 59 respostas de 250: as dez do balde no começo, depois umas dez por segundo. O
resto foi recusado em um ou dois milissegundos, quase sem custo para a loja. **A Ana recebeu todas as
dela**, porque o limite é por cliente e o balde dela nunca esvaziou.

## Onde o limite mora

Um limite de taxa em geral nem fica no serviço. O **API gateway** na frente dos serviços, que a aula 19
constrói, é o lugar natural: ele vê todo cliente, sabe quem cada um é, e uma configuração ali protege
todo serviço atrás dele. Gateways de nuvem, Envoy, NGINX e Kong já o trazem. Com várias instâncias de
gateway os baldes têm de ser compartilhados, em geral no Redis, senão cada instância permite a taxa
inteira e o limite de verdade é essa taxa vezes o número de instâncias.

Dois vizinhos da ideia merecem ser conhecidos pelo nome:

- **Cotas** são limites de taxa sobre períodos longos, "10.000 requisições por dia", e em geral dizem
  respeito a um plano que alguém paga, e não a proteger o serviço.
- **Load shedding** recusa trabalho pela importância, não por quem o mandou: quando a loja está
  sobrecarregada ela descarta primeiro a caixa de recomendações e por último o checkout. Exige que o
  serviço saiba que requisições importam, o que é uma decisão do negócio, não uma configuração.
