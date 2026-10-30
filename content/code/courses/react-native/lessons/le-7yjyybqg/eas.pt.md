---
title: EAS Build, e iOS sem um Mac
version: 1
---

**O EAS Build é o serviço de build do Expo**: o projeto é enviado, construído nas máquinas do Expo, Linux
para Android e macOS para iOS, e o resultado é um app assinado que você pode baixar, instalar ou mandar às
lojas com o `eas submit`. É a resposta para "não tenho Mac" no iOS, e para "o release depende do laptop de uma
pessoa" nos dois.

Ele é guiado pelo `eas.json`, na raiz do projeto, que nomeia **perfis de build**. Salve o `eas.json`:

```json
{
  "cli": { "version": ">= 27.0.0", "appVersionSource": "remote" },
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview": {
      "distribution": "internal",
      "android": { "buildType": "apk" },
      "env": { "EXPO_PUBLIC_API_URL": "https://staging.planner.example.org" }
    },
    "production": {
      "autoIncrement": true,
      "env": { "EXPO_PUBLIC_API_URL": "https://planner.example.org" }
    }
  },
  "submit": { "production": {} }
}
```

- **O `development`** é um development build, o da aula 3, com o `expo-dev-client`, para os celulares do
  time. A distribuição `internal` dá um link para instalar em vez de uma loja.
- **O `preview`** é um build de release para quem testa: um APK no Android, que instala direto, contra um
  servidor de homologação.
- **O `production`** é o que vai para as lojas: um AAB no Android, e um build de iOS assinado para a App
  Store.
- **O `env` define as variáveis de cada build**, então o `EXPO_PUBLIC_API_URL` tem o valor onde o release é
  construído, que é o hábito que a aula 18 pediu.
- **O `appVersionSource: "remote"` e o `autoIncrement`** deixam o EAS cuidar do `versionCode` do Android e
  do `buildNumber` do iOS, os números que todo envio precisa aumentar, para ninguém precisar lembrar o último.

```
ana@dev:~/planner$ node -e "const e = require(\"./eas.json\"); console.log(Object.keys(e.build))"
[ 'development', 'preview', 'production' ]
```

Essa conferência é tudo o que este curso executou: três perfis num arquivo que é lido sem erro. *O resto não
foi executado, porque os servidores do Expo recusaram a máquina que gravou este curso.* O que segue é o fluxo
da documentação do Expo:

- **`npx eas-cli@27.2.0 login`** e **`npx eas-cli@27.2.0 init`** ligam o projeto a uma conta do Expo e
  escrevem o `projectId` dele no `app.json`, o id que o token de push da aula 16 pedia.
- **`eas build --platform android --profile production`** envia o projeto e o constrói. Na primeira vez, o
  EAS oferece gerar uma chave de upload e guardá-la; ou o `eas credentials` envia a que você criou.
- **`eas build --platform ios --profile production`** pede a sua conta de Apple Developer, cria lá o
  certificado de distribuição e o perfil de provisionamento, e os guarda. Nenhum Mac participa em momento
  nenhum, do seu lado.
- **`eas submit`** manda o resultado ao Google Play ou ao App Store Connect, de onde o TestFlight o entrega a
  quem testa.

**Guardar as credenciais nos servidores do Expo é uma decisão, não um padrão que você precisa aceitar**:
quer dizer um segundo lugar onde a sua chave de assinatura mora. A alternativa, `credentialsSource:
"local"`, as mantém num arquivo que você administra, como a keystore desta aula.
