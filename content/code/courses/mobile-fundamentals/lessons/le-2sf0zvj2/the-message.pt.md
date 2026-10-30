---
title: O que um push leva, e quanto
version: 1
---

**Uma mensagem push é um JSON pequeno, e vem em dois tipos que se comportam de forma diferente no
celular.** Uma mensagem de *notificação* diz o que mostrar, um título e um corpo, e quando o app não
está na tela o sistema a mostra sozinho. Uma mensagem de *dados* leva só chaves e valores para o app,
não mostra nada, e acorda o app em segundo plano se o sistema permitir. Muitas mensagens são as duas
coisas: um título e um corpo para mostrar, e algumas chaves que o app lê quando a pessoa toca.

| | uma mensagem de notificação | uma mensagem só de dados |
|---|---|---|
| o que leva | um título e um corpo, talvez um som; dados opcionais ao lado | só dados |
| app fora da tela | o sistema a mostra; o seu código roda num toque | o sistema pode acordar o app para tratá-la, e pode não acordar |
| no iOS | um `aps.alert` no payload | uma notificação em segundo plano, `content-available` |
| o planner a usa para | "Your SQL session starts in 15 minutes" | "a sua semana mudou": atualizar em silêncio |

A tabela segue o guia da Expo sobre tipos de notificação e a documentação da Apple sobre gerar uma
notificação remota, lidos em 30 de outubro de 2026. **O tipo só de dados é o menos confiável.** O
mesmo guia da Expo diz que o sistema não garante entregá-lo ao app, sob o Doze por exemplo, e cita o
conselho da Apple de não mandar mais que duas ou três notificações em segundo plano por hora. Uma
atualização que precisa acontecer não se apoia nele; o job agrupado da aula 15 é o piso por baixo.

## O tamanho, que é pequeno de propósito

**Os dois serviços limitam o tamanho de uma mensagem, e o limite é de poucos kilobytes.** A
documentação da Apple sobre gerar uma notificação remota dá **4 KB, 4096 bytes**, para toda
notificação remota exceto a de VoIP. A página do próprio Firebase sobre tamanhos de mensagem não
pôde ser lida da máquina em que este curso foi gravado; a documentação do serviço de push da Expo,
que envia pelo FCM e pelo APNs, dá os mesmos 4096 bytes para Android e iOS. Um push é uma campainha,
não uma encomenda.

O `payload.ts` monta o lembrete de uma sessão no formato que cada serviço espera, e o mede. O token
é um substituto: um de verdade vem do celular, e nenhuma mensagem é enviada a lugar nenhum. A
verificação mede o JSON inteiro que o servidor mandaria, que é pelo menos tão grande quanto o que
cada serviço conta, então ela erra para o lado seguro. Salve-o em `~/planner` como `payload.ts`:

```schooling-example
{"language": "typescript", "file": "payload.ts", "parts": [{"code": "// payload.ts: one session reminder as APNs and FCM expect it, and a check of its size\nconst LIMIT = 4096; // bytes, for an ordinary remote notification\n\ntype Push = Record<string, unknown>;\ntype Data = Record<string, string>;\n", "note": "O limite é uma constante com a unidade, da documentação que a aula cita. `Data` é só texto, porque o FCM recusa qualquer outra coisa em `data`."}, {"code": "// APNs: what to show goes under \"aps\"; the app's own keys sit beside it.\nexport function apns(title: string, body: string, data: Data): Push {\n  return { aps: { alert: { title, body }, sound: \"default\" }, ...data };\n}\n\n// FCM HTTP v1: one \"message\", with the Android channel it is shown on.\nexport function fcm(token: string, title: string, body: string, data: Data): Push {\n  return {\n    message: { token, notification: { title, body }, android: { notification: { channelId: \"reminders\" } }, data },\n  };\n}\n", "note": "Uma função por serviço, para o formato ser escrito uma vez. O mesmo título, corpo e dados entram nos dois; só muda onde cada um fica."}, {"code": "// The size the service sees is at most the size of the JSON we would send.\nexport function check(name: string, push: Push): boolean {\n  const bytes = Buffer.byteLength(JSON.stringify(push), \"utf8\");\n  const ok = bytes <= LIMIT;\n  console.log(`${name}: ${bytes} of ${LIMIT} bytes${ok ? \"\" : \", refused: too large to send\"}`);\n  return ok;\n}\n", "note": "Bytes, não caracteres: `Buffer.byteLength` conta UTF-8, em que uma letra acentuada num lembrete em português ocupa dois. Uma mensagem acima do limite é recusada aqui, antes que algum serviço a veja."}, {"code": "// A busy week: 4 courses a day for 7 days, each session with its notes.\nfunction busyWeek() {\n  const days = [\"19\", \"20\", \"21\", \"22\", \"23\", \"24\", \"25\"].map((d) => `2026-10-${d}`);\n  return days.flatMap((date, d) =>\n    [\"sql\", \"mobile\", \"kotlin\", \"git\"].map((courseId, c) => ({\n      id: `w${d * 4 + c + 1}`, courseId, date, minutes: 45, done: false,\n      notes: \"Re-read the section, redo the exercises answered wrong, write down one question.\",\n    })),\n  );\n}\n", "note": "Dados para o erro mais abaixo: 28 sessões, o tipo de semana que uma aluna que planeja muito tem de verdade."}, {"code": "const token = \"token-the-phone-sent-us\"; // a stand-in: a real one comes from the phone\nconst title = \"SQL Databases\";\nconst body = \"Your SQL session starts in 15 minutes\";\nconst data = { sessionId: \"s3\", courseId: \"sql\" };\n\nconsole.log(JSON.stringify(apns(title, body, data)));\ncheck(\"APNs\", apns(title, body, data));\nconsole.log(JSON.stringify(fcm(token, title, body, data)));\ncheck(\"FCM\", fcm(token, title, body, data));\n\nconst big = fcm(token, title, body, { ...data, week: JSON.stringify(busyWeek()) });\nif (!check(\"FCM with the whole week\", big)) {\n  console.log(\"send the sessionId alone, and let the app fetch the week\");\n}", "note": "O lembrete de `s3`, montado para cada serviço e medido, e depois o mesmo lembrete levando a semana inteira. Nada é enviado: o programa imprime o que um servidor entregaria."}]}
```

```
ana@dev:~/planner$ node payload.ts
{"aps":{"alert":{"title":"SQL Databases","body":"Your SQL session starts in 15 minutes"},"sound":"default"},"sessionId":"s3","courseId":"sql"}
APNs: 142 of 4096 bytes
{"message":{"token":"token-the-phone-sent-us","notification":{"title":"SQL Databases","body":"Your SQL session starts in 15 minutes"},"android":{"notification":{"channelId":"reminders"}},"data":{"sessionId":"s3","courseId":"sql"}}}
FCM: 231 of 4096 bytes
FCM with the whole week: 5511 of 4096 bytes, refused: too large to send
send the sessionId alone, and let the app fetch the week
```

**O lembrete tem 142 bytes para o APNs e 231 para o FCM, muito abaixo do limite nos dois.** Os dois
formatos diferem em onde cada coisa vai: o APNs põe o que mostrar em `aps.alert` e deixa as chaves
do próprio app ao lado de `aps`. A API HTTP v1 do FCM embrulha tudo numa `message`, põe o que
mostrar em `notification`, nomeia o canal de notificação do Android em que a mensagem aparece, e
exige que todo valor em `data` seja texto. A descrição da própria API do FCM, lida no mesmo dia,
marca o campo `token` como obsoleto em favor de `fid`, um ID de instalação do Firebase que faz o
mesmo papel. Esse é o tipo de mudança que justifica montar um payload numa função testada em vez de à
mão em cinco lugares.

**A terceira mensagem é o erro, e a verificação a recusa.** Ela leva a semana inteira da aluna, 28
sessões com as anotações, dentro do push, para que o app não precise perguntar ao servidor. Com 5.511
bytes ela passa de 4096, então nenhum dos serviços a aceitaria. E mesmo abaixo do limite seria o
desenho errado: o push pode chegar atrasado, duas vezes reduzido a uma, ou nunca, como a etapa
anterior disse. **Mande o id do que mudou, e deixe o app buscar o resto**, que é a última linha que
o programa imprime.

## O que não pôr num push

**Um push passa pelos servidores do Google ou da Apple e aparece numa tela bloqueada.** As App Store
Review Guidelines da Apple, lidas em 30 de outubro de 2026, dizem na diretriz 4.5.4 que notificações
push não devem ser usadas para mandar informação pessoal sensível ou confidencial. "Your SQL session
starts in 15 minutes" cabe numa tela bloqueada. Uma mensagem que levasse as notas de uma aluna, ou o
motivo de ela ter faltado uma semana, não cabe, e o push certo para isso diz "você tem uma mensagem
nova" e mais nada.
