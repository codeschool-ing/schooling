---
title: O Langfuse no laboratório
version: 1
---

O laboratório roda o Langfuse 3.225.11 a partir das imagens oficiais, com o arquivo compose em
`lab/langfuse/docker-compose.yml`, iniciado por `sudo bash lab.sh langfuse`. Ele cria uma organização,
um projeto chamado `support-assistant`, as duas chaves de API do projeto e um usuário ao iniciar, a
partir das configurações `LANGFUSE_INIT_*`, para que nenhuma tela de cadastro precise ser clicada. As
chaves são do laboratório, e estão no ambiente da ana como `LANGFUSE_PUBLIC_KEY` e
`LANGFUSE_SECRET_KEY`.

```
ana@lab:~/obs$ curl -s $LANGFUSE_HOST/api/public/health; echo
{"status":"OK","version":"3.225.11"}
```

## Seis contêineres

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Os seis contêineres do Langfuse. O assistente manda spans por OTLP ao servidor web. O servidor web grava cada lote recebido no armazenamento de objetos (MinIO) e põe uma tarefa numa fila (Redis). O worker pega a tarefa, lê o lote e grava traces e observações no ClickHouse. O PostgreSQL guarda usuários, projetos, chaves, preços de modelos e prompts. O servidor web lê do ClickHouse e do PostgreSQL para responder às telas e à API.\"><rect x=\"150\" y=\"14\" width=\"556\" height=\"256\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"12\" y=\"112\" width=\"116\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">assistant.py</text><text x=\"70\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\"></text><rect x=\"172\" y=\"112\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">web</text><text x=\"242\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">telas, API, OTLP</text><rect x=\"360\" y=\"30\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MinIO</text><text x=\"435\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada lote, como chegou</text><rect x=\"360\" y=\"112\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Redis</text><text x=\"435\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a fila</text><rect x=\"546\" y=\"112\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">worker</text><text x=\"619\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquiva o que chegou</text><rect x=\"546\" y=\"200\" width=\"146\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ClickHouse</text><text x=\"619\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">traces, observações, notas</text><rect x=\"172\" y=\"200\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"242\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"242\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">projetos, chaves, preços</text><path d=\"M128 136 L172 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">OTLP / HTTP</text><path d=\"M312 124 L360 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M312 136 L360 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M510 136 L546 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 124 L510 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M619 160 L619 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M546 224 L312 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M242 160 L242 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "O que chega é guardado primeiro e processado depois. Um trace só está na API depois que o worker o arquivou."}
```

| contêiner | o que guarda | por que é separado |
|---|---|---|
| `web` | as telas, a API pública, e o endpoint que recebe OTLP | é com ele que pessoas e programas falam |
| `worker` | nada; ele põe no lugar o que chegou | a ingestão pode atrasar sem deixar as telas lentas |
| `postgres` | usuários, projetos, chaves, preços de modelos, prompts | pequeno, relacional, muda pouco |
| `clickhouse` | traces, observações, notas | grande, só cresce, lido por agregação |
| `redis` | a fila entre `web` e `worker` | para que uma rajada de traces espere em vez de falhar |
| `minio` | cada lote que chegou, como chegou | armazenamento compatível com S3; a fonte que o worker lê |

É mais maquinaria que o binário único do Jaeger, e é o preço de um banco feito para as perguntas das
próximas seções: somas de tokens e de custo por dia e por usuário sobre milhões de observações. Isso
também tem uma consequência que as transcrições mostram: **um span enviado agora não está na API
agora**. Ele está na fila, depois no worker, depois no ClickHouse. As capturas esperam vinte segundos
depois de cada reprodução, o que é preparado e não aparece.

Cada segredo daquele arquivo compose, `SALT`, `ENCRYPTION_KEY` e `NEXTAUTH_SECRET`, é um valor do
laboratório que não abre nada. Uma instalação de verdade gera os seus, os mantém fora do arquivo, e põe
o servidor web atrás de HTTPS; o laboratório o publica só em 127.0.0.1.
