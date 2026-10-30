---
title: Construindo na nuvem com o EAS
version: 1
---

**O EAS Build é o serviço do Expo que constrói o app nativo por você**, nas máquinas dele: Linux para o
Android e Macs para o iOS. Você roda um comando, ele envia o projeto, roda o `prebuild` e o build nativo
lá, assina o resultado com credenciais que guarda para você, e devolve um pacote Android ou um iOS. **É
assim que muita gente publica na App Store sem ter um Mac**, o caminho que a aula 1 mencionou.

*Nada nesta seção foi rodado para este curso. O EAS precisa de uma conta no Expo e de uma pessoa aceitando
os termos dele, e a máquina de gravação não alcançava os servidores do Expo. Os comandos e o arquivo vêm
da documentação do Expo para o EAS Build.*

## `eas.json`

Os builds são descritos no `eas.json`, ao lado do `app.json`, como **perfis** com nome. O `npx eas-cli
build:configure` escreve um primeiro depois que você entra na conta; este é o formato dele, com os três
perfis com que quase todo projeto termina:

```json
{
  "cli": { "version": ">= 25.3.0", "appVersionSource": "remote" },
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview": { "distribution": "internal", "android": { "buildType": "apk" } },
    "production": { "autoIncrement": true }
  }
}
```

- **`development`** constrói o development build da primeira seção, com o menu de desenvolvedor dentro,
  para os seus próprios celulares.
- **`preview`** constrói um app parecido com o de lançamento para quem testa, instalado direto de um
  link; no Android um APK, que um celular instala diretamente, em vez do pacote que a loja quer.
- **`production`** constrói o que vai para as lojas. O `autoIncrement` sobe o número do build a cada
  build, e o `appVersionSource: "remote"` guarda esse número do lado do Expo, para duas pessoas
  construindo não fazerem as duas o build 12. A aula 15 é sobre esses números.

## Os comandos

```sh
npx eas-cli@25.3.0 login
npx eas-cli@25.3.0 build --platform android --profile preview
npx eas-cli@25.3.0 build --platform ios --profile production
```

O primeiro build iOS pede a sua conta do Apple Developer e oferece criar nela o certificado de assinatura
e o perfil de provisionamento, que a aula 14 explica; depois o Expo os guarda para os builds seguintes.
**O plano gratuito tem uma cota mensal de builds e uma fila**, em termos que o Expo define e muda, e os
planos pagos compram mais das duas coisas.

O `eas build --local` roda o mesmo build no seu próprio computador, o que exige tudo o que um build nativo
exige: o SDK do Android da aula 3, e para iOS um Mac com Xcode. É como uma equipe que não quer o código na
máquina de outra pessoa ainda usa os mesmos perfis.
