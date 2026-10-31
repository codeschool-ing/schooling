---
title: Você precisa de um módulo nativo?
version: 1
---

**Toda biblioteca deste curso com código nativo é um módulo nativo que outra pessoa escreveu.** A câmera,
o SQLite, a localização, as notificações: cada um é um pacote com Kotlin, Swift e uma cara em JavaScript, e
um config plugin do Expo para as declarações dele. Escrever o seu é o mesmo trabalho, feito para algo que
ninguém empacotou.

Faça três perguntas antes de escrever um:

1. **Existe uma biblioteca?** O [React Native Directory](https://reactnative.directory) lista milhares,
   com as plataformas que cada uma suporta e se funciona com a nova arquitetura. Uma biblioteca mantida é
   melhor que o seu próprio módulo para quase tudo que um segundo app também poderia querer.
2. **Isso já é alcançável pelo JavaScript?** O React Native expõe muita coisa pelos próprios módulos:
   `Linking`, `AccessibilityInfo`, `Platform`, `Appearance`. Um módulo para algo que eles já respondem é
   código a manter por nada.
3. **Precisa ser síncrono, ou rápido?** Uma função nativa pode ser chamada de forma síncrona pelo JSI, a
   interface da aula 1, e roda na velocidade nativa. Computação pesada, processamento de imagem, áudio,
   podem pertencer ao lado nativo só por isso.

**O caso do planner é pequeno de propósito.** Em que dia o calendário da pessoa começa a semana? É domingo
no Brasil e nos Estados Unidos, segunda na maior parte da Europa, e a pessoa pode mudar isso nos ajustes do
celular. O JavaScript do React Native não tem um jeito portável de perguntar, e o calendário de cada
plataforma responde numa linha. Um módulo com uma função é o menor exemplo honesto, e mostra cada passo que
um maior dá.

## Expo Modules e Turbo Modules

Há dois jeitos de escrever um módulo para o React Native de hoje:

- **Turbo Modules** são do próprio React Native: uma especificação em TypeScript, código gerado a partir
  dela pelo Codegen, e classes nativas que implementam as interfaces geradas, em Java ou Kotlin e em
  Objective-C++.
- **A Expo Modules API** descreve o módulo direto em Kotlin e em Swift, com uma linguagem pequena de
  `Name`, `Function`, `AsyncFunction`, `Events` e `View`, e não gera nada que você precise ler. Ela fica
  sobre o mesmo JSI, então uma chamada custa o mesmo.

**Este curso usa a Expo Modules API**: no iOS é Swift em vez de Objective-C++, não precisa de código
gerado, e é o que toda biblioteca do Expo usa, então tem a mesma forma de tudo o que você instalou. Um Turbo
Module é a escolha certa para uma biblioteca feita para ser usada sem os pacotes do Expo.
