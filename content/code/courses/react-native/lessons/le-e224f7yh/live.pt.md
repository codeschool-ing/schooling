---
title: O planner contra um servidor de verdade
version: 1
---

**Os testes provam a lógica; esta seção observa as requisições.** O build web é exportado com o endereço do
servidor, servido como na aula 8, e aberto enquanto o `server.mjs` roda no próprio terminal:

```sh
EXPO_PUBLIC_API_URL=http://localhost:8008 npx expo export --platform web
npx -y serve@14.2.6 --single -l 8082 dist
```

Três visitas: os cursos, a semana com a sessão de violão marcada como feita, e os cursos de novo num navegador
**novo**, sem cache nenhum:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- progressbar "Minutes done this week"
- button "Spanish A2 2 sessions planned"
- button "Statistics 2 sessions planned"
- button "Guitar 2 sessions planned"
- text: Saved in this browser
- tablist:
  - tab "Courses" [selected]
  - tab "This week"
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/week?today=2026-10-21' --click 'Mark 20 min on 2026-10-21 done'
- heading "This week" [level=1]
- heading "2026-10-19" [level=2]
- text: 30 min, done
- heading "2026-10-20" [level=2]
- text: 45 min, done
- heading "2026-10-21" [level=2]
- text: 20 min, done
- heading "2026-10-22" [level=2]
- text: 30 min
- button "Mark 30 min on 2026-10-22 done": Mark done
- tablist:
  - tab "Courses"
  - tab "This week" [selected]
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 95 of 125 minutes done"
- progressbar "Minutes done this week"
- button "Spanish A2 2 sessions planned"
- button "Statistics 2 sessions planned"
- button "Guitar 2 sessions planned"
- text: Saved in this browser
- tablist:
  - tab "Courses" [selected]
  - tab "This week"
```

**A terceira visita leu 95 num navegador que nunca tinha visto o toque.** A mudança chegou ao servidor, e um
cliente novo a buscou. Eis o que o terminal do servidor imprimiu enquanto isso:

```
listening on 8008
GET /
GET /plan
POST /sessions/s9/done
POST /sessions/s9/done
GET /plan
GET /plan
POST /sessions/s3/done
GET /plan
GET /plan
```

Leia como uma linha do tempo. O `GET /` é a máquina de gravação conferindo que o servidor tinha subido, e não é
do app. As três linhas seguintes são os comandos `curl` da seção sobre o servidor. Depois o app: o `GET /plan`
da primeira visita; o `GET /plan` da segunda visita, o `POST /sessions/s3/done` do toque, e outro `GET /plan`,
que é o `onSettled` invalidando a query e buscando a versão do servidor; e o `GET /plan` da terceira visita.

**Nenhum `OPTIONS` antes do `POST`.** Um navegador só pergunta antes a um servidor se uma requisição de outra
origem é permitida quando ela não é uma requisição simples, um corpo JSON ou um cabeçalho próprio por exemplo; um
`POST` sem nenhum dos dois sai na hora, e o `access-control-allow-origin` do servidor deixa a página ler a
resposta. **Cada requisição desse log é uma que o código desta aula pediu, e nenhuma é duplicada**, que é o sinal
de que o cache está fazendo o trabalho dele.
