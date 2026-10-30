---
title: O ciclo de desenvolvimento, e onde o Expo Go para
version: 1
---

**O `npx expo start` é o centro do dia de um projeto Expo.** Ele inicia o Metro, o empacotador do React
Native, que transforma a `app/` e tudo o que ela importa num bundle JavaScript só e o serve a partir do
seu computador. Um celular ou emulador rodando o app pede esse bundle ao Metro, o roda, e o recarrega
quando você salva um arquivo, do jeito que o `npm run dev` recarregava o planner na aula 1.

O que roda no celular para pedir o bundle é a pergunta que importa, e há duas respostas:

| | **Expo Go** | **um development build** |
|---|---|---|
| o que é | um app das lojas, o mesmo para todo mundo | o seu próprio app, construído uma vez com o `expo-dev-client` dentro |
| código nativo dentro dele | as bibliotecas que o Expo traz para aquele SDK, e nada mais | o que o seu app incluir, os módulos nativos dele também |
| como você o consegue | instala pela loja | constrói, na nuvem ou localmente, e instala |
| bom para | os primeiros dias, e um app sem código nativo próprio | tudo depois disso |

**O Expo Go é fixo.** Ele contém o lado nativo das bibliotecas do próprio Expo para uma versão de SDK,
então um app que só usa essas roda nele sem mudança, e o planner roda. No dia em que o seu app precisar
de uma biblioteca nativa que o Expo Go não traz, ou de um módulo nativo seu como o plugin da aula 5, o
Expo Go não consegue rodá-lo, porque código nativo não pode ser baixado para dentro de um app instalado.
Um **development build** é a resposta: o seu app, com o menu de desenvolvedor do Expo dentro, construído
uma vez e depois alimentado com JavaScript novo pelo Metro exatamente como o Expo Go era.

*Nenhum dos dois foi rodado para este curso: os dois precisam de um celular ou de um emulador, e a aula 3
diz por que não havia nenhum. O resto desta aula roda as partes do Expo que funcionam sem eles.*

## As teclas que o `npx expo start` escuta

Num terminal, o servidor de desenvolvimento do Expo imprime um QR code e um menu curto. As mais usadas:

- **`a`** abre o app num emulador Android ou num celular ligado, **`i`** no simulador iOS num Mac, **`w`**
  num navegador;
- **`r`** recarrega o app, **`j`** abre o depurador de JavaScript, **`m`** abre o menu de desenvolvedor no
  aparelho;
- ler o QR code com a câmera do celular, ou de dentro do Expo Go no Android, abre o projeto naquele
  celular, que tem que estar na mesma rede que o computador.
