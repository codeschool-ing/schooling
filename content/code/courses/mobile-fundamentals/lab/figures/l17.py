"""Lesson 17: the road a push travels, a token's life, and the reminders of the week."""
from fig import Fig

T = {
    "en": dict(
        r_aria="The road of a push message, left to right. Your server sends the message to FCM, for Android, or to APNs, for iOS. The service sends it down the one connection the phone keeps open to it, to the push service on the phone. From there, a notification message goes to the notification shade, shown by the system without starting your app; a data message goes to your app, woken in the background if the system allows it. The phone sent its device token to your server first, which is the address on every message.",
        server=["your server", "the planner's API"], svc=["FCM or APNs", "Google's or Apple's"], phone=["the push service", "on the phone"],
        shade=["the notification shade:", "shown by the system"], app=["your app, woken in the", "background, if allowed"],
        one="one connection per phone, shared by every app", tok="the device token, sent once at launch and when it changes",
        notif="notification", data="data",
        r_cap="Your server never reaches the phone. It hands the message to the platform's service, and the phone decides what to do with it.",
        t_aria="The life of a device token. The app launches and asks the system for its token; it sends the token to the server, which stores it beside the account. The server puts the token on every message. The token changes when the device is restored from a backup, when the app is installed on a new device, or when the system is reinstalled; the app sends the new one at its next launch. When the app is uninstalled, the service answers the next message with not registered, and the server deletes the token.",
        s1=["the app launches,", "asks for its token"], s2=["sends it to", "the server"], s3=["the server stores it", "beside the account"],
        s4=["every message", "carries it"],
        change=["restored from a backup, new device,", "system reinstalled: a new token"],
        gone=["app uninstalled: the service", "answers 'not registered'"], drop=["the server", "deletes it"],
        again="at the next launch",
        t_cap="A token is an address that moves. The app re-sends it at every launch, and the server forgets the ones the service says are dead.",
    ),
    "pt": dict(
        r_aria="O caminho de uma mensagem push, da esquerda para a direita. O seu servidor manda a mensagem ao FCM, para Android, ou ao APNs, para iOS. O serviço a manda pela única conexão que o celular mantém aberta com ele, até o serviço de push no celular. Dali, uma mensagem de notificação vai para a gaveta de notificações, mostrada pelo sistema sem iniciar o seu app; uma mensagem de dados vai para o seu app, acordado em segundo plano se o sistema permitir. Antes, o celular mandou o token do aparelho ao seu servidor, que é o endereço em toda mensagem.",
        server=["o seu servidor", "a API do planner"], svc=["FCM ou APNs", "do Google ou da Apple"], phone=["o serviço de push", "no celular"],
        shade=["a gaveta de notificações:", "mostrada pelo sistema"], app=["o seu app, acordado em", "segundo plano, se permitido"],
        one="uma conexão por celular, compartilhada por todos os apps", tok="o token do aparelho, mandado ao abrir e quando muda",
        notif="notificação", data="dados",
        r_cap="O seu servidor nunca alcança o celular. Ele entrega a mensagem ao serviço da plataforma, e o celular decide o que fazer com ela.",
        t_aria="A vida de um token de aparelho. O app abre e pede ao sistema o seu token; manda o token ao servidor, que o guarda ao lado da conta. O servidor põe o token em toda mensagem. O token muda quando o aparelho é restaurado de um backup, quando o app é instalado num aparelho novo, ou quando o sistema é reinstalado; o app manda o novo na abertura seguinte. Quando o app é desinstalado, o serviço responde à próxima mensagem com não registrado, e o servidor apaga o token.",
        s1=["o app abre e", "pede o seu token"], s2=["manda ao", "servidor"], s3=["o servidor o guarda", "ao lado da conta"],
        s4=["toda mensagem", "o leva"],
        change=["restaurado de backup, aparelho novo,", "sistema reinstalado: token novo"],
        gone=["app desinstalado: o serviço", "responde 'não registrado'"], drop=["o servidor", "o apaga"],
        again="na abertura seguinte",
        t_cap="Um token é um endereço que muda. O app o reenvia a cada abertura, e o servidor esquece os que o serviço diz que morreram.",
    ),
}


def road(t):
    f = Fig("l17-road", 720, 250, t["r_aria"])
    f.box(10, 90, 130, 50, t["server"], stroke="wire")
    f.box(190, 90, 150, 50, t["svc"], stroke="amber")
    f.box(390, 90, 130, 50, t["phone"], stroke="phosphor")
    f.box(560, 40, 155, 50, t["shade"], stroke="phosphor", size=9.5)
    f.box(560, 150, 155, 50, t["app"], stroke="wire", size=9.5)
    f.arrow([(140, 115), (190, 115)])
    f.arrow([(340, 115), (390, 115)], color="amber", width=2)
    f.text(365, 160, t["one"], fill="amber", size=9, italic=True)
    f.arrow([(520, 105), (560, 70)], color="phosphor")
    f.text(538, 74, t["notif"], size=9, fill="phosphor", anchor="end")
    f.arrow([(520, 125), (560, 170)])
    f.text(538, 168, t["data"], size=9, fill="paper-dim", anchor="end")
    f.arrow([(455, 140), (455, 225), (75, 225), (75, 140)], dashed=True)
    f.text(265, 214, t["tok"], size=9.5, fill="paper-dim", italic=True)
    return f


def token(t):
    f = Fig("l17-token", 720, 270, t["t_aria"])
    xs = [10, 190, 370, 550]
    for x, lines, s in zip(xs, [t["s1"], t["s2"], t["s3"], t["s4"]], ["phosphor", "wire", "wire", "wire"]):
        f.box(x, 30, 160, 46, lines, stroke=s)
    for x in xs[:-1]:
        f.arrow([(x + 160, 53), (x + 190, 53)])
    f.box(10, 140, 250, 46, t["change"], stroke="amber", size=9.5)
    f.arrow([(90, 140), (90, 76)], color="amber", dashed=True)
    f.text(100, 110, t["again"], anchor="start", size=9, fill="amber", italic=True)
    f.box(370, 140, 200, 46, t["gone"], stroke="amber", size=9.5)
    f.arrow([(630, 76), (630, 110), (470, 110), (470, 140)], dashed=True)
    f.box(470, 214, 160, 40, t["drop"], stroke="wire", size=9.5)
    f.arrow([(470, 186), (510, 214)])
    return f


def figures(lang):
    t = T[lang]
    return {
        "l17-road": road(t).json(t["r_cap"]),
        "l17-token": token(t).json(t["t_cap"]),
    }


PAYLOAD = [
    ('// payload.ts: one session reminder as APNs and FCM expect it, and a check of its size\nconst LIMIT = 4096; // bytes, for an ordinary remote notification\n\ntype Push = Record<string, unknown>;\ntype Data = Record<string, string>;\n',
     "The limit is a constant with its unit, from the documentation the lesson names. `Data` is strings only, because FCM refuses anything else under `data`.",
     "O limite é uma constante com a unidade, da documentação que a aula cita. `Data` é só texto, porque o FCM recusa qualquer outra coisa em `data`."),
    ('// APNs: what to show goes under "aps"; the app\'s own keys sit beside it.\nexport function apns(title: string, body: string, data: Data): Push {\n  return { aps: { alert: { title, body }, sound: "default" }, ...data };\n}\n\n// FCM HTTP v1: one "message", with the Android channel it is shown on.\nexport function fcm(token: string, title: string, body: string, data: Data): Push {\n  return {\n    message: { token, notification: { title, body }, android: { notification: { channelId: "reminders" } }, data },\n  };\n}\n',
     "One function per service, so the shape is written once. The same title, body and data go into both; only where each one sits differs.",
     "Uma função por serviço, para o formato ser escrito uma vez. O mesmo título, corpo e dados entram nos dois; só muda onde cada um fica."),
    ('// The size the service sees is at most the size of the JSON we would send.\nexport function check(name: string, push: Push): boolean {\n  const bytes = Buffer.byteLength(JSON.stringify(push), "utf8");\n  const ok = bytes <= LIMIT;\n  console.log(`${name}: ${bytes} of ${LIMIT} bytes${ok ? "" : ", refused: too large to send"}`);\n  return ok;\n}\n',
     "Bytes, not characters: `Buffer.byteLength` counts UTF-8, where an accented letter in a Portuguese reminder takes two. A message over the limit is refused here, before any service sees it.",
     "Bytes, não caracteres: `Buffer.byteLength` conta UTF-8, em que uma letra acentuada num lembrete em português ocupa dois. Uma mensagem acima do limite é recusada aqui, antes que algum serviço a veja."),
    ('// A busy week: 4 courses a day for 7 days, each session with its notes.\nfunction busyWeek() {\n  const days = ["19", "20", "21", "22", "23", "24", "25"].map((d) => `2026-10-${d}`);\n  return days.flatMap((date, d) =>\n    ["sql", "mobile", "kotlin", "git"].map((courseId, c) => ({\n      id: `w${d * 4 + c + 1}`, courseId, date, minutes: 45, done: false,\n      notes: "Re-read the section, redo the exercises answered wrong, write down one question.",\n    })),\n  );\n}\n',
     "Data for the mistake below: 28 sessions, the kind of week a student who plans hard really has.",
     "Dados para o erro mais abaixo: 28 sessões, o tipo de semana que uma aluna que planeja muito tem de verdade."),
    ('const token = "token-the-phone-sent-us"; // a stand-in: a real one comes from the phone\nconst title = "SQL Databases";\nconst body = "Your SQL session starts in 15 minutes";\nconst data = { sessionId: "s3", courseId: "sql" };\n\nconsole.log(JSON.stringify(apns(title, body, data)));\ncheck("APNs", apns(title, body, data));\nconsole.log(JSON.stringify(fcm(token, title, body, data)));\ncheck("FCM", fcm(token, title, body, data));\n\nconst big = fcm(token, title, body, { ...data, week: JSON.stringify(busyWeek()) });\nif (!check("FCM with the whole week", big)) {\n  console.log("send the sessionId alone, and let the app fetch the week");\n}',
     "The reminder for `s3`, built for each service and measured, then the same reminder carrying the whole week. Nothing is sent: the program prints what a server would hand over.",
     "O lembrete de `s3`, montado para cada serviço e medido, e depois o mesmo lembrete levando a semana inteira. Nada é enviado: o programa imprime o que um servidor entregaria."),
]

EXAMPLES = {"the-message": [{"language": "typescript", "file": "payload.ts", "parts": PAYLOAD}]}
