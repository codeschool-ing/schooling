---
title: V, build, release, execução
version: 1
---

Três estágios, mantidos separados de propósito.

| estágio | o que faz | o que sai |
| --- | --- | --- |
| **build** | transforma um commit em algo que roda: dependências instaladas, código compilado ou copiado | uma imagem |
| **release** | combina um build com a configuração de um ambiente | uma release, numerada, que nunca muda |
| **execução** | inicia processos a partir de uma release | o programa rodando |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três estágios da esquerda para a direita. O build transforma um commit do código numa imagem com a tag 1.0.0. A release combina essa imagem com a configuração de um ambiente na release 41, e depois a mesma imagem com configuração nova na release 42. A execução inicia processos a partir de uma release. Uma seta da release 42 de volta para a 41 tem o rótulo rollback.\"><defs><marker id=\"l4-brr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4-brr-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l4-brr-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">build</text><text x=\"330\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">release</text><text x=\"610\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">execução</text><rect x=\"30\" y=\"60\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">commit</text><rect x=\"140\" y=\"60\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">imagem 1.0.0</text><path d=\"M112 80 L138 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-wire)\"></path><rect x=\"270\" y=\"60\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">release 41</text><text x=\"370\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">imagem 1.0.0 + config A</text><path d=\"M232 80 L268 85\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-amber)\"></path><rect x=\"270\" y=\"150\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">release 42</text><text x=\"370\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">imagem 1.0.0 + config B</text><path d=\"M232 80 L268 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-amber)\"></path><rect x=\"540\" y=\"150\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processos</text><path d=\"M472 175 L538 175\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-phosphor)\"></path><path d=\"M330 148 C 300 130, 300 125, 330 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l4-brr-ah-amber)\"></path><text x=\"345\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rollback</text></svg>", "caption": "Construa uma vez, lance muitas vezes, rode o que foi lançado. Um rollback é escolher uma release anterior, não construir nada de novo.", "same": ["build", "release", "rollback"]}
```

O motivo da separação é o que ela proíbe. **Nenhuma mudança é feita em código rodando**: uma correção é
um commit novo, um build novo e uma release nova, nunca uma edição feita num servidor, que não
existiria em nenhum outro lugar e se perderia no próximo deploy. E **um rollback nunca faz build**: ele
inicia os processos de uma release anterior, que continua existindo exatamente como era.

## No laboratório

A imagem que o Compose construiu é `quitanda/catalogue:dev`. **Construir de novo para fazer uma versão
quebraria o fator**: um segundo build é um segundo artefato, e nada garante que ele bate com o que foi
testado. Dê outro nome ao build que você já tem, e liste as imagens do catálogo:

```
ana@vm:~/lab/twelve$ docker tag quitanda/catalogue:dev quitanda/catalogue:1.0.0
ana@vm:~/lab/twelve$ docker image ls quitanda/catalogue
IMAGE                      ID             DISK USAGE   CONTENT SIZE   EXTRA
quitanda/catalogue:1.0.0   54ee8d968ec5        220MB         53.1MB   U    
quitanda/catalogue:dev     54ee8d968ec5        220MB         53.1MB   U    
```

**As duas tags apontam para o mesmo id de imagem**: uma tag é um nome para um build, e dois nomes podem
dividir um. Uma release numa plataforma de verdade fixa o build pelo digest, `sha256:…`, e não pela
tag, porque uma tag pode ser movida para outra imagem depois e um digest não.

O `compose.yaml` chama a imagem de `quitanda/catalogue:${TAG:-dev}`, então rodar uma release específica
é iniciá-la com a sua tag:

```
ana@vm:~/lab/twelve$ TAG=1.0.0 docker compose up -d catalogue
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
ana@vm:~/lab/twelve$ docker compose ps catalogue --format "{{.Name}} {{.Image}} {{.Status}}"
twelve-catalogue-1 quitanda/catalogue:1.0.0 Up Less than a second
```

O Compose recriou o contêiner porque o nome da imagem mudou, de `:dev` para `:1.0.0`. Um rollback numa
plataforma é a mesma operação com um número anterior. As plataformas guardam a lista de releases para
você: o Heroku as numera, o Kubernetes guarda o histórico de revisões de um Deployment e
`kubectl rollout undo` volta para a anterior, e um pipeline que implanta por digest consegue reimplantar
qualquer digest anterior.
