---
title: O rollback que não existe
version: 1
---

**Não existe rollback num celular, e todo plano que supõe um falha no dia em que é preciso.** Num
servidor, desfazer um release é rodar o build anterior de novo. Num celular, a versão nova está
instalada, os dados dela migrados, e a loja não entrega às pessoas uma versão mais antiga de um app
que elas já têm.

## Por que as lojas se recusam a voltar

- **O Google Play recusa um version code menor que o que as pessoas têm.** A lição 9 explica os
  números; o que importa aqui é que "enviar o build anterior" é recusado, porque o código dele é
  menor e, de qualquer jeito, já foi usado.
- **A App Store instala a versão mais nova que um aparelho suporta.** Não há como publicar uma
  versão mais antiga por cima de uma mais nova.
- **Os dados seguiram em frente.** Uma versão que mudou o esquema do banco já rodou a migração em
  todo celular que a instalou. A versão mais antiga, instalada por cima, abriria um banco que ela não
  entende. A lição 20 volta a isso do lado do servidor.

## O que existe no lugar: seguir em frente

O caminho de volta é uma **versão nova que se comporta como a antiga**: o código anterior, ou o
código anterior com a única correção, gerado com um version code **maior** e liberado. Isso leva um
build, uma revisão e uma liberação, que num dia bom são horas e num dia ruim são dois dias, então não
é algo para descobrir no meio de um incidente.

| o que uma equipe diz | o que ela consegue fazer de fato |
|---|---|
| "voltar para a 1.4.0" | liberar a 1.5.1, cujo código é o da 1.4.0, com um version code maior |
| "tirar o release do ar" | interromper a liberação; quem tem a 1.5.0 continua com ela |
| "desligar o recurso" | só se o recurso estava atrás de uma chave remota antes do release, lição 19 |

A terceira linha é a única instantânea, e só existe se alguém a construiu antes.

## O mesmo nas três plataformas

Apps em Kotlin, Swift e React Native são todos binários instalados, então os três seguem em frente.
O React Native tem mais uma porta: uma atualização over-the-air pode trocar o bundle JavaScript sem
release na loja, dentro dos limites que a lição 6 descreveu. Ela não troca código nativo, e só chega
a apps que abrem e a baixam.
