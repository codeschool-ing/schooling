---
title: Uma notificação local, do conteúdo ao pedido
version: 1
---

**Uma notificação local é agendada pelo próprio app e entregue pelo sistema, esteja o app rodando ou não
nessa hora.** O artigo da Apple sobre agendar uma notificação localmente lista as três peças: o conteúdo,
um gatilho, e um pedido que junta os dois com um identificador. Nada nesta seção foi executado; ela segue
esse artigo e a documentação das classes que ele cita, lidos em 30 de outubro de 2026.

## O lembrete do planner

```swift
// Scheduling the reminder for one session
import UserNotifications
import PlannerCore

func scheduleReminder(for session: StudySession, course: Course) async throws {
    let content = UNMutableNotificationContent()
    content.title = course.title
    content.body = "\(session.minutes) minutes planned for tomorrow"
    content.sound = .default
    content.threadIdentifier = course.id

    let when = reminder(forDay: session.date, at: 19)
    let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)

    let request = UNNotificationRequest(identifier: "reminder-\(session.id)",
                                        content: content, trigger: trigger)
    try await UNUserNotificationCenter.current().add(request)
}
```

O `reminder(forDay:at:)` é a função da seção 04, do pacote: a única peça deste código que rodou para o
curso. O resto são as três peças do artigo, em ordem.

**O identificador é o da sessão, e essa é a decisão de que este código depende.** A documentação da Apple
para o `UNNotificationRequest` diz que um pedido com o identificador de um já agendado o substitui. Então
reagendar depois de o estudante mudar uma sessão de dia é a mesma chamada de novo, sem lembrete
duplicado para o dia antigo; e cancelar um, quando a sessão é marcada como feita ou apagada, é uma linha:

```swift
// Cancelling the reminder of a session that is done
UNUserNotificationCenter.current()
    .removePendingNotificationRequests(withIdentifiers: ["reminder-\(session.id)"])
```

O artigo põe isso como hábito: você cancela um pedido "quando as condições mudam e você não precisa mais
avisar o usuário", e o exemplo dele é o caso do planner, um lembrete de algo já concluído. **Um lembrete
de uma sessão já feita é pior que nenhum**, porque o próximo é lido com menos atenção.

O `threadIdentifier` é o mesmo agrupamento que o `thread-id` do payload na seção 07: os lembretes de um
curso se juntam sob um título na tela de bloqueio.

## O que o `add` não promete

O `add` agenda; ele não entrega. A pessoa pode ter desligado as notificações depois de dizer sim, ou
posto o telefone num Foco que silencia o app, e o app não é avisado quando uma dessas coisas impede que
um lembrete seja visto. Então o planner nunca confia num lembrete como único registro de nada: a sessão
está no plano, tenha o lembrete aparecido ou não.
