---
title: Construindo algo para entregar
version: 1
---

O `./gradlew run` precisa do Gradle e do código-fonte. Um usuário não tem nenhum dos dois. **O plugin
`application` consegue montar o programa como um diretório que um usuário roda**: os jars do programa,
toda biblioteca de que ele precisa, e um script de início que encontra o Java e põe tudo no classpath.

```
ana@vm:~/kt/studyplan$ ./gradlew -q :app:installDist
ana@vm:~/kt/studyplan$ ls app/build/install/app/bin app/build/install/app/lib
app/build/install/app/bin:
app
app.bat

app/build/install/app/lib:
annotations-13.0.jar
app.jar
core.jar
kotlin-stdlib-2.4.21.jar
ana@vm:~/kt/studyplan$ app/build/install/app/bin/app
2 sessions, 75 of 300 min (25%)
```

O `installDist` construiu os dois módulos e copiou o resultado para `app/build/install/app`. O `lib`
guarda quatro jars, os dois módulos e as duas bibliotecas que o relatório de dependências nomearia; o
`bin/app` é um script de shell, o `bin/app.bat` o gêmeo dele para Windows. O programa rodou sem Gradle
nenhum envolvido.

O `distZip` e o `distTar` empacotam o mesmo diretório como um arquivo só, que é o que um lançamento
anexa. Quem o desempacota precisa de um Java na versão 21 ou mais nova, o número que a seção 04 pôs no
bytecode, e de mais nada.

O `./gradlew build` é a tarefa que a CI roda: compila todo módulo, roda todo teste e monta os pacotes, e
falha se algum passo falhar. Os testes da aula 18 fazem parte do build daqui em diante, não são um
passo extra que alguém precisa lembrar.
