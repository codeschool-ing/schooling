---
title: Pedir para notificar, e não desperdiçar a resposta
version: 1
---

**Uma notificação é a única coisa que um app consegue fazer a uma pessoa que não o está usando**:
acender a tela, fazer um som, interromper uma conversa. Por isso os dois sistemas fazem dela algo
que o usuário concede e pode retirar, e os dois dão ao usuário controles mais finos que um botão de
liga e desliga. Um app que gasta isso com coisas que ninguém pediu é desligado, e aí até os
lembretes úteis dele param de chegar.

## A permissão, em cada plataforma

**No iOS, um app precisa pedir antes de mostrar alertas, sons ou badges**, e a documentação da Apple
sobre pedir permissão, lida em 30 de outubro de 2026, diz que o sistema pergunta à pessoa uma vez e
registra a resposta; pedir de novo não mostra a pergunta de novo. O conselho dela sobre o momento
poderia ter sido escrito para o planner: num app de tarefas que manda lembretes, peça depois que a
pessoa agendar a primeira tarefa, quando ela consegue ver para que servem as notificações, e não na
primeira abertura. É a regra da aula 12 sobre pedir no momento certo, aplicada a notificações.

**O iOS também oferece a autorização provisória**, um teste que não precisa de pergunta. As
notificações enviadas sob ela chegam em silêncio: sem som nem banner e nada na tela bloqueada, só no
histórico da Central de Notificações, com botões para mantê-las ou desligá-las. A pessoa decide
depois de ter visto uma, o que é uma pergunta mais justa que perguntar antes.

**No Android, a partir do Android 13, publicar notificações é uma permissão em tempo de execução,
`POST_NOTIFICATIONS`.** A página do Android sobre ela diz que um app recém-instalado no Android 13 ou
posterior tem as notificações **desligadas por padrão** até pedir e o usuário concordar, e que um app
que mira o Android 13 escolhe quando o diálogo aparece. Se o usuário recusa, todos os canais do app
ficam bloqueados.

**E no Android toda notificação pertence a um canal**, desde o Android 8.0: uma categoria que o app
cria, como "Lembretes de sessão" ou "Cursos compartilhados", cada uma com uma importância. O guia do
Android sobre canais diz que, uma vez criado o canal, o app não pode mais mudar o comportamento dele;
**o usuário tem controle total**, e pode silenciar um canal mantendo outro. Esse é o motivo de criar
um canal por tipo de mensagem, para que uma aluna incomodada com um tipo não precise perder todos.

Os trechos abaixo pedem permissão e criam o canal de lembretes; foram adaptados das mesmas páginas da
Apple e do Android e da documentação do `expo-notifications`, e **não foram compilados nem executados
para este curso**:

```swift
let center = UNUserNotificationCenter.current()
// .provisional: no prompt now; quiet delivery until the person keeps or turns them off
let granted = try await center.requestAuthorization(options: [.alert, .sound, .provisional])
```

```kotlin
val channel = NotificationChannel(
    "reminders", "Session reminders", NotificationManager.IMPORTANCE_DEFAULT,
)
context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
// Android 13 and later: ask, after the student plans a first session
permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
```

```tsx
import * as Notifications from "expo-notifications";

await Notifications.setNotificationChannelAsync("reminders", {
  name: "Session reminders",
  importance: Notifications.AndroidImportance.DEFAULT,
});
const { status } = await Notifications.requestPermissionsAsync();
```

## O que as lojas dizem, e o que os usuários fazem

**A Apple escreve a regra.** A diretriz 4.5.4 das App Store Review Guidelines, lida em 30 de outubro
de 2026, diz que notificações push não podem ser necessárias para o app funcionar, não devem levar
informação pessoal sensível ou confidencial, e não devem ser usadas para promoções ou marketing
direto a menos que o cliente tenha aceitado explicitamente, por um texto de consentimento no app, com
um jeito de sair no próprio app. Ela termina dizendo que o abuso pode custar ao desenvolvedor esse
privilégio.

**Os usuários fazem valer o resto por conta própria.** Toda notificação que o planner manda é pesada
contra a interrupção que causou, e a resposta do usuário é um botão nas configurações que o app não
consegue religar. Então a lista do planner é curta:

| o planner manda | porque |
|---|---|
| um lembrete 15 minutos antes de uma sessão que a aluna planejou | ela pediu ao planejar a sessão, e ele é útil na hora |
| "Ana compartilhou um curso com você" | outra pessoa fez algo que envolve a aluna |
| nada sobre um curso novo no catálogo | isso é marketing; precisa de um aceite explícito, e de um canal próprio |
| nada para "trazê-la de volta" depois de três dias quietos | é a mensagem com mais chance de fazer todos os canais serem desligados |

**E o app funciona com todas desligadas.** A tela da semana, as sessões e os totais não dependem de
nenhum push chegar, que é o que a diretriz 4.5.4 pede e o que o caminho do começo desta aula torna
necessário de qualquer jeito. Uma notificação é algo que o planner oferece. Os cursos depois da
bifurcação montam uma de ponta a ponta: o curso `android-apps` na aula 19, o `ios-apps` na aula 17,
e o `react-native` na aula 16, conforme o caminho que você seguir.
