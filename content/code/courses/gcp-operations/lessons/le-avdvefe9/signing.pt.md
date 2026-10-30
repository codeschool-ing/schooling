---
title: Assinando uma imagem, e conferindo a assinatura
version: 1
---

**Assinar uma imagem significa assinar o digest dela com uma chave privada, para que qualquer um com a
chave pública possa conferir que essa imagem exata foi assinada por quem tem aquela chave.** Os atestados
do Binary Authorization são isso, guardados no Container Analysis do Google. A mesma ideia, com uma
ferramenta de código aberto que você pode rodar, é o **cosign**, do projeto Sigstore. O Binary
Authorization aceita assinaturas do Sigstore nas políticas de plataforma baseadas em verificação do GKE,
então o que vem a seguir é próximo do que um passo de assinatura real faz, contra o registro local da lição
2. **Nada disso é o Binary Authorization**: nada aqui recusa um deploy. Mostra o que está sendo
verificado.

O cosign publica uma imagem de si mesmo, então não precisa de instalação. Esta linha faz de `cosign` um
comando no seu terminal que roda essa imagem com o diretório atual montado, como você, na rede do host,
para que ele alcance `localhost:5000`:

```sh
cosign() { docker run --rm --network host --user "$(id -u):$(id -g)" -v "$PWD":/w -w /w -e COSIGN_PASSWORD gcr.io/projectsigstore/cosign:v2.6.1 "$@"; }
```

Como as variáveis da lição 1, ela vive só naquele terminal. Inicie o registro local de novo, construa a
imagem da loja, envie com a tag `a1b2c3d` e guarde o digest:

```sh
docker run -d --rm --name registry -p 5000:5000 mirror.gcr.io/library/registry:3.0.0
docker build -q -t localhost:5000/shop/api:a1b2c3d api
docker push -q localhost:5000/shop/api:a1b2c3d
```

## Um par de chaves

```
ana@laptop:~/gcp/shop$ cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
```

`COSIGN_PASSWORD` foi definido como nada (`export COSIGN_PASSWORD=`) antes disso, então a chave privada
não está protegida por senha. **Isso é só para este laboratório.** Uma chave de assinatura real nunca fica
num arquivo: ela vive no Cloud KMS, assunto da lição 18, e o cosign assina com ela pelo nome,
`--key gcpkms://…`, sem a metade privada jamais sair do Google.

## Assinando um digest

```
ana@laptop:~/gcp/shop$ cosign sign --key cosign.key --tlog-upload=false --yes localhost:5000/shop/api@sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352
Pushing signature to: localhost:5000/shop/api
```

**A assinatura é sobre o digest**, e o cosign a guarda no registro ao lado da imagem, como um artefato com
a tag do digest e `.sig`. `--tlog-upload=false` a mantém fora do log público de transparência do
Sigstore, onde uma esteira real escreveria e este laboratório não escreve.

Qualquer um com `cosign.pub` pode agora conferir:

```
ana@laptop:~/gcp/shop$ cosign verify --key cosign.pub --insecure-ignore-tlog --offline localhost:5000/shop/api@sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352 2>&1 | grep -v 'Could not fetch'
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5000/shop/api@sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key

[{"critical":{"identity":{"docker-reference":"localhost:5000/shop/api"},"image":{"docker-manifest-digest":"sha256:f94313ba8319ba82712078b14c817a479f788d39de8d53f4731b36b02a9e1352"},"type":"cosign container image signature"},"optional":null}]
```

O aviso é o cosign dizendo, com razão, que não verificou o log de transparência, porque nada foi escrito
nele. O `grep` tira um segundo aviso, sobre não alcançar os servidores do Sigstore para atualizar as chaves
deles, que depende da sua rede e não diz nada sobre esta assinatura. Depois vem o resultado: a assinatura
confere com a chave pública, e o payload nomeia o digest sobre o qual ela foi feita.

## A tag se move; a assinatura não

Agora o movimento da lição 2: acrescente a borracha ao `api/app.py`, reconstrua, e envie com a **mesma
tag**. Depois peça ao cosign para verificar a tag:

```
ana@laptop:~/gcp/shop$ cosign verify --key cosign.pub --insecure-ignore-tlog --offline localhost:5000/shop/api:a1b2c3d 2>&1 | grep -v 'Could not fetch'
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no signatures found
error during command execution: no signatures found
```

**Nenhuma assinatura encontrada.** O cosign resolveu a tag para o digest novo e procurou uma assinatura
sobre esse digest; não há nenhuma, porque ninguém assinou a imagem nova. A assinatura antiga continua no
registro, sobre o digest antigo, e não diz nada sobre outra coisa. Uma política que exige assinatura recusa,
portanto, uma imagem que alguém enviou por cima de uma tag assinada, que é exatamente o erro que a lição 2
mostrou passar em silêncio.
