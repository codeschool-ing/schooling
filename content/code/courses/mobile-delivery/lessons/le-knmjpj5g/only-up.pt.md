---
title: O número que só sobe
version: 1
---

**Um version code que desce é um release que nenhum celular instala, e um version code usado duas
vezes é um release que nenhuma loja aceita.** As duas regras existem para que "mais novo" signifique
uma coisa só em todo lugar, e as duas são impostas no envio, e não no build.

## Android e Google Play

- **Uma atualização precisa ter um `versionCode` maior que o do app instalado.** O Android se recusa
  a instalar um menor por cima de um maior, que é o rollback que falta da lição 8 visto do celular.
- **O Google Play recusa um `versionCode` que já viu** para o app, em qualquer faixa. O 42 gerado de
  novo na lição 7 foi recusado exatamente por isso.
- **O maior valor que o Google Play permite é 2.100.000.000.** Um esquema que multiplica as partes
  da versão no código precisa ficar abaixo disso.

## iOS e App Store

- **A string de versão, `CFBundleShortVersionString`, precisa aumentar de uma versão da App Store
  para a seguinte.** Ela tem até três números separados por pontos.
- **O número de build precisa ser único entre os builds enviados para uma versão.** Dois envios da
  1.5.0 podem ser o build 1 e o build 2, ou 1050002 e 1050003; não podem ser os dois 1050003.
- A Apple compara o número de build como inteiros separados por pontos, então `10` é mais novo que
  `9`, e não mais velho como a ordenação de texto diria.

## A falha que ensina

Uma equipe publica a 1.5.0 e depois descobre um bug na linha 1.4 em que alguns clientes ficaram. Ela
gera a **1.4.1**, um nome perfeitamente sensato, com o código que o esquema dá à 1.4.1, menor que o
da 1.5.0. O Google Play a recusa na produção, porque a produção já tem um código maior, e um celular
na 1.5.0 nunca a aceitaria de qualquer jeito. **Num celular existe uma linha de versões só, e ela só
anda para a frente**: a correção é a 1.5.1, com a correção dentro, e o script da próxima seção recusa
a 1.4.1 antes que alguém a envie.
