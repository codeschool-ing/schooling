---
title: "Um projeto bare: as pastas nativas são suas"
version: 1
---

**O React Native sozinho começa escrevendo dois projetos nativos no seu repositório**, e daquele dia em
diante eles são código-fonte que você mantém. A ferramenta que faz isso é o CLI da comunidade React
Native, e o jeito mais claro de ver o que *bare* quer dizer é rodá-lo e olhar:

```
ana@dev:~$ npx @react-native-community/cli@20.2.0 init Bare --version 0.88.1 --skip-install --skip-git-init > /dev/null 2>&1
ana@dev:~$ ls Bare
App.tsx
Gemfile
README.md
__tests__
android
app.json
babel.config.js
index.js
ios
jest.config.js
metro.config.js
package.json
tsconfig.json
ana@dev:~$ ls Bare/android Bare/ios
Bare/android:
app
build.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle

Bare/ios:
Bare
Bare.xcodeproj
Podfile
ana@dev:~$ find Bare/android Bare/ios -type f | wc -l
37
```

`--version 0.88.1` pede o mesmo React Native que o SDK 58 do Expo usa, então os dois projetos desta
aula diferem apenas na abordagem. `--skip-install` e `--skip-git-init` o impedem de instalar pacotes e
de fazer um commit, porque este projeto é para olhar.

## Pelo que você passa a responder

**`android/` é um projeto Gradle** e **`ios/` é um projeto Xcode** com um `Podfile` para o CocoaPods, o
gerenciador de dependências que as bibliotecas iOS usam. Entre os dois, 37 arquivos, e cada um é seu:
o manifesto Android, as configurações do Gradle, o arquivo de projeto do Xcode, o app delegate do iOS.
O JavaScript do `App.tsx` é a parte que se parece com o resto deste curso; as pastas nativas são a
parte que faz deste um projeto bare.

Três coisas decorrem de ser dono delas, e cada uma é um custo de verdade:

- **Uma mudança de configuração é uma edição em duas linguagens.** Uma permissão nova é uma linha no
  `AndroidManifest.xml` e uma chave no `Info.plist`; um nome novo para o app, mais dois lugares. Nada
  confere se as duas plataformas concordam.
- **Uma atualização é um diff para aplicar à mão.** Quando o React Native passa de uma versão para a
  seguinte, o modelo dessas pastas muda junto. A comunidade publica o *upgrade helper*, uma página que
  mostra o diff do modelo entre duas versões, e você o aplica a arquivos que talvez tenha editado
  desde então. Num projeto algumas versões atrás, isso é trabalho de dias.
- **Uma biblioteca com código nativo pode precisar de mãos nas duas pastas.** A maioria se liga sozinha
  hoje, pelo autolinking, mas algumas ainda pedem que você cole linhas no manifesto ou no app delegate.

## O que você ganha

**Nada fica entre você e o projeto nativo.** Qualquer código Android ou iOS, qualquer configuração de
build, qualquer ferramenta que espera um projeto Gradle ou Xcode normal funciona como funcionaria em
qualquer lugar. Uma equipe que já tem desenvolvedores nativos e código nativo, ou um app quase todo
nativo com React Native em algumas telas, começa daqui, e a documentação do React Native tem uma seção
sobre acrescentá-lo a um app nativo existente exatamente para esse caso.

**As próximas seções mostram que um projeto Expo pode ter as mesmas pastas**, escritas sob demanda, e
depois decidir se fica com elas. A escolha com que esta aula termina, portanto, não é *pastas nativas
ou nenhuma*: é *pastas nativas que você edita, ou pastas nativas que você gera*.
