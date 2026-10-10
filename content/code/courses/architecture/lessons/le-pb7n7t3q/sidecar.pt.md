---
title: O sidecar
version: 1
---

A borda não fala com o serviço de estoque; ela fala com `stock:8080`, que é o **sidecar**. Veja como ele
é declarado no `compose.yaml`: `network_mode: service:stock`. O sidecar roda no seu próprio contêiner, a
partir da sua própria imagem, mas **no namespace de rede do serviço de estoque**: as mesmas interfaces, o
mesmo `localhost`, as mesmas portas. Para o serviço de estoque, o sidecar é um processo na mesma máquina;
para todo o resto, os dois são um endereço só.

Toda requisição que a borda mandou ao novo serviço de estoque passou por ele, e ele registrou cada uma:

```
ana@vm:~/lab/strangler$ docker compose logs sidecar --tail 5
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 1 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
sidecar-1  | sidecar: GET /stock/coffee -> 200 in 2 ms, 1 attempt(s)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma caixa para o namespace de rede do serviço de estoque contém dois processos: o sidecar, escutando na porta 8080, e o serviço de estoque, na porta 8000. A borda manda requisições para o sidecar na 8080; o sidecar registra cada uma e a repassa para localhost:8000.\"><defs><marker id=\"l15-sidecar-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"95\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">borda</text><rect x=\"230\" y=\"40\" width=\"460\" height=\"160\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"460\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">um namespace de rede: o do serviço de estoque</text><rect x=\"260\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sidecar</text><text x=\"340\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:8080, registra</text><rect x=\"500\" y=\"95\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estoque</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:8000</text><path d=\"M162 120 L258 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-sidecar-ah-phosphor)\"></path><path d=\"M422 120 L498 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-sidecar-ah-phosphor)\"></path><text x=\"460\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localhost</text></svg>", "caption": "Um sidecar divide o namespace de rede do serviço: para o serviço ele é localhost, e toda requisição que entra passa por ele.", "same": ["sidecar"]}
```

O serviço de estoque não tem código de log e não sabe que está sendo registrado. Esse é o ponto do
padrão: **o trabalho transversal é feito ao lado do serviço em vez de dentro dele**, por um componente que
é o mesmo para todo serviço, seja qual for a linguagem de cada um. Um serviço em Python e um em Java
recebem os mesmos logs de requisição, as mesmas métricas e o mesmo TLS, do mesmo sidecar, configurado do
mesmo jeito.

O nome vem do carrinho lateral preso a uma motocicleta (*sidecar*): ele vai aonde a motocicleta vai, liga
e desliga com ela, e é uma coisa separada. No Kubernetes o arranjo já vem pronto: os contêineres de um
**pod** dividem um namespace de rede exatamente como os dois contêineres do laboratório, e um sidecar é
simplesmente um segundo contêiner no pod.

É também disso que a **service mesh** da aula 3 é feita. O Istio e o Linkerd põem um proxy Envoy ou
Linkerd como sidecar ao lado de todo serviço; juntos, esses sidecars são o **plano de dados** da mesh. O
que o laboratório não tem é o **plano de controle**, o componente que configura todos os sidecars de uma
vez, distribui certificados e coleta o que eles observam. O sidecar do laboratório é configurado por
três variáveis de ambiente; os sidecars de uma mesh são configurados pelo plano de controle, que é o que
torna cem deles administráveis.
