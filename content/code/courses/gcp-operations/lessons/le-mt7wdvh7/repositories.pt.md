---
title: Um repositório é um lugar, um formato e uma região
version: 1
---

**O Artifact Registry guarda artefatos em repositórios, e um repositório tem três propriedades que nunca
mudam depois de criado: o formato, a localização e o nome.** O formato diz o que ele guarda: imagens
Docker, pacotes Python, pacotes npm, artefatos Maven, pacotes Debian ou RPM, e mais alguns, um formato
por repositório. A localização é uma região, como `southamerica-east1`, ou uma multirregião, como `us`.
O nome é seu. Juntos formam o endereço com que a lição anterior construiu uma imagem:

```localised
southamerica-east1-docker.pkg.dev / planner-dev / shop / api : v1
└──── location and format ──────┘   └project┘   └repo┘ └image┘ └tag┘
```

Então uma imagem não pode ir para outra região editando nada. Um repositório na região errada é um
repositório novo e uma cópia, e todo deploy que nomeia o endereço antigo precisa mudar. As imagens da
loja vivem em São Paulo porque os serviços que as baixam rodam lá: um pull da mesma região não tem
cobrança de transferência, e um de outro continente tem.

O repositório da loja, como o `gcloud` o cria:

```sh
gcloud artifacts repositories create shop \
  --repository-format=docker \
  --location=southamerica-east1 \
  --description="The shop's container images"
```

Ele não foi executado: nenhum emulador responde pelo Artifact Registry. Há três **modos**, e o comando
acima cria o primeiro, o padrão:

| modo | o que faz |
|---|---|
| padrão (standard) | guarda o que você envia a ele |
| remoto (remote) | um cache na frente de outro registro, como o Docker Hub, mantido no seu projeto |
| virtual | um endereço na frente de vários repositórios, consultados numa ordem que você define |

Um repositório **remoto** é a resposta ao limite de pulls anônimos que a lição anterior evitou com
`mirror.gcr.io`: o build baixa do seu próprio cache na sua própria região, e só o primeiro pull de cada
imagem vai ao Docker Hub.

## Um registro no seu computador

O que um repositório Docker faz na rede é o protocolo de registro, o mesmo que o Docker Hub e qualquer
outro registro falam. O registro de código aberto que o define roda como contêiner, e é para ele que
esta lição envia. Ele guarda e serve imagens, e só: não tem repositórios com formato, nem regiões, nem
permissões, nem tags imutáveis, nem varredura. Tudo nesta lição além do envio e do download é ensinado
pela documentação do Google.

```
ana@laptop:~/gcp/shop$ docker run -d --rm --name registry -p 5000:5000 mirror.gcr.io/library/registry:3.0.0
4f7e2f37f36b54ddc3297709d5d9b6b5c47e9aa90599c9a2e6a7dc8661a22284
ana@laptop:~/gcp/shop$ curl -s localhost:5000/v2/_catalog; echo
{"repositories":[]}
```

`/v2/_catalog` é a lista de imagens que ele guarda, vazia por enquanto. O endereço dele é
`localhost:5000`, onde o do Artifact Registry é `southamerica-east1-docker.pkg.dev`; o resto do nome
funciona igual. Os arquivos da loja da lição 1 continuam em `~/gcp/shop`: só os emuladores esquecem, e
os seus próprios arquivos ficam onde você os escreveu.

## Quem pode baixar

O acesso a um repositório é IAM no repositório: `roles/artifactregistry.reader` para baixar,
`roles/artifactregistry.writer` para enviar, concedidos a uma conta de serviço em vez de ao projeto. A
conta de build da loja da lição 1 é writer no `shop` e em nada mais; a conta que roda a API é reader.
**Um reader no projeto inteiro pode baixar cada imagem de cada repositório**, o que inclui as que
carregam o código de outro time.
