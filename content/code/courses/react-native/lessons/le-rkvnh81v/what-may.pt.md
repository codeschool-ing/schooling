---
title: O que pode ser mandado assim
version: 1
---

Dois tipos de regra decidem o que uma atualização over-the-air pode conter: o que é tecnicamente possível, e
o que as lojas permitem.

## O que é possível

| pode mudar numa atualização | precisa de um build novo |
|---|---|
| qualquer JavaScript ou TypeScript: telas, lógica, texto, estilos | uma biblioteca com código nativo, acrescentada, removida ou atualizada |
| imagens, fontes e outros assets que o bundle importa | uma permissão, ou a frase dela |
| um valor `EXPO_PUBLIC_`, que fica fixado no bundle | o nome do app, o ícone, a tela de abertura, o nome do pacote |
| | tudo no `app.json` que o prebuild escreve nos projetos nativos |
| | a versão do SDK do Expo ou do React Native |

**Uma atualização que precisa de código nativo que o build não tem não falha com delicadeza.** JavaScript que
chama um módulo nativo ausente do build cai no momento em que chega a essa chamada, em todo celular que pegou
a atualização. O `requireNativeModule` da aula 17 lança um erro exatamente assim. A próxima seção é como
isso é evitado.

## O que as lojas permitem

- **A Apple** permite código baixado depois da revisão quando ele roda num motor JavaScript e não muda o
  propósito principal do app, nem acrescenta recursos que precisariam de revisão. Uma correção, uma mudança
  de texto, uma pequena melhora numa tela existente são o que as atualizações são para fazer. Um recurso
  novo que a revisão nunca viu é exatamente o assunto da regra.
- **A política do Google Play** proíbe um app de se atualizar por fora do Play, com uma exceção para código
  que roda numa máquina virtual ou num interpretador, como o JavaScript aqui, sem acesso direto às APIs do
  Android.

*Esta é a leitura deste curso das diretrizes publicadas das duas lojas, e as duas são escritas por pessoas
que se reservam o direito de julgar cada caso.* A regra prática é a mesma de qualquer jeito: **uma
atualização corrige e melhora o que foi revisado; qualquer coisa nova passa pela loja.**
