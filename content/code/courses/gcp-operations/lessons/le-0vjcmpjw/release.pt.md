---
title: Um release é renderizado uma vez e promovido sem mudança
version: 1
---

**Um release é um retrato: os manifestos para cada alvo, renderizados no momento em que ele é criado,
com a imagem fixada por digest.** Promovê-lo para `prod` faz o deploy do que foi renderizado para `prod`
quando o release foi feito. Nada é reconstruído, nada é renderizado de novo, e um envio ao registro
depois da criação do release não muda nada nele. É isso que dá sentido a uma promoção: o que chega à
produção é a coisa que rodou em `dev`, não algo construído de novo a partir do mesmo commit.

O release, criado no fim do build da lição 1, seria assim (não executado):

```sh
gcloud deploy releases create rel-a1b2c3d \
  --delivery-pipeline=shop-api \
  --region=southamerica-east1 \
  --images=shop-api=southamerica-east1-docker.pkg.dev/planner-dev/shop/api:a1b2c3d
```

`--images` liga o nome nos manifestos à imagem que o build enviou, pela tag. O Cloud Deploy resolve a
tag para o digest naquele momento e renderiza cada alvo com o digest, então a tag se mover depois, como
na lição 2, não alcança um release que já existe. O release então vai sozinho para o primeiro alvo,
`dev`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma fila de quatro caixas ligadas por setas: um build produz uma imagem identificada pelo digest; uma release renderiza os manifestos de cada alvo com esse digest; o alvo dev a roda; uma promoção, com uma aprovação no caminho, roda a mesma release em prod. Nada é reconstruído entre dev e prod.\"><defs><marker id=\"ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">build</text><text x=\"90\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma imagem</text><rect x=\"200\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">release</text><text x=\"270\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manifestos, renderizados</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">alvo dev</text><text x=\"450\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda o digest</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">alvo prod</text><text x=\"630\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o mesmo digest</text><line x1=\"162\" y1=\"70\" x2=\"198\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><line x1=\"342\" y1=\"70\" x2=\"378\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><line x1=\"522\" y1=\"70\" x2=\"558\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><text x=\"540\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aprovação</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:… fixed at release time, from dev to prod</text></svg>", "caption": "A release fica fixa quando é criada. A promoção a move; nunca a reconstrói.", "same": ["build", "release"]}
```

## A mesma propriedade, no seu computador

O Cloud Deploy não roda aqui, mas a propriedade que ele existe para garantir pode ser mostrada com dois
contêineres. Abaixo, `dev` e `prod` são dois contêineres em duas portas, e **isto não é o Cloud
Deploy**; é o que uma promoção deixa para trás. A imagem que o build enviou como `a1b2c3d` é baixada, e
o digest dela é de onde os dois ambientes partem:

```
ana@laptop:~/gcp/shop$ docker pull -q localhost:5000/shop/api:a1b2c3d
localhost:5000/shop/api:a1b2c3d
ana@laptop:~/gcp/shop$ docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:a1b2c3d
localhost:5000/shop/api@sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
```

O registro local da lição 2 está rodando de novo aqui, já com a imagem dentro. `dev` roda o digest e
responde ao health check:

```
ana@laptop:~/gcp/shop$ docker run -d --rm --name dev -p 8081:8080 localhost:5000/shop/api@sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
dcd13fb546667ac8fbc067d3c95e81495bf685f93fc4096c7582d44124900097
ana@laptop:~/gcp/shop$ curl -s localhost:8081/healthz; echo
{"status": "ok"}
```

Depois a promoção: `prod` a partir do mesmo digest, e os dois contêineres perguntados sobre qual imagem
rodam:

```
ana@laptop:~/gcp/shop$ docker run -d --rm --name prod -p 8082:8080 localhost:5000/shop/api@sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
d46ff18324ca73a2a333a56dfe470e2d74336ab952a06f9efe36f0148fcc46c0
ana@laptop:~/gcp/shop$ docker inspect --format '{{.Name}} {{.Image}}' dev prod
/dev sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
/prod sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
ana@laptop:~/gcp/shop$ curl -s localhost:8082/healthz; echo
{"status": "ok"}
```

**Uma imagem, dois ambientes.** Se `prod` tivesse sido iniciado pela tag depois de alguém enviar para
ela, as duas linhas difeririam, e os testes que passaram em `dev` não diriam nada sobre o que roda em
produção. O release do Cloud Deploy é o registro de que elas não diferem, guardado pelo Google em vez de
por quem digitou o comando.

## O que difere, e o que não pode diferir

| entre `dev` e `prod` | difere? |
|---|---|
| a imagem | **nunca**: um digest |
| o nome do serviço, a escala, a memória | sim, pelo perfil |
| o endereço do banco e os nomes dos segredos | sim, pelo perfil |
| a conta de serviço que faz deploy | sim, pelo alvo |

Uma diferença na primeira linha é outro release, e o jeito de ter um é um build novo e um release novo,
nunca uma edição no caminho para a produção.
