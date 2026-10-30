---
title: O que as pessoas leem numa versão
version: 1
---

**O versionamento semântico, MAJOR.MINOR.PATCH, foi escrito para bibliotecas, em que o leitor é
outro programa; o leitor de um app é uma pessoa, e uma pessoa lê menos nele.** Numa biblioteca, um
major novo promete que algo vai quebrar. Uma pessoa vendo *2.0* numa loja espera algo grande e novo;
vendo *1.5.3*, não espera nada em especial. Os números ainda ajudam, desde que a equipe os use com
coerência.

## Uma convenção para um app

| parte | sobe quando | o que uma pessoa deveria entender |
|---|---|---|
| major | o app muda de um jeito que as pessoas vão perceber: um redesenho, um modelo novo do que ele faz | leia as notas |
| minor | um release acrescenta algo | tem coisa nova |
| patch | um release só corrige | o mesmo app, funcionando melhor |

Muitas equipes versionam por data, `2026.10`, ou só contam; as duas formas servem, e a loja não se
importa. **O que importa é o nome ser único e significar algo para o suporte**: quando alguém escreve
"quebra na 1.5.0", a equipe precisa saber exatamente que build é esse, e os relatórios de crash da
lição 12 agrupam pelo mesmo nome.

## As palavras ao lado do número

O número é lido num relance; as **notas da versão** é que o explicam. O *What's New* da Apple e as
notas da versão do Google, campos da lição 4, são onde uma pessoa descobre o que mudou.

- **Diga o que mudou para a pessoa, e não para o código.** *"As sessões agora sincronizam entre o
  celular e o tablet"*, e não *"Refatoramos o motor de sincronização"*.
- **"Correções de bugs e melhorias de desempenho" não diz nada.** É a nota mais comum nas duas lojas
  e não diz a ninguém se vale atualizar.
- **As notas são traduzidas**, como todo outro campo da ficha, e o Fastlane da lição 11 as manda a
  partir de arquivos ao lado da ficha da lição 4.

## A versão dentro do app

O app deveria mostrar o próprio nome de versão e o número de build em algum lugar que a pessoa ache,
uma tela Sobre ou o pé das Configurações, para que uma conversa com o suporte comece do build exato.
Cada plataforma lê os próprios números durante o uso:

| | como o app lê a versão dele |
|---|---|
| Android | `packageManager.getPackageInfo(packageName, 0).versionName` |
| iOS | `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` |
| React Native, Expo | `Application.nativeApplicationVersion` do `expo-application` |
