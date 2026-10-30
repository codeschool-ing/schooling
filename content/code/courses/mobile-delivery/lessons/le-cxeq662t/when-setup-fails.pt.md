---
title: Quando a preparação falha
version: 1
---

**A maioria das preparações que falham aqui falha de um de cinco jeitos, e cada um diz qual na
primeira linha.** Leia a primeira linha do erro antes de qualquer outra coisa.

## `keytool: command not found`, ou `java: command not found`

Não há JDK no `PATH` do terminal. Aqui o keytool é chamado com um `PATH` que não alcança nada, que
é como um computador sem JDK aparece para o shell:

```
ana@dev:~/signing$ PATH=/nonexistent keytool -list -keystore upload.jks
bash: line 1: keytool: command not found
```

No Ubuntu e no WSL, `sudo apt install openjdk-21-jdk-headless` instala, e um terminal interativo
ali pode sugerir a mesma linha sozinho. Num Mac, instale o build Temurin do JDK 21 da Adoptium e
abra um terminal novo.

## `sdkmanager: command not found`, ou falta o `apksigner`

As duas linhas no fim do `~/.profile` são lidas quando um terminal começa, então um terminal aberto
antes de você acrescentá-las não as tem. Abra um novo. Se ainda falhar, `ls ~/android` deveria
mostrar `cmdline-tools`, `build-tools` e `platforms`; uma pasta `cmdline-tools` com outra
`cmdline-tools` dentro em vez de `latest` quer dizer que o passo do `mv` foi pulado, e então o
sdkmanager se recusa a começar com uma mensagem sobre o local de instalação.

## A senha errada

O keytool não distingue uma senha errada de um arquivo danificado, e diz a mesma coisa para os
dois:

```
ana@dev:~/signing$ keytool -list -keystore upload.jks -storepass not-the-password
keytool error: java.io.IOException: keystore password was incorrect
```

Nada recupera um keystore cuja senha se perdeu. É para isso que ele existe. Se esta é a sua chave
de upload e a senha sumiu, o dono da conta da lição 3 pede ao Google uma redefinição da chave de
upload.

## O `sdkmanager` para nas licenças

Todo pacote que o Google distribui tem termos que precisam ser aceitos uma vez em cada computador.
Rode `sdkmanager --licenses`, responda `y` a cada um e rode a linha de instalação de novo.

## No Windows: mantenha as pastas no Linux

No WSL, os discos do Windows aparecem em `/mnt/c`, e um projeto ali fica lento, porque todo acesso
a arquivo atravessa do Linux para o Windows. Mantenha `~/planner`, `~/signing` e `~/android` no
seu diretório pessoal do Linux, onde as transcrições os têm.
