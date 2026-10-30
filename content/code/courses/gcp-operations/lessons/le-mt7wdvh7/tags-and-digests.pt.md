---
title: Uma tag é um rótulo que se move; um digest é a imagem
version: 1
---

**Uma tag aponta para uma imagem, e enviar de novo a move. Um digest é a impressão digital da própria
imagem, e não pode apontar para outra coisa.** Um digest é o SHA-256 do manifesto da imagem, então duas
imagens diferentes não podem compartilhar um, e a mesma imagem tem o mesmo digest em todo registro para
onde for copiada. Um deploy que nomeia uma tag roda o que quer que a tag aponte quando ele baixa; um
deploy que nomeia um digest roda uma imagem, sempre.

Construa a API da loja com uma tag no registro local, envie, e peça ao Docker o digest que o registro
devolveu:

```sh
docker build -q -t localhost:5000/shop/api:v1 api
```

```
ana@laptop:~/gcp/shop$ docker push -q localhost:5000/shop/api:v1
localhost:5000/shop/api:v1
ana@laptop:~/gcp/shop$ docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:v1
localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
```

Agora mude o código. Acrescente um terceiro produto a `PRODUCTS` em `api/app.py`, abaixo do estojo:

```python
    {"id": "p-003", "name": "Eraser", "price_cents": 390},
```

Construa de novo com **a mesma tag**, e envie:

```
ana@laptop:~/gcp/shop$ grep -c price_cents api/app.py
3
ana@laptop:~/gcp/shop$ docker push -q localhost:5000/shop/api:v1
localhost:5000/shop/api:v1
ana@laptop:~/gcp/shop$ docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:v1
localhost:5000/shop/api@sha256:f35a09acfff5676670ca95f02f72479bbc8a1173d716feb33787ae3a89e18c1d
ana@laptop:~/gcp/shop$ curl -s localhost:5000/v2/shop/api/tags/list; echo
{"name":"shop/api","tags":["v1"]}
```

O registro aceitou o segundo envio sem dizer nada. Continua havendo uma tag, `v1`, e agora ela aponta
para outra imagem, `f35a…`. **Tudo o que baixar `v1` daqui em diante recebe a borracha**, inclusive uma
máquina que reinicia amanhã rodando o que ela acredita ser o release de ontem, e um rollback "para a v1"
que na verdade avança. Nada nos dois envios disse que algo tinha mudado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A tag v1 aparece duas vezes. Antes do segundo envio, ela aponta para a imagem de digest sha256:7f5d, com dois produtos. Depois do envio, aponta para sha256:f35a, com três. A primeira imagem continua no registro, sem tag, e alcançável pelo digest.\"><defs><marker id=\"ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a mesma tag, antes e depois do segundo envio</text><rect x=\"20\" y=\"60\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">v1</text><text x=\"65\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes</text><rect x=\"20\" y=\"130\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">v1</text><text x=\"65\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois</text><rect x=\"300\" y=\"50\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:7f5dda35…</text><text x=\"500\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dois produtos; sem tag depois do envio</text><rect x=\"300\" y=\"120\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:f35a09ac…</text><text x=\"500\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três produtos</text><line x1=\"112\" y1=\"75\" x2=\"298\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><line x1=\"112\" y1=\"145\" x2=\"298\" y2=\"145\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line></svg>", "caption": "Enviar de novo moveu o rótulo. As duas imagens continuam lá; só uma tem nome."}
```

A primeira imagem não sumiu. A tag saiu dela, e ela ainda pode ser baixada pelo digest:

```
ana@laptop:~/gcp/shop$ docker pull -q localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
ana@laptop:~/gcp/shop$ docker run --rm -d --name api -p 8080:8080 localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
854df6e7fd771402869f6a6bca79c31816ac8a03d02629fd9ff5ddf4760e7f5d
ana@laptop:~/gcp/shop$ curl -s localhost:8080/products; echo
[{"id": "p-001", "name": "Notebook", "price_cents": 2490}, {"id": "p-002", "name": "Pencil case", "price_cents": 1890}]
```

Dois produtos: a imagem de antes da mudança, exatamente. Uma imagem da qual todas as tags saíram fica
**sem tag** (untagged), e é o tipo de imagem que uma política de limpeza apaga, na próxima seção.

## Qual escrever onde

| onde | escreva | por quê |
|---|---|---|
| o `images` de um build e o envio dele | uma tag do commit, `$SHORT_SHA` | uma pessoa consegue ler de que commit a imagem veio |
| um deploy, um release, um manifesto do Kubernetes | o digest | o que roda não pode mudar por baixo dele |
| a conversa entre pessoas | a tag | ninguém lê um digest em voz alta |

O Cloud Run já faz o segundo por você: uma revisão registra o digest para onde a tag apontava quando a
revisão foi criada, então um envio posterior para a tag não muda uma revisão em execução. Uma máquina
do Compute Engine com um script de inicialização que baixa `:latest` não faz isso, e a lição 3 faz deploy
por digest por esse motivo.
