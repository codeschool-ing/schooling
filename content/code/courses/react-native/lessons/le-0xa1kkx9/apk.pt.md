---
title: O módulo dentro de um build de verdade
version: 1
---

**Um teste prova a regra; um build prova que o módulo está ligado.** O mesmo build de debug da aula 3, para
uma arquitetura de processador só, para ser mais rápido, compila todo arquivo Kotlin de todo módulo dentro
do app, inclusive o local:

```
ana@dev:~/planner/android$ ./gradlew :app:assembleDebug -PreactNativeArchitectures=arm64-v8a -q > /dev/null 2>&1
ana@dev:~/planner/android$ du -h app/build/outputs/apk/debug/app-debug.apk
91M	app/build/outputs/apk/debug/app-debug.apk
ana@dev:~/planner/android$ unzip -p app/build/outputs/apk/debug/app-debug.apk 'classes*.dex' | grep -a -o 'org/example/weekstart/[A-Za-z]*' | sort -u
org/example/weekstart/R
org/example/weekstart/WeekStartModule
org/example/weekstart/WeekStartModuleKt
```

O build levou alguns minutos, a maioria no C++ das bibliotecas das aulas 12 a 16, e o APK cresceu bem além
dos 64 MB da aula 3 com elas. O último comando lê o bytecode Java compilado do app, os arquivos
`classes*.dex` dentro do APK, e acha três classes do pacote do módulo: `WeekStartModule`, o módulo;
`WeekStartModuleKt`, onde o Kotlin põe a função `firstWeekday` de nível de cima; e `R`, a classe de recursos
que toda biblioteca Android ganha.

*Isso prova que o módulo foi compilado no app e nada mais. Se um celular rodando este APK responde 0 no
Brasil não foi executado: não há emulador na máquina que gravou este curso, que não tem virtualização de
hardware, e nenhum celular ligado a ela.*
