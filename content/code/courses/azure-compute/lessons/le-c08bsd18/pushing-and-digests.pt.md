---
title: O push, e o digest que dá nome a uma imagem
version: 1
---

Um push parece o upload de uma coisa só chamada `shop:1.0`. **Um registry guarda blobs nomeados
pelo seu SHA-256, e um pequeno documento JSON, o manifest, que os lista.** A tag é um rótulo posto
num manifest, e o hash do próprio manifest, o seu *digest*, é o nome que nada consegue mover. Esta
seção faz o push da loja, lê pela API do registry o que chegou, baixa de volta pelo digest e depois
move uma tag para mostrar do que um digest protege você.

## Um registry no seu laptop

Não há registry do Azure neste curso. O que faz o papel de um é o **distribution registry**, o
registry de código aberto que começou na Docker e hoje é um projeto da CNCF, publicado como a imagem
`registry:3`. Ele fala a API de distribuição OCI, a mesma API HTTP que `shopregistry.azurecr.io`
fala com o Docker, então cada pedido abaixo tem o mesmo formato contra o ACR. Ele não é o ACR: não
há login, nem tier, nem replicação, nem scan, e as seções seguintes dizem onde essas coisas entram.

Inicie-o com o armazenamento num volume nomeado, para as imagens sobreviverem ao contêiner. O `-d`
deixa o terminal livre e imprime o id do contêiner:

```
ana@laptop:~/azure$ docker run -d --name registry -p 5000:5000 -v shop-registry:/var/lib/registry registry:3 | cut -c1-12
a210baede287
ana@laptop:~/azure$ curl -s -i localhost:5000/v2/ | grep -i -E '^HTTP|^docker-distribution'
HTTP/1.1 200 OK
Docker-Distribution-Api-Version: registry/2.0
```

`/v2/` é a porta de entrada da API, e o cabeçalho diz qual versão do protocolo responde.

## O push

Faça o build da loja com os dois arquivos da lição 7, `~/azure/shop/app.py` e
`~/azure/shop/Dockerfile`, e dê a ela um segundo nome. **O Docker lê a parte de um nome antes da
primeira barra como o registry para onde enviar**, então `localhost:5000/shop:1.0` significa o
repositório `shop` no registry em `localhost:5000`. No Azure a mesma tag seria
`shopregistry.azurecr.io/shop:1.0`:

```
ana@laptop:~/azure$ docker build --quiet --tag shop:1.0 shop | cut -c1-19
sha256:3e0a1805feba
ana@laptop:~/azure$ docker tag shop:1.0 localhost:5000/shop:1.0
ana@laptop:~/azure$ docker push localhost:5000/shop:1.0
The push refers to repository [localhost:5000/shop]
98de7320882b: Waiting
c6e0519ecc17: Pushed
c7660dcffdbf: Waiting
868de9318199: Waiting
3eb771151506: Pushed
44136fa355b3: Pushed
46a894d7e97f: Pushed
acca7542dfc7: Pushed
c7660dcffdbf: Pushed
868de9318199: Pushed
98de7320882b: Pushed
f574edac59d9: Pushed
6fc242d221a6: Pushed
1.0: digest: sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676 size: 856
```

Cada id é um blob de que a imagem precisa: as camadas, a configuração e a atestação que o Docker 29
anexa a um build, um registro de como ele foi feito. Os ids são os doze primeiros caracteres do
digest de cada blob, e os seus vão ser outros; um blob mostrado como `Waiting` está na fila atrás dos
outros e aparece de novo quando é enviado. **O digest da última linha é o nome da imagem no
registry**, e `size: 856` é o tamanho em bytes do documento de que esse digest é calculado.

## Lendo de volta

Tudo o que um registry guarda pode ser lido com `curl`. O catálogo lista os repositórios, um
repositório lista as tags, e um manifest é buscado pela tag ou pelo digest. O cabeçalho `Accept` diz
que tipos de manifest o cliente entende:

```
ana@laptop:~/azure$ curl -s localhost:5000/v2/_catalog
{"repositories":["shop"]}
ana@laptop:~/azure$ curl -s localhost:5000/v2/shop/tags/list
{"name":"shop","tags":["1.0"]}
ana@laptop:~/azure$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | grep -i -E '^content-type|^docker-content-digest'
Content-Type: application/vnd.oci.image.index.v1+json
Docker-Content-Digest: sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
ana@laptop:~/azure$ curl -s -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | jq -c '.manifests[] | {platform: (.platform.os + "/" + .platform.architecture), digest, size}'
{"platform":"linux/amd64","digest":"sha256:ef188112e7902124d910d0993669bfd411709d9473347c83bd88d05b98e0f72f","size":1812}
{"platform":"unknown/unknown","digest":"sha256:d137d882968c0fb41bb03280fe997398829cadf4fdfa3f2deb8c63e93e1db058","size":837}
ana@laptop:~/azure$ curl -s -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | sha256sum
3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676  -
```

O documento por trás da tag não é um manifest, e sim um **índice**, uma lista de manifests, um por
plataforma. Este cita dois: a imagem para `linux/amd64`, com 1.812 bytes, e a atestação do build,
que leva `unknown/unknown` porque não roda em lugar nenhum. Passados pelo `sha256sum`, os bytes do
índice dão os mesmos 64 caracteres do `Docker-Content-Digest` e do push. **Nada mais entra num
digest**: os mesmos bytes sempre dão o mesmo nome, e um byte mudado em qualquer lugar dá outro.

O manifest da imagem fica um passo abaixo, buscado pelo digest que o índice deu:

```
ana@laptop:~/azure$ M=$(curl -s -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | jq -r '.manifests[0].digest')
ana@laptop:~/azure$ curl -s -H 'Accept: application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/manifests/$M | jq '{mediaType, config: .config.mediaType, last_layer: .layers[-1]}'
{
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": "application/vnd.oci.image.config.v1+json",
  "last_layer": {
    "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
    "digest": "sha256:98de7320882bbf6bbb4ab9e54d8ae97ad20e3bb00c9d8cca7c1c7568b0d02b5e",
    "size": 827
  }
}
```

A última camada é a que o `COPY app.py .` fez, 827 bytes de arquivo comprimido com o programa; as
camadas antes dela são as do `python:3.12-slim` e a da linha `WORKDIR`. Todo tipo de mídia aqui
começa com `application/vnd.oci`, que é como o Docker 29 escreve uma imagem. A seção 04 precisa
desse detalhe, porque um dos recursos de limpeza do ACR lê só os tipos de mídia Docker, mais
antigos.

## Pull pelo digest

Guarde o digest numa variável, remova os dois nomes locais e peça a imagem só pelo digest:

```
ana@laptop:~/azure$ D=$(curl -s -o /dev/null -w '%header{docker-content-digest}' -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0)
ana@laptop:~/azure$ echo $D
sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
ana@laptop:~/azure$ docker image rm shop:1.0 localhost:5000/shop:1.0
Untagged: shop:1.0
Untagged: localhost:5000/shop:1.0
Deleted: sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
ana@laptop:~/azure$ docker pull localhost:5000/shop@$D
localhost:5000/shop@sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676: Pulling from shop
Digest: sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
Status: Downloaded newer image for localhost:5000/shop@sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
localhost:5000/shop@sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
ana@laptop:~/azure$ docker image ls --digests --format "{{.Repository}}  {{.Tag}}  {{.Digest}}" localhost:5000/shop
localhost:5000/shop  <none>  sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
```

A imagem voltou, e o `docker image ls` a lista sem tag nenhuma: o que você tem é identificado pelo
que ele é. Um nome com `@sha256:` é aceito em todo lugar onde se nomeia uma imagem. O grupo de
contêineres da lição 7, o Container App da lição 8 e os pods da lição 11 aceitariam
`shopregistry.azurecr.io/shop@sha256:` seguido dos 64 caracteres.

## Uma tag que se move

Ponha a mesma imagem também sob `latest`. Toda camada já está no registry, então o push não envia
nada novo, e o digest é o que a `1.0` tem:

```
ana@laptop:~/azure$ docker tag localhost:5000/shop@$D localhost:5000/shop:latest
ana@laptop:~/azure$ docker push localhost:5000/shop:latest | tail -n 1
latest: digest: sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676 size: 856
```

Agora a próxima versão da loja. A versão 1.1 só difere da 1.0 na versão que o `/version` informa,
então o Dockerfile dela, num diretório próprio, parte da imagem do registry e muda uma configuração.
Salve-o como `~/azure/shop-1.1/Dockerfile`:

```dockerfile
# shop-1.1/Dockerfile
FROM localhost:5000/shop:1.0
ENV SHOP_VERSION=1.1
```

Faça o build, dê a ela as tags `1.1` e `latest`, faça push das duas e pergunte ao registry o que
cada tag nomeia:

```
ana@laptop:~/azure$ cat shop-1.1/Dockerfile
# shop-1.1/Dockerfile
FROM localhost:5000/shop:1.0
ENV SHOP_VERSION=1.1
ana@laptop:~/azure$ docker build --quiet --tag localhost:5000/shop:1.1 shop-1.1 | cut -c1-19
sha256:5ae14e5b334e
ana@laptop:~/azure$ docker tag localhost:5000/shop:1.1 localhost:5000/shop:latest
ana@laptop:~/azure$ docker push localhost:5000/shop:1.1
The push refers to repository [localhost:5000/shop]
868de9318199: Layer already exists
98de7320882b: Layer already exists
3eb771151506: Layer already exists
acca7542dfc7: Layer already exists
c7660dcffdbf: Layer already exists
580b1718bd00: Pushed
44136fa355b3: Already exists
6fc242d221a6: Layer already exists
f574edac59d9: Layer already exists
c6e0519ecc17: Layer already exists
1.1: digest: sha256:5ae14e5b334e8b2192e83b1f5cfee8064c619fe7f284fed7903d8e310a7c6f82 size: 856
ana@laptop:~/azure$ docker push localhost:5000/shop:latest | tail -n 1
latest: digest: sha256:5ae14e5b334e8b2192e83b1f5cfee8064c619fe7f284fed7903d8e310a7c6f82 size: 856
ana@laptop:~/azure$ for t in 1.0 1.1 latest; do printf '%-7s' $t; curl -s -o /dev/null -w '%header{docker-content-digest}\n' -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/$t; done
1.0    sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676
1.1    sha256:5ae14e5b334e8b2192e83b1f5cfee8064c619fe7f284fed7903d8e310a7c6f82
latest sha256:5ae14e5b334e8b2192e83b1f5cfee8064c619fe7f284fed7903d8e310a7c6f82
```

**Só uma linha diz `Pushed`**, e toda camada já estava lá, então uma versão que muda uma
configuração ou um arquivo pequeno quase não custa nada ao registry. Depois, as três linhas do
fim. O `latest` foi para o build da 1.1, como mandado. A `1.0` nomeia o digest que nomeava antes,
caractere por caractere, e o mesmo vale para toda cópia daquela imagem, em qualquer lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Três tags, dois índices e os blobs que eles citam. A tag 1.0 aponta para o índice A, o build da 1.0. A tag 1.1 aponta para o índice B. latest apontava para o índice A até o push da 1.1 e agora aponta para o índice B. Cada índice lista uma imagem para linux/amd64 e uma atestação de build. As duas imagens têm as mesmas camadas; só as configs diferem, então o push da 1.1 não enviou camada nenhuma.\"><defs><marker id=\"acr-tags-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"acr-tags-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"85\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tags, que se movem</text><text x=\"330\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">índices, nomeados pelo digest</text><text x=\"600\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">blobs, nomeados pelo digest</text><rect x=\"20\" y=\"52\" width=\"130\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.0</text><rect x=\"20\" y=\"132\" width=\"130\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"85\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">latest</text><rect x=\"20\" y=\"212\" width=\"130\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.1</text><rect x=\"230\" y=\"40\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">índice A, build da 1.0</text><text x=\"330\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">imagem para linux/amd64</text><text x=\"330\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">atestação do build</text><rect x=\"230\" y=\"190\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"330\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">índice B, build da 1.1</text><text x=\"330\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">imagem para linux/amd64</text><text x=\"330\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">atestação do build</text><rect x=\"500\" y=\"36\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">config de A</text><text x=\"600\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem SHOP_VERSION definida</text><rect x=\"500\" y=\"118\" width=\"200\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as mesmas camadas</text><text x=\"600\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">python:3.12-slim, depois app.py</text><rect x=\"500\" y=\"210\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">config de B</text><text x=\"600\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHOP_VERSION=1.1</text><path d=\"M150 70 L228 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M150 156 L228 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M150 144 L228 104\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#acr-tags-ah2)\"></path><text x=\"20\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">antes da 1.1</text><path d=\"M150 230 L228 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 64 L498 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 100 L498 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 210 L498 154\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 246 L498 234\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M40 292 L680 292\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o push da 1.1 não enviou camada: todas já estavam no registry</text></svg>", "caption": "Uma tag aponta para um índice, o índice aponta para imagens, e as imagens apontam para os seus blobs, tudo por digest. Mover o latest mudou um ponteiro; nada do que o índice A cita foi tocado, então quem pede A pelo digest continua recebendo o build da 1.0."}
```

Nada avisou da mudança. Um pull de `latest` hoje de manhã e um pull de `latest` agora dão dois
programas diferentes, e um cluster cujos nós baixaram em momentos diferentes roda os dois atrás de
um nome. Um digest não faz isso, porque é calculado dos bytes em vez de ser atribuído a eles.
**Então um deploy deve nomear o digest**, e deixar a tag para as pessoas: `1.1` diz a quem lê qual
versão é, o digest diz à máquina exatamente quais bytes. A seção 04 mostra o preço dessa escolha. Um
registry que apaga imagens que ninguém marcou com tag vai apagar uma que um deploy ainda nomeia pelo
digest, a menos que a imagem tenha uma tag própria.

No Azure os comandos são os mesmos com o nome longo na frente, depois do `az acr login` da seção
anterior. O registry continua rodando para a seção 04, que apaga algo dele.
