---
title: O workflow inteiro
version: 1
---

**O pipeline de release são as lições anteriores em ordem, cada uma um passo que pode pará-lo.**
Nada nele é novo; o que é novo é que ele roda em todo release, numa máquina que ninguém configurou à
mão, e que a decisão de enviar é tomada pelas checagens e não pela memória de alguém.

Aqui está ele como um workflow do GitHub Actions, `.github/workflows/release.yml`. *Ele não foi
rodado: os runners do GitHub não são alcançáveis da máquina de gravação, e o job iOS precisa de um
Mac. Todo comando dos jobs Linux é um que rodou antes neste curso.*

```yaml
# .github/workflows/release.yml: build, check and sign a release of the planner
name: release
on:
  push:
    tags: ["v*"]
  schedule:
    - cron: "17 9 * * *"

jobs:
  checks:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22.22.0
          cache: npm
      - run: npm ci
      - run: node expiry.ts certs
      - if: github.event_name == 'push'
        run: node preflight.ts

  android:
    needs: checks
    if: github.event_name == 'push'
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21
          cache: gradle
      - run: node version.ts "${GITHUB_REF_NAME#v}" "$((GITHUB_RUN_NUMBER % 100))"
      - run: ./gradlew bundleRelease
      - run: bash ci-sign-bundle.sh app/build/outputs/bundle/release/app-release.aab
        env:
          UPLOAD_KEYSTORE_B64: ${{ secrets.UPLOAD_KEYSTORE_B64 }}
          UPLOAD_PASS: ${{ secrets.UPLOAD_PASS }}
      - run: bundle exec fastlane android internal

  ios:
    needs: checks
    if: github.event_name == 'push'
    runs-on: macos-15
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - run: bundle exec fastlane ios beta
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
```

## Lendo o workflow

- **Dois gatilhos.** Uma tag como `v1.5.0` roda o release; o agendamento roda só as checagens toda
  manhã, então a checagem de certificado da lição 2 fica vermelha um mês antes do dia em que teria
  parado um release. O minuto na linha do cron é 17, e não 0, porque todo job agendado do mundo
  começa na hora cheia.
- **`checks` controla tudo.** Os dois jobs de build dependem dele (`needs`), então um preflight
  vermelho, lição 6, significa que nada é gerado, assinado ou enviado.
- **O contador de builds é o número da execução**, lição 9, mantido em dois dígitos pelo resto da
  divisão. O nome da versão é a tag.
- **O segredo do keystore chega a um passo só**, o de assinatura, como a seção "Assinatura dentro do
  pipeline" pede. O `ci-sign-bundle.sh` é o gêmeo do `ci-sign.sh` para o bundle, com o `jarsigner`
  no lugar do `apksigner`.
- **O job macOS só começa quando as checagens passam**, então um erro de digitação na ficha custa
  minutos de Linux, e não de Mac.
- **O último passo de cada job de build é o Fastlane**, lição 11, enviando para a faixa interna e
  para o TestFlight. Dali, a promoção é feita por uma pessoa, lição 7.

## Fixando o que roda

`actions/checkout@v4` nomeia uma tag, e uma tag pode ser movida por quem controla aquele
repositório. Num workflow de verdade, **fixe toda action num hash de commit completo** com a versão
num comentário ao lado, como `actions/checkout@<hash de 40 caracteres> # v4.2.2`. O pipeline que
guarda a sua chave de assinatura não deveria rodar código que outra pessoa pode mudar sem avisar.
