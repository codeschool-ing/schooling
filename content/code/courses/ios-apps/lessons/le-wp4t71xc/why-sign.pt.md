---
title: Por que o iOS só roda código assinado
version: 1
---

**Um iPhone não roda código que a cadeia de confiança da Apple não tenha avalizado.** Todo app, todo
framework dentro dele e toda extensão é assinado, e o iOS confere a assinatura antes de rodar uma
única instrução. Num Mac você roda um programa que compilou; num iPhone não, e essa diferença é todo o
motivo de esta aula existir. Nada aqui foi executado: foi escrito a partir do *Platform Security
Guide* da Apple e da documentação dela sobre assinatura de código, lidos em 30 de outubro de 2026.

Uma assinatura responde três perguntas de uma vez:

- **Quem fez isto?** O certificado de assinatura cita um desenvolvedor, e o certificado foi emitido
  pela Apple, então o nome é um que a Apple conferiu quando a assinatura do programa foi comprada.
- **Mudou desde então?** A assinatura cobre todo arquivo do app. Mude um byte e a assinatura deixa de
  bater, então o iOS se recusa a abri-lo. É isso que faz de um app da App Store o mesmo app que o
  desenvolvedor enviou.
- **O que ele pode fazer?** Os entitlements da seção 07 fazem parte do conteúdo assinado, então um app
  não se dá acesso ao iCloud ou a notificações push depois do fato.

**A crença a largar é que assinar é um passo no fim.** Ela é conferida a cada instalação num aparelho,
no desenvolvimento tanto quanto para a loja. Um Personal Team gratuito, da seção 02, também assina: o
Xcode cria um certificado de desenvolvimento e um perfil para você, e é por isso que o seu telefone
roda o seu app por sete dias de cada vez.

## Três peças, uma pergunta cada

Assinar são três arquivos que as pessoas costumam misturar, e todo erro de assinatura é um deles
faltando, vencido ou sem bater:

| peça | o que é | a pergunta que responde |
|---|---|---|
| **certificado** | a sua chave pública, assinada pela Apple, com a sua chave privada guardada no seu Mac | quem assinou isto? |
| **perfil de provisionamento** | um arquivo assinado pela Apple que cita um App ID, certificados, aparelhos e entitlements | este app, assinado por eles, pode rodar aqui e fazer isto? |
| **entitlements** | as permissões que o app reivindica, dentro da assinatura | o que ele quer fazer? |

As seções 04 e 05 tratam do certificado, a seção 06 do perfil, a seção 07 dos entitlements, e a seção
08 do botão do Xcode que cuida dos três por você.
