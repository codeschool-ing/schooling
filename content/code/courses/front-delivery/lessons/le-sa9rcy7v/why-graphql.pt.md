---
title: Por que GraphQL
version: 1
---

**GraphQL é uma linguagem para pedir dados a um servidor, em que o cliente nomeia cada campo que quer e a
resposta tem exatamente esse formato.** Um servidor que fala GraphQL publica um **schema**, a lista de
tipos e campos que ele sabe responder, e recebe toda pergunta num único endereço. O cliente escreve uma
**consulta**, o servidor a confere contra o schema, executa e devolve um JSON organizado como a consulta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma consulta contra o seu schema. À esquerda, o tipo Course do schema tem os campos id, title, sessions e minutesPlanned, e Session tem id, course, date, minutes e done. No meio, uma consulta pede o curso git com o título e a data e os minutos das sessões; esses campos estão marcados no schema. À direita, a resposta tem exatamente esses campos, aninhados do mesmo jeito.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o schema</text><text x=\"260\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a consulta</text><text x=\"490\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a resposta</text><rect x=\"20\" y=\"34\" width=\"210\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">type Course {</text><text x=\"42\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id: ID!</text><text x=\"42\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">title: String!</text><text x=\"42\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sessions: [Session!]!</text><text x=\"42\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutesPlanned: Int!</text><text x=\"30\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">type Session {</text><text x=\"42\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id: Int!</text><text x=\"42\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">course: Course!</text><text x=\"42\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">date: String!</text><text x=\"42\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">minutes: Int!</text><text x=\"42\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">done: Boolean!</text><text x=\"30\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><rect x=\"250\" y=\"34\" width=\"210\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{</text><text x=\"272\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">course(id: \"git\") {</text><text x=\"284\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">title</text><text x=\"284\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sessions {</text><text x=\"296\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">date</text><text x=\"296\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">minutes</text><text x=\"284\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"272\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"260\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><rect x=\"480\" y=\"34\" width=\"220\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{\"data\": {</text><text x=\"502\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"course\": {</text><text x=\"514\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"title\": \"Git\",</text><text x=\"514\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"sessions\": [</text><text x=\"526\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{\"date\": \"2026-10-08\",</text><text x=\"532\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"minutes\": 30}</text><text x=\"514\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">]</text><text x=\"502\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><text x=\"490\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}}</text><line x1=\"232\" y1=\"140\" x2=\"248\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"462\" y1=\"140\" x2=\"478\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,140.0 470.6,143.1 470.6,136.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"355\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conferida contra o schema</text></svg>", "caption": "O cliente nomeia os campos; o servidor os confere contra o schema e responde no mesmo formato, sem nada a mais."}
```

## O que muda para um front-end

O planner lê o `courses.json`, um arquivo com tudo dentro. Uma API REST costuma dividir os mesmos dados em
endereços, um por tipo de coisa: `/courses`, `/courses/git`, `/courses/git/sessions`. Uma página que
mostra um curso com as sessões pede dois ou três deles, e cada resposta traz todos os campos que o
servidor decidiu pôr nela, a página mostrando-os ou não.

Um cliente GraphQL pede uma vez, exatamente o que a página desenha:

```
{
  course(id: "git") {
    title
    sessions {
      date
      minutes
    }
  }
}
```

Os dois problemas que isso elimina têm nome: **over-fetching**, receber campos que ninguém usa, e
**under-fetching**, precisar de um segundo pedido para o que o primeiro deixou de fora. Num celular numa
rede lenta, os dois custam segundos.

## O que custa

Nada disso é de graça, e uma equipe deve conhecer a conta antes de escolher:

- **O cache fica mais difícil.** Toda consulta vai para o mesmo endereço, normalmente como `POST`, então
  os caches HTTP que um navegador e uma CDN já têm não ajudam; os clientes da aula 10 fazem cache por
  objeto, em vez disso.
- **O servidor trabalha mais por requisição.** Uma consulta pode pedir cursos, as sessões deles, o curso
  de cada sessão, as sessões dele, e assim por diante. Um servidor GraphQL público limita a profundidade e
  o tamanho de uma consulta, e confere permissões em cada campo, não uma vez por endereço.
- **Erros chegam com um 200.** A seção sobre erros mostra o que isso significa para o código que lê a
  resposta.

O GraphQL foi criado no Facebook para os seus apps de celular e publicado como especificação aberta em
2015; hoje é mantido pela GraphQL Foundation. Ele não torna o REST obsoleto. Esta aula é sobre o lado do
cliente, e o curso `apis`, na trilha de backend, constrói o lado do servidor a fundo.
