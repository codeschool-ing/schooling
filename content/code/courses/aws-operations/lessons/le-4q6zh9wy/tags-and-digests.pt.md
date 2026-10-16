---
title: Uma tag é um nome, um digest é a imagem
version: 1
---

A imagem comum de `shop/api:latest` é que ela nomeia uma imagem. **Ela nomeia um ponteiro**, e o
ponteiro pode ser movido pelo próximo push. O que identifica uma imagem é o **digest** dela:
`sha256:` seguido de um hash do manifesto da imagem, o pequeno documento JSON que lista as camadas.
Mude um byte de uma camada e o digest da camada muda, então o manifesto muda, então o digest da
imagem muda. Duas imagens com o mesmo digest são a mesma imagem; duas imagens com a mesma tag podem
não ter nada em comum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois repositórios lado a lado. No mutável, shop/web, a tag latest primeiro aponta para o build A, digest sha256:f75f, e depois de um segundo push aponta para o build B, digest sha256:29c5; o build A fica sem nome. No imutável, shop/api, a tag 1.4.0 aponta para o build A para sempre, enquanto o build B leva duas tags, 1.4.1 e 3f9c2a1b7e40; um segundo push de 1.4.0 é recusado.\"><defs><marker id=\"tag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"330\" height=\"258\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">repositório mutável: shop/web</text><rect x=\"40\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">latest</text><rect x=\"200\" y=\"60\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build A</text><text x=\"265.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:f75f…</text><rect x=\"200\" y=\"150\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build B</text><text x=\"265.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:29c5…</text><path d=\"M132 80 L198 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#tag-ah)\"></path><path d=\"M132 92 L160 92 L160 170 L198 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><text x=\"30\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Segundo push: a tag passa para B.</text><text x=\"30\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A fica sem nome nenhum.</text><rect x=\"374\" y=\"16\" width=\"330\" height=\"258\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"388\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">repositório imutável: shop/api</text><rect x=\"392\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1.4.0</text><rect x=\"392\" y=\"140\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1.4.1</text><rect x=\"392\" y=\"182\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3f9c2a1b7e40</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build A</text><text x=\"625.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:f75f…</text><rect x=\"560\" y=\"150\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build B</text><text x=\"625.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:29c5…</text><path d=\"M504 85 L558 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><path d=\"M504 155 L558 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><path d=\"M504 197 L558 185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><text x=\"388\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Um segundo push de 1.4.0 é recusado.</text></svg>", "caption": "Os digests são os dois builds do laboratório desta lição. Uma tag mutável é um ponteiro que o próximo push move; uma imutável é um nome dado uma vez só.", "same": ["build A", "build B"]}
```

## O que um push envia

O `docker push` faz duas coisas, e só a segunda tem a ver com nomes. Ele envia cada camada que o
registro ainda não tem, como um blob endereçado pelo digest. Depois envia o manifesto com uma tag, e
o registro anota que a tag agora aponta para o digest do manifesto. Contra um registro de verdade, de
uma máquina com Docker, isso é:

```sh
aws ecr get-login-password | docker login --username AWS --password-stdin 123456789012.dkr.ecr.sa-east-1.amazonaws.com
docker build -t 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/api:1.4.0 .
docker push 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/api:1.4.0
```

**Esses três comandos não foram executados para este curso**: o moto não fala o protocolo de
registro que o `docker push` usa. Ele responde a `PutImage`, a chamada de API que registra um
manifesto com uma tag, que é o último passo de um push. Então o laboratório desta lição escreve dois
manifestos à mão, como dois builds do front-end da loja os produziriam, diferindo na única camada em
que o código mudou:

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": 1470,
    "digest": "sha256:9c7a54a9a43cca047013b82af109fe963fde787f63f9e016fdc3384500c2823d"
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": 29724688,
      "digest": "sha256:c6a83fedfae6ed8a4f5f7cbb6a7b6f1c1ec3d86fea8cb9e5ba2e01e6a87b2a6e"
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": 412933,
      "digest": "sha256:3f1b0d6c4e2a8b9f7d5c3e1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c"
    }
  ]
}
```

## A tag que mudou de lugar

O repositório do front-end foi criado com o padrão, tags **mutáveis**. A esteira envia cada build
como `latest`:

```
ana@laptop:~/aws/ecr$ aws ecr create-repository --repository-name shop/web --query repository.imageTagMutability
"MUTABLE"
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://build-a.json --query image.imageId.imageDigest --output text
sha256:f75f6a0bd9a18e062a99e28be6c7cfd04509c65060939669e110da25bf700ad3
ana@laptop:~/aws/ecr$ diff build-a.json build-b.json
17,18c17,18
<       "size": 412933,
<       "digest": "sha256:3f1b0d6c4e2a8b9f7d5c3e1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c"
---
>       "size": 415007,
>       "digest": "sha256:7a2e9c1d5b3f8e6a7d5c3e1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c"
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://build-b.json --query image.imageId.imageDigest --output text
sha256:29c52796acf6ec53f1dd957d4a08f457f117c5935c785f7cf3cdc30cecd86a94
ana@laptop:~/aws/ecr$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags[0]]' --output text
sha256:29c52796acf6ec53f1dd957d4a08f457f117c5935c785f7cf3cdc30cecd86a94	latest
```

Dois pushes, dois digests, uma tag. O moto calcula o digest a partir dos digests das camadas, onde um
registro faz o hash dos bytes do manifesto, mas a consequência é a mesma: conteúdo diferente, digest
diferente. **Depois do segundo push, `latest` nomeia o build B, e nada diz que um dia nomeou o build
A.** No ECR, o build A continuaria no repositório sem tag nenhuma, custando armazenamento; o moto o
descartou.

Agora imagine a manhã seguinte. Uma tarefa do front-end reinicia e puxa `latest`, então roda o build
B, enquanto as vizinhas que começaram ontem ainda rodam o build A. O serviço roda duas versões e todo
painel as chama de uma só. Reverter significa enviar A de novo como `latest`, se alguém ainda
conseguir descobrir qual imagem era A. **Um deploy que nomeia uma tag implanta o que a tag aponta no
momento em que cada máquina pergunta**, e esse é o problema que a próxima seção fecha.
