---
title: O que o Expo é, e o que ele não é
version: 1
---

**O Expo não é outro framework.** Um app Expo é um app React Native: a mesma `View`, o mesmo `Text`, o
mesmo React, o mesmo Hermes rodando o mesmo bytecode. O que o Expo acrescenta é tudo o que fica em
volta do React Native e que uma equipe montaria à mão de outro jeito, e desde 2024 a própria
documentação do React Native recomenda começar um app novo com ele.

O nome cobre várias coisas que vale manter separadas, porque cada uma pode ser adotada ou deixada de
lado por conta própria:

| parte | o que é | custa dinheiro? |
|---|---|---|
| **o SDK** | um conjunto de bibliotecas, `expo-camera`, `expo-sqlite`, `expo-location` entre mais de oitenta, lançadas juntas e testadas contra uma versão do React Native | não |
| **o CLI** | `npx expo`: sobe o servidor de desenvolvimento, instala versões compatíveis, exporta, gera os projetos nativos | não |
| **o Expo Go** | um app das lojas que roda o seu projeto num celular sem compilá-lo | não |
| **o prebuild** | gera as pastas `android/` e `ios/` a partir da sua configuração | não |
| **o EAS** | Expo Application Services: builds na nuvem do Expo, atualizações over-the-air, envios às lojas | uma franquia gratuita, depois planos pagos |

**Os quatro primeiros são código aberto e rodam no seu computador.** O EAS é o serviço pago de uma
empresa, e nada nos quatro primeiros depende dele. As aulas 20 e 21 tratam do EAS, do que ele custa e
da alternativa local a cada parte dele.

## Um SDK, um React Native

**Cada versão do SDK do Expo é feita para exatamente uma versão do React Native.** O SDK 58, que este
curso usa, anda junto com o React Native 0.88. Toda biblioteca do SDK é testada contra essa versão e
contra as outras da mesma versão do SDK, e essa é a principal coisa de que o Expo poupa você: descobrir
qual versão de uma biblioteca de câmera funciona com qual versão de uma biblioteca de navegação e com
qual versão do React Native, uma falha de cada vez.

O `npx expo install` é como você usa isso. Pedido um pacote, ele procura a versão que pertence ao seu
SDK e instala essa, em vez da mais nova. Para um pacote que não faz parte do SDK, instala a mais nova,
como o `npm install` faria. A aula 3 o usa para cada biblioteca de que o planner precisa.

## O que "managed" queria dizer

Material mais antigo divide os projetos Expo em **managed** e **bare**, ou fala em **ejetar**. Essas
palavras descrevem o Expo de antes de 2021. Um projeto managed, naquela época, não podia conter código
nativo nenhum, e ejetar queria dizer convertê-lo, de uma vez por todas, num projeto React Native
comum com as pastas nativas escritas. **Nenhuma das duas restrições existe mais.** Um projeto Expo hoje
pode conter qualquer código nativo, seu ou de uma biblioteca; as aulas 2 e 17 mostram como. Se você
encontrar *eject* num artigo, ele está descrevendo um passo que ninguém dá hoje.

## O que o Expo não faz

Ele não esconde as plataformas nativas. Permissões, identificadores do app, chaves de assinatura e
regras das lojas são as mesmas para um app Expo e para qualquer outro, e as aulas 13, 20 e 21 tratam
delas diretamente. Ele não faz um app rodar numa plataforma que o React Native não suporta. E não
elimina a necessidade de um Mac para compilar para iOS: ele muda o Mac de lugar, para a sua mesa ou
para a nuvem do Expo.
