---
title: Assinatura dentro do pipeline
version: 1
---

**Um pipeline que assina precisa ter a chave, e a questão toda é como ele a tem sem que a chave vá
parar em outro lugar.** A lição 1 manteve o keystore de upload fora do repositório. O pipeline o
recebe pelo outro caminho: como um **segredo criptografado** do serviço de CI, entregue ao único job
que assina, gravado num arquivo temporário, usado e apagado.

## O keystore como segredo

Segredos de CI são texto, e um keystore é um arquivo binário, então ele é guardado em **Base64**,
uma codificação dos bytes em texto. No seu computador:

```sh
base64 -w0 ~/signing/upload.jks
```

A saída, uma linha longa, é colada nos segredos do repositório como `UPLOAD_KEYSTORE_B64`, e a senha
como `UPLOAD_PASS`. Num Mac, `base64 -i upload.jks` faz o mesmo. **O cofre de segredos passa a ser a
segunda cópia da chave**, e o backup criptografado da lição 1 a primeira; o arquivo no notebook pode
ser apagado.

## O passo de assinatura, rodando aqui

O passo que um pipeline roda é um script curto, e ele roda igual no seu computador quando os dois
segredos estão no ambiente. Salve isto como `ci-sign.sh` em `~/planner`:

```sh
# ci-sign.sh: the signing step of the release pipeline, runnable on your own computer
set -euo pipefail
: "${UPLOAD_KEYSTORE_B64:?the keystore secret is missing}"
: "${UPLOAD_PASS:?the keystore password is missing}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '%s' "$UPLOAD_KEYSTORE_B64" | base64 -d > "$work/upload.jks"

apksigner sign --ks "$work/upload.jks" --ks-key-alias upload --ks-pass env:UPLOAD_PASS \
  --out "$1" "$2"
apksigner verify --print-certs "$1" | grep DN
```

O `set -euo pipefail` para na primeira falha e numa variável não definida. As duas linhas com `:` se
recusam a começar sem os segredos, com uma frase dizendo qual falta. O keystore é gravado numa pasta
temporária nova que o `trap` remove quando o script termina, seja como for. Aqui ele assina o APK
alinhado da lição 1, primeiro com os dois segredos exportados do jeito que um serviço de CI os
exporta, depois sem o segredo do keystore, como num job que não o recebeu:

```
ana@dev:~/planner$ bash ci-sign.sh planner-ci.apk ~/signing/planner-aligned.apk
Signer #1 certificate DN: CN=Ana Souza, O=Study Planner, C=BR
ana@dev:~/planner$ bash ci-sign.sh planner-ci.apk ~/signing/planner-aligned.apk
ci-sign.sh: line 3: UPLOAD_KEYSTORE_B64: the keystore secret is missing
```

## Regras que mantêm a chave no cofre

- **Nunca imprima um segredo, e nunca ligue `set -x` num passo que tem um.** O rastreamento ecoa
  cada comando com as variáveis expandidas. Serviços de CI mascaram o valor exato de um segredo nos
  logs, e o Base64 de um keystore, quebrado em linhas ou decodificado, não é esse valor exato.
- **Entregue o segredo só ao job que assina.** Testes, lint e a checagem da ficha rodam sem ele,
  então um teste que imprime o ambiente não consegue vazá-lo.
- **Nunca o entregue a pull requests de forks.** O GitHub Actions não passa segredos a eles por
  padrão, e um workflow que muda isso entrega a chave a qualquer um que abra um pull request.
- **Assine o envio, e não o release.** Com o Play App Signing o pipeline guarda só a chave de
  upload, então um pipeline vazado custa uma redefinição, lição 1, e não o app.

## A metade iOS

O job iOS precisa do certificado de distribuição com a chave privada, e de um perfil. As três
respostas da lição 2 valem: o **fastlane match** os busca num repositório criptografado usando uma
frase-senha como segredo; as **chaves de API do App Store Connect**, uma chave `.p8` com os IDs de
emissor e de chave como segredos, deixam o Xcode baixar o que precisa; o **EAS** os guarda ele mesmo.
Um arquivo `.p12` cru num segredo, importado num chaveiro temporário, é a versão manual da mesma
coisa. *Não rodado: isso precisa de um Mac e de uma conta Apple.*
