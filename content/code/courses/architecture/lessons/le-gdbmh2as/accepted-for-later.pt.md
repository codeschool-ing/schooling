---
title: Aceito agora, respondido depois
version: 1
---

Algumas requisições demoram demais para responder com quem chama esperando: um relatório de vendas do
mês, um vídeo para converter, uma exportação grande. Segurar uma conexão HTTP aberta por minutos convida
cada timeout entre o cliente e o servidor a cortá-la. O padrão de **requisição e resposta assíncronas**
divide a requisição em duas conversas, cada uma delas curta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Uma sequência entre um cliente e o serviço de relatórios. O cliente manda POST /reports e recebe 202 Accepted na hora, com um cabeçalho Location. O serviço trabalha em segundo plano por cerca de três segundos. Enquanto isso o cliente manda GET /reports/1 e recebe status running; depois outro GET devolve status done com o resultado.\"><defs><marker id=\"l5-accepted-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5-accepted-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"70\" y=\"24\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><rect x=\"500\" y=\"24\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reports</text><path d=\"M140 56 L140 270\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570 56 L570 270\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"576\" y=\"84\" width=\"104\" height=\"152\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"628\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">montando</text><text x=\"628\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3 s</text><path d=\"M142 76 L566 76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-accepted-ah-amber)\"></path><text x=\"354\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /reports</text><path d=\"M566 98 L142 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-accepted-ah-phosphor)\"></path><text x=\"354\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">202 Accepted, Location: /reports/1</text><path d=\"M142 150 L566 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-accepted-ah-amber)\"></path><text x=\"354\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /reports/1</text><path d=\"M566 172 L142 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-accepted-ah-phosphor)\"></path><text x=\"354\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {\"status\": \"running\"}</text><path d=\"M142 228 L566 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-accepted-ah-amber)\"></path><text x=\"354\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /reports/1</text><path d=\"M566 250 L142 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-accepted-ah-phosphor)\"></path><text x=\"354\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200 {\"status\": \"done\", …}</text></svg>", "caption": "Requisição e resposta assíncronas: aceita na hora, trabalhada em segundo plano, recolhida depois num endereço que a primeira resposta deu."}
```

1. O cliente pede o trabalho. O servidor aceita, inicia em segundo plano, e responde na hora com
   **`202 Accepted`**, que o HTTP define exatamente para isto: a requisição foi recebida e vai ser processada, e
   ainda não foi. Um cabeçalho `Location` diz onde o resultado vai estar.
2. O cliente pergunta nesse endereço, agora ou depois, quantas vezes quiser. Cada resposta diz até onde
   o trabalho chegou, e a última traz o resultado.

O `report.py` do começo da aula é este padrão, e já está rodando como o serviço `reports` na porta
8001. Peça um relatório e depois peça o resultado duas vezes, uma na hora e outra depois dos três
segundos que o trabalho leva:

```
ana@vm:~/lab/chain$ curl -s -i -X POST localhost:8001/reports
HTTP/1.0 202 Accepted
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:59:24 GMT
Location: /reports/1
Content-Length: 13

{"job": "1"}
ana@vm:~/lab/chain$ curl -s localhost:8001/reports/1
{"status": "running"}
ana@vm:~/lab/chain$ sleep 4; curl -s localhost:8001/reports/1
{"status": "done", "orders": 412, "revenue_cents": 1893450}
```

O `POST` voltou num instante com `202` e `Location: /reports/1`. O primeiro `GET` achou o trabalho ainda
rodando; o segundo, depois de `sleep 4`, achou pronto, com os 412 pedidos do mês e a receita deles.

## Polling, e as alternativas

Perguntar de novo e de novo é **polling**, e é simples e funciona através de qualquer proxy. Os custos são
uma requisição a cada poucos segundos enquanto nada mudou, e um resultado percebido só no próximo
polling. Um servidor pode ajudar mandando um cabeçalho `Retry-After` que diz quanto esperar antes de
perguntar de novo. Quando o polling custa demais, o servidor pode empurrar o resultado: um **callback**
para um endereço que o cliente deu ao pedir, ou uma mensagem numa fila que o cliente escuta, ou uma
conexão mantida aberta para atualizações, que é a aula 18.

**O trabalho precisa sobreviver ao processo que o iniciou.** O `report.py` guarda os trabalhos num
dicionário, que a aula 4 já explicou ser o lugar errado: reinicie o contêiner e todo trabalho rodando e
todo resultado somem, e o cliente consulta um endereço que responde `404`. Um serviço de verdade guarda
os trabalhos num banco, para qualquer cópia poder responder ao `GET` e um reinício não perder nada.

Pare os serviços da aula quando terminar:

```sh
docker compose down
```
