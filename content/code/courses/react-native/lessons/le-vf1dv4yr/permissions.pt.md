---
title: Permissões, pedidas na hora e respondidas de três jeitos
version: 1
---

**Um celular protege o que é privado de quem o segura**: a câmera, o microfone, onde a pessoa está, os
contatos, as fotos, se o app pode interrompê-la com uma notificação. Um app não ganha nada disso por ser
instalado. Ganha cada coisa em dois passos, e os dois precisam acontecer:

1. **Declarada**, quando o app é construído. O manifest do Android lista toda permissão que o app pode
   um dia pedir, e o `Info.plist` do iOS traz uma frase para cada uma, que o sistema mostra quando
   pergunta. Um app que pede algo que nunca declarou é recusado no Android e fechado no iOS.
2. **Concedida**, pela pessoa, com o app rodando. O sistema mostra o próprio diálogo, que o app não
   consegue estilizar, reescrever nem pular.

## Quando pedir

**Peça no momento em que a pessoa faz algo que precisa daquilo, e nunca na abertura.** Quem acabou de
apertar *Take a photo* sabe por que o planner quer a câmera. Quem abriu o app pela primeira vez e
encontra três diálogos seguidos não sabe, e diz não a todos. O segundo motivo é mais rígido: o sistema não
vai continuar perguntando por você.

- **O iOS pergunta uma vez.** Depois da primeira resposta, pedir de novo devolve essa resposta na hora,
  sem diálogo.
- **O Android pergunta duas.** Recuse uma segunda vez e o sistema para de mostrar o diálogo para aquele
  app.

Depois disso, só a pessoa pode mudar de ideia, nos Ajustes do celular. O trabalho do app é saber em qual
situação está.

## Três respostas

Toda biblioteca do Expo que precisa de uma permissão responde ao pedido com o mesmo tipo de objeto. O
`granted` diz sim ou não, e o `canAskAgain` diz se uma recusa é definitiva:

| `granted` | `canAskAgain` | o que quer dizer | o que o app faz |
|---|---|---|---|
| `true` | — | permitido | segue em frente |
| `false` | `true` | recusado desta vez | diz o que se perde, oferece outro caminho, e pode pedir na próxima vez |
| `false` | `false` | recusado de vez, ou proibido por quem administra o aparelho | explica, e oferece um caminho até os Ajustes |

Existe também o `status`, que é `"granted"`, `"denied"` ou `"undetermined"` (nunca perguntado), e um
`getCameraPermissionsAsync()` ao lado de cada `request…`, que lê a resposta sem perguntar. Ele serve para
desenhar uma tela de outro jeito antes de a pessoa apertar qualquer coisa.

## O que não precisa de permissão nenhuma

**Escolher uma foto da galeria não precisa.** As duas plataformas têm hoje um seletor de fotos do sistema,
que roda fora do seu app: a pessoa navega pelas fotos na tela do próprio sistema, e o seu app recebe só as
que ela escolheu. Como o app nunca vê o resto da galeria, não há nada a conceder. Uma permissão para a
galeria é para um app que lê a galeria ele mesmo, uma galeria ou uma ferramenta de backup, e o planner não
é nenhum dos dois. *Mesmo esses podem receber acesso parcial, as fotos que a pessoa marcou num diálogo
posterior, que a resposta informa como `accessPrivileges: "limited"`; o planner nunca pede, então este
curso não viu nenhum.*
