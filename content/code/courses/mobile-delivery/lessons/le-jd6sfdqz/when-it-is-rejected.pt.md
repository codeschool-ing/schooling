---
title: Quando ele é recusado mesmo assim
version: 1
---

**Uma recusa é uma mensagem de uma pessoa, com um motivo e quase sempre uma captura de tela, e o
caminho mais rápido é lê-la como um relatório de bug.** *Lido nas páginas de App Review da Apple,
outubro de 2026, e na Central de Ajuda do Play Console como publicada em 2025; não rodado.*

## Lendo a recusa

Do lado da Apple, a recusa chega nas mensagens de **App Review** do App Store Connect, nomeando a
diretriz, descrevendo o que o revisor viu e muitas vezes anexando uma captura ou um vídeo curto. Do
lado do Google, o Play Console nomeia a política e a versão, e um e-mail diz o mesmo.

Três perguntas, nesta ordem:

1. **Você consegue reproduzir o que eles viram?** Entre com a conta de demonstração, numa
   instalação limpa, no tipo de aparelho que eles citam. A maioria das recusas 2.1 se reproduz em
   cinco minutos.
2. **O motivo é sobre o build ou sobre a ficha?** Um problema de ficha, uma captura ou uma frase, é
   corrigido sem build novo; um crash não.
3. **Eles entenderam errado o app?** Às vezes sim: um recurso atrás de uma configuração, um fluxo
   que precisa de um segundo aparelho. Aí a resposta é uma explicação, e não uma mudança.

## Respondendo

- **Corrija e reenvie** quando o revisor estava certo. Diga nas notas o que mudou. O relógio da
  revisão recomeça.
- **Responda** quando eles entenderam errado. Do lado da Apple, uma resposta na mesma conversa, com
  um vídeo curto do recurso funcionando, resolve a maioria desses casos sem build novo.
- **Recorra** quando você acredita que uma regra foi aplicada errado. O **App Review Board** da
  Apple ouve os recursos, um por envio recusado, e pede que você responda antes a qualquer pedido de
  informação. O Google tem um **formulário de recurso** para decisões de política. Um recurso é mais
  lento do que uma correção, e certo só quando a correção tiraria algo que o app deveria ter.

## O que não fazer

- **Reenviar o mesmo build esperando outro revisor.** É o mesmo build, e a segunda recusa fica
  registrada.
- **Esconder o recurso durante a revisão.** Um recurso desligado para o revisor e ligado para todo
  mundo é o comportamento pelo qual as duas lojas removem apps, e a configuração remota da lição 19
  facilita fazer isso sem querer.
- **Discutir na ficha.** Uma recusa se responde na conversa da revisão, e não na descrição.

## As outras duas plataformas

O processo é da loja, então é o mesmo para Kotlin, Swift e React Native. O que muda é a rapidez
com que uma correção sai: uma correção de ficha é um formulário nas duas lojas, enquanto uma
correção de código num app React Native pode tentar a equipe a mandá-la over-the-air em vez de
reenviar. A seção "As recusas comuns" diz por que isso é um risco quando a correção muda o que o
revisor viu.
