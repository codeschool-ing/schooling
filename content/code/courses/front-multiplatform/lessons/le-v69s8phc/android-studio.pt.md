---
title: O Android Studio, o SDK e um lugar para rodar
version: 1
---

**Para construir o projeto Android você precisa de três coisas que este curso ainda não instalou**: um
Java Development Kit, o SDK do Android e um lugar para rodar o app, um emulador ou um celular. O
Android Studio traz a segunda e os meios para a terceira, e o Capacitor conta com ele.

*Nada nesta seção depois do JDK foi rodado para este curso. A máquina onde ele foi gravado não
alcançava `dl.google.com`, onde o Google serve o Android Studio, o SDK e o plugin Android do Gradle,
então os passos vêm da documentação do Google em developer.android.com e da do Capacitor em
capacitorjs.com, e a única saída mostrada é o que o Capacitor imprimiu sem eles.*

## O JDK

O Gradle e as ferramentas de build do Android rodam em Java, e o projeto que o Capacitor gerou pede o
Java 21 pelo nome:

```
ana@dev:~/planner$ grep -A3 compileOptions android/app/capacitor.build.gradle
  compileOptions {
      sourceCompatibility JavaVersion.VERSION_21
      targetCompatibility JavaVersion.VERSION_21
  }
ana@dev:~/planner$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
```

No Ubuntu esse JDK é um pacote, `sudo apt install openjdk-21-jdk-headless`. O Android Studio também traz
um JDK próprio, que ele usa quando você constrói de dentro dele; o do `apt` é para rodar o Gradle num
terminal.

## O que acontece sem o SDK

`npx cap run android` constrói o app e o põe num aparelho. Numa máquina sem SDK, ele chega até a cópia
dos seus arquivos e depois diz o que falta:

```
ana@dev:~/planner$ npx cap run android
✔ Copying web assets from dist to android/app/src/main/assets/public in 5.96ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 533.92μs
[info] Inlining sourcemaps
✔ copy android in 17.64ms
✔ Updating Android plugins in 1.27ms
✔ update android in 22.86ms
[error] native-run failed with error
        
        ERR_SDK_NOT_FOUND: No valid Android SDK root found.
        
        More details for this error may be available online: https://github.com/ionic-team/native-run/wiki/Android-Errors
        
```

**O `native-run`** é o programa que o Capacitor usa para falar com aparelhos, e a **SDK root** é a pasta
onde o SDK fica, que ele procura na variável `ANDROID_HOME` e no lugar padrão do Android Studio. O `npx
cap open android`, que abre o projeto no Android Studio, falha do mesmo jeito pelo mesmo motivo:

```
ana@dev:~/planner$ npx cap open android
[error] Unable to launch Android Studio. Is it installed?
        Attempted to open Android Studio at: /usr/local/android-studio/bin/studio.sh
        You can configure this with the CAPACITOR_ANDROID_STUDIO_PATH environment variable.
```

## Instalando, pelos passos do Google

1. **Baixe o Android Studio** em developer.android.com/studio. No Linux é um `.tar.gz`; descompacte e
   rode `bin/studio.sh`. O Capacitor o procura em `/usr/local/android-studio`, como a mensagem acima
   diz, então descompacte lá ou defina `CAPACITOR_ANDROID_STUDIO_PATH` apontando para o `studio.sh`
   onde quer que o tenha posto. No Windows e no macOS é um instalador, e o Capacitor o encontra sozinho.
2. **Deixe o assistente de configuração instalar o SDK.** Ele baixa a plataforma do SDK, as
   ferramentas de build e as de plataforma, que incluem o `adb`, em `~/Android/Sdk` no Linux. Depois
   defina a variável no seu `~/.profile`, `export ANDROID_HOME="$HOME/Android/Sdk"`, e abra um terminal
   novo.
3. **Instale a plataforma que o projeto nomeia.** O `compileSdkVersion` era 36 na seção anterior; no
   SDK Manager do Android Studio, a plataforma "Android API 36" é essa.
4. **Crie um aparelho onde rodar.** No Device Manager, crie um aparelho virtual a partir de um celular e
   de uma imagem de sistema. Um emulador precisa da virtualização do processador: no Linux é o
   `/dev/kvm`, com o seu usuário no grupo `kvm`.

**Um celular de verdade é o outro caminho**, e muitas vezes o mais rápido. Nas configurações dele, abra
"Sobre o telefone" e toque sete vezes em "Número da versão"; aparece um menu novo, "Opções do
desenvolvedor", e nele "Depuração USB". Com o celular ligado pelo cabo e o aviso na tela dele aceito,
`adb devices` o lista.

Aí o `npx cap run android` lista os emuladores e celulares que encontrou e pergunta qual usar, e o `npx
cap open android` abre o projeto no Android Studio, onde o botão verde Run faz o mesmo. **Use o Studio
quando algo nativo estiver errado**: a janela de build dele mostra os erros do Gradle por inteiro, que
um terminal deixa passar rolando.

No Windows com WSL, o Android Studio e o emulador rodam no Windows, e a aula 1 pôs o seu terminal no
Linux. **Mantenha o projeto de um lado só dessa linha**: rode o `npm install`, os comandos `cap` e o
Gradle a partir do mesmo sistema, para que os arquivos que o Gradle lê sejam os que o npm escreveu.
Esse arranjo também não foi rodado para este curso, e a documentação do Capacitor para Windows é a que
deve ser seguida.
