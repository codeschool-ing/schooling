---
title: Migrações e versões
version: 1
---

Uma versão é uma imagem nova, uma migração e um reinício, nessa ordem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 172\" role=\"img\" aria-label=\"Quatro passos de uma versão: construir a imagem com uma tag nova; rodar a migração uma vez com compose run; subir os contêineres novos com compose up; conferir com check --deploy e uma requisição. A migração roda antes de o código novo subir, enquanto o código antigo ainda pode estar servindo, então ela precisa deixar um esquema que as duas versões consigam usar.\"> <defs><marker id=\"rl-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"97\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">construir</text> <text x=\"97\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">docker build -t agenda:0.1.1</text> <path d=\"M175 78 L191 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rl-a)\"></path> <rect x=\"195\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"272\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">migrar</text> <text x=\"272\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">compose run --rm web migrate</text> <path d=\"M350 78 L366 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rl-a)\"></path> <rect x=\"370\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"447\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">subir</text> <text x=\"447\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">compose up -d</text> <path d=\"M525 78 L541 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rl-a)\"></path> <rect x=\"545\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"622\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">conferir</text> <text x=\"622\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">check --deploy, curl</text> <text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A migração roda uma vez, antes de o código novo subir, enquanto o antigo ainda pode estar servindo:</text> <text x=\"360\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">então ela precisa deixar um esquema que as duas versões consigam usar.</text> </svg>", "caption": "Uma versão em ordem. Uma migração dentro do comando de início do contêiner rodaria uma vez por réplica, todas no mesmo instante."}
```

## Por que a migração é um passo próprio

Um comando como `migrate && gunicorn` na imagem parece arrumado. Rode três cópias do serviço web, ou
reinicie uma com um deploy pela metade, e três migrações começam no mesmo instante contra um banco. O
Django e o Alembic registram quais migrações rodaram, mas nenhum promete que dois processos migrando ao
mesmo tempo seja seguro. **Um contêiner, uma vez, antes de o código novo subir**, como a seção anterior
fez com `docker compose run --rm`.

## Migrações com que as duas versões convivem

Durante uma versão o código antigo continua servindo enquanto a migração roda, e depois dela o código
novo sobe. Uma migração que **acrescenta** uma coluna que aceita nulo, como o `organiser` da aula 12, não
faz mal ao código antigo, que nem sabe que a coluna existe. Uma migração que **remove ou renomeia** uma
coluna quebra o código antigo na hora, no meio da versão. A resposta comum é dividi-la, **expandir e
depois contrair**: uma versão acrescenta a coluna nova e escreve nas duas, uma seguinte passa as
leituras, e só uma terceira apaga a coluna antiga, quando nenhum código rodando a usa. A renomeação de
`venue` da aula 10 é exatamente a mudança que precisa de três versões num site no ar.

## Com o que uma versão é conferida

```
ana@vm:~/deploy$ docker compose exec web python manage.py check --deploy 2>&1 | grep "^?:" | cut -c1-72
?: (security.W005) You have not set the SECURE_HSTS_INCLUDE_SUBDOMAINS s
?: (security.W021) You have not set the SECURE_HSTS_PRELOAD setting to T
```

Os dois avisos deliberados de HSTS da aula 16, e mais nada; a chave secreta tem tamanho suficiente
porque foi gerada com cinquenta bytes, como a da aula 15. Uma chave com menos de cinquenta caracteres
ganha um aviso próprio, que é a conferência fazendo o seu trabalho.

```
ana@vm:~/deploy$ docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -4
REPOSITORY    TAG         SIZE
agenda-api    0.1.0       347MB
agenda        0.1.0       381MB
python        3.12-slim   179MB
```

**Uma imagem é nomeada pela tag**, aqui `0.1.0`. Uma versão constrói uma tag nova a partir de um commit
novo, a envia a um registro de que o servidor consegue baixar, e muda o `image:` no arquivo do compose.
Voltar atrás é mudar a tag de volta, desde que o banco ainda sirva ao código antigo, que é para o que
serve expandir e contrair. Uma tag como `latest`, que se move, não diz nada sobre qual código está
rodando.

```
ana@vm:~/deploy$ docker compose down 2>&1 | tail -1
 Network deploy_default Removed 
```

## Onde isso deixa o agenda

As mesmas duas aplicações agora rodam de três jeitos, cada um a partir do anterior: num notebook com
`uv run`, num servidor sob o systemd atrás do nginx, e como contêineres a partir de um arquivo do
compose. O nginx da aula 16 continua na frente no último caso também, repassando para `127.0.0.1:8000` e
`127.0.0.1:8001` exatamente como antes, porque os contêineres publicam as mesmas portas que os serviços
usavam.
