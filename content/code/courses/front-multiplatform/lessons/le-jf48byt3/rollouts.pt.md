---
title: Celulares, lançamentos graduais, e builds em três máquinas
version: 1
---

**Num celular a loja é o atualizador**, e você só decide a que velocidade uma versão nova chega às pessoas. As duas
lojas deixam você lançar primeiro para uma parte:

| loja | como | o que dá para fazer enquanto roda |
|---|---|---|
| Google Play | um **lançamento gradual** (staged rollout): o release vai para uma porcentagem da faixa de produção que você escolhe e aumenta | aumentar a porcentagem, ou interromper o lançamento se os relatórios de falha subirem |
| App Store | um **lançamento em fases** (phased release) ao longo de sete dias, em passos que a Apple define | pausá-lo, ou liberar para todo mundo de uma vez |

**Um lançamento gradual é um teste com pessoas de verdade**, e o valor dele está em acompanhá-lo: os relatórios de
falha e de erro dos primeiros dias, nos vitals do Play Console ou no Organizer do Xcode, comparados com a versão
anterior. Uma atualização ruim para 5% das pessoas é uma tarde ruim; para todo mundo, é uma semana. *Nenhuma das
lojas foi usada para este curso.*

Uma atualização na loja também espera a revisão, e algumas pessoas desligam as atualizações automáticas. **Então um
app precisa lidar com ser antigo**: um planner `0.2.0` que abre dados escritos pelo `0.3.0` deve lê-los ou dizer
com clareza que não consegue, e nunca perdê-los. É a mesma regra do número major do versionamento semântico, vista
do outro lado.

## Atualizações sem a loja

A aula 9 mostrou o outro tipo no Expo: uma atualização só do JavaScript, buscada pelo app ao iniciar, sem loja no
meio. Apps Capacitor têm a mesma opção por meio de serviços de terceiros, o Capgo entre eles, que trocam a `dist/`
dentro do app instalado. **As regras de loja da aula 9 valem para eles sem mudança**: uma atualização pode corrigir
e ajustar o que o app revisado já faz, e não pode transformá-lo em outro app. *Nenhum desses serviços foi usado
aqui.*

## Três sistemas, três máquinas

A aula 13 disse que cada pacote de desktop é gerado no próprio sistema. **Um serviço de CI com runners dos três faz
isso a cada tag**, e o GitHub Actions é o que a maioria dos projetos encontra primeiro. Um workflow para os pacotes
Electron do planner, em `.github/workflows/release.yml`, rodaria a cada tag que o `npm version` cria:

```yaml
# .github/workflows/release.yml: build the desktop packages on each version tag.
name: release
on:
  push:
    tags: ["v*"]
jobs:
  desktop:
    strategy:
      matrix:
        os: [ubuntu-24.04, windows-2025, macos-15]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-node@v5
        with:
          node-version: 22.22.0
      - run: npm ci
      - run: npm run build
      - run: npx electron-builder --publish never
      - uses: actions/upload-artifact@v5
        with:
          name: planner-${{ matrix.os }}
          path: release/*.*
```

**O `matrix` roda o mesmo job em três sistemas**, e cada um gera os pacotes do seu: o AppImage e o `.deb` no
Ubuntu, o instalador no Windows, o `.dmg` no Mac. O `--publish never` impede o electron-builder de enviar qualquer
coisa por conta própria; os pacotes ficam como artefatos do job, para serem conferidos antes de irem para onde o
atualizador olha. As chaves de assinatura da aula 14 entrariam como secrets do repositório, nas variáveis que o
electron-builder lê para elas, como `CSC_LINK`.

*Este workflow não foi executado: o planner não tem repositório num serviço de CI.* Fixe cada action num commit
completo, já que as tags `actions/…@v5` aqui são só a forma curta: a aula 6 de `testing-cicd`, na seção "Actions, e como
fixá-las num commit", explica por quê, e um workflow que assina releases é exatamente onde isso importa.
