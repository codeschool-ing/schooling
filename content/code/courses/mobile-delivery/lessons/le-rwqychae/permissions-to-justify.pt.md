---
title: A permissão que você tem de justificar
version: 1
---

**Um app que quer a câmera, o calendário ou a localização tem de perguntar à pessoa, e a loja
quer saber por que ele pergunta.** São duas portas diferentes. O sistema pergunta à pessoa durante
o uso; a loja pergunta a você na revisão, e uma permissão que os recursos do app não explicam é um
dos motivos de recusa que a lição 6 lista.

## A única permissão do planner

O planner manda um lembrete antes de uma sessão de estudo. No Android 13 e mais novos, mostrar uma
notificação é uma **permissão de tempo de execução**; no iOS, sempre foi. Então o planner pergunta,
e pergunta no momento em que importa: quando alguém liga os lembretes, e não na primeira abertura,
quando ninguém sabe ainda para que o app serve.

## As palavras que a pessoa lê

**No iOS, toda permissão vem com uma purpose string**, uma frase no `Info.plist` que o sistema
mostra no diálogo. Uma permissão pedida sem frase derruba o app, e uma frase vaga é recusada na
revisão. A diretriz 5.1.1 da Apple pede que as purpose strings descrevam o uso com clareza e por
completo.

| | a declaração | o que a pessoa vê |
|---|---|---|
| Android | `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` no manifesto | o texto do próprio sistema; o app pode explicar antes com uma tela própria |
| iOS | uma purpose string, como `NSCalendarsFullAccessUsageDescription`, no `Info.plist` | a frase do app, dentro do diálogo do sistema |
| React Native | as mesmas duas, escritas pela configuração do Expo a partir do `app.json` | o mesmo de cada plataforma |

As notificações no iOS são a exceção que confirma a tabela: não precisam de purpose string, porque
o sistema redige o pedido sozinho. O calendário é um exemplo melhor da regra:

```xml
<!-- Info.plist: the sentence the person reads when the planner asks for the calendar -->
<key>NSCalendarsFullAccessUsageDescription</key>
<string>The planner adds your study sessions to your calendar, so they appear beside everything else.</string>
```

```kotlin
// MainActivity.kt: ask for notifications when reminders are switched on, not at launch
val ask = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
    reminders.setEnabled(granted)
}
fun onRemindersSwitchedOn() {
    if (Build.VERSION.SDK_INT >= 33) ask.launch(Manifest.permission.POST_NOTIFICATIONS)
    else reminders.setEnabled(true)
}
```

```json
{
  "expo": {
    "ios": {
      "infoPlist": {
        "NSCalendarsFullAccessUsageDescription": "The planner adds your study sessions to your calendar, so they appear beside everything else."
      }
    }
  }
}
```

*Nenhuma das três listagens foi rodada para este curso; elas foram escritas a partir da
documentação de cada plataforma.* Num app em português, a frase da purpose string vai no arquivo de
tradução do `Info.plist`, e é ela que o diálogo mostra.

## As permissões que uma loja questiona

Algumas permissões precisam de mais do que uma frase. O Google Play pede um **formulário de
declaração** antes de aceitar um app que use certas delas: ler SMS ou o registro de chamadas,
localização em segundo plano, acesso a todos os arquivos, alarmes exatos e mais algumas, cada uma
com uma lista de usos que ele aceita. Um app que pede uma delas e não se encaixa num uso aceito é
recusado, diga o que disser a purpose string. **A correção mais barata é não pedir**: o planner não
precisa de alarme exato para lembrar alguém dez minutos antes de uma sessão, porque um inexato
chega perto o bastante.
