---
title: O ambassador
version: 1
---

O sidecar ficou na frente de um serviço e cuidou do que **entrava**. O **ambassador** é a mesma ideia do
outro lado: ele fica ao lado de um serviço e cuida do que **sai**, para uma dependência com que o serviço
preferiria não lidar diretamente.

O checkout do monólito chama um gateway de pagamento que exige uma chave de API e está ocupado em toda
segunda requisição. O código do monólito não faz nenhuma das duas coisas: ele chama
`http://localhost:9000/charge` e mais nada. O ambassador, no namespace de rede do monólito, acrescenta a
chave, repassa ao gateway, e tenta de novo um `503` até duas vezes. Três checkouts, e o log do
ambassador:

```
ana@vm:~/lab/strangler$ for i in 1 2 3; do curl -s -X POST localhost:8080/checkout; done
monolith: checkout done, gateway said charged
monolith: checkout done, gateway said charged
monolith: checkout done, gateway said charged
ana@vm:~/lab/strangler$ docker compose logs ambassador
ambassador-1  | ambassador: POST /charge -> 200 in 40 ms, 1 attempt(s)
ambassador-1  | ambassador: POST /charge -> 200 in 6 ms, 2 attempt(s)
ambassador-1  | ambassador: POST /charge -> 200 in 6 ms, 2 attempt(s)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma caixa para o namespace de rede do monólito contém o monólito e o ambassador. O monólito chama localhost:9000; o ambassador acrescenta a chave de API, repassa a chamada ao gateway de pagamento externo, e tenta de novo quando o gateway responde 503.\"><defs><marker id=\"l15-ambassador-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"460\" height=\"160\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"260\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um namespace de rede: o do monólito</text><rect x=\"60\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">monólito</text><rect x=\"300\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ambassador</text><text x=\"380\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:9000</text><path d=\"M222 120 L298 120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-ambassador-ah-amber)\"></path><text x=\"260\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost</text><rect x=\"560\" y=\"95\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gateway</text><path d=\"M462 120 L558 120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-ambassador-ah-amber)\"></path><text x=\"525\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">+ chave, retries</text></svg>", "caption": "Um ambassador fica do lado de quem chama: a aplicação faz uma chamada local simples, e o ambassador faz o que falar com o mundo de fora exige.", "same": ["ambassador", "gateway"]}
```

Os três checkouts deram certo, e o log mostra por quê: dois deles foram recusados uma vez pelo gateway e
passaram na segunda tentativa do ambassador. O monólito não viu nada disso. A chave mora na configuração
do ambassador, e não na do monólito, então pode ser trocada sem um release do monólito, e a política de
retry pode ser mudada do mesmo jeito.

É o mesmo `proxy.py` do sidecar, com outras variáveis de ambiente. **O que distingue os dois padrões é a
posição**: um sidecar fica ao lado do serviço que é chamado, um ambassador ao lado do que chama. O
trabalho típico de um ambassador é tudo o que diz respeito a alcançar um sistema de fora específico: as
credenciais dele, as regras de retry e de taxa das aulas 11 e 12, um circuit breaker em volta dele, um
pool de conexões para um cluster de banco que precisa de um cliente esperto, ou a tradução para um
protocolo que a aplicação não fala.
