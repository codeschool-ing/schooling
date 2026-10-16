---
title: Rodando os testes, e lendo o relatório
version: 1
---

**Há dois jeitos de rodar testes de Espresso, e os dois terminam no mesmo comando no aparelho.** O
Android Studio é o jeito para escrever um teste; o Gradle na linha de comando é o jeito para um
pipeline. Em qualquer caso o emulador precisa estar rodando, e o boxoffice com ele, porque o
`ListTest` e o segundo teste do `OfflineTest` leem espetáculos de verdade.

## Antes da primeira execução: animações desligadas

O Espresso espera a thread principal, e uma animação roda nela em pequenos passos que o Espresso não
espera de forma confiável. O conselho do Google para todo aparelho que roda Espresso é desligar as
animações do sistema. No emulador, abra *Settings › System › Developer options* (a lição 14 diz como
fazê-las aparecer) e ponha estas três em *Animation off*:

- *Window animation scale*
- *Transition animation scale*
- *Animator duration scale*

O emulador guarda a escolha. Um teste que só passa com as animações desligadas não achou um defeito
no app; um que só falha com elas ligadas achou um teste instável.

## No Android Studio

Abra o `ListTest.kt`. Um triângulo verde fica na margem ao lado da classe e de cada teste; aperte o
da classe e escolha *Run 'ListTest'*. O Android Studio compila o app e o APK de teste, instala os
dois no emulador, roda os testes, e os lista na janela *Run* com um visto ou um xis cada. Um teste
que falhou mostra a mensagem do Espresso ao lado, com a hierarquia de views em que ele procurou.
Clique com o botão direito na pasta `example.tickets` dentro de `androidTest` para rodar todas as
classes de teste de uma vez.

## Com o Gradle

A partir da pasta `tickets`:

```sh
./gradlew connectedDebugAndroidTest
```

No Windows, no PowerShell, `.\gradlew.bat connectedDebugAndroidTest`. *Connected* quer dizer em todo
aparelho que o adb lista, e *Debug* é a variante de build, a mesma do APK da lição 15. O Gradle sai
com um código diferente de zero quando um teste falha, que é o que um pipeline precisa (lição 6), e
grava dois relatórios: uma página HTML em `app/build/reports/androidTests/connected/`, que você abre
num navegador, e arquivos XML do JUnit em `app/build/outputs/androidTest-results/connected/`, que um
servidor de CI lê como o arquivo do Newman da lição 6.

**Nenhum dos dois foi executado para este curso**, pelo motivo que a seção 03 deu. Então nenhum
relatório aparece aqui, e as duas pastas acima são onde o plugin Android do Gradle os grava; dentro de
cada uma, o plugin pode acrescentar uma pasta para a variante antes dos arquivos.

## O que o Gradle faz no aparelho

Por baixo dos dois, a mesma requisição chega ao aparelho: o adb pede ao Android que inicie a
instrumentação do APK de teste. Você mesmo pode digitá-la depois que os dois APKs estiverem
instalados, e ela mostra o que é um teste instrumentado melhor do que qualquer diagrama. Na máquina
de gravação, que não tem aparelho:

```
ana@laptop:~/boxoffice$ adb shell am instrument -w example.tickets.test/androidx.test.runner.AndroidJUnitRunner
* daemon not running; starting now at tcp:5037
* daemon started successfully
adb: no devices/emulators found
```

`example.tickets.test` é o APK de teste, com o nome do app mais `.test`, e
`androidx.test.runner.AndroidJUnitRunner` é o executor da seção 03. O `-w` espera os testes
terminarem. O adb iniciou o servidor dele e não achou com quem falar, a mesma resposta que o
`adb devices` deu na lição 14. No seu computador, com o emulador rodando e os APKs instalados por uma
execução do Gradle, o mesmo comando imprime cada teste enquanto ele roda e uma contagem no fim.
