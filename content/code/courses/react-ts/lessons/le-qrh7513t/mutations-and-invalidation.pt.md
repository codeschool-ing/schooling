---
title: Mutações, e avisar o cache de que ele está velho
version: 1
---

**Uma mutação muda dados no servidor; invalidar uma query diz ao cache que a cópia dele agora está
errada.** A biblioteca então busca de novo, todo componente que lê aquela key recebe os dados novos, e
ninguém mantém duas cópias em dia à mão. Marque uma sessão e veja as requisições:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep -E 'api|minutes done'
net  GET /api/planner  200
net  PATCH /api/sessions/s2  200
net  GET /api/planner  200
    - paragraph: 120 of 195 minutes done
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | grep 'minutes done'
    - paragraph: 120 of 195 minutes done
ana@dev:~/planner$ grep -A 4 '"s2"' data/planner.json
      "id": "s2",
      "course": "statistics",
      "date": "2026-10-21",
      "minutes": 40,
      "done": true
```

Três requisições: a carga inicial, **o `PATCH` que marcou a `s2` como feita**, e **o `GET` que o
`refresh` causou**, depois do qual o resumo diz 120. O segundo `look` é uma página nova de navegador
com cache vazio, e ainda diz 120, porque agora a mudança está no servidor. O arquivo no disco é onde o
servidor a guarda.

Acrescentar uma sessão vai do mesmo jeito, com um `POST`:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --do 'click button Back to courses' | grep -E 'api|minutes done'
net  GET /api/planner  200
net  POST /api/sessions  201
net  GET /api/planner  200
    - paragraph: 120 of 240 minutes done
```

**120 de 240**: os 45 minutos acrescentados no sábado, com os 40 da transcrição anterior ainda
marcados, porque o servidor lembra dos dois. O formulário da aula 10 não mudou; o `addSession` agora
faz um post em vez de empurrar para o estado local, e o servidor confere a sessão de novo antes de
guardá-la.

```schooling-figure
{"svg": "<svg data-fig=\"invalidate\" viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"Uma linha do tempo de marcar uma sessão. A caixa chama o toggleDone; a mutação manda PATCH ao servidor; quando ele responde, o onSuccess invalida a key do planejador; a query busca GET /api/planner de novo; todo componente que lê a key renderiza com os dados novos.\"><rect x=\"10\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">toggleDone(id)</text><line x1=\"141\" y1=\"42\" x2=\"151\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"151.0,42.0 143.5,45.2 143.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"152\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"217.0\" y=\"35.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">PATCH</text><text x=\"217.0\" y=\"48.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/sessions/s2</text><line x1=\"283\" y1=\"42\" x2=\"293\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"293.0,42.0 285.5,45.2 285.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"294\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">invalidateQueries</text><line x1=\"425\" y1=\"42\" x2=\"435\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"435.0,42.0 427.5,45.2 427.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"436\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"501.0\" y=\"35.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GET</text><text x=\"501.0\" y=\"48.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/planner</text><line x1=\"567\" y1=\"42\" x2=\"577\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"577.0,42.0 569.5,45.2 569.5,38.8\" fill=\"var(--wire)\"></polygon><rect x=\"578\" y=\"20\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">leitores renderizam</text><text x=\"225\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o servidor muda</text><text x=\"507\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a cópia é buscada de novo</text></svg>", "caption": "Mude no servidor, marque a cópia como velha, busque de novo."}
```

Invalidar e buscar de novo custa uma requisição por mudança, e é o padrão simples e correto: a tela
mostra exatamente o que o servidor guarda. Há dois jeitos de economizar a requisição, e os dois trocam
simplicidade por velocidade. O `setQueryData` escreve a resposta do servidor direto no cache, o que
funciona quando a mutação devolve tudo de que a tela precisa. E uma **atualização otimista** muda o
cache antes de o servidor responder, para a marcação aparecer na hora, e a desfaz se a requisição
falhar. Esse é o assunto da aula 16, com o hook do próprio React para isso.
