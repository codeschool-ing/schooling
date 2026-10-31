---
title: O que o Expo cobra de você
version: 1
---

**Os custos do Expo são reais, e nenhum deles é o que as pessoas temem.** O temor é uma jaula: um app
que não pode ter código nativo, ou que não pode sair. Nenhum dos dois é verdade hoje, como as duas
últimas seções mostraram. O que o Expo cobra é mais estreito, e vale nomear antes que uma equipe se
comprometa.

## O calendário de versões dele vira o seu

**Um SDK do Expo sai algumas vezes por ano, cada um para uma versão do React Native.** Atualizar o React
Native quer dizer atualizar o SDK, e toda biblioteca `expo-` se move junto. Esse costuma ser o caminho
mais fácil, porque as bibliotecas foram testadas juntas; mas você não consegue adotar uma versão do
React Native na semana em que ela sai, e não consegue segurar uma biblioteca do Expo enquanto atualiza
o resto. Uma equipe que precisa de uma correção no próprio React Native espera o SDK que a contém, ou
corrige o pacote enquanto isso.

## As convenções dele moldam o projeto

O prebuild funciona porque as pastas nativas são geradas, e isso só se sustenta enquanto **ninguém as
edita à mão**. Toda mudança nativa precisa ser um config plugin. Para uma mudança que uma biblioteca já
cobre, isso não custa nada. Para uma incomum, uma tarefa Gradle personalizada ou uma fase de build do
Xcode, dá mais trabalho do que editar o arquivo daria, e alguém da equipe precisa aprender a escrever
plugins em vez de Gradle.

## Os serviços pagos são cômodos e opcionais

Builds na nuvem, atualizações over-the-air e envios às lojas são o EAS, que tem uma franquia gratuita e
planos pagos além dela. A metade de código aberto do Expo não precisa deles, e cada um tem uma
alternativa local:

| serviço do EAS | a alternativa local | aula |
|---|---|---|
| EAS Build | Gradle no seu computador para Android; Xcode num Mac para iOS | 3 e 20 |
| EAS Update | um servidor seu que fala o protocolo de atualização do Expo | 21 |
| EAS Submit | enviar pelos consoles das próprias lojas | 20 |

**O difícil de substituir é o EAS Build para iOS sem um Mac**, porque a alternativa é um Mac. A aula 20
é sobre esse caso.

## O tamanho do app

Um projeto Expo inclui o `expo` e o sistema de módulos dele, de que um app bare talvez não precise. A
aula 19 mede o que o bundle do planner contém, essa parte incluída. Para a maioria dos apps não é a
parte que importa; para um app que precisa caber num limite de tamanho rígido, ela é medida, e não
suposta.

## O que não é custo

**Sair.** O `npx expo prebuild` escreve as pastas; colocá-las no commit e tirá-las do `.gitignore` é a
migração inteira para um projeto bare, e as bibliotecas do Expo continuam funcionando nele. Uma equipe
que decide daqui a um ano que quer ser dona dos projetos nativos paga um commit. É essa propriedade que
faz de começar com o Expo uma decisão barata, e não permanente.
