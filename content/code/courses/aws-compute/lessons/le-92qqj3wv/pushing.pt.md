---
title: O push, e do que um push é feito
version: 1
---

`docker push` parece um único upload de uma coisa chamada imagem. **É uma sequência.** O registry
é consultado sobre quais camadas já tem, e as que faltam são enviadas uma a uma. Por último vem um
pequeno arquivo JSON, o manifest, que lista todas elas. O que o registry chama de imagem é esse
manifest, e o digest que dá nome à imagem é o hash do próprio manifest. Esta seção constrói uma
imagem, desmonta, e entrega ao moto a única peça de um push que o moto entende.

## Uma imagem para enviar

O Docker é o que o curso `docker` instala, e a imagem do servidor web é a que a lição 8 rodou. Se
ela ainda não está na sua máquina, faça o pull uma vez:

```sh
docker pull nginx:1.29-alpine
```

A imagem que esta lição envia é esse servidor web com uma página própria. Dois arquivos num
diretório `web` ao lado do seu terminal: a página, escrita pelo primeiro comando abaixo, e este
Dockerfile:

```dockerfile
# web/Dockerfile
FROM nginx:1.29-alpine
COPY index.html /usr/share/nginx/html/index.html
```

```
ana@laptop:~/aws$ echo '<h1>shop 1.0.0</h1>' > web/index.html
ana@laptop:~/aws$ docker build -q --provenance=false -t shop/web:1.0.0 web
sha256:dd3256cc31f2bad262adcc72ff42e9868bb9371c066dc39934c050dd1f1adf47
ana@laptop:~/aws$ docker tag shop/web:1.0.0 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0
ana@laptop:~/aws$ docker image ls --format '{{.Repository}}:{{.Tag}}  {{.ID}}' | grep shop/web
123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0  dd3256cc31f2
shop/web:1.0.0  dd3256cc31f2
```

`--provenance=false` mantém a imagem com um só manifest. Sem ele, o Docker 29 anexa uma
attestation de proveniência, um registro assinado de como a imagem foi construída, e a imagem vira
um índice de dois manifests. É um bom padrão para um pipeline de verdade e uma distração quando se
desmonta uma imagem. O `docker tag` deu à mesma imagem um segundo nome, e **os dois nomes têm o
mesmo id**: pôr uma tag não copia nada.

## O push, como a AWS documenta

Na AWS, estes são os dois comandos que enviam a imagem. **Eles não foram rodados para esta
lição**, porque o moto responde à API do ECR, as chamadas JSON que a linha de comando da AWS faz,
e não ao protocolo de registry que `docker login`, `docker push` e `docker pull` falam. Não há nada
na porta 4567 para onde o Docker possa enviar.

```sh
aws ecr get-login-password --region sa-east-1 |
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.sa-east-1.amazonaws.com
docker push 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0
```

A primeira metade do login é uma chamada de API, então o moto responde:

```
ana@laptop:~/aws$ aws ecr get-login-password
123456789012-auth-token
ana@laptop:~/aws$ aws ecr get-authorization-token --query 'authorizationData[0].[proxyEndpoint,expiresAt]'
[
    "https://123456789012.dkr.ecr.sa-east-1.amazonaws.com",
    "2014-12-31T23:00:00-03:00"
]
```

Na AWS a senha é um token feito a partir das suas credenciais do IAM e **válido por 12 horas**, e
é por isso que um pipeline faz login de novo a cada execução em vez de guardar uma senha. O nome de
usuário é sempre a palavra literal `AWS`. O moto imprime um texto fixo e uma validade em 2014, e os
dois são placeholders: nenhum token do moto abriria um registry de verdade, e aqui nenhum é
necessário.

O que o `docker push` faz em seguida está na referência da API do ECR, chamada por chamada.
`BatchCheckLayerAvailability` pergunta quais camadas da imagem o repositório já guarda. Para cada
uma que falta, `InitiateLayerUpload`, `UploadLayerPart` e `CompleteLayerUpload` a enviam. Depois
`PutImage` é chamado **uma vez**, com o manifest e a tag. Uma camada que o registry já tem é
pulada, então o segundo push de uma imagem que mudou um arquivo pequeno envia muito pouco.

## O manifest, tirado de dentro da imagem

O manifest está dentro da imagem que o Docker já tem, e `docker save` escreve a imagem como um
arquivo de blobs com o nome de seus digests:

```
ana@laptop:~/aws$ docker image inspect --format '{{.Id}}' shop/web:1.0.0
sha256:dd3256cc31f2bad262adcc72ff42e9868bb9371c066dc39934c050dd1f1adf47
ana@laptop:~/aws$ D=$(docker image inspect --format '{{.Id}}' shop/web:1.0.0 | cut -d: -f2)
ana@laptop:~/aws$ docker save shop/web:1.0.0 | tar -xO "blobs/sha256/$D" > manifest.json
ana@laptop:~/aws$ jq '{mediaType, config: .config.digest, layers: [.layers[].size]}' manifest.json
{
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": "sha256:1b730d61533d59a77f6755c7ae771d67f67966d82328658de4d7a34d869a15a5",
  "layers": [
    3864189,
    1870921,
    627,
    956,
    404,
    1210,
    1399,
    20248489,
    231
  ]
}
ana@laptop:~/aws$ sha256sum manifest.json
dd3256cc31f2bad262adcc72ff42e9868bb9371c066dc39934c050dd1f1adf47  manifest.json
```

**O id da imagem é o digest do manifest, e o digest é o SHA-256 dos bytes do manifest.** O
`sha256sum` imprimiu os mesmos 64 caracteres que o `docker image inspect`. Nada mais decide isso,
então duas pessoas que constroem os mesmos bytes obtêm o mesmo digest, e mudar um byte em qualquer
lugar o muda.

O manifest lista um config e nove camadas. As oito primeiras são as camadas do próprio
`nginx:1.29-alpine`, byte a byte, e somam 25.988.195 bytes. A nona é a linha `COPY` do Dockerfile,
e os 231 bytes dela são um arquivo comprimido com o `index.html` dentro. **Esses 25.988.426 bytes,
cerca de 26 MB, são o que o ECR guarda e o que ele cobra**, porque um registry guarda as camadas
comprimidas; o `docker image ls` mostra o tamanho maior, descompactado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma tag e um digest apontam para o mesmo manifest. O manifest lista um config e nove camadas por digest: oito camadas do nginx:1.29-alpine, somando 25.988.195 bytes, e uma de 231 bytes acrescentada pelo COPY. Um push envia primeiro as camadas e o config, e por último o manifest.\"><defs><marker id=\"ecr-anat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma tag, que você escolhe</text><rect x=\"20\" y=\"44\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">shop/web:1.0.0</text><text x=\"110\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um digest, que é calculado</text><rect x=\"20\" y=\"132\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">sha256:…</text><text x=\"110\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o sha256 do manifest</text><rect x=\"258\" y=\"44\" width=\"190\" height=\"128\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"353\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">manifest</text><text x=\"353\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um arquivo JSON curto</text><text x=\"353\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">que lista cada peça</text><text x=\"353\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pelo seu digest</text><path d=\"M200 64 L256 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M200 152 L256 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><rect x=\"500\" y=\"30\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">config</text><text x=\"600\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">comando, portas, ambiente</text><rect x=\"500\" y=\"92\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">8 camadas do nginx:1.29-alpine</text><text x=\"600\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">25.988.195 bytes, comprimidas</text><rect x=\"500\" y=\"154\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1 camada do COPY index.html</text><text x=\"600\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">231 bytes</text><path d=\"M448 80 L498 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M448 108 L498 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M448 140 L498 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ecr-anat-ah)\"></path><path d=\"M40 250 L680 250\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">um push envia antes os blobs da direita e depois o manifest, que leva a tag</text></svg>", "caption": "O que uma imagem é para um registry. A tag e o digest apontam para um manifest, e o manifest aponta para todo o resto por digest. Mude um byte de uma camada e o digest dela muda, e o do manifest também.", "same": ["manifest", "config", "231 bytes"]}
```

## A única parte que o moto aceita

`PutImage` é uma chamada de API, então o moto a aceita:

```
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.0 --image-manifest file://manifest.json --query image.imageId
{
    "imageDigest": "sha256:11e030171210d110509505b40732d187e3f6d9523af5a3083263a644563ce41f",
    "imageTag": "1.0.0"
}
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web
{
    "imageDetails": [
        {
            "registryId": "123456789012",
            "repositoryName": "shop/web",
            "imageDigest": "sha256:11e030171210d110509505b40732d187e3f6d9523af5a3083263a644563ce41f",
            "imageTags": [
                "1.0.0"
            ],
            "imageSizeInBytes": 12552,
            "imagePushedAt": "2026-10-16T13:25:51-03:00",
            "imageManifestMediaType": "application/vnd.oci.image.manifest.v1+json"
        }
    ]
}
```

Leia essa resposta ao lado do manifest acima e três coisas nela são do moto, e não da AWS.

**O digest é outro.** O moto calcula o seu a partir da lista de digests das camadas, enquanto o
digest da AWS é o SHA-256 do manifest: o valor que o `sha256sum` imprimiu, e o que o `docker push`
informa ao terminar. A AWS também deixa quem chama informar o digest que espera, e recusa a chamada
com `ImageDigestDoesNotMatchException` quando os dois não batem.

**`imageSizeInBytes` é o tamanho do config no moto.** Na AWS são as camadas comprimidas, os 26 MB
acima.

**Na AWS esta chamada teria sido recusada.** Nenhuma das nove camadas foi enviada, e o `PutImage`
responde a um manifest que cita camadas que o repositório não tem com `LayersNotFoundException`. O
moto guarda manifests sem camadas, o que basta para estudar tags, digests e policies, e não basta
para baixar nada de volta.

Há um trabalho que a AWS documenta para o `PutImage` sozinho: **dar outra tag a uma imagem que já
está no repositório**, sem baixá-la nem enviá-la de novo. O manifest é buscado com
`aws ecr batch-get-image` e posto de volta com a tag nova, e a próxima seção faz exatamente isso.
