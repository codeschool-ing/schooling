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
