---
title: VI a VIII, processos, portas e escalar para fora
version: 1
---

Três fatores que são uma ideia vista de três lados: **o programa roda como processos comuns que não
guardam nada, servem numa porta que recebem, e são multiplicados para aguentar mais carga.**

**VII, vínculo de porta.** O catálogo é um servidor HTTP completo; não precisa ser carregado dentro de
outro servidor web para responder. Ele escuta em `PORT`, e a plataforma, aqui o Compose, decide que
porta de fora leva até ele. É isso que deixa o mesmo programa rodar atrás de qualquer balanceador ou
proxy sem saber deles.

**VIII, concorrência.** Para aguentar mais requisições, rode mais processos, em vez de fazer um
processo maior. O Compose faz isso com `--scale`; a faixa de portas `8000-8002` no `compose.yaml` dá a
cada cópia a sua porta na máquina:

```
ana@vm:~/lab/twelve$ docker compose up -d --scale catalogue=3
 Container twelve-db-1 Running 
 Container twelve-catalogue-3 Creating 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-2 Creating 
 Container twelve-catalogue-2 Created 
 Container twelve-catalogue-3 Created 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
 Container twelve-catalogue-3 Starting 
 Container twelve-catalogue-3 Started 
 Container twelve-catalogue-2 Starting 
 Container twelve-catalogue-2 Started 
ana@vm:~/lab/twelve$ docker compose ps catalogue --format "{{.Name}} {{.Ports}}"
twelve-catalogue-1 127.0.0.1:8001->8000/tcp
twelve-catalogue-2 127.0.0.1:8000->8000/tcp
twelve-catalogue-3 127.0.0.1:8002->8000/tcp
```

**VI, processos.** Cada uma dessas três cópias precisa conseguir responder a qualquer requisição, o que
quer dizer que nenhuma pode guardar algo de que outra requisição vá precisar. O `/hits` do catálogo
quebra essa regra de propósito: conta na memória do próprio processo. Pergunte a cada cópia uma vez, e
depois à primeira mais duas:

```
ana@vm:~/lab/twelve$ curl -s localhost:8000/hits
{"served_by": "a3b89e5e7e5f", "hits": 1}
ana@vm:~/lab/twelve$ curl -s localhost:8001/hits
{"served_by": "4ed40453cdac", "hits": 1}
ana@vm:~/lab/twelve$ curl -s localhost:8002/hits
{"served_by": "280702d81305", "hits": 1}
ana@vm:~/lab/twelve$ curl -s localhost:8000/hits
{"served_by": "a3b89e5e7e5f", "hits": 2}
ana@vm:~/lab/twelve$ curl -s localhost:8000/hits
{"served_by": "a3b89e5e7e5f", "hits": 3}
ana@vm:~/lab/twelve$ curl -s localhost:8001/products
{"served_by": "4ed40453cdac", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três cópias do processo de catálogo lado a lado. Cada uma guarda o seu contador na memória: uma diz 3, uma diz 1, uma diz 1. Embaixo, um banco compartilhado de onde as três leem os produtos.\"><defs><marker id=\"l4-processes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"30\" width=\"190\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">catalogue-1</text><text x=\"135\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na memória</text><rect x=\"85\" y=\"90\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hits = 3</text><path d=\"M135 142 L135 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-processes-ah-phosphor)\"></path><rect x=\"265\" y=\"30\" width=\"190\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">catalogue-2</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na memória</text><rect x=\"310\" y=\"90\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hits = 1</text><path d=\"M360 142 L360 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-processes-ah-phosphor)\"></path><rect x=\"490\" y=\"30\" width=\"190\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">catalogue-3</text><text x=\"585\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na memória</text><rect x=\"535\" y=\"90\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hits = 1</text><path d=\"M585 142 L585 176\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-processes-ah-phosphor)\"></path><rect x=\"40\" y=\"178\" width=\"640\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o banco: os mesmos produtos para toda cópia</text></svg>", "caption": "Cinco requisições, três processos, três respostas diferentes para quantas foram. O que precisa ser igual para toda cópia tem de morar num serviço de apoio."}
```

Cinco requisições chegaram ao catálogo e **nenhuma cópia sabe disso**. A primeira diz 3, as outras dizem
1. Um balanceador na frente espalharia as requisições de um jeito que ninguém controla, e cada resposta
seria um número errado diferente. O mesmo acontece com qualquer coisa guardada na memória entre
requisições: uma cesta de compras, uma sessão de login, um arquivo enviado para o disco local, um
limite de taxa. Os produtos estão certos em toda cópia porque vêm do banco, que as três dividem.

**O que precisa sobreviver a uma requisição vai para um serviço de apoio**: uma sessão no Redis ou no
banco, um arquivo num armazenamento de objetos, uma contagem no banco ou num cache que toda cópia lê.
Um processo ainda pode guardar coisas na memória para ganhar velocidade, desde que perder esse cache
custe só tempo, nunca uma resposta errada. A regra é sobre aquilo em que você *confia*, não sobre o que
você *guarda*.

## Sessões grudadas são um remendo, não uma correção

Alguns balanceadores conseguem mandar toda requisição de um usuário para a mesma cópia, o que faz
sessões na memória parecerem funcionar. **Isso quebra no momento em que essa cópia reinicia, é
substituída ou é removida numa redução de escala**, e a plataforma faz as três coisas sem perguntar,
como a próxima seção mostra.
