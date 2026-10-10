---
title: IV, serviços de apoio são recursos conectados
version: 1
---

Um **serviço de apoio** é qualquer coisa que o programa usa pela rede para fazer o seu trabalho: um
banco, uma fila, um cache, um serviço de e-mail, um armazenamento de objetos. O fator pede que o
programa **não faça distinção entre um rodado pela sua própria equipe e um comprado de um provedor**:
cada um é um recurso na ponta de uma URL, conectado pela configuração, e substituível mudando essa
configuração.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O processo do catálogo à esquerda guarda só uma URL. Ela aponta para o banco db; uma seta tracejada mostra a mesma configuração mudada para apontar para outro banco, other-db, sem mudança no código.\"><defs><marker id=\"l4-backing-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l4-backing-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"70\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">catalogue</text><text x=\"150\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DATABASE_URL=…</text><rect x=\"470\" y=\"30\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">db</text><rect x=\"470\" y=\"130\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"570\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">other-db</text><path d=\"M262 95 L468 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-backing-ah-phosphor)\"></path><path d=\"M262 125 L468 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l4-backing-ah-wire)\"></path><text x=\"365\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mudar a URL</text></svg>", "caption": "Um serviço de apoio é um recurso na ponta de uma URL. Apontar a URL para outro lugar conecta outro, sem mudança no código."}
```

O banco do catálogo é nomeado só em `DATABASE_URL`. Para provar, inicie um segundo PostgreSQL, vazio,
na mesma rede, com outro nome, e aponte o catálogo para ele. `--network twelve_default` põe o contêiner
novo na rede que o Compose criou para o projeto, onde o catálogo consegue achá-lo pelo nome:

```
ana@vm:~/lab/twelve$ docker run -d --name other-db --network twelve_default -e POSTGRES_USER=quitanda -e POSTGRES_PASSWORD=quitanda postgres:17
1957aa2b6ec8e840082457b9c55585aa2d4fbfd0168b033e2163d6660e14e9b6
ana@vm:~/lab/twelve$ DATABASE_URL=postgresql://quitanda:quitanda@other-db:5432/quitanda docker compose up -d catalogue
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
ana@vm:~/lab/twelve$ docker compose port catalogue 8000
127.0.0.1:8001
ana@vm:~/lab/twelve$ curl -sS 127.0.0.1:8001/products
curl: (52) Empty reply from server
```

O catálogo foi recriado com a URL nova e nada mais mudou. **A porta dele pode ter mudado, porém**: o
`compose.yaml` publica a faixa `8000-8002`, e o Docker dá ao contêiner novo a porta da faixa que
estiver livre naquele momento, então `docker compose port` é o jeito de perguntar qual ele recebeu.
É o fator VII, duas seções antes: a plataforma, e não o programa, decide a porta de fora.

A primeira requisição falha, o que é o correto: `other-db` é outro banco e não tem tabela `products`.
O traceback está no log do catálogo; o `curl` só vê a conexão fechada. Rode a tarefa administrativa
contra o banco novo e pergunte de novo:

```
ana@vm:~/lab/twelve$ DATABASE_URL=postgresql://quitanda:quitanda@other-db:5432/quitanda docker compose run --rm catalogue python catalogue.py migrate
 Container twelve-db-1 Running 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-run-5b9df4d36017 Creating 
 Container twelve-catalogue-run-5b9df4d36017 Created 
migrated: 5 products
ana@vm:~/lab/twelve$ curl -s 127.0.0.1:8001/products
{"served_by": "9586548804c3", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

A mesma imagem, conectada a outro recurso, mudando uma variável. É isso que transforma ir para um
banco gerenciado, restaurar um backup num servidor novo, ou apontar uma rodada de testes para uma
cópia descartável numa mudança de configuração em vez de uma mudança de código.

Conecte o original de novo recriando o catálogo sem a variável, para o padrão do `compose.yaml` valer,
e remova o segundo banco:

```
ana@vm:~/lab/twelve$ docker compose up -d catalogue
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
ana@vm:~/lab/twelve$ docker rm -f other-db
other-db
ana@vm:~/lab/twelve$ docker compose port catalogue 8000
127.0.0.1:8002
ana@vm:~/lab/twelve$ curl -s 127.0.0.1:8002/products
{"served_by": "2a00288d3d2d", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

## O que o fator não promete

Trocar o endereço não torna dois serviços de apoio intercambiáveis. Um programa escrito para
PostgreSQL não roda contra MySQL porque a URL mudou; uma fila com garantias de entrega diferentes, aula
7, se comporta de outro jeito atrás do mesmo cliente. O fator é sobre **onde o recurso está**, não sobre
fingir que todo recurso de um tipo é igual.
